function [im1,im2] = pivCreateImageSequence(imagelist,PairInterval,FirstIm,DiffIn,MaxPairs)
% pivCreateImageSequence - process list of image files in two lists of images pairs
%
% Usage:
%    [im1,im2] = pivCreateImageSequence(imagelist)
%    [im1,im2] = pivCreateImageSequence(imagelist,pivPar)
%    [im1,im2] = pivCreateImageSequence(imagelist,PairInterval)
%    [im1,im2] = pivCreateImageSequence(imagelist,PairInterval,FirstIm)
%    [im1,im2] = pivCreateImageSequence(imagelist,PairInterval,FirstIm,Diff)
%    [im1,im2] = pivCreateImageSequence(imagelist,PairInterval,FirstIm,Diff,MaxPairs)
%
% Inputs:
%    imagelist ... (cell array) List of images (or image paths) in the sequence
%    PairInterval ... (if uncpesified, default value is 2): interval between the index of first image in
%        consecutive pairs. E.g., if PairInterval == 1, image pairs will be Img01 + Img02, Img02 + Img03,
%        Img03 + Img04, etc. If PairInterval == 2, image pairs will be Img01 + Img02, Img03 + Img04, Img05 +
%        Img06, etc. For PairInterval == 5, the sequence is Img01+Img02, Img06+Img07, Img11+Img12, etc.
%    FirstIm ... (if unspecified, default value is 1): position of the first image of the first pair in the
%        imagelist. E.g., if PairInterval = 2 and FirstIm = 2, image pairs are Img02 + Img03, Img04 + Img05,
%        Img06 + Img07, etc. 
%    Diff ... (if unspecified, default value is 1): difference between index of images within one pair.
%        Allowed values are 1, 3, 5, 7, ... . E.g. if PairInterval == 5, FirstIm = 5 and Diff = 1, image pairs 
%        are Img05 + Img06, Img10 + Img11, Img15 + Img16. If PairInterval == 5 and Diff = 1, FirstIm = 5 and 
%        Diff = 3, image pairs are Img04 + Img07, Img09 + Img12, Img14 + Img17 etc. This parameter allows to
%        increase time difference between images in the case of time-resolved records.
%    MaxPairs ... (if unspecified, default value is +Inf): Maximum number of images in the output lists. 
%    pivPar ... (structure) pivPar structure. Fields seqPairInterval, seqFirstIm, seqDiff, seqMaxPairs are
%        used as corresponding input parameters.
%
% Outputs:
%    im1, im2 ... (cell arrays) List of filenames with first and second image in the pair, respectively.
%
%
%        
% This subroutine is a part of
%
% =========================================
%               PIVsuite
% =========================================
%
% PIVsuite is a set of subroutines intended for processing of data acquired with PIV (particle image
% velocimetry) within Matlab environment. 
%
% Written by Jiri Vejrazka, Institute of Chemical Process Fundamentals, Prague, Czech Republic
%
% For the use, see files example_XX_xxxxxx.m, which acompany this file. PIVsuite was tested with
% Matlab 7.12 (R2011a) and 7.14 (R2012a).
%
% In the case of a bug, please, contact me: vejrazka (at) icpf (dot) cas (dot) cz  
%
%
% Requirements:
%     Image Processing Toolbox 
%         (required only if pivPar.smMethod is set to 'gaussian')
% 
%     inpaint_nans.m
%         subroutine by John D'Errico, available at http://www.mathworks.com/matlabcentral/fileexchange/4551
%
%     smoothn.m
%         subroutine by Damien Garcia, available at 
%         http://www.mathworks.com/matlabcentral/fileexchange/274-smooth
%
% Credits:
%    PIVsuite is a redesigned version of a part of PIVlab software [3], developped by W. Thielicke and 
%    E. J. Stamhuis. Some parts of this code are copied or adapted from it (especially from its 
%    piv_FFTmulti.m subroutine). 
%
%    PIVsuite uses 3rd party software:
%        inpaint_nans.m, by J. D'Errico, [2]
%        smoothn.m, by Damien Garcia, [5]
%        
% References:
%   [1] Adrian & Whesterweel, Particle Image Velocimetry, Cambridge University Press, 2011
%   [2] John D'Errico, inpaint_nans subroutine, http://www.mathworks.com/matlabcentral/fileexchange/4551
%   [3] W. Thielicke and E. J. Stamhuid, PIVlab 1.31, http://pivlab.blogspot.com
%   [4] Raffel, Willert, Wereley & Kompenhans, Particle Image Velocimetry: A Practical Guide. 2nd edition,
%       Springer, 2007
%   [5] Damien Garcia, smoothn subroutine, http://www.mathworks.com/matlabcentral/fileexchange/274-smooth



% complete unset parameters
if nargin == 2 && isstruct(PairInterval)
    aux = PairInterval;
    if isfield(aux,'seqPairInterval'), PairInterval = aux.seqPairInterval; else PairInterval = 1; end
    if isfield(aux,'seqFirstIm'), FirstIm = aux.seqFirstIm; else FirstIm = 1; end
    if isfield(aux,'seqDiff'), DiffIn = aux.seqDiff; else DiffIn = 1; end
    if isfield(aux,'seqMaxPairs'), MaxPairs = aux.seqMaxPairs; else MaxPairs = +Inf; end
else
    if nargin < 2, PairInterval = 1; end
    if nargin < 3, FirstIm = 1; end
    if nargin < 4, DiffIn = 1; end
    if nargin < 5, MaxPairs = +Inf; end
end

% adapt values
FirstIm = FirstIm - 1;
Diff = round((DiffIn - 1)/2);
if 2*Diff+1 ~= DiffIn || Diff<0
    disp('Error: parameter Diff should be 1, 3, 5, 7, ...');
    im1 = {};
    im2 = {};
    return
end

% number of image pairs
N0 = ceil((- FirstIm)/PairInterval + 1);
N0 = max(N0,1);
Nend = floor((numel(imagelist)-FirstIm-2*Diff-2)/PairInterval+1);
Nend = min(Nend,MaxPairs+N0-1);


% initialize image lists
im1 = cell(1,Nend-N0+1);
im2 = cell(1,Nend-N0+1);

% complete the image lists for first and second image in the pair
for kk=N0:Nend
    index1 = (kk-1)*(PairInterval) + FirstIm + 1;
    index2 = (kk-1)*(PairInterval) + FirstIm + 2*Diff + 2;
    im1{kk-N0+1} = imagelist{index1};
    im2{kk-N0+1} = imagelist{index2};
end
    
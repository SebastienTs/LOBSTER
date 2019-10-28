function [pivDataSeq] = pivAnalyzeImageSequence(im1,im2,pivDataIn,pivParIn,pivParInit)
% pivAnalyzeImageSequence - performs analysis of displacement between pairs of images using PIV technique
%
% Usage:
% [pivDataSeq] = pivAnalyzeImageSequence(im1,im2,pivDataIn,pivPar,pivParInit)
%
% Inputs:
%    im1,im2 ... list of first and second images in pairs (must contain strings with paths to image files)
%    pivDataIn ... (struct) structure containing velocity field estimate. Depending on pivPar.anVelocityEst,
%          the estimate will be used as follows:
%            - if .anVelocityEst == 'none', pivDataIn input will be ignored
%            - if .anVelocityEst == 'previousPair', velocity field contained in pivDataIn will be used as an
%              velocity estimate for the first pair of images
%            - if .anVelocityEst == 'pivData', then pivDataIn must contain n velocity fields, where n is
%              numel(im1). For kth image pair, kth velocity field of kth time slice in pivDataIn will be used 
%              as the velocity estimate.
%    pivPar ... (struct) parameters defining the evaluation. Use pivParams.m for creating pivPar. Following 
%            fields are considered:
%      --- prefix an - these fields are used mostly in subroutines pivAnalyseImagePair.m
%          anNpasses ... number of passes
%          anOnDrive ... (logical) If true, results of processing of each image pair are stored in the folder
%               specified by .anTargetPath.
%          anTargetPath ... specified folder, to which files containing results of PIV analysis of each image
%               pair are stored
%          anForceProcessing ... if false and if .anOnDrive is true, processing of an image pair is skipped if
%               an output file for a given image pair already exists. Results stored in the output file is
%               read instead. If .anForceProcessing is true, image pair is analyzed and if the output file
%               exists, it is overwritten.
%          anPairsOnly ... if true and if .anOnDrive is true, the subroutine processes only image pairs, but
%               it does not produce final file with sequence data. If this option is set, much less memory is
%               required for processing.
%          anStatsOnly ... if true, the subroutine pivAnalyzeImageSequence.m processes image pairs and add
%               them to the velocity statistics. The final data of velocity processing includes only velocity
%               statistics, but not complete velocity record. Much less memory is required for processing.
%      --- prefix ia - these fields are used mostly in subroutine pivInterrogate.m
%          iaSizeX, iaSizeY ... size of interrogation area [px]
%          iaStepX, iaStepY ... step between interrogation areas [px]
%          imMask1, imMask2 ... Masking images for im1 and im2. It should be either empty (no mask), or of the
%               same size as im1 and im2. Masked pixels should be 0 in .imMaskX, non-masked pixels should be 1
%          iaMethod ... way, how interrogation area are created. Possible values are
%               'basic' ... interrogatio areas are regularly distribute rectangles
%               'offset' ... (not coded) interrogation areas are shifted by the estimated displacement
%               'deflinear' ... (not coded) deformable interrogation areas with linear deformation
%               'defspline' ... (not coded) deformable interrogation areas with spline deformation
%             - Note: if Uest and Vest contains only zeros or if they are empty/unspecified, 'basic' method is
%                    always invoked regardless .iaMethod setting
%          iaImageToDeform ... defines, which image should deform. It is taken in account if .iaMethod is
%                  'deflinear' or 'defspline', or if it is 'offset' (then it defines, in which image IAs are
%                  shifted). Possible values are
%              'image1', 'image2' ... either im1 or im2 is deformed correspondingly to Uest and Vest
%              'both' ... deformation both images are deformed by Uest/2 and Vest/2. Sligthly more CPU time is
%                         required.
%          iaImageInterpolationMethod ... way, how the images are interpolated when deformable IAs are used 
%                  (for .iaMethod == 'deflinear' or 'defspline'. Possible values are:
%              'linear', 'spline' ... interpolation is carried out using interp2 function with option either
%                                     '*linear' or '*spline'
%      --- prefix cc - these fields are used mostly in subroutines pivCrossCorr.m
%          ccRemoveIAMean ... if =0, do not remove IA's mean before cross-correlation; if =1, remove the mean;
%              if in between, remove the mean partially
%          ccMaxDisplacement ... maximum allowed displacement to accept cross-correlation peak. This parameter
%              is a multiplier; e.g. setting ccMaxDisplacement = 0.6 means that the cross-correlation peak
%              must be located within [-0.6*iaSizeX...0.6*iaSizeX, -0.6*iaSizeY...0.6*iaSizeY] from the zero
%              displacement.
%            - Note: IA offset is not included in the displacement accounted by ccMaxDisplacement, hence real
%              displacement can be larger if ccIAmethod is any other than 'basic'.
%      --- prefix vl - these fields relates to vector validation, subroutine pivValidate.m
%          vlTresh, vlEps ... Define treshold for the median test. To accepted, the difference of actual vector
%              from the median (of vectors in the neighborhood) should be at most vlTresh *(vlEps +
%              (neighborhood vectors) - (their median))
%          vlDist ... to what distance median test is performed (if vlDist = 1, kernel has size 3x3; for
%              vlDist = 2, kernel is 5x5, and so on)
%          vlPasses ... number of passes of the median test
%      --- prefix rp - affects replacement of invalid vectors, subroutine pivReplace.m
%          rpMethod ... specifies how the spurious vectors are replaced. Possible values are
%              'none' ... do not replace spurious vectors
%              'linear' ... replace spurious vectors with the use of TriScatteredInterp in Matlab, specifying
%                   its method as 'linear'. If pivData contains data for image sequence, replacement is done 
%                   in each time slice indepedently on other time slices.
%              'natural' ... replace spurious vectors with the use of TriScatteredInterp in Matlab, specifying
%                   its method as 'natural'. If pivData contains data for image sequence, replacement is done 
%                   in each time slice indepedently on other time slices.
%              'inpaint' ... use D'Errico's subroutine "inpaint_nans". If pivData contains data for image 
%                   sequence, replacement is done in each time slice indepedently on other time slices.
%              'inpaintGarcia' ... use Garcia's subroutine "inpaintn". If pivData contains data for image 
%                   sequence, replacement is done in each time slice indepedently on other time slices.
%              'linearT' ... replace spurious vectors with the use of TriScatteredInterp in Matlab, specifying
%                   its method as 'linear'. If pivData contains data for image sequence, replacement considers
%                   also values in other time slices.
%              'naturalT' ... replace spurious vectors with the use of TriScatteredInterp in Matlab, 
%                   specifying its method as 'natural'. If pivData contains data for image sequence, 
%                   replacement considers also values in other time slices.
%              'inpaintT' ... use D'Errico's subroutine "inpaint_nans". If pivData contains data for image 
%                   sequence, replacement considers also values in other time slices.
%              'inpaintGarciaT' ... use Garcia's subroutine "inpaintn". If pivData contains data for image 
%                   sequence, replacement considers also values in other time slices.
%      --- prefix sm - affects smoothing of vector field, subroutine pivSmooth.m
%          smMethod ... defines smoothing method. Possible values are:
%              'none' ... do not perform smoothing
%              'smoothn' ... uses smoothn.m function by Damian Garcia [5]
%              'gauss' ... uses Gaussian kernel
%          smSigma ... amount of smoothing
%          smSize ... size of filter (applies only to Gaussian filter)
%
% Outputs:
%    pivData  ... (struct) structure containing more detailed results. If some fiels were present in pivData 
%           at the input, they are repeated. Followinf fields are added:
%        imFilename1, imFilename2 ... path and filename of image files (stored only if im1 and im2 are 
%              filenames)
%        imMaskFilename1, imMaskFilename2 ... path and filename of masking files (stored only if imMask1 and 
%              imMask2 are filenames)
%        N ... number of interrogation area (= of velocity vectors)
%        Nx, Ny ... number of "rows" and "columns", N = Nx*Ny
%        Nt ... number of velocity fields (= image pairs)
%        X, Y ... matrices with centers of interrogation areas (positions of velocity vectors)
%        U, V ... components of velocity vectors
%        Status ... matrix with statuis of velocity vectors (uint8). Bits have this coding:
%            1 (bit 1) ... masked (set by pivInterrogate)
%            2 (bit 2) ... cross-correlation failed (set by pivCrossCorr)
%            4 (bit 3) ... peak detection failed (set by pivCrossCorr)
%            8 (bit 4) ... indicated as spurious by median test based on image pair (set by pivValidate)
%           16 (bit 5) ... interpolated (set by pivReplaced)
%           32 (bit 6) ... smoothed (set by pivSmooth)
%           64 (bit 7) ... indicated as spurious by median test performed on image sequence (set by pivValidate)
%          128 (bit 8) ... interpolated within image sequence (set by pivReplaced)
%          256 (bit 9) ... smoothed within an image sequence (set by pivSmooth)
%           (example: if Status for a particulat point is 56 = 32 + 16 + 8, the velocity vector in this point
%            was indicated as spurious, was replaced by interpolating neighborhood values and was then
%            adjusted by smoothing.)
%        iaSizeX, iaSizeY, iaStepX, iaStepY ... copy of dorresponding fields in pivPar input
%        imSizeX, imSizeY ... image size in pixels
%        imFilename1, imFilename2 ... path and filename of image files (stored only if im1 and im2 are 
%            filenames)
%        imMaskFilename1, imMaskFilename2 ... path and filename of masking files (stored only if imMask1 and 
%            imMask2 are filenames)
%        imNo1, imNo2, imPairNo ... image number and number of image pair (stored only if im1 and im2 are 
%            string with filenames of images). For example, if im1 and im2 are 'Img000005.bmp' and 
%            'Img000006.bmp', value will be imNo1 = 5, imNo2 = 6, and imPairNo = 5.5.
%        ccPeak ... table with values of cross-correlation peak
%        ccPeakSecondary ... table with values of secondary cross-correlation peak (maximum of
%                            crosscorrelation, if 5x5 neighborhood of primary peak is removed)
%        ccFailedN ... number of vectors for which cross-correlation failed
%            at distance larger than ccMaxDisplacement*(iaSizeX,iaSizeY) )
%        ccSubpxFailedN ... number of vectors for which subpixel interpolation failed
%        spuriousN ... number of spurious vectors (status 1)
%        spuriousX, spuriousY ... positions, at which the velocity is spurious
%        spuriousU, spuriousV ... components of the velocity/displacement vectors, which were indicated as
%                             spurious
%        replacedN ... number of interpolated vectors (status 2)
%        replacedX,replacedY ... positions, at which velocity/displacement vectors were replaced
%        replacedU,replacedV ... components of the velocity/displacement vectors, which were replaced
%        validN ... number of original and vectors
%        validX,validY ... positions, at which velocity/displacement vectors is original and valid
%        validU,validV ... original and valid components of the velocity/displacement vector
%        infCompTime ... 1D array containing computational time of individual passes (in seconds)
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


% Acronyms and meaning of variables used in this subroutine:
%    IA ... concerns "Interrogation Area"
%    im ... image
%    dx ... some index
%    ex ... expanded (image)
%    est ... estimate (velocity from previous pass) - will be used to deform image
%    aux ... auxiliary variable (which is of no use just a few lines below)
%    cc ... cross-correlation
%    vl ... validation
%    sm ... smoothing
%    Word "velocity" should be understood as "displacement"


% Check if some image pairs are defined. If not, exit. 
if numel(im1)==0 || numel(im2)==0
    pivDataSeq = [];
    if isfield(pivParIn,'jmLockFile') && numel(pivParIn.jmLockFile)>0 && exist(pivParIn.jmLockFile,'file')
        delete(pivParIn.jmLockFile);
    end
    return;
end

% Check the existance of output folder. If it does not exist, try to create it. If unsuccessful, give a
% message.
if pivParIn.anOnDrive && ~exist(pivParIn.anTargetPath,'dir')
    try
        mkdir(pivParIn.anTargetPath);
    catch  %#ok<*CTCH>
        disp('Error: Target folder does not exist');
        return;
    end
end

% Test, if the final output file is present
[~,filename1] = treatImgPath(im1{1});
[~,filename2] = treatImgPath(im2{1});
if numel(im2)>1
    [~,filename3] = treatImgPath(im1{2});
    [~,filename4] = treatImgPath(im2{end});
else
    [~,filename3] = treatImgPath(im1{end});
    [~,filename4] = treatImgPath(im2{end});
end
seqFilename = [pivParIn.anTargetPath,'/pivSeq_',filename1,'_',filename2,'_',filename3,'_',filename4,'.mat'];
pivSeqFileExist = exist(seqFilename,'file');

% Test, whether presence of all files should be pretested
TestFilePresence = true;
if isfield(pivParIn,'seqJobNumber'), TestFilePresence = false; end
if ~pivParIn.anOnDrive, TestFilePresence = false; end
if pivParIn.anForceProcessing, TestFilePresence = false; end


% Check the presence of all output files. If all output files are present, read the data and skip the processing.
AllFilesFound = false;
if TestFilePresence
    AllFilesFound = true;
    fprintf('Checking presence of %d output files...', numel(im1)+1);
    tic;
    % get list of existing output files 
    aux = dir([pivParIn.anTargetPath, '/piv*.mat']);
    filelist = cell(numel(aux,1));
    for ki = 1:numel(aux)
        filelist{ki,1} = aux(ki).name;
    end
    % get list of required output files
    if ~pivParIn.anPairsOnly
        requiredFiles = cell(numel(im1),1);
    else
        requiredFiles = cell(numel(im1),1);
    end
    for ki = 1:numel(im1)
        [~,filename1] = treatImgPath(im1{ki});
        [~,filename2] = treatImgPath(im2{ki});
        requiredFiles{ki,1} = ['piv_',filename1, '_', filename2, '.mat'];
    end
    % check presence of required files (complicated for better speed...)
    auxPrevious = 0;
    for ki = 1:numel(requiredFiles)
        auxFound = false; % first check, if it is not close to previously found file
        for kj = 1:10
            try
                if strcmpi(requiredFiles{ki,1},filelist{auxPrevious+kj})
                    auxPrevious = auxPrevious + kj;
                    auxFound = true;
                    break
                end
            catch
            end
        end
        if auxFound, continue; end
        auxFound = false;   % now check, if it is elsewhere in the file list
        for kj = 1:numel(filelist)
            if strcmpi(requiredFiles{ki,1},filelist{kj})
                auxPrevious = kj;
                auxFound = true;
                break
            end
        end
        if ~auxFound
            AllFilesFound = false;
            break
        end
    end
    if AllFilesFound
        fprintf(' Finished in %.2f s. All required files found.\n',toc);
    else
        fprintf(' Finished in %.2f s. Some files are missing. \n', toc);
    end
end
% Now variable AllFilesFound contains info about presence of files with results

% Decide, whether process image pairs, or read results and leave:
ReadAndLeave = false;
if isfield(pivParIn,'seqJobNumber') && pivSeqFileExist, ReadAndLeave = true; end
if AllFilesFound && pivSeqFileExist, ReadAndLeave = true; end


% if all files are present, read the last output file end exit subroutine
if ReadAndLeave
    fprintf(' Reading results from result file. This will take a while (in my Matlab, Ctrl+C does not work at this stage)...');
    tic
    pause(0.02);
    if ~pivParIn.anPairsOnly
        aux = load(seqFilename,'pivDataSeq');
        pivDataSeq = aux.pivDataSeq;
    else
        pivDataSeq = [];
    end
    fprintf(' Finished in %.2f s. \n',toc);
    if isfield(pivParIn,'jmLockFile') && numel(pivParIn.jmLockFile)>0 && exist(pivParIn.jmLockFile,'file')
        delete(pivParIn.jmLockFile);
        auxF = fopen([pivParIn.jmLockFile(1:end-4) '_Finished.lck'],'w');
        fprintf(auxF,'Processing finished.');
        fclose(auxF);
    end
    return;
end


% initialization
LastLoopProcessed = false;    % flag whether results for previous image pair is in memory
pivData = pivDataIn;

% check, whether first image pair should be processed with different settings:
if nargin>4, initPair = 0;   % if yes, initialization start with ki = 0, denoting initialization....
else initPair = 1;
end

%% Loop through all images
for ki = initPair:numel(im1)
    % get filenames and numbers in filenames. Behave differently for initialization
    if ki==0
        fprintf('Initialization: Analyzing first image pair...');
        [imgNo1,filename1] = treatImgPath(im1{1});
        [imgNo2,filename2] = treatImgPath(im2{1});
        pivPar = pivParInit;
        KI = 1;  % this index serves for indexing im1 and im2
    else
        if isfield(pivParIn,'expName')
            auxstr = pivParIn.expName;
        else
            auxstr = '???';
        end
        fprintf('Treating pair %d of %d (%s)...', ki, numel(im1),auxstr);
        [imgNo1,filename1] = treatImgPath(im1{ki});
        [imgNo2,filename2] = treatImgPath(im2{ki});
        pivPar = pivParIn;
        KI = ki;
    end
    % check the processing mode. If treating on hard-drive, check the existance of output file. If outputfile
    % is present, read data from it and pass to next image pair.
    if pivParIn.anOnDrive
        if ki == 0
            filenameOut = ['pivInit_',filename1, '_', filename2, '.mat'];
        else
            filenameOut = ['piv_',filename1, '_', filename2, '.mat'];
        end
        pathOut = [pivParIn.anTargetPath, '/', filenameOut];
        if exist(pathOut,'file') && ~pivParIn.anForceProcessing
            aux = load(pathOut,'pivData');
            pivData = aux.pivData;
            LastLoopProcessed = false;
            fprintf(' Results found (%s). Skipping processing.\n', filenameOut);
            if ki==1 && ~pivParIn.anPairsOnly && ~pivParIn.anStatsOnly
                pivDataSeq = pivManipulateData('initSequenceData',pivData,numel(im1));
                pivDataSeq = pivManipulateData('initStatData',pivDataSeq,pivData);
            elseif ki==1 && ~pivParIn.anPairsOnly && pivParIn.anStatsOnly
                pivDataSeq = pivManipulateData('initStatData',pivDataSeq,pivData);
            elseif ki>1 && ~pivParIn.anPairsOnly && ~pivParIn.anStatsOnly
                pivDataSeq = pivManipulateData('writeTimeSlice',pivDataSeq,pivData,KI);
                pivDataSeq = pivManipulateData('writeToStat',pivDataSeq,pivData);
            elseif ki>1 && ~pivParIn.anPairsOnly && pivParIn.anStatsOnly
                pivDataSeq = pivManipulateData('writeToStat',pivDataSeq,pivData);
            else
                pivDataSeq = [];
            end
            % update lock file
            if isfield(pivParIn,'jmLockFile') && numel(pivParIn.jmLockFile)>0
                flock = fopen(pivParIn.jmLockFile,'w');
                fprintf(flock,[datestr(clock) '\nResults for image pair read from file...']);
                fclose(flock);
            end
            continue
        end
    end
    % read images (if image2 from previous pair is same as image1 from actual pair, read only image 2)
    if LastLoopProcessed && strcmp(im2{KI-1},im1{KI}) && ki>1
        Img1 = Img2;
        Img2 = imread(im2{KI});
    else
        Img1 = imread(im1{KI});
        Img2 = imread(im2{KI});
    end
    % get velocity estimate: either previous velocity field, or read it from pivDataIn
    switch lower(pivParIn.anVelocityEst)
        case 'previous'
            % do nothing
        case 'previoussmooth'
            auxPar.smMethod = 'smoothn';
            auxPar.smSigma = 0.1;
            if isfield(pivData,'U')
                pivData = pivSmooth(pivData,auxPar);
            end
        case 'none'
            pivData = [];
        case 'pivdata'
            pivData = pivManipulateData('readTimeSlice',pivDataIn,KI); 
    end
    % if image mask is different for each frame, separate it
    if iscell(pivParIn.imMask1) && numel(pivParIn.imMask1)>1
        pivPar.imMask1 = pivParIn.imMask1{KI};
    elseif isnumeric(pivParIn.imMask1) && size(pivParIn.imMask1,3)>1
        pivPar.imMask1 = pivParIn.imMask1(:,:,KI);
    elseif ischar(pivParIn.imMask1)
        pivPar.imMask1 = pivParIn.imMask1;
    end
    if iscell(pivParIn.imMask2) && numel(pivParIn.imMask2)>1
        pivPar.imMask2 = pivParIn.imMask2{KI};
    elseif isnumeric(pivParIn.imMask2) && size(pivParIn.imMask2,3)>1
        pivPar.imMask2 = pivParIn.imMask2(:,:,KI);
    elseif ischar(pivParIn.imMask2)
        pivPar.imMask2 = pivParIn.imMask2;
    end
    % analyze the image pair
    pivData = pivAnalyzeImagePair(Img1,Img2,pivData,pivPar);
    % store information about image numbers and filenames
    pivData.imFilename1 = im1{KI};
    pivData.imFilename2 = im2{KI};
    pivData.imNo1 = imgNo1;
    pivData.imNo2 = imgNo2;
    pivData.imPairNo = (imgNo1+imgNo2)/2;
    % store results to pivDataSeq, if not working on disk. If working on disk, save to file.
    if ki==1 && ~pivParIn.anPairsOnly && ~pivParIn.anStatsOnly
        pivDataSeq = pivManipulateData('initSequenceData',pivData,numel(im1));
        pivDataSeq = pivManipulateData('initStatData',pivDataSeq,pivData);
    elseif ki==1 && ~pivParIn.anPairsOnly && pivParIn.anStatsOnly
                pivDataSeq = pivManipulateData('initStatData',pivDataSeq,pivData);
    elseif ki>1 && ~pivParIn.anPairsOnly && ~pivParIn.anStatsOnly
        pivDataSeq = pivManipulateData('writeTimeSlice',pivDataSeq,pivData,KI);
        pivDataSeq = pivManipulateData('writeToStat',pivDataSeq,pivData);
    elseif ki>1 && ~pivParIn.anPairsOnly && pivParIn.anStatsOnly
        pivDataSeq = pivManipulateData('writeToStat',pivDataSeq,pivData);
    else
        pivDataSeq = [];
    end
    if pivParIn.anOnDrive
        save(pathOut,'pivData');
        if isfield(pivParIn,'jmLockFile') && numel(pivParIn.jmLockFile)>0
            flock = fopen(pivParIn.jmLockFile,'w');
            fprintf(flock,[datestr(clock) '\nWriting results for image pair...']);
            fclose(flock);
        end
    end
    if ki > 0
        LastLoopProcessed = true;     % set if something computed, except initialization
    end
    % some echo
    fprintf(' Accomplished in %.2f s, last pass %.2f s, Subpix failure %.2f %%, Median-test rejection %.2f %%\n', ...
        sum(pivData.infCompTime), pivData.infCompTime(end), pivData.ccSubpxFailedN/pivData.N*100, pivData.spuriousN/pivData.N*100);
end; % end of loop, in which all files are treated or read

% validate, replace and smooth sequence, if required
if ~pivParIn.anPairsOnly && ~pivParIn.anStatsOnly && isfield(pivPar,'vlDistTSeq') && pivPar.vlDistTSeq > 0
    pivDataSeq = pivValidate(pivDataSeq,pivPar);
end
if ~pivParIn.anPairsOnly && ~pivParIn.anStatsOnly && isfield(pivPar,'rpMethod') && lower(pivPar.rpMethod(end))=='t'
    tic
    fprintf('Replacing spurious velocity vectors... ');
    pivDataSeq = pivReplace(pivDataSeq,pivPar);
    fprintf('Finished in %.2f s.\n', toc);
end;
if ~pivParIn.anPairsOnly && ~pivParIn.anStatsOnly && isfield(pivPar,'smMethodSeq') && ~strcmpi(pivPar.smMethodSeq,'none');
    tic
    fprintf('Smoothing velocity field in the sequence... ');
    pivDataSeq = pivSmooth(pivDataSeq,pivPar);
    fprintf('Finished in %.2f s.\n', toc);
end

% add information about number of time steps and elements
if ~pivParIn.anPairsOnly
    pivDataSeq.Nt = numel(im1);
    pivDataSeq.Nx = size(pivDataSeq.X,2);
    pivDataSeq.Ny = size(pivDataSeq.X,1);
    pivDataSeq = orderfields(pivDataSeq);
end

% save all sequence data
if pivParIn.anOnDrive && ~pivParIn.anPairsOnly
    if isfield(pivParIn,'jmLockFile') && numel(pivParIn.jmLockFile)>0
        flock = fopen(pivParIn.jmLockFile,'w');
        fprintf(flock,[datestr(clock) '\nWriting results for PIV sequence']);
        fclose(flock);
    end
    save(seqFilename,'pivDataSeq','-v7.3');
end

% erase lock file when finished
if isfield(pivParIn,'jmLockFile') && numel(pivParIn.jmLockFile)>0 && exist(pivParIn.jmLockFile,'file')
    delete(pivParIn.jmLockFile);
    auxF = fopen([pivParIn.jmLockFile(1:end-4) '_Finished.lck'],'w');
    fprintf(auxF,'Processing finished.');
    fclose(auxF);
end

end


%% local functions
function [imgNo, filename, folder] = treatImgPath(path)
% separate the path to get the folder, filename, and number if contained in the name
filename = '';
imgNo = [];
folder = '';
if numel(path)>0
    path = path(end:-1:1);
    I = find(path=='/'|path=='\');
    I = I(1);
    Idot = find(path=='.');
    Idot = Idot(1);
    try
        folder = path(I+1:end);
        folder = folder(end:-1:1);
    catch  %#ok<CTCH>
        folder = '';
        I = length(path)+1;
    end
    try
        filename = path(Idot+1:I-1);
        filename = filename(end:-1:1);
    catch  %#ok<CTCH>
        filename = '';
    end
    try
        aux = regexp(filename,'[0-9]');
        aux = filename(aux);
        imgNo = str2double(aux);
    catch  %#ok<CTCH>
        imgNo = [];
    end
end
end

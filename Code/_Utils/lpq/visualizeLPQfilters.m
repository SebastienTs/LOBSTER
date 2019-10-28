function []=visualizeLPQfilters(LPQfilters)
% function [] = visulizeLPQfilters(LPQfilters) visualized the precomputed LPQ filters.
%
% Input:
% LPQfilters = 8*neigborhoodPix*numAngle double, Precomputed LPQ filters (computed using createLPQfilters.m function). 
%                                                If no filters are given they are automatically created with default parameters.
%
% Output:
% function will draw an image, where each row contains filters at one angle. Column correspond to filters at each frequency point. 
% odd columns show the real part and even columns the imaginary part.
%

% Version published in 2010 by Janne Heikkilä, Esa Rahtu, and Ville Ojansivu 
% Machine Vision Group, University of Oulu, Finland

%% Default inputs
% LPQ filters
if nargin<1 || isempty(LPQfilters)
    LPQfilters=createLPQfilters; % Creat LPQ filters if they are not given. Use default parameters (see createLPQfilters.m)
end

% Border in image between two rows of filters (in pixels)
brd=5;

%% Initialize
numAngle=size(LPQfilters,3); % Number of different oriented LPQ filters
winSize=sqrt(size(LPQfilters,2)); % Size of the window (read from pre-computed LPQ filters) This is "enlarged" window size, which fits all rotated filters.
filterImage=zeros(winSize*numAngle+(numAngle-1)*brd,8*winSize);
filPart=zeros(winSize,8*winSize);

%% Loop through rotation angles and draw each filter set
cnt=1;
for i=1:numAngle
    flt=LPQfilters(:,:,i).'; % Get filter from filter array
    filPart(:)=flt(:); % Reshape filter to winSize x winSize
    filterImage(cnt:(cnt+winSize-1),:)=filPart; % Draw filter to filter image
    cnt=cnt+winSize; % Add counter
    if i<numAngle % Leave small cap between different rows
        cnt=cnt+brd;
    end
end

%% Draw filter image
figure;
imshow(filterImage,[]);
title('LPQ filters. Each Row corresponds to one angle. Odd and even columns show the real and imaginary parts of the filter, respectively.');






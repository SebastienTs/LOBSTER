%Tristan Ursell
%Read large image stack (TIFF)
%Feb 2017
%Modified by Sébastien Tosi to support image field crop (Dec 2018)
%
% This function can load TIFF image stacks larger than 4GB.  
% Designed to work with single-channel uncompressed TIFF stacks.  
% Also works for files smaller than 4GB.
%
% [stack_out,Nframes] = imread_big(stack_name,read_x,read_y,start_x,start_y);
%
% stack_name = the path and file name to the image stack
%
% optional input arguments:
% start_x, start_y: Position of image field to read
% read_x, read_y: Size of image field to read
%
% Nframes = number of frames as determined by total file size divided by
% estimated size of each frame data block
%
% stack_out = the output image stack

function [stack_out,Nframes] = imread_big(stack_name,varargin)

%% Get data block size
info1 = imfinfo(stack_name);
stripOffset = info1(1).StripOffsets;
stripByteCounts = info1(1).StripByteCounts;

%% Get image size
sz_x = info1(1).Width;
sz_y = info1(1).Height;
if length(info1)<2
    Nframes=floor(info1(1).FileSize/stripByteCounts);
else
    Nframes=length(info1);
end

%% Crop mode
if nargin > 1
    st_x = varargin{1};
    st_y = varargin{2};
    rd_x = varargin{3};
    rd_y = varargin{4};
else
    st_x = 0;
    st_y = 0;
    rd_x = sz_x;
    rd_y = sz_y;
end

%% Allocate memory
if info1(1).BitDepth==16
    stack_out = zeros([rd_y rd_x Nframes],'uint16');
else
    stack_out = zeros([rd_y rd_x Nframes],'uint8');
end

%% Open file
fID = fopen (stack_name, 'r');

%% Compute starting point
if info1(1).BitDepth==16
    start_point = stripOffset(1) + (0:1:(Nframes-1)).*stripByteCounts + 2*(st_x + st_y*sz_x);
else
    start_point = stripOffset(1) + (0:1:(Nframes-1)).*stripByteCounts + st_x + st_y*sz_x;
end

%% Read data from starting point
for i = 1:Nframes
    fseek (fID, start_point(i)+1, 'bof');
    if info1(1).BitDepth==16
        A = fread (fID, [rd_x rd_y], [num2str(rd_x) '*uint16=>uint16'],2*(sz_x-rd_x));
    else
        A = fread (fID, [rd_x rd_y], [num2str(rd_x) '*uint8=>uint8' ],(sz_x-rd_x));
    end
    stack_out(:,:,i) = A';
end

%% Close file
fclose(fID);
function [info BigTIFF] = imfinfo_big(stack_name)

%% Get data block size
info = imfinfo(stack_name);
stripByteCounts = info(1).StripByteCounts;

%% Get image size
if length(info)<2
    info(1).NFrames = floor(info(1).FileSize/stripByteCounts);
    info(1).BigTIFF = 1;
else
    info(1).NFrames = length(info);
    info(1).BigTIFF = 0;
end
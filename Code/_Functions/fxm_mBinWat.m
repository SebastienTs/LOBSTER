function [M] = fxm_mBinWat(I, params)

    % Split objects by binary watershed algorithm.
    %
    % Sample journal: No journal currently uses this function, prefer fxm_mModBinWat.m 
    %
    % Input: 2D binary mask
    % Output: 2D binary mask
    %
    % Parameters:
    % SmallHolesArea:   Maximum holes area (pix)

    %% Parameters
    SmallHolesArea = params.SmallHolesArea;

    if ~isempty(I) 
        
        %% Close small holes
        I = ~bwareaopen(~I,SmallHolesArea);
        
        %% Compute distance map
        D = bwdist(~I);
        
        %% Watershed image
        Dopp = -D;
        M = (watershed(Dopp)>0);
        M(~I) = 0;
        
        %% Create output
        M = uint8(255*M);
        
    else
       
        M = [];
        
    end

end
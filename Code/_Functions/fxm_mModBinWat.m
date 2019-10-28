function [M] = fxm_mModBinWat(I, params)

    % Split objects by modified watershed algorithm.
    %
    % Sample journal: <a href="matlab:JENI('RiceGrains_ModBinWat.jl');">RiceGrains_ModBinWat.jl</a>
    %
    % Input: 2D binary mask
    % Output: 2D binary mask
    %
    % Parameters:
    % SmallHolesArea:   Maximum holes area (pix)
    % DistStdRad:       Disk size to compute distance map local variance (pix)
    % MinDistLocVar:    Minimum distances local variance for seeding (pix)

    %% Parameters
    SmallHolesArea = params.SmallHolesArea;
    DistStdRad = params.DistStdRad;
    MinDistLocVar = params.MinDistLocVar;

    if ~isempty(I) 
        
        %% Filter used to compute local std
        nhood = getnhood(strel('disk',DistStdRad));
        
        %% Close small holes
        I = ~bwareaopen(~I,SmallHolesArea);
        
        %% Compute distance map
        [D IDX] = bwdist(~I);
        [Xp Yp] = ind2sub(size(I),IDX);
        
        %% Find split points
        R = stdfilt(Xp, nhood).^2+stdfilt(Yp, nhood).^2;
        R = imhmax(R,MinDistLocVar);
        BW = imregionalmax(R);
        
        %% Watershed image
        Dopp = -D;
        Dopp = imimposemin(Dopp,BW);
        M = (watershed(Dopp)>0);
        M(~I) = 0;
        
        %% Create output
        M = uint8(255*M);
        
    else
       
        M = [];
        
    end

end
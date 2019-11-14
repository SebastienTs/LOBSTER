function [M] = fxm_mFilterObjSize(M, params)

    % Only keep objects in given area/volume range.
    %
    % Sample journal: <a href="matlab:JENI('VesselsSpots_sptdet.jl');">VesselsSpots_sptdet_sptdet.jl</a>
    %
    % Input: Binary mask (2D/3D)
    % Output: Binary mask (2D/3D)
    %
    % Parameters:
    % MinArea: Minimum object area/volume (pix/vox)
    % MaxArea: Maximum object area/volume (pix/vox)
 
    %% Parameters
    MinArea = params.MinArea;
    MaxArea = params.MaxArea;
    
    M = uint8(M);
    
    if (MinArea > 0) || (MaxArea < Inf)
     
        %% Analyze connected particles and compute their areas
        M = uint8(255*(M>0));
        CC = bwconncomp(M);
        areas = regionprops(CC,'Area');
        areas = round(vertcat(areas.Area));

        %% Remove particles outside user defined area/volume range
        for i = 1:CC.NumObjects
            if (areas(i)>MaxArea)|(areas(i)<MinArea)
                M(CC.PixelIdxList{i}) = 0;
            end
        end
    
    end
        
end
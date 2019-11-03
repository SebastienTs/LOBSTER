function [M] = fxm_mFilterObjSizeLbl(M, params)

    % Only keep objects in given area/volume range. Label objects.
    %
    % Sample journal: <a href="matlab:JENI('Cytopacq_Segment_lbl.jl');">VesselsSpots_sptdet_sptdet.jl</a>
    %
    % Input: Binary mask (2D/3D)
    % Output: Label mask (2D/3D)
    %
    % Parameters:
    % MinArea: Minimum object area/volume (pix/vox)
    % MaxArea: Maximum object area/volume (pix/vox)
 
    %% Parameters
    MinArea = params.MinArea;
    MaxArea = params.MaxArea;
    
    if (MinArea > 0) || (MaxArea < Inf)
    
        %% Analyze connected particles and compute their areas
        M = uint16(255*(M>0));
        CC = bwconncomp(M);
        areas = regionprops(CC,'Area');
        areas = round(vertcat(areas.Area));

        %% Remove particles outside user defined area/volume range
        for i = 1:CC.NumObjects
            if (areas(i)>MaxArea)|(areas(i)<MinArea)
                M(CC.PixelIdxList{i}) = 0;
            else
                M(CC.PixelIdxList{i}) = i;
            end
        end
    
    end
        
end
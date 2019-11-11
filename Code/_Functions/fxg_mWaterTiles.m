function [M] = fxg_mWaterTiles(A, params)
    
    % Detect edges (intensity gradient magnitude) and apply watershed from intensity regional minima 
    % to segment objects into tiles. 
    %
    % Sample journal: <a href="matlab:JENI('Tissue_SegWaterTiles.jl');">Tissue_SegWaterTiles.jl</a>
    %
    % Input: 2D grayscale image
    % Output: 2D binary mask
    %
    % Parameters:
    % GRad:             Gaussian blur radius (pix)
    %                   Higher: increased robustness to noise but resolution loss
    % ExtendedMinThr:   Regional minimal noise tolerance (gray levels) 
    %                   Lower: more (weaker edges) tiles detected 

    GRad = params.GRad;
    ExtendedMinThr = params.ExtendedMinThr;
    
    if ~isempty(A)
    
        %% Gaussian blur filter
        Gint = fspecial('gaussian',[round(GRad*2+1) round(GRad*2+1)], GRad);
        Af = imfilter(A, Gint, 'same', 'symmetric');

        %% Compute regional minima seeded watershed
        Marker = single(imextendedmin(Af,ExtendedMinThr));
        Amod = imimposemin(Af, Marker);
        M = uint8(255*watershed(Amod));
        
    else
        
        M = [];
        
    end
    
end
function [M] = fxg_mWaterTiles(A, params)
    
    % Apply watershed algorithm from intensity regional minima.
    %
    % Sample journal: <a href="matlab:JENI('Tissue_SegWaterTiles.jl');">Tissue_SegWaterTiles.jl</a>
    %
    % Input: 2D grayscale image
    % Output: 2D binary mask
    %
    % Parameters:
    % GRad:             Gaussian blur pre-filter radius (pix)
    % ExtendedMinThr:   Regional minimal noise tolerance

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
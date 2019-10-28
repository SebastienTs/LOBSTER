function [M] = fxg_mGradWaterTiles(A, params)
    
    % Apply watershed algorithm (from regional intensity minima) to gradient magnitude image.
    %
    % Sample journal: <a href="matlab:JENI('NucleiCytoo_GradWaterTilesMerge.jl');">NucleiCytoo_GradWaterTilesMerge.jl</a>
    %
    % Input: 2D grayscale image
    % Output: 2D binary mask
    %
    % Parameters:
    % GRad:             Gaussian blur pre-filter radius (pix)
    % ExtendedMinThr:   Intensity regional minima detection noise tolerance

    GaussianRadInt = params.GaussianRadInt;
    ExtendedMinThr = params.ExtendedMinThr;
    
    if ~isempty(A)
    
        %% Gaussian blur filter
        Gint = fspecial('gaussian',[round(GaussianRadInt*2+1) round(GaussianRadInt*2+1)], GaussianRadInt);
        Af = imfilter(A, Gint, 'same', 'symmetric');

        %% Compute gradient vector field and magnitude
        [AGx,AGy] = gradient(single(Af));
        AGm = sqrt(AGx.^2+AGy.^2);
        Af = AGm;

        %% Compute regional minima seeded watershed
        Marker = single(imextendedmin(Af,ExtendedMinThr));
        Amod = imimposemin(Af, Marker);
        M = uint8(255*watershed(Amod));
    
    else
       
        M = [];
        
    end

end
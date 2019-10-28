function [O] = fxg_sLocMax(I, params)

    % Local intensity extrema detection (mark seeds).
    %
    % Sample journal: <a href="matlab:JENI('NucleiDAB_LocMaxRadFeatSVM.jl');">NucleiDAB_LocMaxRadFeatSVM.jl</a>
    %
    % Input: 2D grayscale image
    % Output: 2D seed mask
    %
    % Parameters:
    % GRad:             Gaussian blur pre-filter radius (pix)
    % LocalMaxBox:      Local extrema search box size (pix)    
    % ThrLocalMax:      Min/max intensity to validate extrema
    % Polarity:         Set to 1 for maxima and -1 for minima

    % Parameters
    GRad = params.GRad;
    LocalMaxBox = params.LocalMaxBox;
    ThrLocalMax = params.ThrLocalMax;
    Polarity = params.Polarity;

    if ~isempty(I)

        %% Initialize filters
        F = fspecial('gaussian', round(5*GRad), GRad);
        LocMxse = ones(LocalMaxBox(1),LocalMaxBox(2));
        LocMxse(ceil(end/2),ceil(end/2)) = 0;

        %% Filter image
        If = imfilter(I, F,'same','symmetric');

        %% Local extrema detection
        if Polarity == 1
            Extrema = If > imdilate(If,LocMxse);
            O = uint8(200*Extrema.*(If>ThrLocalMax));
        else
            Extrema = If < imerode(If,LocMxse);
            O = uint8(200*Extrema.*(If<ThrLocalMax));
        end
        
    else
        
        O = [];
        
    end
    
end
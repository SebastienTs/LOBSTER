function [If] = fxg_gEnhanceVessels2D(I, params)

    % Computes vesselness probability map (local tubularity)
    %
    % Sample journal: <a href="matlab:JENI('EyeFundus_Enhance.jl');">EyeFundus_Enhance.jl</a>
    %
    % Input: 2D grayscale image
    % Output: 2D grayscale image
    %
    % Parameters:
    % Scales:   Scales used to compute vesselness (vector)
    % Spacings: Input image XY spacing
    % Tau:      Controls response uniformity (between 0.5 and 1)
	%			Higher tau -> stronger discrimination 
    % Polarity: Set to 1 for bright vessels
    % Gamma:    Post-filtering gamma correction
    
    % Parameters
    Scales = params.Scales;
    Spacings = params.Spacings;
    Tau = params.Tau;
    Polarity = params.Polarity;
    Gamma = params.Gamma;
    
    if ~isempty(I)
        I = single(I)/max(I(:));
        If = vesselness2D(I, Scales, Spacings, Tau, Polarity);
        if Gamma ~= 1
            If = If.^Gamma;
        end
        If = uint8(255*If/max(If(:)));
    else
        If = [];  
    end
     
end
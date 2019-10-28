function [If] = fxg_gEnhanceVessels2D(I, params)

    % Calculates vesselness probability map (local tubularity) of a 3D input image
    %
    % Sample journal: <a href="matlab:JENI('EyeFundus_Enhance.jl');">EyeFundus_Enhance.jl</a>
    %
    % Input: 2D grayscale image
    % Output: 2D grayscale image
    %
    % Parameters:
    % Scales:   Vector of scales on which the vesselness is computed
    % Spacings: Input image spacing resolution  
    % Tau:      Controls response uniformity (between 0.5 and 1), lower tau -> more spread 
    % Polarity: Set to 1 for bright vessels
    % Gamma:    Post-filtering gamma
    
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
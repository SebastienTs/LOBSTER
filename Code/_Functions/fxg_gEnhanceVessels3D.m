function [If] = fxg_gEnhanceVessels3D(I, params)

    % Calculates vesselness probability map (local tubularity) 
    %
    % Sample journal: <a href="matlab:JENI('BloodVessels3D_VessLocThr3DSkl3D.jls');">BloodVessels3D_VessLocThr3DSkl3D.jls</a>
    %
    % Input: 3D grayscale image
    % Output: 3D grayscale image
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
        If = vesselness3D(I, Scales, Spacings, Tau, Polarity);
        if Gamma ~= 1
            If = If.^Gamma;
        end
        If = uint8(255*If/max(If(:)));
    else
        If = [];  
    end
     
end
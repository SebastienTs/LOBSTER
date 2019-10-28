function [Imc] = fxg_gIllumCorr(Im, params)

    % Correct illumination by rescaling to local median intensity.
    %
    % Sample journal: <a href="matlab:JENI('CellColonies3D_StackFocuser3D.jls');">CellColonies3D_StackFocuser3D.jls</a>
    %
    % Input: 2D grayscale image
    % Output: 2D grayscale image (8-bit) !! Intensity rescaled to 255 !!
    %
    % Parameters:
    % Scale:    Rescaling factor prior to processing (<=1, speedup vs details)
    % Rad:      2D Median filter radius (after image rescaling)
    
    Scale = params.Scale;           % Rescale image to compute correction map
    Rad = params.Rad;               % Radius used for illumination correction (after rescaling)

    if ~isempty(Im)
        Ims = imresize(Im,Scale);
        Imsm = medfilt2(Ims, [Rad Rad], 'symmetric');
        Imm = imresize(Imsm,1/Scale,'bilinear');
        Imc = uint8(255*Im./Imm);
    else
        Imc = [];
    end
    
end
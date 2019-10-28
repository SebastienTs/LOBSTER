function [M] = fxg_gSieveValue(M, params)

    % Set all pixels with intensity different to input value to 0.
    %
    % Input: Any image (2D/3D)
    % Output: Any image (2D/3D)
    %
    % Parameters:
    % Value: Intensity value to keep in the image

    Value = params.Value;
    M(M ~= Value) = 0;    
    
end
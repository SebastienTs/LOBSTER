function [DenoisedImg, NoisyImg] = fxg_gDenoiseBM3(I, params)

    % Denoise by BM3D algorithm.
    %
    % Sample journal: <a href="matlab:JENI('NucleiNoisy_DenoiseBM3.jl');">NucleiNoisy_DenoiseBM3.jl</a>
    %
    % Input: 2D grayscale image
    % Output: 2D grayscale image, 2D noisy image (if AddNoiseVar > 0)
    %
    % Parameters:
    % AddNoiseVar:  Add noise to input image (set to 0!)

    AddNoiseVar = params.AddNoiseVar;

    if ~isempty(I)
        I = im2double(uint8(I));
        NoisyImg = I;

        if AddNoiseVar>0
            NoisyImg = imnoise(I,'gaussian', 0, AddNoiseVar);
        end

        [NA DenoisedImg] = BM3D(1, NoisyImg*255);
        DenoisedImg = uint16(DenoisedImg*255);
        
    else
        
        DenoisedImg = [];
        NoisyImg = [];
        
    end
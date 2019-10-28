function [Btot, NoisyImg] = fxg_gDenoiseDCT(I, params)

    % Denoise by thresholding small DCT coefficients in overlapping analysis blocks.
    %
    % Sample journal: <a href="matlab:JENI('NucleiNoisy_DenoiseDCT.jl');">NucleiNoisy_DenoiseDCT.jl</a>
    %
    % Input: Image
    % Output: Image, noisy image (if AddNoiseVar > 0)
    %
    % Parameters:
    % Winize:       DCT window size (pix)
    % Step:         DCT window shift (pix, control windows overlap)
    % Thresh:       DCT coefficients threshold
    % TopOpen:      Top-hat opening filter radius (postprocess, set to 0 to disable)
    % AddNoiseVar:  Add noise to input image (set to 0!)

    WinSize = params.WinSize;  
    Step = params.Step;
    Thresh = params.Thresh;
    AddNoiseVar = params.AddNoiseVar;
    TopOpen = params.TopOpen;
    scl = max(I(:));
    NoisyImg = double(I)/scl;

    if ~isempty(I)
    
        if AddNoiseVar>0
            NoisyImg = imnoise(I,'gaussian', 0, AddNoiseVar);
        end

        padX = mod(size(I,1),WinSize);
        padY = mod(size(I,2),WinSize);
        I = [zeros(padX,size(I,2));I];
        I = [zeros(size(I,1),padY) I];
        Btot = zeros(size(I));
        Bj   = zeros(size(I));

        avg = 1;
        for j=0:Step:WinSize-1
            [Bj] = dctfltadp(circshift(I, [j j]),WinSize,2,Thresh);
            Btot = Btot+circshift(Bj, [-j -j]);
            avg  = avg+1;
        end
        Btot = Btot(1+padX:end,1+padY:end)/avg;

        if TopOpen>0
            Btot = imtophat(Btot, strel('disk',TopOpen));
        end

        %% Convert to 16-bit
        Btot = uint16(Btot);
        
    else
        
        Btot = [];
        NoisyImg = [];
        
    end
        
end
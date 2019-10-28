function [It] = fxg_mBlockOtsu(I, params)

    % Accumulate Otsu thresholded overlapping blocks and threshold accumulated image.
    %
    % Sample journal: <a href="matlab:JENI('NucleiCytoo_BlockOtsuThr.jl');">NucleiCytoo_BlockOtsuThr.jl</a>
    %
    % Input: 2D grayscale image
    % Output: 2D binary mask
    %
    % Parameters:
    % OpenRad:          Morphological opening pre-filter radius (pix, reduce noise)
    % TopHatRad:        Background subtraction pre-filter radius (pix, reduce background)
    % BlckSize:         Block size (pix)
    % BlckShft:         Step between blocks (pix)
    % MinRatio:         Minimum max/min local std intensity to process image
    % Lvl:              Minimum std to mean intensity to process block
    % Bck:              Object detection threshold
    % AbsBck:           Background level, everything below is considered background
    
    OpenRad = params.OpenRad;
    TopHatRad = params.TopHatRad;
    BlckSize = params.BlckSize;
    BlckShft = params.BlckShft;
    Lvl = params.Lvl;
    MinRatio = params.MinRatio;
    Bck = params.Bck;
    AbsBck = params.AbsBck;

    if ~isempty(I)
        
        % Rescale to uint8 for Otsu thresholding
        I = uint8(255*I/max(I(:)));

        % Smoothening
        If = imopen(I, strel('disk',OpenRad));

        % Attenuate very smooth regions
        If = imtophat(If,strel('disk',TopHatRad));

        % Contrast test
        fun = @(block_struct) std2(block_struct.data);
        Istd = blockproc(single(I),[BlckSize,BlckSize],fun,'PadMethod','symmetric');
        Ratio = max(Istd(:))/(min(Istd(:))+eps);

        % Thresholding
        if Ratio >= MinRatio
            fun = @(block_struct) BlockOtsu(block_struct.data, Lvl);
            It = zeros(size(If));
            for i = 0:BlckShft:BlckSize-1
                for j = 0:BlckShft:BlckSize-1
                    Is = circshift(If, [i j]);
                    It = It + circshift(blockproc(Is,[BlckSize,BlckSize],fun,'PadMethod','symmetric'), [-i -j]); 
                end
            end
            It = uint8(255*((It >= (Bck*(BlckSize/BlckShft)^2))&(I >= (AbsBck*255))));
        else
           It = uint8(zeros(size(I)));
        end

    else
        
        It = [];
        
    end
        
end
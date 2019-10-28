function [O] = fxg_sLocMax3D(I, params)

    % 3D local intensity extrema detection (mark seeds).
    %
    % Sample journal: <a href="matlab:JENI('Nuclei3D_DetLog3DLocMax3D.jls');">Nuclei3D_DetLog3DLocMax3D.jls</a>
    %
    % Input: 3D grayscale image
    % Output: 3D seed mask
    %
    % Parameters:
    % Sigmas:           X,Y,Z sigmas for Gaussian blur pre-filter (vector, pix)
    % LocalMaxBox:      Local extrema search box size (pix)     
    % ThrLocalMax:      Min/max intensity to validate extrema
    % Polarity:         Set to 1 for maxima and -1 for minima

    %% Parameters
    Sigmas = params.Sigmas;
    LocalMaxBox = params.LocalMaxBox;
    ThrLocalMax = params.ThrLocalMax;
    Polarity = params.Polarity;

    if ~isempty(I)

        %% Initialize filters
        LocMxse = ones(LocalMaxBox(1),LocalMaxBox(2),LocalMaxBox(3));
        LocMxse(ceil(end/2),ceil(end/2),ceil(end/2)) = 0; 
        
        disp('Filtering stack...');
        %% 3D Gaussian filter
        I = single(I);
        G2 = fspecial('gauss',[round(7*Sigmas(2)) 1], Sigmas(2));
        G1 = fspecial('gauss',[round(7*Sigmas(1)) 1], Sigmas(1));
        G3 = fspecial('gauss',[round(7*Sigmas(3)) 1], Sigmas(3));
        If = imfilter(I,G2,'same'); 
        If = imfilter(If,permute(G1,[2 1 3]),'same'); 
        If = imfilter(If,permute(G3,[3 2 1]),'same'); 
        
        %% Local extrema detection
        if Polarity == 1
            Extrema = If > imdilate(If,LocMxse);
            O = uint8(200*imdilate(Extrema.*(If>ThrLocalMax),ones(5,5)));
        else
            Extrema = If < imerode(If,LocMxse);
            O = uint8(200*imdilate(Extrema.*(If<ThrLocalMax),ones(5,5)));
        end
        
    else
        
    	O = [];
        
    end
    
end
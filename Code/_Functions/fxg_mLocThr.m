function [It] = fxg_mLocThr(I, params)

    % 2D local threshold.
    %
    % Sample journal:
    %
    % Input: 2D grayscale image
    % Output: 2D binary mask
    %
    % Parameters:
    % Sigmas:       Gaussian blur X,Y radii (vector, pix)
    % MeanBox:      X, Y box size to compute local mean (vector, pix)
    % AddThr:       Minimum difference to local mean
    % IgnoreZero:   If set to 1 ignore zeros in local mean computation

    %% Parameters
    Sigmas = params.Sigmas;
    MeanBox = params.MeanBox;
    AddThr = params.AddThr;
    IgnoreZero = params.IgnoreZero;

    if ~isempty(I)

            M2 = ones(MeanBox(2),1)/MeanBox(2);
            M1 = ones(MeanBox(1),1)/MeanBox(1);
            if IgnoreZero
                I0 = single(I==0);
                Im0 = imfilter(I0,M2,'same','symmetric');
                clear I0;
                Im0 = imfilter(Im0,permute(M1,[2 1 3]),'same','symmetric'); 
            end
            Im = imfilter(I,M2,'same','symmetric'); 
            Im = imfilter(Im,permute(M1,[2 1 3]),'same','symmetric'); 
            if IgnoreZero == 1
                Im = Im./(1-Im0);
                clear Im0;
                I(isnan(I)) = 0;
            end
            
            if sum(Sigmas)>0
                G2 = fspecial('gauss',[round(Sigmas(2)*5) 1], Sigmas(2));
                G1 = fspecial('gauss',[round(Sigmas(1)*5) 1], Sigmas(1));
                If = imfilter(I,G2,'same','symmetric'); 
                If = imfilter(If,permute(G1,[2 1 3]),'same','symmetric');
            else
                If = I;
            end
            It = uint8(255*( (If >= (Im + AddThr)) ));
            
    else
        
        It = [];
        
    end
      
end
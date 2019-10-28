function [It] = fxg_mLocThr3D(I, params)

    % 3D local threshold.
    %
    % Sample journal: <a href="matlab:JENI('BloodVessels3D_LocThr3D.jls');">BloodVessels3D_LocThr3D.jls</a>
    %
    % Input: 3D grayscale image
    % Output: 3D binary mask
    %
    % Parameters:
    % Sigmas:       Gaussian blur X,Y,Z radii (vector, pix)
    % MeanBox:      X, Y, Z box size to compute local mean (vector, pix)
    % AddThr:       Minimum difference to local mean
    % IgnoreZero:   Ignore zeros in local mean computation
    % DoubleThr:    Perform a second threshold, ignoring thresholded voxels in mean computation
    % MinVol:       Minimum 3D connected objects volume
    
    %% Parameters
    Sigmas = params.Sigmas;
    MeanBox = params.MeanBox;
    AddThr = params.AddThr;
    IgnoreZero = params.IgnoreZero;
    DoubleThr = params.DoubleThr;
    MinVol = params.MinVol;
    
    if ~isempty(I)

            %% Initialize filters
            M2 = ones(MeanBox(2),1)/MeanBox(2);
            M1 = ones(MeanBox(1),1)/MeanBox(1);
            M3 = ones(MeanBox(3),1)/MeanBox(3);
        
            %% Filter image
            if sum(Sigmas)>0
                G2 = fspecial('gauss',[round(Sigmas(2)*5) 1], Sigmas(2));
                G1 = fspecial('gauss',[round(Sigmas(1)*5) 1], Sigmas(1));
                G3 = fspecial('gauss',[round(Sigmas(3)*5) 1], Sigmas(3));
                If = imfilter(I,G2,'same','symmetric'); 
                If = imfilter(If,permute(G1,[2 1 3]),'same','symmetric'); 
                If = imfilter(If,permute(G3,[3 2 1]),'same','symmetric');
            else
                If = I;
            end
        
            %% Compute local mean
            Im = imfilter(I,M2,'same','symmetric'); 
            Im = imfilter(Im,permute(M1,[2 1 3]),'same','symmetric'); 
            Im = imfilter(Im,permute(M3,[3 2 1]),'same','symmetric');
            
            %% Ignore null voxels
            if IgnoreZero
                I0 = single(I==0);
                Im0 = imfilter(I0,M2,'same','symmetric');
                clear I0;
                Im0 = imfilter(Im0,permute(M1,[2 1 3]),'same','symmetric'); 
                Im0 = imfilter(Im0,permute(M3,[3 2 1]),'same','symmetric');
            end
            if IgnoreZero == 1
                Im = Im./(1-Im0);
                clear Im0;
                I(isnan(I)) = 0;
            end
            
            %% First threshold
            It = uint8(255*( (If >= (Im + AddThr)) ));
            
            if DoubleThr == 1
                %% Pass 2 (ignore already thresholded voxels in mean computation)
                I0 = single(It>0);
                I(It>0) = 0;
                Im0 = imfilter(I0,M2,'same','symmetric');
                clear I0;
                Im0 = imfilter(Im0,permute(M1,[2 1 3]),'same','symmetric'); 
                Im0 = imfilter(Im0,permute(M3,[3 2 1]),'same','symmetric');
                Im = imfilter(I,M2,'same','symmetric'); 
                Im = imfilter(Im,permute(M1,[2 1 3]),'same','symmetric'); 
                Im = imfilter(Im,permute(M3,[3 2 1]),'same','symmetric');
                Im = Im./(1-Im0);
                clear Im0;

                % Threshold 2
                It = uint8(255*( (If >= (Im + AddThr)) ));
            end
            
            %% Remove small isolated skeletons
            if MinVol > 0
                It = uint8(bwareaopen(It>0,MinVol,26));
            end
            
    else
        
        It = [];
        
    end
      
end
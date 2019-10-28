function [M] = fxg_mRadStdThr(I, params)

    % Radial local standard deviation threshold.
    %
    % Sample journal: <a href="matlab:JENI('Mitochondria_RadStdThr.jl');">Mitochondria_RadStdThr.jl</a>
    %
    % Input: 2D grayscale image
    % Output: 2D binary mask
    %
    % Parameters:
    % Grad:         Gaussian blur pre-filter radius (pix)
    % RSet:         Analysis disks radii (vector, pix)
    % Fracstd:      Fraction of total variance to include
    % SegThr:       Object detection sensitivity
    
    % Parameters
    GRad = params.GRad;
    RSet = params.RSet;
    Fracstd = params.Fracstd;
    SegThr = params.SegThr;
 
    if ~isempty(I)
    
        % Compute background level
        %Isrt = sort(I);
        %BckLvl = Isrt(length(Isrt)/4)*1.25;

        % 2D filters
        Ggauss = fspecial('gaussian',[round(GRad*2+1) round(GRad*2+1)],GRad);
        Gmean = cell(length(RSet),1);
        cnt = 1;
        for i = [RSet]
            Gmean{cnt} = fspecial('disk',i);
            cnt = cnt+1;
        end

        % Filter image
        I = imfilter(double(I),Ggauss,'same','symmetric');

        % Compute image variance
        IVar = mean(I(:).^2)-mean(I(:))^2;

        % Compute local variance
        Ilvar = zeros(length(RSet),size(I,1),size(I,2));
        Ilmean = zeros(length(RSet),size(I,1),size(I,2));
        cnt = 1;
        for i = [RSet]
            buf = imfilter(I,Gmean{cnt},'same','symmetric');
            Ilmean(cnt,:,:) = buf;
            Ilvar(cnt,:,:) = imfilter(I.^2,Gmean{cnt},'same','symmetric')-buf.^2;
            cnt = cnt+1;
        end

        % Find minimum radius to reach aim normalized variance
        flag = (Ilvar >= IVar*(Fracstd^2));
        [val indx] = max(flag, [], 1);
        indx = squeeze(indx);

        % Intensity local normalization
        [i j] = ind2sub(size(I),1:numel(I));
        Iladpmean = Ilmean(sub2ind(size(Ilmean),indx(:),i.',j.'));
        Iladpstd = max(sqrt(IVar)*Fracstd,sqrt(Ilvar(sub2ind(size(Ilmean),indx(:),i.',j.'))));
        In = (I-reshape(Iladpmean,size(I)))./reshape(Iladpstd,size(I));

        % Thresholding
        M = uint8(255*(In >= SegThr));%&(I >= BckLvl);
         
    else
        
        M = [];
        
    end

end
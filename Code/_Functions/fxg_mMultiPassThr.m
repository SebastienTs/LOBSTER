function [It3] = fxg_mMultiPassThr(I, params)

    % Multi-pass local thresholding.
    %
    % Sample journal: <a href="matlab:JENI('NucleiCytoo_MultiPassThr.jl');">NucleiCytoo_MultipassThr.jl</a>
    %
    % Input: 2D grayscale image
    % Output: 2D binary mask
    %
    % Parameters:
    % NeighRad:         Radius of disk used for local thresholding (pix)
    % GaussRad:        	Gaussian blur pre-filter radius (pix)
    % Rescale:          Rescaling factor prior to processing (>=1, speedup vs detail)
    % Th1:              Lower threshold
    % Th2:              Higher threshold
    % Rel:              Seed average intensity rescaling
    % MinArea:          Min object area (pix)

    NeighRad = params.NeighRad;
    GaussRad = params.GaussRad;
    Rescale = params.Rescale;
    Th1 = params.Th1;
    Th2 = params.Th2;
    MinArea = params.MinArea;
    Rel = params.Rel;

    if ~isempty(I)
    
        %% Compute local mean
        Gmean = fspecial('disk',NeighRad/Rescale);
        Im = imresize(imfilter(imresize(I,1/Rescale,'method','nearest'),Gmean,'symmetric'),size(I),'method','nearest');

        %% Smooth image
        If = imgaussfilt(I,GaussRad,'padding','symmetric');

        %% Compute 2 thresholded images (low, high)
        It1 = (If>=(Im+Th1));
        It2 = (If>=(Im+Th2));

        %% Re-estimate local mean by this time considering significant "connected regions"
        CC = bwconncomp(It1);
        Pxs = CC.PixelIdxList;
        Im = single(zeros(size(I)));
        for i = 1:CC.NumObjects
            Pxsi = Pxs{i};
            SeedArea = sum(It2(Pxsi));
            mn = mean(I(Pxsi));
            if SeedArea>0
                Im(Pxsi) = mn*Rel;
            end
        end

        %% Second pass: perform local thresholding / local mean
        It3 = Im;
        It3(It3==0) = Inf;
        It3 = imresize(imerode(imresize(It3,1/Rescale,'method','nearest'),strel('disk',round(NeighRad/Rescale))),size(I),'method','nearest');

        %% Combine segmentation masks
        It3 = (((If >= (It3))+ Im)>0);

        %% Remove small objects
        It3 = bwareaopen(It3,MinArea);
        It3 = uint8(255*It3);
        
    else
        
        It3 = [];
        
    end
    
end
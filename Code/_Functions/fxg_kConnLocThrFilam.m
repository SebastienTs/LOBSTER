function [M] = fxg_kConnLocThrFilam(I, params)

    % Connected local thresholding to segment filaments + thinning.
    %
    % Sample journal: <a href="matlab:JENI('EyeVesselsSpots_ConnLocThrFilamClean.jl');">EyeVesselsSpots_ConnLocThrFilamClean.jl</a>
    %
    % Input: 2D grasycale image
    % Output: 2D skeleton mask
    %
    % Parameters:
    % GRad:             Gaussian blur pre-filter radius (pix)
    % LocMeanRad:       Radius of disk used to compute local mean (pix)
    % LocMeanThr1:      Intensity threshold (seed)
    % LocMeanThr2:      Intensity threshold (connected objects)
    % MinSeedArea:      Minimum seed area (pix)

    % Parameters
    GRad = params.GRad;			
    LocMeanRad = params.LocMeanRad;				
	LocMeanThr1 = params.LocMeanThr1;			
	LocMeanThr2 = params.LocMeanThr2;
    MinSeedArea = params.MinSeedArea;
    
    if ~isempty(I)
    
        % 2D filters
        Ggauss = fspecial('gaussian',[round(GRad*2+1) round(GRad*2+1)],GRad);
        Gmean = fspecial('disk',LocMeanRad);
        Gcoh = fspecial('disk',3);
        se8 = strel(ones(3,3));

        %% 2-pass thresholding

        % Filter image
        Af = imfilter(I,Ggauss,'same','symmetric');

        % Local mean threshold pass 1
        Ilocmean = imfilter(Af,Gmean,'same','symmetric');
        At = (Af./Ilocmean) >= LocMeanThr1;
  
        % Local mean threshold pass 2
        Af2 = Af;
        Af2(At) = 0;
        Ilocmean2 = imfilter(Af2,Gmean,'same','symmetric');
        At2 = ((Af./Ilocmean2) >= LocMeanThr2);

        % Remove small objects + weak objects that are unconnected to bright objects
        At = bwareaopen(At, MinSeedArea);
        At2only = ((At2-At)>0); 
        At2only = single(imreconstruct(imdilate(At,se8),At2only));
        M = At|At2only;
      
        %imagesc(At+2*At2only);
        %figure;imagesc(I);
        %keyboard;
        
        %% Skeletonize
        skl = bwmorph(M,'thin',Inf);

        %% Create skeleton mask
        M = uint8(100*(M&(skl==0))+200*skl);  
        
    else
       
        M = [];
        
    end
    
end
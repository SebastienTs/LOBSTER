function [R] = fxg_kIsoScanFilam(I, params)

    % Enhance anisotropic structures + threshold + skeletonize.
    %
    % Sample journal: <a href="matlab:JENI('EyeVesselsSpots_IsoScanFilamClean.jl');">EyeVesselsSpots_IsoScanFilamClean.jl</a>
    %
    % Input: 2D grayscale image
    % Output: 2D skeleton mask
    %
    % Parameters:
    % GRad:             Gaussian blur pre-filter radius (pix)
    % NAngles:          Number of angles to scan
    % Len:              Scanning line length (pix)
    % Contrast1:        Directional contrast threshold 1 (grayscale lvl)
    % Contrast2:        Directional contrast threshold 2 (grayscale lvl)
    % Anis:             Minimum anisotropy
    % MaxHoleArea:      Maximum hole area (close holes post-processing, pix)
    
    %% Parameters
    GRad = params.GRad;
    NAngles = params.NAngles;
    Len = params.Len;
	Contrast1 = params.Contrast1;
	Contrast2 = params.Contrast2;
    Anis = params.Anis;
    MaxHoleArea = params.MaxHoleArea;

    if ~isempty(I)
    
        Ggauss = fspecial('gaussian',[round(GRad*2+1) round(GRad*2+1)],GRad);
        I = imfilter(I,Ggauss,'same','symmetric');

        %% Threshold
        Acc = zeros(size(I));
        Acc2 = zeros(size(I));
        Acc3 = zeros(size(I));
        Mx = zeros(size(I));
        Mn = ones(size(I))*Inf;
        for i = 0:180/NAngles:180-180/NAngles
            se = strel('line', Len, i);
            Iero = imerode(I,se);
            Idil = imdilate(I,se);
            Acc = Acc+((Idil-I)==0);
            Acc2 = Acc2+((I-Iero) >= Contrast1);
            Acc3 = Acc3+((I-Iero) >= Contrast2);
            Mx = max(Mx,Iero);
            Mn = min(Mn,Iero);    
        end
        R1 = (Acc2>=1)&((Mx-Mn)./(Mx+Mn)>=Anis);
        R2 = (Acc>=1)&(Acc3>=2)&((Mx-Mn)./(Mx+Mn)>=Anis);
        R = imreconstruct(imdilate(R1,ones(3,3)),R2);

        %% Close small holes inside vessels
        Rc = (~(bwareaopen(~R,MaxHoleArea,4)))-R;
        R = R|Rc;

        %% Skeletonize
        Rmask = R;
        R = bwmorph(R,'skel',Inf);
        
        %% Create skeleton mask
        R = uint8(100*((Rmask>0)&(R==0))+200*(R>0));
        
    else
        
        M = [];
        
    end
    
end
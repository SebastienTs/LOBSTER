function [M] = fxg_mIsoScanSpot(I, params)

    % Enhance pixels with strong central symmetry + threshold
    %
    % Sample journal: <a href="matlab:JENI('EyeVesselsSpots_IsoScanSpot.jl');">EyeVesselsSpots_IsoScanSpot.jl</a>
    %
    % Input: 2D image
    % Output: 2D binary mask
    %
    % Parameters:
    % GRad:             Gaussian blur pre-filter radius
    % Len:              Ray length (pix)
    % Tol:              Local threshold tolerance       
    % NAngles:          Number of ray angles
    % MinUnif:          Minimum min / max intensity ratio across rays
    
    % Parameters
    GRad = params.GRad;
    Len = params.Len;
    Tol = params.Tol;
    NAngles = params.NAngles;
    MinUnif = params.MinUnif;

    if ~isempty(I)
    
        %% Initialize filters
        GXY = fspecial('gaussian',[round(GRad*2+1) round(GRad*2+1)],GRad);
        se8 = [[1 1 1];[1 1 1];[1 1 1]];

        %% Filter
        I = imfilter(I,GXY,'same','symmetric');

        %% Local threshold
        B = medfilt2(I, [Len Len]);
        T = (I > (B+Tol));

        %% Uniformity filtering
        Acc = zeros(size(I));Acc2 = zeros(size(I));Acc3 = zeros(size(I));Mx = zeros(size(I));Mn = ones(size(I))*Inf;
        for i = 0:180/NAngles:180-180/NAngles
            se = strel('line', Len, i);
            mat = se.getnhood();
            l1 = size(mat,1);l2 = size(mat,2);
            mat1 = double(mat);mat2 = double(mat);
            if l1>=l2
                mat1(1:ceil(l1/2)-1,:) = 0;
                mat2(1+ceil(l1/2):end,:) = 0;
            else
                mat1(:,1:ceil(l2/2)-1) = 0;
                mat2(:,1+ceil(l2/2):end) = 0;
            end
            se1 = strel(mat1);
            se2 = strel(mat2);
            Iero1 = imerode(I,se1,'same');
            Iero2 = imerode(I,se2,'same');
            Ctr = (I-Iero1)./I;
            Mx = max(Mx,Ctr);Mn = min(Mn,Ctr);
            %Ctr = (I-Iero2)./(max(I,10));
            Ctr = (I-Iero2)./I;
            Mx = max(Mx,Ctr);Mn = min(Mn,Ctr);
        end
        R = ((Mn./Mx)>= MinUnif);
        
        %% Combining masks
        M = uint8(R&T);
        
        %% Adding seeds
        S = fxm_sMarkObjCentroids(M,[]);
        
        %% Final output
        M = M*100;
        M(find(S)) = 200;
        
    else
       
        M = [];
        
    end

end
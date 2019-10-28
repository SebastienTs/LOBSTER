function [T] = fxm_kSklGeod3D(T, params)

    % Skeletonize binary mask (geodesic distance based).
    % !! Experimental, does not provide "true" skeleton, could be extended to export to SWC format directly !!
    %
    % Sample journal: <a href="matlab:JENI('BloodVessels3D_LocThr3DSklGeod3D.jls');">BloodVessels3D_LocThr3DSklGeod3D.jls</a>
    %
    % Input: 3D binary mask
    % Output: 3D skeleton mask (with branch and end points)
    %
    % Parameters:
    % Step:             Slicing step (pix), minimum: 3

    %% Parameters
    Step = params.Step;
    
    if ~isempty(T)
        
        %% Filters
        se8 = strel(ones(3,3,3));

        %% Analyze CCs
        T = uint8(T>0);
        CC = bwconncomp(T);

        %% Seed each CC ("random")
        Seeds = false(size(T));
        for cci = 1:CC.NumObjects
            Pxs = CC.PixelIdxList{cci};
            Seeds(Pxs(1)) = 1;    
        end

        %% Geodesic distance map from seeds + discretize
        D = single(bwdistgeodesic(T>0,Seeds,'quasi-euclidean'));
        D(isinf(D)) = NaN;
        D = round(D/Step);
        
        %% Analyze snake even slices
        cp1 = bwconncomp((mod(D,2)==0),26);
        Ctrs1 = regionprops(cp1,'centroid');
        Ctrs1 = reshape([Ctrs1.Centroid],3,cp1.NumObjects).';

        %% Analyze snake odd slices
        cp2 = bwconncomp((mod(D,2)==1),26);
        Ctrs2 = regionprops(cp2,'centroid');
        Ctrs2 = reshape([Ctrs2.Centroid],3,cp2.NumObjects).';

        % DstMap = single(bwdist(T==0));
        % Could pick max distance pixel insted of centroid for improved precision
        
        %% Build connection map odd slices --> even slices
        D = single(labelmatrix(cp2));
        D = imdilate(D,se8);
        D = D.*(T>0);
        
        %% Keep track of links to each slice
        ConnMult = single(zeros(cp1.NumObjects+cp2.NumObjects,1));
        
        %% Connect snake pair CCs to two closest odd CCs
        for i = 1:cp1.NumObjects
            inds = unique(D(cp1.PixelIdxList{i}));
            for j = 1:numel(inds)
                if (inds(j)>0)
                    x1 = Ctrs1(i,1);y1 = Ctrs1(i,2);z1 = Ctrs1(i,3);
                    x2 = Ctrs2(inds(j),1);y2 = Ctrs2(inds(j),2);z2 = Ctrs2(inds(j),3);
                    [xpts ypts zpts] = bresenham_line3d([x1 y1 z1], [x2 y2 z2]);
                    indx = sub2ind(size(T),ypts,xpts,zpts);  
                    T(indx) = 200;
                    ConnMult(i) = ConnMult(i)+1;
                    ConnMult(cp1.NumObjects+inds(j)) = ConnMult(cp1.NumObjects+inds(j))+1;
                end
            end
        end
        
        %% Analyze branch and end points
        for i = 1:cp1.NumObjects
            if(ConnMult(i)==1)
                x1 = round(Ctrs1(i,1));y1 = round(Ctrs1(i,2));z1 = round(Ctrs1(i,3));
                if ((x1>1) && (y1>1) && (z1>1) && (x1<size(T,2)) && (y1<size(T,1)) && (z1<size(T,3)))
                    T(y1,x1,z1) = 220;
                end
            end
            if(ConnMult(i)>2)
                x1 = round(Ctrs1(i,1));y1 = round(Ctrs1(i,2));z1 = round(Ctrs1(i,3));
                if ((x1>1) && (y1>1) && (z1>1) && (x1<size(T,2)) && (y1<size(T,1)) && (z1<size(T,3)))
                    T(y1,x1,z1) = 250;
                end
            end
        end
        for i = 1:cp2.NumObjects
            if( ConnMult(cp1.NumObjects+i)==1 )
                x1 = round(Ctrs2(i,1));y1 = round(Ctrs2(i,2));z1 = round(Ctrs2(i,3));
                if ((x1>1) && (y1>1) && (z1>1) && (x1<size(T,2)) && (y1<size(T,1)) && (z1<size(T,3)))
                    T(y1,x1,z1) = 220;
                end
            end
            if( ConnMult(cp1.NumObjects+i)>2 )
                x1 = round(Ctrs2(i,1));y1 = round(Ctrs2(i,2));z1 = round(Ctrs2(i,3));
                if ((x1>1) && (y1>1) && (z1>1) && (x1<size(T,2)) && (y1<size(T,1)) && (z1<size(T,3)))
                    T(y1,x1,z1) = 250;
                end
            end
        end
        
        %% Remove mask
        T(T==1) = 0;
        
    else
        
        T = [];
        
    end
end
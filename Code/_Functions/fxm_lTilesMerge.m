function [L] = fxm_lTilesMerge(L, A, params)

    % Merge/split particles in binary mask to reconstruct loosely convex bright objects.
    % The algorithm requires the original image to use intensity information.
    %
    % Sample journal: <a href="matlab:JENI('NucleiCytoo_GradWaterTilesMerge.jl');">NucleiCytoo_GradWaterTilesMerge.jl</a>
    %
    % Input: 2D binary mask, 2D original image
    % Output: 2D label mask
    %
    % Parameters:
    % GaussianRad:      Gaussian blur pre-filter radius (pix)
    % MinObjArea:       Minimum object area (pix)
    % MinSal:           Minimum tile saliency (low -0.5 -> 0.5 high)
    %                   Saliency captures the "intensity flux" inside a tile
    %                   It is mostly used to discard background and can usually be set around 0 
    % MaxValleyness:    Maximum tile valleyness (rescue more 0.75 -> 1.25 rescue less)
    %                   Valleyness is the ratio of tile edge mean int. and inner pix. mean int.
    % ConcavityThresh:  Concavity threshold (sensitive 0.25 -> 0.5 coarse)

    if ~isempty(L)
    
        %% Parameters
        GaussianRad = params.GaussianRad;
        MinObjArea = params.MinObjArea;       
        MinSal = params.MinSal;                       
        MaxValleyness = params.MaxValleyness;   
        ConcavityThresh = params.ConcavityThresh;
        GaussianRadGeom = GaussianRad; 
        
        % Filters
        se8 = strel(ones(3,3));
        Gint = fspecial('gaussian',[round(GaussianRad*2+1) round(GaussianRad*2+1)], GaussianRad);

        %% Gaussian blur filter
        Af = imfilter(A, Gint, 'same', 'symmetric');
        [AGx,AGy] = gradient(single(Af));

        %% Find tiles (watershed regions)
        Tiles = bwconncomp(L>0, 8);

        %% Compute intensity "flux" at tile edges
        D = bwdist(L==0);
        Mrk = (D<=1);
        [Dx, Dy] = gradient(D); % Normal to tile edge
        Msk = ~((D<=1)&(L>0));
        AGx(Msk) = 0;
        AGy(Msk) = 0;
        Sal = (AGx.*Dx+AGy.*Dy); % Dot product: <int. grad. , edge normal>

        %% Compute tiles stats
        Obj = L;
        TileArea = zeros(Tiles.NumObjects,1);
        TileMeanSaliency = zeros(Tiles.NumObjects,1);
        TileValleyness = zeros(Tiles.NumObjects,1);
        WeakTiles = zeros(Tiles.NumObjects,1); 
        for i = 1:Tiles.NumObjects
         Pix = Tiles.PixelIdxList{i};
         L(Pix) = i;
         TileArea(i) = numel(Pix);
         NIntPix = sum(Mrk(Pix));
         if NIntPix>0
            TileMeanSaliency(i) = sum(Sal(Pix))./NIntPix;
            ExtPix = Pix(Sal(Pix)~=0);
            IntPix = setdiff(Pix,ExtPix);
            TileValleyness(i) = mean(A(ExtPix))/mean(A(IntPix));
         end
         if TileMeanSaliency(i) > MinSal
             Obj(Pix) = 255;    % Strong tile
         else
             if TileValleyness(i) > MaxValleyness
                Obj(Pix) = 1;   % Discard tile
             else
                Obj(Pix) = 127; % Weak tile
                WeakTiles(i) = 1;
             end
         end
        end 

        %% Clusters of strong + weak tiles
        Obj = imclose(Obj==255, se8)+(Obj==127)*0.5;

        %% Split clusters into convex parts (filtered distance map watershed)
        if ConcavityThresh > -1
            Ggeom = fspecial('gaussian',[round(GaussianRadGeom*2+1) round(GaussianRadGeom*2+1)], GaussianRadGeom);
            Msk = (Obj==0);
            D = -bwdist(Msk,'euclidean');
            D = imfilter(D,Ggeom,'same', 'symmetric');
            marker = imextendedmin(D,ConcavityThresh);
            D = imimposemin(D,marker);
            Obj = (Obj).*single(watershed(D)>0);
        end

        %% Weak tiles merging 

        % Clusters statistics 
        Clusters = bwconncomp((Obj==1), 8);
        S = single(zeros(size(L)));
        ClustArea = zeros(Clusters.NumObjects);
        for i = 1:Clusters.NumObjects
         Pix = Clusters.PixelIdxList{i};
         S(Pix) = i;
         ClustArea(i) = numel(Pix);
        end
        NClust = Clusters.NumObjects;

        % Merge valid weak tiles to most likely neighbor cluster(s)
        clustdil = imdilate(imdilate(S,se8),se8);
        ind = find(WeakTiles == 1);
        Sm = S;
        for j = 1:length(ind)
            i = ind(j);
            Pix = Tiles.PixelIdxList{i};
            clustlbl = clustdil(Pix);
            lbl = unique(clustlbl);
            lbl(lbl == 0) = [];
            % Only 1 neighbor cluster: Merge weak tile is below thr area
            if numel(lbl) == 1
                if(TileArea(i)<MinObjArea)
                    Sm(Pix) = lbl;
                else
                    NClust = NClust + 1;Sm(Pix) = NClust;
                end
            end
            % Two neighbor clusters
            if numel(lbl) == 2
                % Join two debris clusters to debris weak tile
                if TileArea(i)<MinObjArea && (ClustArea(lbl(1))<MinObjArea && ClustArea(lbl(2))<MinObjArea)               
                    Sm(Pix) = lbl(1);
                    Sm(Clusters.PixelIdxList{lbl(2)}) = lbl(1);
                else
                    % Join weak tile to cluster with longest border or create new cluster (large weak tile)
                    if(TileArea(i)<MinObjArea)
                        sel = 1 + single(sum(clustlbl==lbl(2)) > sum(clustlbl==lbl(1)));
                        Sm(Pix) = lbl(sel);
                    else
                        NClust = NClust + 1;Sm(Pix) = NClust;
                    end
                end
            end
        end

        % Remove edges between merged tiles
        %Sm = imclose(Sm,se8);
        Sm = imdilate(Sm,se8);
        
        % Remove small clusters + fill holes 
        h = hist(Sm(:),max(Sm(:)));
        for i = 1:length(h)
            if h(i)<MinObjArea
                Sm(Sm==i) = 0;
            end
        end
        L = uint16(imfill(Sm,'holes'));
        
    else
       
        L = [];
        
    end
    
end
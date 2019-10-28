function [L] = fxl_lGroupEllipsoids(L, params)

    % Cluster touching object pairs if this does not lead to prominent concavities
    %
    % Sample journal: <a href="matlab:JENI('CellPilar3D_LogLocMaxLocThrPropagate3DGroup.jls');">CellPilar3D_LogLocMaxLocThrPropagate3DGroup.jls</a>
    %
    % Input: Label mask (2D/3D)
    % Output: Label mask (2D/3D)
    %
    % Parameters:
    % MergeDstFrc: Merge object pair if maximum edge distance to their splitting surface is > MergeDstFrc * (max_dist inside particles)
    %
    % Experimental, work in progress
    
    if  ~isempty(L)
    
        disp('Grouping...');
        
        %% Parameter
        MergeDstFrc = params.MergeDstFrc;

        %% Initialize filter
        if size(L,3) == 3
            se(:,:,1) = [0 0 0;0 1 0;0 0 0];
            se(:,:,2) = [0 1 0;1 1 1;0 1 0];
            se(:,:,3) = [0 0 0;0 1 0;0 0 0];
        else
            se = [0 1 0;1 1 1;0 1 0];
        end
        
        %% Compute distance map
        D = uint16(bwdist(L==0));
        
        %% Particles voxels
        PartVox = regionprops(L,'PixelIdxList');

        %% Find edges
        Lshrink = imerode(L,se);
        Edges = L-Lshrink;
        EdgesIdx = find(Edges);
        
        %% Compute particle distance map
        Dpart = uint16(bwdist((L==0)|(Edges==1)));

        %% Particles maximum edge distance
        MaxDst = zeros(numel(PartVox),1);
        for i = 1:numel(PartVox)
            MaxDst(i) = max(Dpart(PartVox(i).PixelIdxList));
        end
        
        %% Find splitting planes
        Pairs = [L(EdgesIdx) Lshrink(EdgesIdx)];
        clear Lshrink;
        [SortedPairs IdRows ] = sortrows(Pairs);
        PairsIdxSt = [0; find(diff(SortedPairs(:,1))|diff(SortedPairs(:,2))); size(SortedPairs,1)];
        for i = 1:numel(PairsIdxSt)-1
           Part = SortedPairs(PairsIdxSt(i)+1,1);
           Neigh = SortedPairs(PairsIdxSt(i)+1,2);
           if Neigh > 0
               SplitIndx = EdgesIdx(IdRows(PairsIdxSt(i)+1:PairsIdxSt(i+1)));
               EdgeDst = max(D(SplitIndx));
               RefDst = max([MaxDst(Part) MaxDst(Neigh)]);
               %disp([Part Neigh EdgeDst RefDst]);
               if EdgeDst >= RefDst*MergeDstFrc
                   L(PartVox(Neigh).PixelIdxList) = Part;
               end
           end
        end
        
    end
    
end
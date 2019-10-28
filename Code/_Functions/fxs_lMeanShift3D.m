function [C, L] = fxs_lMeanShift3D(M, params)

    % Cluster points by mean shift algorithm.
    %
    % Sample journal: <a href="matlab:JENI('PointClusters_MeanShift.jl');">PointClusters_MeanShift.jl</a>
    %
    % Input: Seed mask (2D/3D)
    % Output: Label mask (2D/3D)
    %
    % Parameters:
    % ZRatio:       Stack Z ratio (only used for image stack)
    % Bandwidth:    Spatial bandwidth (pix, assuming Z ratio = 1)
    % MinPts:       Minimum number of points in a cluster
    
    %% Parameters
    if numel(size(M))>2
        ZRatio = params.ZRatio;
    end
    Bandwidth = params.Bandwidth;
    MinPts = params.MinPts;
 
    if ~isempty(M)
    
        %% Find spots (CC) coordinates
        if size(M,3) == 1
            CC = bwconncomp(M>0,8);
        else
            CC = bwconncomp(M>0,26);
        end
        stats = regionprops(CC,'centroid');
        Coords = round([stats.Centroid]);
        if size(M,3) == 1
            Coords = reshape(Coords,2,numel(Coords)/2);
        else
            Coords = reshape(Coords,3,numel(Coords)/3);
            Coords(3,:) = Coords(3,:)*ZRatio;
        end

        %% Cluster points
        [clustCent,point2cluster,clustMembsCell] = MeanShiftCluster(Coords,Bandwidth);
        PtsperCluster = hist(point2cluster,1:max(point2cluster));
        RmClust = PtsperCluster<MinPts;
        clustCent(:,RmClust) = [];
        clustMembsCell(RmClust) = [];
        clustLbl = find(RmClust==0);
        numClust = length(clustMembsCell);

        %% Build output label mask
        C = uint16(zeros(size(M)));
        L = uint16(zeros(size(M)));
        if size(M,3) == 1
            for i = 1:size(clustCent,2)
                C(round(clustCent(2,i)),round(clustCent(1,i))) = 1;
                ind = Coords(2,clustMembsCell{i}) + (Coords(1,clustMembsCell{i})-1)*size(L,1);
                L(ind) = i;
            end
        else
            for i = 1:size(clustCent,2)
                C(round(clustCent(2,i)),round(clustCent(1,i)),round(clustCent(3,i)/ZRatio)) = 1;
                ind = Coords(2,clustMembsCell{i}) + (Coords(1,clustMembsCell{i})-1)*size(L,1) + (Coords(3,clustMembsCell{i})/ZRatio-1)*size(L,1)*size(L,2);
                L(round(ind)) = i;
            end
        end
    
    else
        
        C = [];
        L = [];
        
    end
    
end
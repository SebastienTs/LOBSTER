function [Seeds] = fxm_sMarkObjCentroids(Obj, params)

    % Set seed at centroid of every connected particles.
    %
    % Sample journal: <a href="matlab:JENI('FISH_sptdet.jl');">FISH_sptdet.jl</a>
    %
    % Input: Binary mask (2D/3D)
    % Output: Seed mask (2D/3D)
    %
    % No parameter

    %% Analyze connected particles and find centroids
    CC = bwconncomp(Obj);
    Seeds = uint8(zeros(size(Obj)));
    ctr = regionprops(CC,'Centroid');
    ctr = round(vertcat(ctr.Centroid));
    
    %% Add seeds
    if ~isempty(ctr)
        if size(ctr,2) == 2
            Seeds(sub2ind(size(Seeds),ctr(:,2),ctr(:,1))) = 200;
        else
            Seeds(sub2ind(size(Seeds),ctr(:,2),ctr(:,1),ctr(:,3))) = 200;
        end
    end
        
end
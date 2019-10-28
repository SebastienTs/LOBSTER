function [O] = fxsm_sSeedTissue3D(M, S, params)

    % Find loosely closed contours embed in a 3D surface, the surface must
    % be XY parametric (unique Z for given XY coordinate)
    %
    % Sample journal: <a href="matlab:JENI('EmbryoTissue3D_LocThrFitSurfFindCells3D.jls');">EmbryoTissue3D_LocThrFitSurfFindCells3D.jls</a>
    %
    % Input: 3D binary mask (contours), 3D binary mask (surface)
    % Output: 3D seed mask (contour seeds)
    %
    % Parameters:
    % DmapBlurRad:      3D distance map Gaussian blur radius (pix)
    % MinMaxHeight:     Distance map minimum maxima saliency

    %% Parameters
    DmapBlurRad = params.DmapBlurRad;
    MinMaxHeight  = params.MinMaxHeight;
    
    if ~isempty(M)

        %% Compute contour mask distance map
        D = single(bwdist(M));
        D = D.*(S>0);
        
        %% Project distance map
        Proj = max(D,[],3);
        
        %% Filter distance map and find 2D regional maxima
        Proj = imgaussfilt(Proj,DmapBlurRad);
        Proj = imhmax(Proj,MinMaxHeight);
        Spots = imregionalmax(Proj)>0;
        Spots(1:3,:) = 0;Spots(end-2:end,:) = 0;
        Spots(1:3,1) = 0;Spots(:,end-2:end) = 0;
        
        %% Compute seed markers (spots)
        Seeds = fxm_sMarkObjCentroids(Spots,[]);
        
        %% Build height map from surface
        [Max Hght] = max(S,[],3);
        
        %% Create output by remaping spots and seeds to height map
        O = uint8(zeros(size(S)));
        SpotsInd = find(Spots>0);
        O(SpotsInd+(Hght(SpotsInd)-1)*size(M,1)*size(M,2)) = 100;
        SeedsInd = find(Seeds);
        O(SeedsInd+(Hght(SeedsInd)-1)*size(M,1)*size(M,2)) = 200;
        
    else
        
        O = [];
        
    end

end
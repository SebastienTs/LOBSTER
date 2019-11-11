function [L] = fxgs_lSeededPolarGeod(I, M, params)

    % Minimize intensity variation along closed contour around seeds.
    %
    % Sample journal: <a href="matlab:JENI('CrazyCells_1ManualSeededPolarGeod.jl');">CrazyCells_1ManualSeededPolarGeod.jl</a>
    %
    % Input: 2D original image, 2D seed mask
    % Output: 2D label mask
    %
    % Parameters:
    % ThDiv:   Number of points along contour
    % ObjRad:  Approximate object radius (pix)
    % MinArea: Minimum object area (pix)
    % Method:  Optimization method 'simple' 'euler' or 'rk4'

    % Params
    ThDiv = params.ThDiv;
    ObjRad = params.ObjRad;
    MinArea = params.MinArea;
    Method = params.Method;
    
    if ~isempty(I)
    
        % Seeds
        CC = bwconncomp(M);
        stats = regionprops(CC,'centroid');

        % Label mask
        L = zeros(size(I));

        for it = 1:length(stats)

            %% Retrieve centroid positions
            Ctr = stats(it).Centroid;    
            coln = round(Ctr(1));
            rown = round(Ctr(2));

            %% Initialization
            [row_max,col_max] = size(I);
            th_incr = 2*pi/(ThDiv-1);

            %% Perform polar to cartesian transform to create polar weight matrix
            full_rad_mat = repmat(1:ObjRad,1,ThDiv);
            th_mat = [0:th_incr:2*pi];
            th_mat = repmat(th_mat,ObjRad,1);
            full_th_mat = reshape(th_mat,1,length(full_rad_mat));
            [col_offset,row_offset] = pol2cart(full_th_mat,full_rad_mat);
            col_offset = (round(col_offset));
            row_offset = (round(row_offset));

            %% Filter the row and column numbers so that they are in image domain
            im_cols = col_offset + coln;
            im_rows = row_offset + rown;
            valid_im_cols = (im_cols>0) & (im_cols <= col_max);
            valid_im_rows = (im_rows>0) & (im_rows <= row_max);
            valid_locations = find((valid_im_cols+valid_im_rows) == 2);

            %% Usable image locations for creation of weight matrix
            final_im_cols = im_cols(valid_locations);
            final_im_rows = im_rows(valid_locations);
            final_im_indices = sub2ind(size(I),final_im_rows,final_im_cols);
            valid_im_vals_image = I(final_im_indices);

            %% Polar map
            polar_wt_mat_image = zeros(ObjRad,ThDiv);
            polar_wt_mat_image(valid_locations) = valid_im_vals_image;
            polar_wt_mat_image = reshape(polar_wt_mat_image,ObjRad,ThDiv);

            %% Find gradient
            [~, polar_grad_y] = gradient(double(polar_wt_mat_image));
            polar_wt_mat = polar_grad_y;

            %% Normalize polar gradient matrix to 0-1 inverted so that edge locations are close to 1
            polar_wt_mat = polar_wt_mat - min(polar_wt_mat(:));
            polar_wt_mat = polar_wt_mat/max(polar_wt_mat(:));
            polar_cost_y = polar_wt_mat;

            %% Speed Image
            SpeedImage = (max(polar_cost_y(:))-polar_cost_y).^2;

            % Display polar images
            %figure;imagesc(polar_wt_mat_image);colormap(gray);
            %figure;imagesc(polar_cost_y);colormap(gray);

            %% Mask for distance map, seed is first column
            mask = logical(zeros(size(SpeedImage)));
            mask(:,1) = 1;

            %% Compute geodesic distance map from seed
            DistanceMap = graydist(polar_cost_y,mask);

            %% Search for minimum distance on last column --> path start
            LastCol = DistanceMap(:,size(polar_cost_y,2));
            [vl indx] = min(LastCol);

            %% Trace optimal path from last column back to first column
            StartPoint = [indx;size(SpeedImage,2)];
            ShortestLine = shortestpath(DistanceMap,StartPoint,'',1,Method);

            %hold on;plot(ShortestLine(:,2),ShortestLine(:,1),'r');
            %figure;imagesc(SpeedImage);colormap(gray);
            
            %% Build mask from contour
            Xp = coln+ShortestLine(:,1).*cos((ShortestLine(:,2)-1)*th_incr);
            Yp = rown+ShortestLine(:,1).*sin((ShortestLine(:,2)-1)*th_incr);
            M = poly2mask(Xp,Yp,size(I,1),size(I,2));

            %% Combine masks
            L(L==0) = L(L==0) + M(L==0)*it;
 
            % Display contours
            %figure;imagesc(I);hold on;plot(coln,rown,'r.','MarkerSize',20);colormap(gray);;hold on;plot(Xp,Yp,'r');

        end
        
        %% Remove small objects (could be improved by removing small object isolated bits)
        props = regionprops(L,'Area','PixelIdxList');
        smallRegions = find([props(:).Area] < MinArea);
        L(vertcat(props(smallRegions).PixelIdxList)) = 0;
        L = uint16(L);
        
    else
        
        L = [];
        
    end

end
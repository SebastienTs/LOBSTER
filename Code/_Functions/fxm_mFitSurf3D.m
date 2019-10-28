function [L] = fxm_mFitSurf3D(I, params)

    % Fit a 3D surface to a binary image (pixels > 0 considered surface seed points).
    %
    % Sample journal: <a href="matlab:JENI('TissuePilar3D_LocThrFitSurf3D.jls');">TissuePilar3D_LocThrFitSurf3D.jls</a>
    %
    % Input: 3D binary mask
    % Output: 3D binary mask
    %
    % Parameters:
    % ZRatio:       Stack Z ratio
    % Scl:          Undersampling factor prior to estimating surface points (>=1, details vs speedup)
    % Smoothness:   Fitted surface smoothness
    % ComputeArea:  Estimate surface area if set to 1

    ZRatio = params.ZRatio;
    Scl = params.Scl;
    Smoothness = params.Smoothness;
    ComputeArea = params.ComputeArea;
    
    if ~isempty(I)
 
        %% Set known surface points (mask + grid intersection)
        if Scl ~= 1
            Grd = uint8(zeros(size(I)));
            Grd(1:Scl:end,:,:) = 1;
            Grd(:,1:Scl:end,:) = 1;
            Grd(:,:,1:Scl:end) = 1;
            [y,x,z] = ind2sub(size(I),find((I&Grd)>0));
        else
            [y,x,z] = ind2sub(size(I),find(I>0));
        end
       
        %% Define sampling points
        xnodes = 1:Scl:size(I,2);
        ynodes = 1:Scl:size(I,1);
        
        %% Estimate surface
        [zgrid,xgrid,ygrid] = RegularizeData3D(x,y,z,xnodes,ynodes,'smoothness',Smoothness,'extend','always');
        
        %% Rescale surface to original image size
        if Scl ~= 1
            zgrid = imresize(zgrid,[size(I,1) size(I,2)]);
        end
        
        %% Create mask holding surface
        L = uint8(zeros(size(I)));
        N = size(L,1)*size(L,2);
        idx = (1:N).';
        zpos = round(zgrid(:));
        zpos(zpos < 1) = 1;
        zpos(zpos > size(L,3)) = size(L,3);
        L(idx+N*(zpos-1)) = 255;
           
        %% Optionally compute surface area
        if ComputeArea == 1
            [x y z] = meshgrid(1:size(I,2),1:size(I,1),1:size(I,3));
            [elem,node,col] = MarchingCubes(x,y,z,L,127);
            node(:,3) = node(:,3)*ZRatio;
            a = node(elem(:, 2), :) - node(elem(:, 1), :);
            b = node(elem(:, 3), :) - node(elem(:, 1), :);        
            c = cross(a, b, 2);
            area = 1/2 * sum(sqrt(sum(c.^2, 2)));
            fprintf('\nSurface area: %f XY pixels\n', area); 

            %figure('color',[1 1 1]);
            %patch('vertices',V,'faces',F,'edgecolor','none',...
            %'facecolor',[1 0 0],'facelighting','phong');
            %light;
            %axis equal;
        end
      
    else
        
        L = [];
        
    end

end
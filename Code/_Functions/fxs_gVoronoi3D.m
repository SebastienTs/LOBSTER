function [G] = fxs_gVoronoi3D(M, params)

    % Compute density map from seed mask
    %
    % Sample journal: <a href="matlab:JENI('PointClusters_Voronoi.jl');">PointClusters_Voronoi.jl</a>
    %
    % Input: Seed mask (2D/3D)
    % Output: Grayscale image (2D/3D)
    %
    % Parameters:
    % ovs:      Oversampling factor
    
    %% Parameters
    ovs = params.ovs;
    
    if ~isempty(M)

        G = uint16(zeros(ovs*size(M)));
        
        if numel(size(M))==2
           [Y, X] = find(M>0);
           RefPts = [1+(Y-1)*ovs 1+(X-1)*ovs];
           [X1, Y1] = meshgrid(1:size(G,2),1:size(G,1));
           QuePts = [Y1(:) X1(:)];
           clear Y1;clear X1;
        else
           ind = find(M>0);
           [Y, X, Z] = ind2sub(size(M),ind);
           RefPts = [1+(Y-1)*ovs 1+(X-1)*ovs 1+(Z-1)*ovs];
           [X1, Y1, Z1] = meshgrid(1:size(G,2),1:size(G,1),1:size(G,3));
           QuePts = [Y1(:) X1(:) Z1(:)];
           clear Y1;clear X1;clear Z1;
        end
        
        [Idx D] = knnsearch(RefPts,QuePts,'K',1);
        A = accumarray(Idx,ones(numel(Idx),1));
        %[Idx D] = knnsearch(RefPts,QuePts,'K',3);
        %A = accumarray(Idx(:,1),ones(size(Idx,1),1));
        
        %% 3 neighbor interpolation
        %% Voronoi, cell IDs
        %G(:) = Idx(:,1);
        %% Voronoi, cell densities
        %Ds = 1./A;
        %G(:) = 65535*Ds(Idx(:,1));
        %% trilinear interpolated densities
        %Ds = 1./A;
        %D = D + eps;
        %n = 1;
        %%G(:) = uint16(1000000*(D(:,1).^n+D(:,2).^n+D(:,3).^n)./(A(Idx(:,1)).*D(:,1).^n+A(Idx(:,2)).*D(:,2).^n+A(Idx(:,3)).*D(:,3).^n));
        %G(:) = uint16(1000000*(Ds(Idx(:,1)).*D(:,1).^(-n)+Ds(Idx(:,2)).*D(:,2).^(-n)+Ds(Idx(:,3)).*D(:,3).^(-n))./(D(:,1).^(-n)+D(:,2).^(-n)+D(:,3).^(-n)));
        %% Natural interpolation
        F = scatteredInterpolant(RefPts,1./A);
        F.Method = 'natural';
        %F.Method = 'linear';
        G(:) = uint16(1000000*F(QuePts));
    else     
        G = [];   
    end
        
end
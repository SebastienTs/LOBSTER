function [Rays] = ExtractRays3D(I, pxinds, L, Step, Nangles, Nangles2)

    %% Compute rays coordinates / origin
    Rads = 0:Step:L;
    Nrads = numel(Rads);
    OffX = single(zeros(Nrads,Nangles));
    OffY = single(zeros(Nrads,Nangles));
    i = 1;
    for phi = 0:2*pi/Nangles2:2*pi-2*pi/Nangles2
    for theta = 0:2*pi/Nangles:2*pi-2*pi/Nangles
        [x, y, z] = sph2cart(theta,phi,Rads);
        OffX(:,i) = x;
        OffY(:,i) = y;
        OffZ(:,i) = z;
        i = i+1;
    end
    end
    OffX = OffX(:);OffY = OffY(:);OffZ = OffZ(:);
    %OffX, OffY and OffZ: column vectors holding X,Y or Z coordinates of ray points (all rays concatenated).
    %plot3(OffX,OffY,OffZ,'.');axis equal;

    %% Extract rays
    [Yq Xq Zq] = ind2sub(size(I),pxinds);
    PosX = repmat(single(Xq),numel(OffX),1)+repmat(OffX,1,size(Xq,2));
    PosY = repmat(single(Yq),numel(OffY),1)+repmat(OffY,1,size(Yq,2));
    PosZ = repmat(single(Zq),numel(OffZ),1)+repmat(OffZ,1,size(Zq,2));
    Rays = interp3(single(I),PosX,PosY,PosZ,'linear',NaN);
    Rays = reshape(Rays,Nrads,Nangles*Nangles2,size(Rays,2));

end
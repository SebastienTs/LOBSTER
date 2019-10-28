function [Rays] = ExtractRays(I, pxinds, L, Step, Nangles)

    %% Compute rays coordinates / origin
    Rads = 0:Step:L;
    Nrads = numel(Rads);
    OffX = single(zeros(Nrads,Nangles));
    OffY = single(zeros(Nrads,Nangles));
    i = 1;
    for theta = 0:2*pi/Nangles:2*pi-2*pi/Nangles
        [x, y] = pol2cart(theta,Rads);
        OffX(:,i) = x;
        OffY(:,i) = y;
        i = i+1;
    end
    OffX = OffX(:);OffY = OffY(:);
    %OffX, OffY and OffZ: column vectors holding X,Y or Z coordinates of ray points (all rays concatenated).
    %plot(OffX,OffY,'.');axis equal;

    %% Extract rays
    [Yq Xq] = ind2sub(size(I),pxinds);
    PosX = repmat(single(Xq),numel(OffX),1)+repmat(OffX,1,size(Xq,2));
    PosY = repmat(single(Yq),numel(OffY),1)+repmat(OffY,1,size(Yq,2));
    Rays = interp2(single(I),PosX,PosY,'linear',NaN);
    Rays = reshape(Rays,Nrads,Nangles,size(Rays,2));

end
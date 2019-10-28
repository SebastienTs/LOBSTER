function [S] = fxg_sBlobDetRay(I, params)

    % Blob detection (mark seeds) by ray gradient voting + regional maxima detection.
    %
    % Sample journal: <a href="matlab:JENI('ManyCells_BlobDetRay.jl');">ManyCells_BlobDetRay.jl</a>
    %
    % Input: 2D grayscale image
    % Output: 2D seed mask
    %
    % Parameters:
    % Scale:        Rescaling factor prior to processing (<= 1, speedup vs details)
    % Thr:          Minimum intensity to enable vote from a given pixel
    % NAngles:      Number of possible voting angles
    % L:            Ray length (pix)
    % Step:         Ray step (pix)
    % Fraction:     Fraction of "blob like" rays to keep for feature computation
    % NoiseTol:     Regional maxima detection noise tolerance

    Scale = params.Scale;
    Thr = params.Thr;
    NAngles = params.NAngles;
    L = params.L;
    Step = params.Step;
    Fraction = params.Fraction;
    NoiseTol = params.NoiseTol;

    if ~isempty(I)
    
        %% Rescale
        irow = size(I,1);
        icol = size(I,2);
        I = imresize(I,Scale);

        %% Compute LoG as reference
        H = fspecial('log',21,9);
        ILog = -imfilter(single(I),H,'same','symmetric');

        %% Compute rays coordinates / origin
        Rads = 0:Step:L;
        Nrads = numel(Rads);
        OffX = single(zeros(Nrads,NAngles));
        OffY = single(zeros(Nrads,NAngles));
        i = 1;
        for theta = 0:2*pi/NAngles:2*pi-2*pi/NAngles
            [x, y] = pol2cart(theta,Rads);
            OffX(:,i) = x;
            OffY(:,i) = y;
            i = i+1;
        end
        OffX = OffX(:);OffY = OffY(:);
        %OffX, OffY and OffZ: column vectors holding X,Y or Z coordinates of ray points (all rays concatenated).

        %% Extract rays
        pxinds = find(I>=Thr).';
        [Yq Xq] = ind2sub(size(I),pxinds);
        PosX = repmat(single(Xq),numel(OffX),1)+repmat(OffX,1,size(Xq,2));
        PosY = repmat(single(Yq),numel(OffX),1)+repmat(OffY,1,size(Yq,2));
        Rays = interp2(single(I),PosX,PosY,'linear',NaN);
        Rays = reshape(Rays,Nrads,NAngles,size(Rays,2));

        %% Process rays
        %doming = squeeze((Rays(1,1,:)-mean(Rays(end,:,:),2))).';
        %nrj = squeeze(mean(mean(Rays))).';
        val = abs(diff(Rays)).*(Rays(2:end,:,:)<=repmat(Rays(1,1,:),Nrads-1,NAngles));
        %val = abs(diff(Rays));
        [mx d] = max(val);
        d = squeeze(d);
        %Feat = 1./(std(d)+0.5);
        dmax = max(d);
        df = abs(d-repmat(dmax,NAngles,1));
        sdf = sort(df,'ascend');
        Feat = 1./squeeze(std(sdf(1:round(Fraction*NAngles),:))+0.5);
        Pix = zeros(size(I));
        Pix(pxinds) = Feat;

        %% Smooth response map
        Pix = imgaussfilt(Pix,2);

        %% Scale back
        Pix = imresize(Pix,[irow icol]);

        %% Extract spots and seeds
        S = uint8(100*imextendedmax(Pix,NoiseTol));
        Seeds = fxm_sMarkObjCentroids((S>0),[]);
        S(find(Seeds)) = 200;
        
    else
        
        S = [];
        
    end
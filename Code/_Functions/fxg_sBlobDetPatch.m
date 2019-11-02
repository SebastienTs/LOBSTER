function [VotesCrop] = fxg_mBlobDetPatch(I, params)

    % Blob detection (mark seeds) by patch gradient voting + regional maxima detection.
    %
    % Sample journal: <a href="matlab:JENI('NucleiCluster_BlobDetPatch.jl');">NucleiCluster_BlobDetPatch.jl</a>
    %
    % Input: 2D grayscale image
    % Output: 2D grayscale or seed mask
    %
    % Parameters:
    % GaussianGradRad:  Gaussian blur pre-filter radius (gradient estimation, pix)
    % GaussianVoteRad:  Vote casting length (pix)
    % GradMagThr:       Gradient magnitude threshold for voting (normalized to 1)
    % Rmin:             Minimum object radius (pix)
    % Rmax:             Maximum object radius (pix)
    % NAngles:          Number of possible vote directions
    % Delta:            Vote angle opening (radian) at each iteration
    % DScale:           Vote radius scaling at each iteration
    % Thr:              Threshold output (seed mask output)
    %
    % Note: Number of iterations is set by length of vector Delta
    
    GaussianGradRad = params.GaussianGradRad;
    GaussianVoteRad = params.GaussianVoteRad;
    GradMagThr = params.GradMagThr;
    Rmin = params.Rmin;
    Rmax = params.Rmax;
    NAngles = params.NAngles;
    Delta = params.Delta;
    DScale = params.DScale;
    Thr = params.Thr;

    if ~isempty(I)
    
        Ggrad = fspecial('gaussian',[round(GaussianGradRad*2+1) round(GaussianGradRad*2+1)],GaussianGradRad);
        If = imfilter(I,Ggrad,'replicate');
        [Ix,Iy] = gradient(double(If));
        IGm = sqrt(Ix.^2+Iy.^2);
        mn = min(IGm(:));
        mx = max(IGm(:));
        IGm = (IGm-mn)/(mx-mn);
        Alpha = pi/2+atan(Iy./Ix)+(Ix>=0)*pi;
        Alpha(isnan(Alpha)) = 0;

        % Compute masks for all possible orientations (NAngles)
        A = cell(NAngles,length(Delta),length(DScale));
        K = cell(NAngles,length(Delta),length(DScale));
        for k = 1:length(DScale)
            hgth = round((Rmax-Rmin)/DScale(k));
            Gvote = fspecial('gaussian',[hgth 2*Rmax],GaussianVoteRad);
            Gvote = [zeros(2*Rmax-hgth, 2*Rmax) ; Gvote];
            for j = 1:length(Delta)
                tempa = double(roipoly(2*Rmax,2*Rmax, Rmax+[Rmin*tan(Delta(j)) Rmax*tan(Delta(j)) -Rmax*tan(Delta(j)) -Rmin*tan(Delta(j))], [Rmax+Rmin 2*Rmax 2*Rmax Rmin+Rmax]));
                tempk = tempa.*Gvote;
                tempa(tempa == 0) = nan;
                for i = 1:NAngles
                    A{i,j,k} = imrotate(tempa,-(360*(i-1)/NAngles),'crop','bilinear');
                    K{i,j,k} = imrotate(tempk,-(360*(i-1)/NAngles),'crop','bilinear');
                end  
            end
        end

        [Yv Xv] = ind2sub(size(IGm),find(IGm>=GradMagThr));
        AlphaNCur = 1+mod(floor(Alpha/(2*pi)*NAngles),NAngles);
        DScaleNCur = ones(size(AlphaNCur))*ceil(length(DScale)/2);

        L = 2*Rmax-1;
        Ref = Rmax+1;
        DRef = (Rmax+Rmin)/2;
        for it = 1:length(Delta)
            Votes = zeros(size(I)+2*Rmax+1);
            for i = 1:length(Xv)
                X = Xv(i);
                Y = Yv(i);    
                Votes(Y:Y+L,X:X+L) = Votes(Y:Y+L,X:X+L)+IGm(Y,X)*K{AlphaNCur(Y,X),it,DScaleNCur(Y,X)};
            end
            for i = 1:length(Xv)
                X = Xv(i);
                Y = Yv(i);
                ScanArea = Votes(Y:Y+L,X:X+L).*A{AlphaNCur(Y,X),it,DScaleNCur(Y,X)};
                [val,ind] = max(ScanArea(:));
                if val >= Thr
                    [ymax xmax] = ind2sub(size(ScanArea),ind);
                    Dx = xmax-Ref;
                    Dy = ymax-Ref;
                    AlphaNCur(Y,X) = 1+mod(floor((0.25+0.5*atan(Dy./Dx)/pi+0.5*(Dx>=0))*NAngles),NAngles);
                    if length(DScale)>1
                        Dratio = sqrt(Dx^2+Dy^2)/DRef;
                        [val,ind] = min(abs(DScale-Dratio));
                        DScaleNCur(Y,X) = ind;
                    end
                end
            end
            VotesCrop = Votes(Rmax+1:end-Rmax-1,Rmax+1:end-Rmax-1);
        end

        if Thr > 0
            VotesCrop = (VotesCrop >= Thr);
            Seeds = fxm_sMarkObjCentroids(VotesCrop,[]);
            VotesCrop = uint8(100*VotesCrop);
            VotesCrop(find(Seeds)) = 200;
        else
            VotesCrop = uint8(255*VotesCrop/max(VotesCrop(:)));
        end     
          
    else
        
        VotesCrop = [];
        
    end
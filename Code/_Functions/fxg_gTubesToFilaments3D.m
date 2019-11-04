function [R2] = fxg_gTubesToFilaments3D(I, params)

    % Perform intensity casting along local gradient. Primarily used to
    % transform tubular objects into filaments but can be used to estimate
    % markers close to concave object centroids.
    % 
    % Sample journal: <a href="matlab:JENI('BloodVessels3D_TubesToFilam3D.jls');">BloodVessels3D_TubesToFilam3D.jls</a>
    % 
    % Input: 3D grayscale image
    % Output: 3D grayscale image (8-bit) !! Intensity rescaled to 255 !!
    %
    % Parameters:
    % ZRatio            Stack Z ratio
    % GRad              Gaussian blur pre-filter (compute gradient direction)
    % Thr               Minimum gradient strength to cast vote from given pixel
    % Dist              Ray length (pix)
    % Steps             Sampling steps along ray (pix)
    % VoteMode          Set to 1 to accumulate votes close to tube axis, 0 close to surface
    % ResRad            Radius of Gaussian blur filter (post-processing, pix)
    % PowerLaw          Apply power law (post-processing, set to 1 to disable)

    if ~isempty(I)
    
        %% Retrieve parameters    
        ZRatio = params.ZRatio;
        GRad = params.GRad;
        Thr = params.Thr;
        Steps = params.Steps;
        VoteMode = params.VoteMode;
        Dist = params.Dist;
        ResRad = params.ResRad;
        PowerLaw = params.PowerLaw;
        
        %% Initialize variables
        mid = ((Steps/2)+1);
        NSlice = size(I,3);

        %% Z interpolation
        if ZRatio>0
            I = resize3D(I,[size(I,1) size(I,2) round(NSlice*ZRatio)],'bilinear');
            clear X;clear Y;clear Z;
        end

        %% Filter image
        If = single(imgaussfilt3(I,GRad));

        %% Estimate intensity gradient
        [Ifx,Ify,Ifz] = gradient(If);
        GradMag = sqrt(Ifx.^2+Ify.^2+Ifz.^2);
        DirVecX = Ifx(:)./GradMag(:);
        DirVecY = Ify(:)./GradMag(:);
        DirVecZ = Ifz(:)./GradMag(:);

        %% Extract rays along gradient direction at positions of significant intensity gradient magnitude
        StepCoeffs = Dist*(0:Steps)/Steps;
        ind = single(find(GradMag>=Thr));
        [Yg Xg Zg] = ind2sub(size(GradMag),ind);
        Xg = single(Xg);Yg = single(Yg);Zg = single(Zg);
        Xq = single(repmat(Xg,1,Steps+1))+DirVecX(ind)*StepCoeffs;
        Yq = single(repmat(Yg,1,Steps+1))+DirVecY(ind)*StepCoeffs;
        Zq = single(repmat(Zg,1,Steps+1))+DirVecZ(ind)*StepCoeffs;
        GradMagq = interp3(GradMag,Xq(:),Yq(:),Zq(:),'nearest',NaN);
        GradMagq = reshape(GradMagq,numel(GradMagq)/(Steps+1),Steps+1);
        flag = (GradMagq(:,1) > GradMagq(:,2)); % Additionally enforce ray start to be a candidate intensity maxima
        %flag = (GradMagq(:,1) == GradMagq(:,1));
        indvalid = single(find(flag));

        %% Local gradient ray voting
        %Xqval = min(max(Xq(indvalid,:),1),size(I,2));
        %Yqval = min(max(Yq(indvalid,:),1),size(I,1));
        %Zqval = min(max(Zq(indvalid,:),1),size(I,3));
        %AccPtsInd = single(sub2ind(size(I),round(Yqval(:)),round(Xqval(:)),round(Zqval(:))));
        %R = single(accumarray(AccPtsInd,1,[numel(N) 1]));
        %R = reshape(R,size(N));
        %R = single(imgaussfilt3(R,Rad2));

        %% Only vote at gradient magnitude minima (along the ray)
        if VoteMode == 1
            [mn votepos] = min(GradMagq(indvalid,:),[],2);
        else
            [mn votepos] = max(GradMagq(indvalid,:),[],2);
        end
        Xqval = min(max(Xq(indvalid+size(Xq,1)*(votepos-1)),1),size(I,2));
        Yqval = min(max(Yq(indvalid+size(Yq,1)*(votepos-1)),1),size(I,1));
        Zqval = min(max(Zq(indvalid+size(Zq,1)*(votepos-1)),1),size(I,3));
        AccPtsInd = single(sub2ind(size(I),round(Yqval(:)),round(Xqval(:)),round(Zqval(:))));
        R2 = single(accumarray(AccPtsInd,1,[numel(GradMag) 1]));
        R2 = reshape(R2,size(GradMag));

        %% Filter the result
        R2 = single(imgaussfilt3(R2,ResRad));

        %% Z interpolation (back to original size)
        if ZRatio>0
            R2 = resize3D(R2,[size(R2,1) size(R2,2) NSlice],'bilinear');
            clear X;clear Y;clear Z;
        end

        %% Apply power law to result and normalize intensity
        if PowerLaw ~= 1
            R2 = R2.^PowerLaw;
        end
        R2 = uint8(255*(R2/max(R2(:))));
    
    else
       
        R2 = [];
        
    end
    
end
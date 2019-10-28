function [ICm] = fxg_sSBFRegMax(I, params)

    % Detect pixels with strong central symmetry (mark seeds).
    %
    % Sample journal: <a href="matlab:JENI('NucleiCytoo_SBFRegMax.jl');">NucleiCytoo_SBFRegMax.jl</a>
    %
    % Input: 2D grayscale image
    % Output: 2D seed mask
    %
    % Parameters:
    % UnderSamp:    Undersampling factor (>= 1, details vs speedup)
    % Rmin:         Minimum oject radius (pix)    
    % Rmax:         Maximum object radius (pix)
    % Rstep:        Object radius step (pix)
    % Band:         Guard band (pix)
    % lambdaMag:    SBF lambda
    % LocMaxThr:    h-Maxima tolerance
    % BckLvl:       Force output pixels to 0 if input below this threshold
    % Sym:          Symmetry mode (1 or 2)

    Rmin = params.Rmin;
    Rmax = params.Rmax;
    Rstep = params.Rstep;
    Band = params.Band;
    lambdaMag = params.lambdaMag;
    LocMaxThr = params.LocMaxThr; 
    BckLvl = params.BckLvl;
    UnderSamp = params.UnderSamp;
    Sym = params.Sym;

    if ~isempty(I)

        I = single(I);
        [px,py] = gradient(I);
        GradMag = sqrt(px.^2+py.^2);
        GradMag = GradMag/max(GradMag(:));
        GradAngle = atan(py./px);
        GradAngle = GradAngle+(px<0)*pi;
        GradAngle(GradMag==0) = 0;
        ICm = zeros(size(I));
        ICr = zeros(size(I));
        AngleStep = (24/Sym);
        AngleVec = (2/Sym)*pi/AngleStep*(1:AngleStep); 
        Rvec = Rmin:Rstep:Rmax;
        Shift = repmat(-Band:Band,length(Rvec),1).';
        Rmat = repmat(Rvec,2*Band+1,1)+Shift;
        Rcube = repmat(Rmat,[1 1 AngleStep]);
        AngleVecCube = repmat(reshape(AngleVec,[1 1 AngleStep]),1+2*Band,length(Rvec));
        SinCube = sin(AngleVecCube);
        CosCube = cos(AngleVecCube);
        AngleVecCube = AngleVecCube - pi;
        RcubeSin = round(Rcube.*SinCube);
        RcubeCos = round(Rcube.*CosCube);

        for Xpos = Band+1+Rmax:UnderSamp:size(I,1)-Rmax-Band-1
           for Ypos = Band+1+Rmax:UnderSamp:size(I,2)-Rmax-Band-1

               offsets = Xpos+RcubeSin+((Ypos-1)+RcubeCos)*size(GradAngle,1);
               AngleDif = GradAngle(offsets)-AngleVecCube;
               Mag = GradMag(offsets);
               Metric = cos(AngleDif)+Mag*lambdaMag;
               %Metric = cos(AngleDif);
               [mx ind] = max(sum(Metric));
               ICm(Xpos,Ypos) = sum(mx); 
               [mx2 ind2] = max(sum(Mag));
               ICr(Xpos,Ypos) = mean(ind2);

               if(Sym==2)
                    offsets = Xpos-RcubeSin+((Ypos-1)-RcubeCos)*size(GradAngle,1);
                    AngleDif = GradAngle(offsets)-AngleVecCube+pi;
                    Metric = cos(AngleDif)+Mag*lambdaMag;
                    Metric = cos(AngleDif);
                    buf = sum(Metric);
                    mx = buf(ind);
                    ICm(Xpos,Ypos) = ICm(Xpos,Ypos) + sum(mx);
               end

           end
        end

        %% Resize to original size
        if not(UnderSamp==1)
            ICm = imresize((UnderSamp^2)*ICm,1/UnderSamp,'bilinear');
            ICm = imresize(ICm,size(I),'bilinear');
            ICr = imresize((UnderSamp^2)*ICr,1/UnderSamp,'bilinear');
            ICr = imresize(ICr,size(I),'bilinear');
        end

        %% Extract regional maxima    
        ICm = imhmax(ICm,LocMaxThr);
        ICm = imregionalmax(ICm);
        ICm = ICm.*(I>BckLvl);
        
        %% Build output mask
        Seeds = fxm_sMarkObjCentroids(ICm,[]);
        ICm = uint8(100*ICm);
        ICm(find(Seeds)) = 200;

    else
       
        ICm = [];
        
    end
    
end
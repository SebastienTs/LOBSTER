function [D] = fxg_gDeconv3D(A, B, params)

    % Deconvolve image by Richardson-Lucy, regularized inverse or Wiener algorithm.
    %
    % Sample journal: <a href="matlab:JENI('Neurons3D_Deconv3D.jls');">Neurons3D_Deconv3D.jls</a>
    %
    % Input: 3D grayscale image, 3D grayscale image (PSF)
    % Output: 3D grayscale image
    %
    % Parameters:
    % Type:         Algorithm ('Wiener', 'reg' or 'rl')
    % wnr3Dnsr:     Noise to Signal ration (Wiener algorithm only)
    % regnoise:     Noise regularization (regularized inverse algorithm only)
    % rlit:         Number of iterations (RL algorithm only)
    % Model_sep:    Force PSF separable model (experimental, set to 0 to disable)
    % Brick:        Internal bricked mode (set to 1 to enable)
    % BrckSize:     Brick size (pix, 3D cube)
    % GuardBand:    Brick guard band to avoid artefacts between bricks (pix)
    
    Type = params.type;
    wnr3Dnsr = params.wnr3Dnsr;
    regnoise = params.regnoise;
    rlit = params.rlit;
    Model_sep = params.Model_sep;
    Brick = params.Brick;
    BrckSize = params.BrckSize;
    GuardBand = params.GuardBand;

    if  ~isempty(A)

    % Image info and configuration
    BrckStep = BrckSize-2*GuardBand;
    Nslices = size(A,3);
    Imghgth = size(A,1);
    Imgwdth = size(A,2);
    if Brick == 0
        BrckStep = 0;
        GuardBand = 0;
    end

    % PSF
    B = B/max(B(:));

    % Model separable PSF
    if Model_sep > 0

        %% Max projection XY
        RefXY = max(B,[],3);
        %% Max projection YZ
        RefYZ = squeeze(max(B,[],1));
        %% Max projection components
        RefX = max(RefXY,[],1);
        RefY = max(RefXY,[],2);
        RefZ = max(RefYZ,[],1);

        %% Model X component
        x = (1:numel(RefX)).';y = RefX.';
        f = fit(x,y,'gauss1');
        f.b1 = round(f.b1);
        %figure;plot(f,x,y);
        kX = f(x);kX = kX/max(kX(:));
        %% Model Y component   
        x = (1:numel(RefY)).';y = RefY;
        f = fit(x,y,'gauss1');
        f.b1 = round(f.b1);
        %figure;plot(f,x,y);
        kY = f(x);kY = kY/max(kY(:));
        %% Model Z component
        x = (1:numel(RefZ)).';y = RefZ.';
        f = fit(x,y,'gauss1');
        f.b1 = round(f.b1);
        %figure;plot(f,x,y);
        kZ = f(x);kZ = kZ/max(kZ(:));

        % PSF 3D model
        B_mod = zeros(numel(kY),numel(kX),numel(kZ));
        Bxy_mod = (kY*kX.');
        for i = 1:numel(kZ)
            B_mod(:,:,i) = Bxy_mod*kZ(i);
        end
        Res = B-B_mod;disp(sqrt(mean(Res(:).^2)));

        % Use PSF 3D model for further processing
        B = B_mod;
    end

    % Edge anti-ringing
    A = edgetaper(A,B);

    if Model_sep < 2
    if Brick == 1
        % Brick deconvolution
        D = single(zeros(size(A)));
        NBricks = ceil((size(A,2)-BrckStep-3*GuardBand)/BrckStep)*ceil((size(A,1)-BrckStep-3*GuardBand)/BrckStep);
        cntBrick = 1;
        for i = GuardBand+1:BrckStep:size(A,1)-BrckStep-2*GuardBand
            for j = GuardBand+1:BrckStep:size(A,2)-BrckStep-2*GuardBand
                disp(round(100*cntBrick/NBricks));
                In = uint16(zeros(BrckStep+2*GuardBand,BrckStep+2*GuardBand,size(A,3)));
                In = A(i-GuardBand:i+BrckStep+GuardBand-1,j-GuardBand:j+BrckStep+GuardBand-1,:);
                if strcmp(Type,'wiener')
                    Out = deconvwnr(In, B, wnr3Dnsr);
                end
                if strcmp(Type,'reg')
                    Out = deconvreg(In, B, regnoise);
                end
                if strcmp(Type,'rl')
                    Out = deconvlucy(In, B, rlit);
                end
                D(i:i+BrckStep-1,j:j+BrckStep-1,:) = Out(GuardBand+1:end-GuardBand,GuardBand+1:end-GuardBand,:);
                cntBrick = cntBrick+1;
            end
        end
        D = D(GuardBand+1:GuardBand+Imghgth,GuardBand+1:GuardBand+Imgwdth,:);
    else
        % 3D deconvolution of whole data set in memory    
        if strcmp(Type,'wiener')
            D = deconvwnr(A, B, wnr3Dnsr);   
        end
        if strcmp(Type,'reg')
            D = deconvreg(A, B, regnoise);
        end
        if strcmp(Type,'rl')
            D = deconvlucy(A, B, rlit);
        end
    end
    end

    % Plane by plane deconvolution (experimental)
    if Model_sep == 2
        h = kX*kZ.';
        A = permute(A,[3 2 1]);
        D = single(zeros(size(A)));
        hpad = zeros(size(D,1),size(D,2));
        hpad(floor(size(D,1)/2)-floor(size(h,1)/2):floor(size(D,1)/2)+floor(size(h,1)/2),floor(size(D,2)/2)-floor(size(h,2)/2)+1:floor(size(D,2)/2)+floor(size(h,2)/2)) = h;
        for i = 1:size(D,3)
            D(:,:,i) = tsvd_dct(single(A(:,:,i)), hpad, [floor(size(hpad,1)/2),floor(size(hpad,2)/2)], 3);
            disp(i);
        end
        A = permute(A,[3 2 1]);
        D = permute(D,[3 1 2]);
        h = kY*kZ.';
        h(:,1:floor(size(h,2)/2)) = 0;
        h(:,floor(size(h,2)/2)+2:end) = 0;
        hpad = zeros(size(D,1),size(D,2));
        hpad(floor(size(D,1)/2)-floor(size(h,1)/2):floor(size(D,1)/2)+floor(size(h,1)/2),floor(size(D,2)/2)-floor(size(h,2)/2)+1:floor(size(D,2)/2)+floor(size(h,2)/2)) = h;
        for i = 1:size(D,3)
            D(:,:,i) = tsvd_dct(D(:,:,i), hpad, [floor(size(hpad,1)/2),floor(size(hpad,2)/2)], 3);
            disp(i);
        end
        D = permute(D,[1 3 2]); 
    end
  
    D = uint16(D*mean(A(:))/mean(D(:)));
    
    else
        
        D = [];
    
    end
    
end
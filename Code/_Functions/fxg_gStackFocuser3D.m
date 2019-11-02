function [Im] = fxg_gStackFocuser3D(Im, params)

    % Compute extended depth of field projection (conserve in focus structures).
    %
    % Sample journal: <a href="matlab:JENI('CellColonies3D_StackFocuser3D.jls');">CellColonies3D_StackFocuser3D.jls</a>
    %
    % Input: 3D grayscale image
    % Output: 2D grayscale image
    %
    % Parameters:
    % WSize:    Analysis window size (pix)
    % Alpha:    Parameter of the AIF algorithm
    % Sth:      Parameter of the AIF algorithm

    WSize = params.WSize;
    Alpha = params.Alpha;
    Sth = params.Sth;
    
    if ~isempty(Im)

        Options.Size(1) = size(Im, 1);
        Options.Size(2) = size(Im, 2);
        Options.Size(3) = size(Im, 3);
        Options.RGB = false;
        Options.STR = false;
        Options.Alpha = Alpha;
        Options.Sth = Sth;
        Options.WSize = WSize;
        Options.Focus = 1:Options.Size(3);
        M = Options.Size(1);
        N = Options.Size(2);
        P = Options.Size(3);

        ImagesG = Im;
        FM = zeros(size(Im));

        %********* Compute fmeasure **********
        for p = 1:P
            FM(:,:,p) = gfocus(im2double(Im(:,:,p)), Options.WSize);
        end

        %********** Compute Smeasure ******************
        [u s A Fmax] = gauss3P(Options.Focus, FM);
        %Aprox. RMS of error signal as sum|Signal-Noise| instead of sqrt(sum(Signal-noise)^2)
        Err = zeros(M,N);
        for p = 1:P
            Err = Err + abs( FM(:,:,p) - ...
                A.*exp(-(Options.Focus(p)-u).^2./(2*s.^2)));
            FM(:,:,p) = FM(:,:,p)./Fmax;
        end
        H = fspecial('average', Options.WSize);
        inv_psnr = imfilter(Err./(P*Fmax), H, 'replicate');

        S = 20*log10(1./inv_psnr);
        Phi = 0.5*(1+tanh(Options.Alpha*(S-Options.Sth)))/...
           Options.Alpha;

        %********** Compute weights: ********************
        fun = @(phi,fm) 0.5+0.5*tanh(phi.*(fm-1));
        for p = 1:P    
            FM(:,:,p) = feval(fun, Phi, FM(:,:,p));
        end

        %********* Fuse images: *****************
        FMn = sum(FM,3);
        Im = sum((ImagesG.*FM), 3)./FMn;
    
    else
        
        Im = [];
    
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [u s A Ymax] = gauss3P(x, Y)
        STEP = 2;
        [M,N,P] = size(Y);
        [Ymax, I] = max(Y,[ ], 3);
        [IN,IM] = meshgrid(1:N,1:M);
        Ic = I(:);
        Ic(Ic<=STEP)=STEP+1;
        Ic(Ic>=P-STEP)=P-STEP;
        Index1 = sub2ind([M,N,P], IM(:), IN(:), Ic-STEP);
        Index2 = sub2ind([M,N,P], IM(:), IN(:), Ic);
        Index3 = sub2ind([M,N,P], IM(:), IN(:), Ic+STEP);
        Index1(I(:)<=STEP) = Index3(I(:)<=STEP);
        Index3(I(:)>=STEP) = Index1(I(:)>=STEP);
        x1 = reshape(x(Ic(:)-STEP),M,N);
        x2 = reshape(x(Ic(:)),M,N);
        x3 = reshape(x(Ic(:)+STEP),M,N);
        y1 = reshape(log(Y(Index1)),M,N);
        y2 = reshape(log(Y(Index2)),M,N);
        y3 = reshape(log(Y(Index3)),M,N);
        c = ( (y1-y2).*(x2-x3)-(y2-y3).*(x1-x2) )./...
            ( (x1.^2-x2.^2).*(x2-x3)-(x2.^2-x3.^2).*(x1-x2) );
        b = ( (y2-y3)-c.*(x2-x3).*(x2+x3) )./(x2-x3);
        s = sqrt(-1./(2*c));
        u = b.*s.^2;
        a = y1 - b.*x1 - c.*x1.^2;
        A = exp(a + u.^2./(2*s.^2));
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function FM = gfocus(Image, WSize)
        MEANF = fspecial('average',[WSize WSize]);
        U = imfilter(Image, MEANF, 'replicate');
        FM = (Image-U).^2;
        FM = imfilter(FM, MEANF, 'replicate');
    end

end
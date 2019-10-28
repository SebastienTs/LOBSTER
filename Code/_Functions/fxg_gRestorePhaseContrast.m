function [O] = fxg_gRestorePhaseContrast(I, params)

    % Restore contrast phase image by inverse optical modeling.
    %
    % Sample journal: <a href="matlab:JENI('CellsPhaseContrast_Restore.jl');">CellsPhaseContrast_Restore.jl</a>
    %
    % Input: 2D grayscale image
    % Output: 2D grayscale image
    %
    % Parameters:
    % w_smooth_spatio:  Weight of spatial smoothness term
    % w_sparsity:       Weight of sparsity term
    % gamma:            Used for reweighting
    % maxiter:          Maximum number of iterations
    % tol:              Iteration stopping criterion
    % Rwid:             Phase contrast annulus geometry              
    % Wwid:             Phase contrast annulus geometry 
    % MRadius:          Phase contrast annulus geometry 
    
    warning('off','Images:initSize:adjustingMag');

    %parameter setting
    w_smooth_spatio = params.w_smooth_spatio;    
    w_sparsity = params.w_sparsity;
    gamma = params.gamma;
    maxiter = params.maxiter; 
    tol = params.tol;
    Rwid = params.Rwid; 
    Wwid = params.Wwid; 
    MRadius = params.MRadius;

    PhaseIm = double(I);
    PhaseIm = PhaseIm/max(PhaseIm(:));
    [nrows, ncols] = size(PhaseIm); 
    N = nrows*ncols;

    %flattern the image
    [xx yy] = meshgrid(1:ncols, 1:nrows);
    xx = xx(:); yy = yy(:);
    X = [ones(N,1), xx, yy, xx.^2, xx.*yy, yy.^2];
    p = X\PhaseIm(:); %p = (X'*X)^(-1)*X'*im(:);    
    flatPhaseIm = reshape(PhaseIm(:)-X*p,[nrows,ncols]);
    
    %get the microscope imaging model
    [H] = getPhaseImagingModelHAiry(nrows, ncols, Rwid, Wwid, MRadius); 
    HH = H'*H;

    %get the smooth kernel
    wid = 3; hwid = floor(wid/2); nsz = wid^2;     
    D = -ones(wid,wid)/(nsz-1);
    D(hwid+1,hwid+1) = 1; 
    inds = reshape(1:N, nrows, ncols);
    inds_pad = padarray(inds,[hwid hwid],'symmetric');
    row_inds = repmat(1:N,nsz,1);
    col_inds = im2col(inds_pad,[wid,wid],'sliding'); %slide col and then row
    vals = repmat(D(:),N,1);
    R = sparse(row_inds(:), col_inds(:), vals, N, N); 
    L = R'*R;

    %solve the optimization problem            
    A = HH + w_smooth_spatio*L;
    btmp = -H'*flatPhaseIm(:);
    Ap = A; Ap(A<0) = 0;
    An = Ap-A;    
    f = ones(N,1);
    W = ones(N,1);
    err = zeros(maxiter,1);
    for iter = 1:maxiter        
        b = btmp + w_sparsity*W;
        tmp = Ap*f;       
        newf = 0.5*f.*(-b+sqrt(b.^2+4*tmp.*(An*f)))./(tmp+eps);       
        W = ones(N,1)./(newf+gamma);        
        err(iter) = sum(abs(f-newf));
        if err(iter) < tol
            break;
        end
        f = newf;
        Phasef = reshape(f,[nrows, ncols]);
    end         

    O = uint16(65535*Phasef/max(Phasef(:)));

end

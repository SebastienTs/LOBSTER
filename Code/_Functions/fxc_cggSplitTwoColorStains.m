function [Inorm, H, E] = fxc_cggSplitTwoColorStains(I, params)

    % Normalize color image (two stains) to reference H&E color image. 
    % The stains can actually have any color vectors, the normalized image will look like H&E. 
    %
    % Sample journal: <a href="matlab:JENI('TwoPureColors_SplitTwoStains.jl');">TwoPureColors_SplitTwoStains.jl</a>
    %
    % Input: 2D RGB image
    % Output: 2D RGB H&E image, 2D grayscale image (first stain), 2D grayscale image (second stain)
    %
    % Parameters:
    % beta:     OD threshold for transparent pixels (default: 0.15);
    % alpha:    Tolerance for pseudo-min and pseudo-max (default: 1);
    %
    % Fixed parameters
    % Io:       Transmitted light intensity (default: 240)
    % HERef:    H&E OD matrix
    % maxCRef:  Maximum stain concentrations for H&E (1.9705, 1.0308)

    Io = params.Io;
    beta = params.beta; 
    alpha = params.alpha;
    
    % reference H&E OD matrix
    if ~exist('HERef', 'var') || isempty(HERef)
        HERef = [
            0.5626    0.2159
            0.7201    0.8012
            0.4062    0.5581
            ];
    end

    % reference maximum stain concentrations for H&E
    if ~exist('maxCRef)', 'var') || isempty(maxCRef)
        maxCRef = [
            1.9705
            1.0308
            ];
    end

    h = size(I,1);
    w = size(I,2);

    I = double(I);

    I = reshape(I, [], 3);

    % calculate optical density
    OD = -log((I+1)/Io);

    % remove transparent pixels
    ODhat = OD(~any(OD < beta, 2), :);

    % calculate eigenvectors
    [V, ~] = eig(cov(ODhat));

    % project on the plane spanned by the eigenvectors corresponding to the two
    % largest eigenvalues
    That = ODhat*V(:,2:3);

    % find the min and max vectors and project back to OD space
    phi = atan2(That(:,2), That(:,1));

    minPhi = prctile(phi, alpha);
    maxPhi = prctile(phi, 100-alpha);

    vMin = V(:,2:3)*[cos(minPhi); sin(minPhi)];
    vMax = V(:,2:3)*[cos(maxPhi); sin(maxPhi)];

    % a heuristic to make the vector corresponding to hematoxylin first and the
    % one corresponding to eosin second
    if vMin(1) > vMax(1)
        HE = [vMin vMax];
    else
        HE = [vMax vMin];
    end

    % rows correspond to channels (RGB), columns to OD values
    Y = reshape(OD, [], 3)';

    % determine concentrations of the individual stains
    C = HE \ Y;

    % normalize stain concentrations
    maxC = prctile(C, 99, 2);

    C = bsxfun(@rdivide, C, maxC);
    C = bsxfun(@times, C, maxCRef);

    % recreate the image using reference mixing matrix
    Inorm = Io*exp(-HERef * C);
    Inorm = reshape(Inorm', h, w, 3);
    Inorm = uint8(Inorm);

    if nargout > 1
        %H = Io*exp(-HERef(:,1) * C(1,:));
        %H = reshape(H', h, w, 3);
        H = Io*exp(-C(1,:));
        H = reshape(H', h, w);
        H = uint8(H);
    end

    if nargout > 2
        %E = Io*exp(-HERef(:,2) * C(2,:));
        %E = reshape(E', h, w, 3);
        E = Io*exp(-C(2,:));
        E = reshape(E', h, w);
        E = uint8(E);
    end

end

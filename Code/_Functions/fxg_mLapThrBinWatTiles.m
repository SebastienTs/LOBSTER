function [M] = fxg_mLapThrBinWatTiles(A, params)
    
    % Apply LoG + threshold + regularized binary watershed.
    %
    % Sample journal: <a href="matlab:JENI('HeLaMovie_LapThrBinWatTiles.jl');">HeLaMovie_LapThrBinWatTiles.jl</a>
    %
    % Input: 2D grayscale image
    % Output: 2D binary mask
    %
    % Parameters:
    % GRad:             Gaussian blur pre-filter radius
    % Thr:              LoG threshold
    % GaussianD:        Particle splitting regularization, set to -1 to disable splitting
    % MinArea:          Minimum particle area
    
    %% Parameters
    GRad = params.GRad;
    Thr = params.Thr;
    GaussianD = params.GaussianD;
    MinArea = params.MinArea;
    
    if ~isempty(A)
    
        %% Initialize filter
        H = fspecial('log',3*GRad,GRad);
        
        %% Filter
        ALog = -imfilter(A,H,'same','symmetric');
        
        %% Threshold
        At = (ALog >= Thr);

        %% Split convex particles
        if GaussianD > -1
            D = -bwdist(~At);
            D = imgaussfilt(D,GaussianD);
            M = watershed(D)>0;
            M(~At) = 0;
        else
            M = At;
        end
        
        %% Remove small particle
        if MinArea > 0
            M = bwareaopen(M, MinArea);
        end
        
        %% Create segmentation mask
        M = uint8(255*M);
        
    else
      
        M = [];
        
    end
    
end
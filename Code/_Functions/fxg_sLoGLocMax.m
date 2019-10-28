function [O] = fxg_sLoGLocMax(I, params)

    % Apply LoG + invert + detect 3D local intensity maxima (mark seeds).
    %
    % Sample journal: <a href="matlab:JENI('NucleiNoisy_DetLogLocMax.jl');">NucleiNoisy_DetLogLocMax.jl</a>
    %
    % Input: 2D grayscale image
    % Output: 2D seed mask
    %
    % Parameters:
    % GRad:             Gaussian blur pre-filter radius (pix)
    % LocalMaxBox:      Size of local intensity maxima search box (pix)     
    % ThrLocalMax:      Minimum intensity to validate local maxima
    % MinLocThr:        Minimum local contrast between closest detection (0 - 1, set to 0 to disable)
    
    % Parameters
    GRad = params.GRad;
    LocalMaxBox = params.LocalMaxBox;
    ThrLocalMax = params.ThrLocalMax;
    MinLocThr = params.MinLocThr;
    
    if ~isempty(I)

        %% Initialize filters
        H = fspecial('log',3*GRad,GRad);
        LocMxse = ones(LocalMaxBox(1),LocalMaxBox(2));
        LocMxse(ceil(end/2),ceil(end/2)) = 0;

        %% XY LoG filter
        I = single(I);
        ILog = -imfilter(I,H,'same','symmetric');
        
        %% Local maxima detection
        Maxima = ILog > imdilate(ILog,LocMxse);
        Maxima = Maxima.*(ILog>ThrLocalMax);       
        
        %% Local maxima CC --> pixels
        O = fxm_sMarkObjCentroids(Maxima,[]);
        
        %% Remove spurious local maxima
        if MinLocThr > 0
            [Y, X] = find(O>0);
            [Idx D] = knnsearch([Y X],[Y X],'K',2);
            for i = 1:size(Y,1)
                [x y] = bresenham(X(i),Y(i),X(Idx(i,2)),Y(Idx(i,2)));
                P = ILog(y+1+(x-1)*size(I,1));
                mx = max(P(:));mn = min(P(:));
                C = (mx-mn)/mx;
                if C < MinLocThr
                    O(Y(i),X(i)) = 0;
                    O(Y(Idx(i,2)),X(Idx(i,2))) = 0;
                    O(round((Y(i)+Y(Idx(i,2)))/2),round((X(i)+X(Idx(i,2)))/2)) = 200;
                end
            end
        end
        
    else
        
        O = [];
        
    end
    
end
function [O] = fxg_sLoG3DLocMax3D(I, params)

    % Apply 3D LoG + invert + detect 3D local intensity maxima (mark seeds).
    %
    % Input: 3D grayscale image
    % Output: 3D seed mask
    %
    % Sample journal: <a href="matlab:JENI('CellPilar3D_DetLog3DLocMax3D.jls');">CellPilar3D_DetLog3DLocMax3D.jls</a>
    %
    % Parameters:
    % Sigmas:           X,Y,Z sigmas of Gaussian blur pre-filter (vector, pix)     
    % LocalMaxBox:      X,Y,Z size of the local maxima search window
    % MinLoG:           Minimum LoG response for object detection (normalized to 1)
    % MinDst:           Minimum distance between local maxima (assuming Zratio=1, set o 0 to disable)

    %% Parameters
    Sigmas = params.Sigmas;
    LocalMaxBox = params.LocalMaxBox;
    NrmLoG = params.NrmLoG;
    MinLoG = params.MinLoG;
    MinDst = params.MinDst;
    
    if ~isempty(I)
        
        %% 3DLoG filter
        disp('Filtering stack...');
        G1 = fspecial('gauss',[round(5*Sigmas(1)) 1], Sigmas(1));
        G2 = fspecial('gauss',[round(5*Sigmas(2)) 1], Sigmas(2));
        G3 = fspecial('gauss',[round(5*Sigmas(3)) 1], Sigmas(3));
        If = imfilter(I,G1,'same','symmetric');
        If = permute(imfilter(permute(If,[2 1 3]),G2,'same','symmetric'),[2 1 3]);
        If = permute(imfilter(permute(If,[3 2 1]),G3,'same','symmetric'),[3 2 1]);
        disp('Computing derivatives...');
        ILog = -padarray(diff(If,2,1),[2 0 0],'post');
        ILog = ILog-padarray(diff(If,2,2),[0 2 0],'post');
        ILog = ILog-padarray(diff(If,2,3),[0 0 2],'post');
        
        %% LoG significant local maxima detection
        disp('Detecting significant local maxima...');
        if NrmLoG > 0
            Lvl = abs(max(ILog(:)))*MinLoG;
        else
            Lvl = MinLoG;
        end
        O = LocMax3D_thr(ILog,Lvl,floor(LocalMaxBox(1)/2),floor(LocalMaxBox(2)/2),floor(LocalMaxBox(3)/2));
        
        %% Remove spurious local maxima
        if MinDst > 0
            Idx = find(O>0);
            [Y, X, Z] = ind2sub(size(O),Idx);
            [Idx D] = knnsearch([Y X Z],[Y X Z],'K',2);
            for i = 1:size(Y,1)
                if D(i,2) < MinDst
                    O(Y(i),X(i),Z(i)) = 0;
                    O(Y(Idx(i,2)),X(Idx(i,2)),Z(Idx(i,2))) = 0;
                    O(round((Y(i)+Y(Idx(i,2)))/2),round((X(i)+X(Idx(i,2)))/2),round((Z(i)+Z(Idx(i,2)))/2)) = 200;
                end
            end
        end
        
        %% Create seed mask
        %disp('Creating seed mask...');
        %O = fxm_sMarkObjCentroids(O,[]);
        %O = uint8(200*O);
        
    else
        
    	O = [];
        
    end
    
end
function [O, M] = fxg_gmLocOrientation(I, params)

    % Compute local orientation.
    %
    % Sample journal: <a href="matlab:JENI('FibersLocOrientation.jl');">FibersLocOrientation.jl</a>
    %
    % Input: 2D grayscale image
    % Output: 2D image encoding local orientation (0-179 deg), 2D binary mask with local orientation segments.
    %
    % Parameters: 
    % GRad:         Gaussian blur pre-filter radius (estimate local intensity gradient)    
    % CellSize:     Analysis block size (pix)
    % MinMag:       Minimum gradient magnitude to estimate local orientation
    % Vecs:         Binary mask: local orientation segments half length  (0 to disable) 

    %% Parameters
    GRad = params.GRad;
    CellSize = params.CellSize; 
    MinMag = params.MinMag;
    Vecs = params.Vecs;
    
    if ~isempty(I)
    
        %% Prefilter
        If = imgaussfilt(I,GRad);
        [Gmag,Gdir] = imgradient(If);

        %% Compute block positions
        [PosX PosY] = meshgrid(1+ceil(CellSize/2):CellSize:size(I,2)-ceil(CellSize/2),1+ceil(CellSize/2):CellSize:size(I,1)-ceil(CellSize/2));
        PosY = PosY(:);PosX = PosX(:);

        %% Compute block dominant orientation
        LocDir = NaN(numel(PosX),1);
        O = uint8(zeros(size(I)));
        for i = 1:numel(PosX)
            WndMag = Gmag(PosY(i)-floor(CellSize/2):PosY(i)+floor(CellSize/2),PosX(i)-floor(CellSize/2):PosX(i)+floor(CellSize/2));
            [MaxMag ind] = max(WndMag(:));
            if MaxMag >= MinMag
                WndDir = Gdir(PosY(i)-floor(CellSize/2):PosY(i)+floor(CellSize/2),PosX(i)-floor(CellSize/2):PosX(i)+floor(CellSize/2));
                LocDir(i) = WndDir(ind);
                MappedVal = round(mod(180+round(WndDir(ind)),180));
                O(PosY(i)-floor(CellSize/2):PosY(i)+floor(CellSize/2),PosX(i)-floor(CellSize/2):PosX(i)+floor(CellSize/2)) = MappedVal;
            end
        end

        if Vecs > 0
            M = uint8(zeros(size(I)));
            nPoints = 6;
            %XVec = [PosX - Vecs*sin((LocDir)*pi/180) PosX + Vecs*sin((LocDir)*pi/180)];
            %YVec = [PosY - Vecs*cos((LocDir)*pi/180) PosY + Vecs*cos((LocDir)*pi/180)];
            for i = 1:numel(PosX)
                PosX1 = PosX(i) - Vecs*sin((LocDir(i))*pi/180);
                PosX2 = PosX(i) + Vecs*sin((LocDir(i))*pi/180);
                PosY1 = PosY(i) - Vecs*cos((LocDir(i))*pi/180);
                PosY2 = PosY(i) + Vecs*cos((LocDir(i))*pi/180);
                rIndex = round(linspace(PosY1, PosY2, nPoints));  % Row indices
                cIndex = round(linspace(PosX1, PosX2, nPoints));  % Column indices
                index = sub2ind(size(M), rIndex, cIndex);
                if sum(isnan(index))==0
                    M(index) = 255;
                end
            end
            %figure;imagesc(If);colormap(gray);hold on;
            %plot(XVec.',YVec.','r');
        else
            M = [];
        end
        
    else
       
        O = [];
        M = [];
        
    end

end
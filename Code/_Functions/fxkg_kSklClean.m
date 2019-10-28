function [M] = fxkg_kSklClean(M, I, params)

        % Clean skeleton mask by removing small branches, attempting to connect close endpoints and
        % removing small connected components.
        %
        % Sample journal: <a href="matlab:JENI('EyeVesselsSpots_ConnLocThrFilamClean.jl');">EyeVesselsSpots_ConnLocThrFilamClean.jl</a>
        %
        % Input: 2D skeleton mask
        % Output: 2D skeleton mask
        %
        % Parameters:
        % MinBrchLgth:      Remove small branches (pre-process, pix)
        % SearchRad:        Maximum end point gap closing (pix) 
        % MinMean:          Minimum mean intensity over gap closing
        % MinArea:          Minimum isolated skeleton area (pix)
        
        %% Parameters
        MinBrchLgth = params.MinBrchLgth;
        SearchRad = params.SearchRad;
        MinArea = params.MinArea;
        MinMean = params.MinMean;
        
        if ~isempty(M)

            %% Retrieve skeleton mask
            skl = (M==200);

            %% Detect branch and end points
            sklep = bwmorph(skl,'endpoints');
            sklbr = bwmorph(skl,'branchpoints');
            
            %% Remove small branches with endpoints
            if MinBrchLgth > 0
                D = bwdistgeodesic(skl,sklbr);
                Msk = (D <= MinBrchLgth)&(D > 1);
                Rem = imreconstruct(sklep, Msk,8);
                skl = (skl-Rem);
                %% Remove one pixel from endpoints
                sklep = bwmorph(skl,'endpoints');           
                skl = (skl-sklep)>0;
                %% Analyze endpoints of cleaned up skeleton
                sklep = bwmorph(skl,'endpoints');
            end

            %% Connect close skeleton endpoints
            if SearchRad > 0
                [CandPtsY CandPtsX] = find(sklep>0);
                CandCoords = [CandPtsX CandPtsY];
                [k Dist] = knnsearch(CandCoords,CandCoords,'K',3);
                for i = 1:size(k,1)
                    score = -1;bestscore = -1;bestind = -1;bestpts = [];
                    for j = 2:3
                        if(Dist(i,j) <= SearchRad)
                            xpts = round(linspace(CandCoords(i,1),CandCoords(k(i,j),1),SearchRad));
                            ypts = round(linspace(CandCoords(i,2),CandCoords(k(i,j),2),SearchRad));
                            pts = sub2ind(size(I),ypts,xpts);
                            score = mean(I(pts));
                        end
                        if (score > bestscore)
                            bestscore = score;
                            bestpts = pts;
                        end
                    end
                    if bestscore >= MinMean
                        skl(bestpts) = 1;
                    end
                end
            end
            
            %% Re-skeletonize
            skl = bwmorph(skl,'thin',Inf);
            
            %% Remove small connected components
            skl = bwareaopen(skl,MinArea);
            
            %% Create skeleton mask
            M = uint8(100*(M&(skl==0)))+uint8(200*(skl>0));
        
        else
            
            M = [];
  
        end
function O = fxk_kSklLbl3D(O, params)

    % Label skeleton mask, optionally prune short branches
    % !!!! Set SklLbl = 1 when calling IRMA 'Skls' !!!! 
    %
    % Sample journal: <a href="matlab:JENI('BloodVessels3D_LocThr3DSkl3D.jls');">BloodVessels3D_LocThr3DSkl3D.jls</a>
    %
    % Input: 3D skeleton mask (binary)
    % Output: 3D skeleton mask
    %
    % Parameters:
    % SklLbl: Labeling mode
    %   0: original segmentation mask + skeleton + branch/end points
    %   1: skeleton + branch/end points
    %   2: skeleton with branch color coding (ID)
    %   3: skeleton with branch color coding (length)
    % MinBrchLgth: Minimum end to branch point link length
    % MinBrchLgth2: Minimum branch to branch point link length
    % MaxIter: Maximum number of iterations for short branch pruning
    % Ignore4Way: Ignore 4 way branches
    % ZRatio: Only used to estimate branch length in pixel width unit

    SklLbl = params.SklLbl;
    MinBrchLgth = params.MinBrchLgth;
    MinBrchLgth2 = params.MinBrchLgth2;
    MaxIter = params.MaxIter;
    Ignore4Way = params.Ignore4Way;
    ZRatio = params.ZRatio;
    
    if ~isempty(O)
        
        %% Skeleton analysis (note: isolated loops are ignored)
        [~, node, link] = Skel2Graph3D((O>=200),0);
        
        %% Remove mask
        if SklLbl > 0
            O = uint8(zeros(size(O)));
        end
        
        %% Make sure this field is added to the structure
        for i = 1:length(node)
            node(i).rem = 0;
        end
        
        %% Flag 4-way+ long branch points
        if(Ignore4Way > 0)
            for i = 1:length(node)
                linkinds = node(i).links;
                brchlinks = link(linkinds);
                if sum(arrayfun(@(x) numel(x.point),brchlinks) > 0) >= 4
                %if sum(arrayfun(@(x) numel(x.point),brchlinks) > MinBrchLgth) >= 4
                    node(i).rem = 1;
                end    
            end
        end
        
        %% Iteratively remove short links
        if MinBrchLgth>0
            nlink = -1;
            nlinknew = numel(link);
            cnt = 1;
            while nlink ~= nlinknew && cnt<= MaxIter
                [node, link] = RemSmallBrch(node, link, MinBrchLgth, MinBrchLgth2);
                nlink = nlinknew;
                nlinknew = numel(link);
                cnt = cnt+1;
            end
        end
 
        %% Branch + end points
        if SklLbl <= 1
            for i = 1:length(link)
                O(link(i).point) = 200;
            end
            for i = 1:length(node) 
                if node(i).rem == 0
                    %if numel(size(O)) == 3
                    %    [yinds xinds zinds] = ind2sub(size(O),node(i).idx);
                    %    flag = sum([yinds xinds zinds] == 1) + sum(yinds == size(O,1)) + sum(xinds == size(O,2)) + sum(zinds == size(O,3));
                    %else
                    %    [yinds xinds] = ind2sub(size(O),node(i).idx);
                    %    flag = sum([yinds xinds] == 1) + sum(yinds == size(O,1)) + sum(xinds == size(O,2));
                    %end
                    if node(i).ep == 0
                        O(node(i).idx) = 250;   % Branch point
                    else
                        O(node(i).idx) = 220;   % End point
                    end
                end
            end 
        end
        
        %% Color code skeleton branches (ID)
        if SklLbl == 2
            O = uint8(zeros(size(O)));
            for i = 1:length(link)
                O(link(i).point) = i;
            end
        end
        
        %% Encode branch lengths
        if SklLbl == 3
            O = uint8(zeros(size(O)));
            for i = 1:length(link)
                [cY cX cZ] = ind2sub(size(O),link(i).point);
                if length(cY) == 3
                    O(link(i).point) = arclength(cX,cY,cZ*ZRatio);
                else
                    O(link(i).point) = arclength(cX,cY,ones(size(cX)));
                end 
                %O(link(i).point) = length(link(i).point);
            end
        end
        
    else
        
        O = [];
        
    end
    
end
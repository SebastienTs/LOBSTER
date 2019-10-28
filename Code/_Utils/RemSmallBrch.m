% Remove short branches from link structure, accordingly flag (node.rem)
% nodes for removal (nodes are not removed to avoid re-indexing). 
% Only short links with endpoint are removed: 
% The endpoint node is flagged, the other node is flagged only if its 
% cardinality is equal to 2 (set as end point if equal to 1).
% Note: node.conn is not updated in this code

function [node, link] = RemSmallBrch(node, link, MinBrchLgth, MinBrchLgth2)

    %% Find short links
    indx = find(arrayfun(@(s) length(s.point), link)<MinBrchLgth);
  
    %% Initialize links remove flags to 0
    rem = uint8(zeros(size(indx)));
    
    %% Remove end to branch point short links
    for i = 1:length(indx)
        n1 = link(indx(i)).n1;
        n2 = link(indx(i)).n2;
        if node(n1).ep == 1
            rem(i) = 1;
            node(n1).rem = 1;
            lnks = node(n2).links;
            lnks(lnks == indx(i)) = [];
            node(n2).links = lnks;
            if length(lnks)==2
                node(n2).rem = 1;
            end
            if length(lnks)==1
                node(n2).ep = 1;
                node(n2).rem = 0;
            end
        end
        if node(n2).ep == 1
            rem(i) = 1;
            node(n2).rem = 1;
            lnks = node(n1).links;  
            lnks(lnks == indx(i)) = [];
            node(n1).links = lnks;
            if length(lnks)==2
                node(n1).rem = 1;
            end
            if length(lnks)==1
                node(n1).ep = 1;
                node(n1).rem = 0;
            end
        end
        % Fuse branch to branch point short links
        if length(link(i).point) < MinBrchLgth2
            if node(n1).ep == 0 && node(n2).ep == 0
                node(n1).idx = [node(n1).idx ; (link(indx(i)).point).' ; node(n2).idx];
                node(n2).rem = 1;
            end
        end
    end
    
    %% Actually remove links if they were true short links
    link(indx(find(rem==1))) = [];
    
end
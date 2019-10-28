function [L, P] = fxgs_lSeededRW(I,L,params)

    % Propagate seeds using Random Walker algorithm.
    %
    % Sample journal: <a href="matlab:JENI('CT_ManualSeededRW.jl');">CT_ManualSeededRW.jl</a>
    %
    % Input: 2D original image, 2D seed mask
    % Output: 2D label mask, 2D probability image
    %
    % Parameters:
    % Beta: Intensity weighting w = exp(-Beta * DeltaInt^2)
    
    Beta = params.Beta;

    if ~isempty(I)
    
        % Indentify seeds
        I = im2double(I);
        Pos = double(find(L>0));

        % Apply the random walker algorithm
        [L, P] = random_walker(I,Pos,L(Pos),Beta);
        L = uint16(L);
        
    else
        
        L = [];
        P = [];
        
    end

end
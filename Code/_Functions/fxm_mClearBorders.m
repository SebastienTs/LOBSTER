function [M] = fxm_mClearBorders(M, params)

    % Remove objects touching image borders.
    %
    % Sample journal: <a href="matlab:JENI('FISH_nucseg.jl');">FISH_nucseg.jl</a>
    %
    % Input: Any mask (2D or 3D)
    % Output: Any mask (2D or 3D)
    %
    % No parameter

    tf = isa(M,'uint8');
    if tf
        M = M.*uint8(imclearborder(M>0));
    else
        M = M.*uint16(imclearborder(M>0));
    end
    
end
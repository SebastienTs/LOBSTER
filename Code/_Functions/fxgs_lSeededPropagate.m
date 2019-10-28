function [L, D] = fxgs_lSeededPropagate(I, L, params)
    
    % Propagate seeds through low intensity variation regions.
    %
    % Sample journal: <a href="matlab:JENI('CellsCyto_SeededPropagate.jl');">CellsCyto_SeededPropagate.jl</a>
    %
    % Input: 2D original image, 2D binary or label mask (seeds)
    % Output: 2D label mask, 2D distance image
    %
    % Parameters:
    % Thr:          Intensity threshold for propagated objects
    % Power:        Apply power law to intensity image prior to processing
    % AnalyzeCC:    Set to 0 for input label mask is passed, 1 for binary mask

    Thr = params.Thr;
    Power = params.Power;
    AnalyzeCC = params.AnalyzeCC;
    
    if ~isempty(I)
    
        if AnalyzeCC
            L = double(bwlabeln(L,4));
        else
            L = double(L);
        end
       
        M = (I>Thr);
        if Power ~= 1 
            [L D] = PropagateRegIntegrate(L,(double(I)).^Power, M);
        else
            [L D] = PropagateRegIntegrate(L,double(I),M);
        end
        
        L = uint16(L);
        
    else
       
        L = [];
        D = [];
        
    end
  
end
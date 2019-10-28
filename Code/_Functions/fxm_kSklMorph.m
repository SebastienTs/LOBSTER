function [Trace] = fxm_kSklMorph(T, params)

    % Skeletonize binary mask.
    %
    % Sample journal: <a href="matlab:JENI('EyeVesselsSpots_IsoScanFilamClean.jl');">EyeVesselsSpots_IsoScanFilamClean.jl</a>
    %
    % Input: 2D binary mask
    % Output: 2D skeleton mask
    %
    % Parameters:
    % Mode:             Thinning 'thin' or skeletonize 'skel'
    % MinBrcLgth:       Minimum branch length (pix)

    %% Parameters
    Mode = params.Mode;
    MinBrcLgth = params.MinBrcLgth;
    sklLvl = 200;
    endLvl = 220;
    brcLvl = 250;
    
    %% Skeletonization first pass
    skl = bwmorph(T, Mode, Inf);
    endpts = bwmorph(skl, 'endpoints');
    brcpts = bwmorph(skl, 'branchpoints');
    Trace = sklLvl*skl;
    Trace(endpts) = endLvl;
    Trace(brcpts) = brcLvl;
    
    if MinBrcLgth > 0
    
        %% Remove small branches
        Branches = zeros(size(Trace));
        Branches(brcpts) = brcLvl;
        Branches = imdilate(Branches,strel(ones(3,3)));
        Trace2 = Trace;
        Trace2(Branches>0) = 0;
        CC = bwconncomp((Trace2 > 0),8);
        for i = 1:CC.NumObjects
            tst = sum(Trace2(CC.PixelIdxList{i}) == endLvl);
            if tst == 1
                if numel(CC.PixelIdxList{i}) < MinBrcLgth
                    Trace2(CC.PixelIdxList{i}) = 0;
                end
            end
        end
    
        %% Redraw branch points and thin
        Trace2 = Trace2+Branches;        
        skl = bwmorph(Trace2, 'thin', Inf);
        endpts = bwmorph(skl, 'endpoints');
        brcpts = bwmorph(skl, 'branchpoints');
        Trace2 = sklLvl*skl;
        Trace2(endpts) = endLvl;
        Trace2(brcpts) = brcLvl;
        Trace = Trace2;
        
        %% Create skeleton mask
        Trace = uint8(100*(T>0).*(Trace==0)+Trace);
        
    end

end
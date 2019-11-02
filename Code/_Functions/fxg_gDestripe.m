function [If] = fxg_gDestripe(I, params)

    % Attenuate loosely parallel stripes.
    %
    % Sample journal: <a href="matlab:JENI('Zebrafish_Destripe.jl');">Zebrafish_Destripe.jl</a>
    %
    % Input: 2D grayscale image
    % Output: 2D grayscale image
    %
    % Parameters: 
    % Angle:        Average stripe orientation (deg / horizontal)
    % Scale:        Scaling factor prior to processing (<=1, speedup vs details)
    % TopRad:       Top-hat filter ball radius (adjust to typical bands width)
    % OpenRad:      Horizontal line structure element length (adjust to typical band gaps)
    % SharpAmount:  Unsharp mask strength (postprocessing, set to 0 to disable)

    Angle = params.Angle;
    Scale = params.Scale; 
    TopRad = params.TopRad;   
    OpenRad = params.OpenRad;  
    SharpAmount = params.SharpAmount;

    if Angle>0
        If = single(imrotate(I,Angle,'crop'));
    else
        If =  single(I);
    end

    for i = 1:2
        Is = imresize(If,Scale);
        I1 = imtophat(Is, strel('ball', TopRad*Scale, 10));
        I2 = imopen(I1, strel('line', OpenRad*Scale, 0));
        If = -If+imresize(I2,1/Scale);
    end

    if Angle>0
        If = imrotate(If,-Angle,'crop');
    end

    if SharpAmount>0
        If = imsharpen(If,'Radius',10,'Amount',SharpAmount);
    end
    
end
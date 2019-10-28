function [] = fxg_gmPIV(InputFolder,OutputFolder,params)

    % Compute the PIV of an image sequence.
    %
    % Sample journal: <a href="matlab:JENI('PIV.jlm');">PIV.jlm</a>
    %
    % Input: 2D grayscale images sequence
    % Output: 2D grayscale velocity map magnitude (scaled, displayed)
    %         2x 2D grayscale velocity components maps (saved)
    %
    % Parameters: 
    % iaSize:   Interrogation window size for each pass (pix, vector)
    % iaStep:   Interrogation window step for each pass (pix, vector)
    % Methods:  Method to use for each pass ('fft' or 'dcn')
    % MinCC:    Minimum cross-correlation peak
    % imMask:   Velocity mask file path (Force 0 velocity where mask is null) 
    
    %% Parameters
    imMask = params.imMask;
    iaSize = params.iaSize;
    iaStep = params.iaStep;
    Methods = params.Methods;
    MinCC = params.MinCC;
    
    %% Initialization
    Files = dir(strcat([InputFolder '*.tif']));
    num_images = numel(Files);
    clear textprogressbar;
    textprogressbar('Processing...');
    pivPar = [];
    pivData = [];
    pivPar.imMask1 = imMask;
    pivPar.imMask2 = imMask;

    for kf = 1:num_images-1

        textprogressbar(round(100*kf/(num_images-1)));
   
        im1 = imread(strcat([InputFolder Files(kf).name]));
        im2 = imread(strcat([InputFolder Files(kf+1).name]));

        [pivPar, pivData] = pivParams(pivData,pivPar,'defaults');
        pivPar.anNpasses = length(iaSize);
        pivPar.iaSizeX = iaSize;
        pivPar.iaSizeY = iaSize;
        pivPar.iaStepX = iaStep;
        pivPar.iaStepY = iaStep;
        pivVar.ccMethod = Methods;
        pivVar.vlMinCC = MinCC; 
        [pivData] = pivAnalyzeImagePair(im1,im2,pivData,pivPar);
        
        Ucomp = 10000*pivData.U;
        Vcomp = 10000*pivData.V;
        Img = imresize(sqrt(single(Ucomp).^2+single(Vcomp).^2),size(im1));
        
        Basename = Files(kf).name;
        Basename = Basename(1:end-4);
        imwrite(uint16(Img), strcat(OutputFolder,[Basename '.tif']),'Compression','deflate');
        imwrite(uint16(32767+Ucomp), strcat(OutputFolder,[Basename '_U.jp2']));
        imwrite(uint16(32767+Vcomp), strcat(OutputFolder,[Basename '_V.jp2']));
        
    end
    
end
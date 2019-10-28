InputFolder = './Images/Yeasts/';
OutputFolder = './Results/Images/Yeasts/';
Rescale = 2;

@iA = '*.tif';

@fxg_mGradWaterTiles [iA] > [L];
params.GaussianRadInt = 2;
params.ExtendedMinThr = 1;
/endf

/%show iA;
/%show L>;

@fxm_lTilesMerge [L, iA] > [L2];
params.GaussianRad = 2;
params.MinObjArea = 175;
params.MinSal = 0.25;
params.MaxValleyness = 0.9;
params.ConcavityThresh = 0.25;
/endf

/%keep L2 > tif;
/show iA > L2;
/keep L2 > tif;
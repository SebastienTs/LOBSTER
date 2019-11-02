InputFolder = './Images/NucleiCytoo/';
OutputFolder ='./Results/Images/NucleiCytoo/';
Fill = 1;
Lbl = 1;

@iA = '*C00*.tif';

@fxg_mGradWaterTiles [iA] > [L];
params.GaussianRadInt = 2;
params.ExtendedMinThr = 2;
/endf

@fxm_lTilesMerge [L, iA] > [L2];
params.GaussianRad = 2;
params.MinObjArea = 175;
params.MinSal = 0;
params.MaxValleyness = 1.1;
params.ConcavityThresh = 0.4;
/endf

/show iA > L2;
/keep L2 > tif;
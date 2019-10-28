InputFolder = './Images/NucleiCytoo/';
OutputFolder ='./Results/Images/NucleiCytoo/';
MinLocalFocus = 2.5;
Min95Percentile = 35;
MaxSatPixFract = 0.05;

@iA = '*C00*.tif';

@fxg_mGradWaterTiles [iA] > [L];
params.GaussianRadInt = 2;
params.ExtendedMinThr = 1.8;
/endf

@fxm_lTilesMerge [L, iA] > [L2];
params.GaussianRad = 2;
params.MinObjArea = 175;
params.MinSal = -0.5;
params.MaxValleyness = 1.075;
params.ConcavityThresh = 0.4;
/endf

/show iA > L2;
/keep L2 > tif;
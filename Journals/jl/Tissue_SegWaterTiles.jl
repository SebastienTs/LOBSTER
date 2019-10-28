InputFolder = './Images/Tissue/';
OutputFolder = './Results/Images/Tissue/';

@iA = '*.tif';

@fxg_mWaterTiles [iA] > [M];
params.GRad = 4;					
params.ExtendedMinThr = 5;
/endf

/show iA > M;
/keep M > tif;
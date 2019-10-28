InputFolder = './Images/TissueSimpleMovie/Movie1/';
OutputFolder = './Results/Images/TissueSimpleMovie/Movie1/';

@iA = '*.tif';

@fxg_mWaterTiles [iA] > [M];
params.GRad = 4;
params.ExtendedMinThr = 1;
/endf

/keep M > tif;
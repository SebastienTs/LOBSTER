InputFolder = './Images/HeLaMCF10AMovie/Movie1/';
OutputFolder = './Results/Images/HeLaMCF10AMovie/Movie1/';

@iA = '*.tif';

@fxg_mLapThrBinWatTiles [iA] > [L];
params.GRad = 7;
params.Thr = 0.02;
params.GaussianD = 2;
params.MinArea = 20;   
/endf

/keep L > tif;
InputFolder = './Images/HeLaMCF10A/';
OutputFolder = './Results/Images/HeLaMCF10A/';

@iA = '*.tif';

@fxg_mLapThrBinWatTiles [iA] > [L];
params.GRad = 7;
params.Thr = 0.02;
params.GaussianD = 5;
params.MinArea = 20;
/endf

/show iA > L;
/keep L > tif;
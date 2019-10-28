InputFolder = './Images/FISH/';
OutputFolder = './Results/Images/FISH_nuc/';

@iA = '*_C00*.tif';

@fxg_mLapThrBinWatTiles [iA] > [L];
params.GRad = 7;
params.Thr = 0.02;
params.GaussianD = 2;
params.MinArea = 150;
/endf

@fxm_mClearBorders [L] > [L2];
params = [];
/endf

/show iA > L2;
/keep L2 > tif;
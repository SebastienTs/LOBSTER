InputFolder = './Images/FISH/';
OutputFolder = './Results/Images/FISH_spt/';

@iA = '*_C01*.tif';

@fxg_mLapThrBinWatTiles [iA] > [L];
params.GRad = 2;
params.Thr = 1;
params.GaussianD = -1;
params.MinArea = 9;
/endf

@fxm_sMarkObjCentroids [L] > [S];
params = [];
/endf

/show iA > S;
/keep S > tif;
InputFolder = './Images/NucleiCytoo/';
OutputFolder = './Results/Images/NucleiCytoo2/';

@iA = '*C00*.tif';
@iB = '*C01*.tif';

@fxg_mMultiPassThr [iA] > [M];
params.NeighRad = 20;
params.GaussRad = 1;
params.Rescale = 1;
params.Th1 = 4;
params.Th2 = 20;
params.Rel = 0.75;
params.MinArea = 100;
/endf

/show iA > M;
/keep M > tif;
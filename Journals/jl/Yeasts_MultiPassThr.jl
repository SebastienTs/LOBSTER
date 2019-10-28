InputFolder = './Images/Yeasts/';
OutputFolder = './Results/Images/Yeasts3/';
Rescale = 2;

@iA = '*.tif';

@fxg_mMultiPassThr [iA] > [M];
params.NeighRad = 25;
params.GaussRad = 1;
params.Rescale = 1;
params.Th1 = 6;
params.Th2 = 10;
params.Rel = 0.9;
params.MinArea = 200;
/endf

@fxm_mModBinWat [M] > [M];
params.SmallHolesArea = 0;
params.DistStdRad = 7;	
params.MinDistLocVar = 9;
/endf

/show iA > M;
/keep M > tif;
InputFolder = './Images/Yeasts/';
OutputFolder = './Results/Images/Yeasts2/';
Rescale = 2;

@iA = '*.tif';

@fxg_mBlockOtsuThr [iA] > [M];
params.OpenRad = 2;
params.TopHatRad = 50;
params.MinRatio = 5;
params.BlckSize = 64;
params.BlckShft = 8;
params.Lvl = 0.5;
params.Bck = 0.5;
params.AbsBck = 0.1;
/endf

@fxm_mModBinWat [M] > [M];
params.SmallHolesArea = 0;
params.DistStdRad = 7;	
params.MinDistLocVar = 9;
/endf

/show iA > M;
/keep M > tif;

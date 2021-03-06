InputFolder = './Images/CytopacqCells/Movie1/';
OutputFolder = './Results/Images/CytopacqCells/Movie1/';

Fill = 0;
Lbl = 1;

@iA = '*.tif';

@fxg_mLocThr [iA] > [M];
params.Sigmas = [4 4];
params.MeanBox = [50 50];
params.AddThr = 2;
params.MinArea = 0;
params.IgnoreZero = 0;   
/endf

@fxm_mModBinWat [M] > [M2];
params.SmallHolesArea = 0;
params.DistStdRad = 5;
params.MinDistLocVar = 9;
/endf

/keep M2 > tif;
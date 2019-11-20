InputFolder = './Images/CytopacqCells/Movie1/';
OutputFolder = './Results/Images/CytopacqCells/Movie1_/';

Fill = 1;
Lbl = 1;

@iA = '*.tif';

@fxg_mLocThr [iA] > [M];
params.Sigmas = [4 4];
params.MeanBox = [50 50];
params.AddThr = 2;
params.IgnoreZero = 0;   
/endf

@fxm_mModBinWat [M] > [M2];
params.SmallHolesArea = 0;
params.DistStdRad = 5;
params.MinDistLocVar = 9;
/endf

@fxm_mFilterObjSizeLbl [M2] > [M3];
params.MinArea = 150;
params.MaxArea = Inf;
/endf

/show iA > M3;
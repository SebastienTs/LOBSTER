InputFolder = './Images/RiceGrains/';
OutputFolder = './Results/Images/RiceGrains/';

@iA = '*.tif';

@fxm_mModBinWat [iA] > [M];
params.SmallHolesArea = 3;
params.DistStdRad = 3;	
params.MinDistLocVar = 5;
/endf

/show iA > M;
/keep M > tif;

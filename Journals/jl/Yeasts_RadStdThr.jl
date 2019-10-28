InputFolder = './Images/Yeasts/';
OutputFolder = './Results/Images/Yeasts/';
Rescale = 4;

@iA = '*.tif';

@fxg_mRadStdThr [iA] > [M];
params.GRad = 1;
params.RSet = [16 24 32];
params.Fracstd = 0.5;
params.SegThr = 0.6;
/endf

/show iA > M;
/keep M > tif;

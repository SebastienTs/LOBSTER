InputFolder = './Images/Mitochondria/';
OutputFolder = './Results/Images/Mitochondria/';

@iA = '*.tif';

@fxg_mRadStdThr [iA] > [M];
params.GRad = 1;	
params.RSet = [2 4 6 8];
params.Fracstd = 0.55;
params.SegThr = 0.55;
/endf

/show iA > M;
/keep M > tif;

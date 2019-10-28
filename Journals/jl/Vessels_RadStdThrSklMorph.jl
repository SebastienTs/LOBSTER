InputFolder = './Images/Vessels/';
OutputFolder = './Results/Images/Vessels/';
Fill = -1;

@iA = '*.tif';

@fxg_mRadStdThr [iA] > [M];
params.GRad = 1;
params.RSet = 5;
params.Fracstd = 0.75;
params.SegThr = 0.075;
/endf

@fxm_kSklMorph [M] > [C];
params.Mode = 'thin';
params.MinBrcLgth = 3;
/endf

/show iA > C;
/keep C > tif;

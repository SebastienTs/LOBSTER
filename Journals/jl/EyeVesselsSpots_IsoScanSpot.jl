InputFolder = './Images/EyeVesselsSpots/';
OutputFolder = './Results/Images/EyeVesselsSpotsSpots/';
Fill = 0;
Dilate = 4;

@iA = '*.tif';

@fxg_mIsoScanSpot [iA] > [M];
params.GRad = 0.75;
params.Len = 9;
params.Tol = 30;
params.NAngles = 9;
params.MinUnif = 0.6;
/endf

/show iA > M;
/keep M > tif;
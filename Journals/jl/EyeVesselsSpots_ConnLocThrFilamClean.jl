InputFolder = './Images/EyeVesselsSpots/';
OutputFolder = './Results/Images/EyeVesselsSpotsFilam2/';
Lbl = 1;
Fill = -1;

@iA = '*.tif';

@fxg_kConnLocThrFilam [iA] > [M1];
params.GRad = 1;
params.LocMeanRad = 9;
params.LocMeanThr1 = 1.7;
params.LocMeanThr2 = 1.35;
params.MinSeedArea = 5;
/endf

@fxkg_kSklClean [M1, iA] > [M2];
params.MinBrchLgth = 5;
params.SearchRad = 9;
params.MinMean = 30;
params.MinArea = 25;
/endf

/show iA > M2;
/keep M2 > tif;
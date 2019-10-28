InputFolder = './Images/EyeVesselsSpots/';
OutputFolder = './Results/Images/EyeVesselsSpotsFilam/';
Lbl = 1;
Fill = -1;

@iA = '*.tif';		% Image filter

@fxg_kIsoScanFilam [iA] > [M1];
params.GRad = 1;
params.NAngles = 8;
params.Len = 7;
params.Contrast1 = 25;						  
params.Contrast2 = 12;						
params.Anis = 0.35;
params.MaxHoleArea = 3;						
/endf

@fxkg_kSklClean [M1, iA] > [M2];
params.MinBrchLgth = 3;
params.SearchRad = 9;
params.MinMean = 30;
params.MinArea = 25;
/endf

/show iA > M2;
/keep M2 > tif;
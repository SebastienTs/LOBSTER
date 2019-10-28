InputFolder = './Images/VesselsSpots/';
OutputFolder = './Results/Images/VesselsSpots/Vessels/';
Fill = -1;
ExportDist = 1; 

@iA = '*.tif';

@fxm_mFilterObjSize [iA] > [M];
params.MinArea = 2;
params.MaxArea = Inf;
/endf

/show iA > M;
/keep M > tif;
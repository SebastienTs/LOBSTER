InputFolder = './Images/VesselsSpots/';
OutputFolder = './Results/Images/VesselsSpots/Spots/';
Fill = -1;

@iA = '*.tif';

@fxm_mFilterObjSize [iA] > [M];
params.MinArea = 1;
params.MaxArea = 1;
/endf

/show iA > M;
/keep M > tif;
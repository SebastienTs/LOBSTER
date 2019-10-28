InputFolder = './Images/CrazyCells/';
OutputFolder = './Results/Images/CrazyCells/';

@iA = '*_C00*.tif';		% Image filter
@iS = '*_C01*.tif';		% Image seeds filter

@fxgs_lSeededPolarGeod [iA, iS] > [L];
params.ThDiv = 180;
params.ObjRad = 35;
params.MinArea = 175;
params.Method = 'simple';
/endf

/show iA > iS;
/show iA > L;
/keep L > tif;
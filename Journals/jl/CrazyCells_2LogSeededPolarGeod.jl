InputFolder = './Images/CrazyCells/';
OutputFolder = './Results/Images/CrazyCells/';
Lbl = 1;

@iA = '*_C00*.tif';

@fxg_sLoGLocMax [iA] > [S];
params.GRad = 15;
params.LocalMaxBox = [9 9];
params.ThrLocalMax = 0.025;
params.MinLocThr = 0;
/endf

@fxgs_lSeededPolarGeod [iA, S] > [L];
params.ThDiv = 180;
params.ObjRad = 35;
params.MinArea = 175;
params.Method = 'simple';
/endf

/show iA > S;
/show iA > L;
/keep L > tif;
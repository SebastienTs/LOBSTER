InputFolder = './Images/CellsSpots/';
OutputFolder = './Results/Images/CellsSpots/';
Lbl = 1;
@iA = '*.tif';

@fxg_sLoGLocMax [iA] > [M];
params.GRad = 2;
params.LocalMaxBox = [5 5];
params.ThrLocalMax = 2;
params.MinLocThr = 0;
/endf

@fxs_lMeanShift3D [M] > [S L];
params.Bandwidth = 40;
params.MinPts = 3;
/endf

/show iA > L;
/keep L > tif;
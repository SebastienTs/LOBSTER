InputFolder = './Images/Fibers/';
OutputFolder = './Results/Images/Fibers/';
Fill = -1;

@iA = '*.tif';		% Image filter

@fxg_gmLocOrientation[iA] > [O, M];
params.GRad = 1;
params.CellSize = 8;
params.MinMag = 75;
params.Vecs = 2;
/endf

/show iA > M;
/keep O > tif;
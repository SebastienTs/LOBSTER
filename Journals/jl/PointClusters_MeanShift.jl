InputFolder = './Images/PointClusters/';
OutputFolder = './Results/Images/PointClusters/';
Rescale = 1;
Dilate = 5;
Fill = 1;

@iA = '*.tif';

@fxs_lMeanShift3D [iA] > [S L];
params.Bandwidth = 75;
params.MinPts = 0;
/endf

/show iA > S;
/keep L > tif;
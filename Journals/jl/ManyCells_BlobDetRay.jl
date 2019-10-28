InputFolder = './Images/ManyCells/';
OutputFolder = './Results/Images/ManyCells/';
Fill = -1;

@iA = '*.tif';		% Image filter

@fxg_sBlobDetRay [iA] > [S];
params.Scale = 0.4;
params.Thr = 30;
params.NAngles = 18;
params.L = 9;
params.Step = 1;
params.Fraction = 0.25;
params.NoiseTol = 0.1;
/endf

/show iA > S;
/keep S > tif;
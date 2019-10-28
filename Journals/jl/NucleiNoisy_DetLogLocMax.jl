InputFolder = './Images/NucleiNoisy/';
OutputFolder = './Results/Images/NucleiNoisy/';
Rescale = 1;

@iA = '*.tif';

@fxg_sLoGLocMax [iA] > [S];
params.GRad = 7;
params.LocalMaxBox = [9 9];
params.ThrLocalMax = 0.3;
params.MinLocThr = 0.2;
/endf

/show iA > S;
/keep S > tif;
InputFolder = './Images/NucleiCluster/';
OutputFolder = './Results/Images/NucleiCluster/';
Rescale = 2;
Fill = -1;

@iA = '*.tif';

@fxg_sBlobDetPatch [iA] > [S];
params.GaussianGradRad = 1.5;			
params.GaussianVoteRad = 6;				
params.GradMagThr = 0.2;				
params.Rmin = 7;
params.Rmax = 11;
params.NAngles = 24;
params.Delta = [pi/8 pi/16];
params.DScale = [1 1];
params.Thr = 0.5;
/endf

/show iA > S;
/keep S > tif;
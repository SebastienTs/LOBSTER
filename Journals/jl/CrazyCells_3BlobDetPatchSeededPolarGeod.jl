InputFolder = './Images/CrazyCells/';
OutputFolder = './Results/Images/CrazyCells/';
Lbl = 1;

@iA = '*_C00*.tif';

@fxg_sBlobDetPatch [iA] > [S];
params.GaussianGradRad = 1.5;
params.GaussianVoteRad = 7;
params.GradMagThr = 0.2;
params.Rmin = 10;
params.Rmax = 20;
params.NAngles = 36;
params.Delta = [pi/4 pi/8];
params.DScale = [1];
params.Thr = 0.225;
/endf

@fxgs_lSeededPolarGeod [iA, S] > [L];
params.ThDiv = 180;
params.ObjRad = 30;
params.MinArea = 175;
params.Method = 'simple'; %rk4 %euler
/endf

/show iA > S;
/show iA > L;
/keep L > tif;
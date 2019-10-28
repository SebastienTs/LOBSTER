InputFolder = './Images/CellsPhaseContrast/';
OutputFolder = './Results/Images/CellsPhaseContrast/';
Rescale = 2;

@iA = '*.tif';

@fxg_gRestorePhaseContrast [iA] > [O];
params.w_smooth_spatio = 1;
params.w_sparsity = 0.001;
params.gamma = 0.1;
params.maxiter = 100;
params.tol = 1;
params.Rwid = 4000;		% Settings for "a" phase contrast
params.Wwid = 800;		% microscope and 1.3 um pixel size
params.MRadius = 3;		%
/endf

/show iA > ;
/show O > ;
/keep O > tif;
InputFolder = './Images/NucleiNoisy/';
OutputFolder = './Results/Images/NucleiNoisy3/';

@iA = '*.tif';		% Image filter

@fxg_gDenoiseNLM [iA] > [D, An];
params.PatchSizeHalf = 5;
params.WindowSizeHalf = 7;
params.Sigma = 0.3;
params.TopOpen = 35;
params.AddNoiseVar = 0;
/endf

/show iA >;
/show D >;
/keep D > tif;
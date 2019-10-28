InputFolder = './Images/NucleiNoisy/';
OutputFolder = './Results/Images/NucleiNoisy2/';

@iA = '*.tif';

@fxg_gDenoiseDCT [iA] > [D, An];
params.WinSize = 32;
params.Step = 2;
params.Thresh = 0.45;
params.TopOpen = 0;
params.AddNoiseVar = 0;
/endf

/show iA >;
/show D >;
/keep D > tif;
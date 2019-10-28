InputFolder = './Images/NucleiNoisy/';
OutputFolder = './Results/Images/NucleiNoisy/';

@iA = '*.tif';

@fxg_gDenoiseBM3 [iA] > [D, An];
params.AddNoiseVar = 0;
/endf

/show iA >;
/show D >;
/keep D > tif;
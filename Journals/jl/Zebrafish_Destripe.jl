InputFolder = './Images/Zebrafish/';
OutputFolder = './Results/Images/Zebrafish/';

@iA = '*.tif';

@fxg_gDestripe [iA] > [D];
params.Angle = 0;
params.Scale = 0.25;
params.TopRad = 40;							
params.OpenRad = 80;
params.SharpAmount = 0.25;
/endf

/show iA >;
/show D >;
/keep D > jp2;
InputFolder = './Images/TwoPureColors/';
OutputFolder = './Results/Images/TwoPureColors/';

@iA = '*.tif';

@fxc_cggSplitTwoColorStains [iA] > [iNorm iH iE];
params.Io = 240;
params.beta = 0.15;
params.alpha = 1;
/endf

/show iNorm >;
/keep iNorm > tif;
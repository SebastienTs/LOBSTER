InputFolder = './Images/EyeFundus/';
OutputFolder = './Results/Images/EyeFundusEnhance/';
Lbl = 1;
Fill = -1;

@iA = '*.tif';

@fxg_gEnhanceVessels2D [iA] > [F];
params.Scales = [1 1.5 2];
params.Spacings = [1 1];
params.Tau = 1;
params.Polarity = 0;
params.Gamma = 1;
/endf

/show iA>;
/show F >;
/%keep F > tif;
InputFolder = './Images/NucleiCytoo/';
OutputFolder = './Results/Images/NucleiCytoo/';

@iA = '*C00*.tif';

@fxg_mBlockOtsuThr [iA] > [M];
params.OpenRad = 2;
params.TopHatRad = 50;
params.BlckSize = 64;
params.BlckShft = 8;
params.MinRatio = 5;
params.Lvl = 0.5;
params.Bck = 0.1875;
params.AbsBck = 0.1;
/endf

/show iA > M;
/keep M > tif;
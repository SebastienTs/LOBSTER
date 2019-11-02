InputFolder = './Images/NucleiCytoo/';
OutputFolder = './Results/Images/NucleiCytoo/';
Rescale = 1;
Fill = 1;

@iA = '*C00*.tif';		% Image filter

@fxg_sSBFRegMax [iA] > [M];
params.UnderSamp = 2;		
params.Rmin = 7;
params.Rmax = 13;
params.Rstep = 1;
params.Band = 1;
params.lambdaMag = 1;
params.LocMaxThr = 4;
params.BckLvl = 20;
params.Sym = 1;
/endf

/show iA > M;
/keep M > tif;
InputFolder = './Images/CellsCyto/';
OutputFolder = './Results/Images/CellsCyto/';
Lbl = 1;

@iA = '*_C0000*.tif';		% Image filter
@iS = '*_C0001*.tif';		% Image seeds filter

@fxgs_lSeededPropagate [iA, iS] > [L, P];
params.Thr = 0;
params.Power = 0.5;
params.AnalyzeCC = 0;
/endf

%show iA > iS;
/show iA > L;
/keep L > tif;
InputFolder = './Images/CT/';
OutputFolder = './Results/Images/CT/';

@iA = '*_C0000*.tif';		% Image filter
@iS = '*_C0001*.tif';		% Image seeds filter

@fxgs_lSeededRW [iA, iS] > [L, P];
params.Beta = 90;
/endf

/show iA > L;
/keep L > tif;
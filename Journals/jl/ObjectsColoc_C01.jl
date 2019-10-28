InputFolder = './Images/ObjColoc/';
OutputFolder = './Results/Images/ObjColoc_C01/';

@iA = '*_C01*.tif';

@fxm_mFilterObjSize [iA] > [M];
params.MinArea = 0;
params.MaxArea = Inf;
/endf

/show iA > M;
/keep M > tif;
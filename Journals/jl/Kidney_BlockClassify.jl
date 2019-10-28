InputFolder = './Images/Kidney/';
OutputFolder = './Results/Images/Kidney/';
Fill = 1;
Dilate = 5;
Lbl = 1;

@iA = '*_C0000*.tif';		% Image filter
@iS = '*_C0001*.tif';		% Image annotations filter

@fxg_lBlockClassify[iA, iS] > [S];
params.BlckSize = 32;
params.Feat = 'mnstdbifs';
params.ClassifierType = 'RF';
params.ClassifierFile = './Classifiers/ClassifierKidney_mnstdbifsRF.mat';
params.ExportAnnotations = './Classifiers/Annotation_Kidney.tif';
/endf

/show iA > S;
/keep S > tif;
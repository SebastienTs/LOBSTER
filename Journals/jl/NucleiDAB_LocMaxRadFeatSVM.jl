InputFolder = './Images/NucleiDAB/';
OutputFolder = './Results/Images/NucleiDAB3/';
Rescale = 1;
Dilate = 2;
Fill = 1;
Lbl = 1;

@iA = '*_C0000*.tif';		% Image filter
@iL = '*_C0001*.tif';		% Image annotations filter

@fxg_sLocMax [iA] > [iS];
params.GRad = 7;
params.LocalMaxBox = [5 5];
params.ThrLocalMax = 127;
params.Polarity = -1;
/endf

@fxgs_lPatchClassify [iA, iS, iL] > [C];
params.FeatType = 'RadFeat';
params.ScanRad = 21;
params.ScanStep = 1;
params.NAngles = 8;
params.ClassifierType = 'SVM';
params.ClassifierFile = './Classifiers/ClassifierDABNuc_RadSVM.mat';
params.ExportAnnotations = './Classifiers/Annotation_DABNuc_RadSVM.tif';
/endf

/show iA > C;
/keep C > tif;
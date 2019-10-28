InputFolder = './Images/NucleiDAB/';
OutputFolder = './Results/Images/NucleiDAB/';
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
params.BoxRad = 35;
params.Expand = 1;
params.FeatType = 'Deep';
params.ClassifierFile = './Classifiers/ClassifierDABNuc_deepnet.mat';
params.ExportAnnotations = './Classifiers/Annotation_DABNuc_deepnet.tif';
/endf

/show iA > C;
/keep C > tif;
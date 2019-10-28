InputFolder = './Images/NucleiDAB/';
OutputFolder = './Results/Images/NucleiDAB2/';
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
params.FeatType = 'HoG';			
params.BoxSize = 7;					
params.Sub = 5;
params.NumBins = 8;
params.ClassifierType = 'RF';
params.ClassifierFile = './Classifiers/ClassifierDABNuc_HoGRF.mat';
params.ExportAnnotations = './Classifiers/Annotation_DABNuc_HoG.tif';
/endf

/show iA > C;
/keep C > tif;
InputFolder = './Images/CellJunctions/';
OutputFolder = './Results/Images/CellJunctions/';
Fill = -1;
Rescale = 1;

@iA = '*.tif';

@fxg_gRestoreFilam [iA] > [I];
params.FrangiScale = [1.5 2.5];
params.Rmin = 0;
params.Rmax = 13;					
params.GaussianVoteRad = 3;
params.ThrVote = [0.05 0.05];
params.NAngles = 24;
params.Delta = [pi/4 pi/8];
params.DScale = [1 0.5];
params.PowerLaw = 0.5;

/endf

/show iA>;
/show I>;
/keep I > tif;
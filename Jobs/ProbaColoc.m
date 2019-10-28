NucFolder = './Results/Images/TestColoc/Nuc';
Spt1Folder = './Results/Images/TestColoc/Spt1';
Spt2Folder = './Results/Images/TestColoc/Spt2';

%% IRMA colocalization analysis 'Spst' expects region masks (level 100)
%% and spots at level >=200. 
%% Here Transfer is used to copy nuclei masks to seed masks
Transfer(NucFolder,Spt1Folder);
Transfer(NucFolder,Spt2Folder);

IRMA(Spt1Folder, '.', 'Spst', 2, {1, 3, ''}, Spt2Folder);
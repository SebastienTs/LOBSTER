RootInput = 'E:/LOBSTER/Images/HeLaMCF10AMovie/';

[RootInputFolders, NFolders] = GetFolders(RootInput);
for i=1:NFolders
    CurrentInputFolder = RootInputFolders{i};  
    [InputFolder1 MaskFolder1] = GENI('HeLaMovie_LapThrBinWatTiles.jl',CurrentInputFolder,-1);
    [InputFolder2 MaskFolder2] = GENI('HeLaMCF10A_TrackOvl.jlm',MaskFolder1,-1);
    ReportFolderFolder = IRMA(MaskFolder2,-1,'Trks',2);
end
[InputFolder1 MaskFolder1] = GENI('HeLaMovie_LapThrBinWatTiles.jl');
[InputFolder2 MaskFolder2] = GENI('HeLaMCF10A_TrackOvl.jlm');
ReportFolder = IRMA( MaskFolder2, '.', 'Trks',  2, {1, '', '.'} );
[InputFolder1 MaskFolder1] = GENI('VesselsSpots_vesseg.jl');
[InputFolder2 MaskFolder2] = GENI('VesselsSpots_sptdet.jl');
ReportFolder = IRMA(MaskFolder2,'.','Objs',2,1, MaskFolder1, '*dst*');
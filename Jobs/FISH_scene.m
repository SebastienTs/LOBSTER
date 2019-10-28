[InputFolder1 MaskFolder1] = GENI('FISH_nucseg.jl');
[InputFolder2 MaskFolder2] = GENI('FISH_sptdet.jl');
ReportFolder1 = IRMA(MaskFolder1,'.','Objs',2,1, MaskFolder2);
ReportFolder2 = IRMA(MaskFolder2,'.','Spts',2);
JOSE(InputFolder1,'*_C00*',InputFolder2,'*_C01*',ReportFolder1,'Objs',ReportFolder2,'Spts',ReportFolder1, 'IJ', 100, '');
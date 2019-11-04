[InputFolder MaskFolder] = GENI('NucleiCytoo_GradWaterTilesMerge.jl');
ReportFolder = IRMA(MaskFolder,'.','Objs',2, 1,InputFolder,'*C01*.tif');
JOSE(InputFolder,'*_C00*',ReportFolder,'Objs',ReportFolder, 'IJ', 100, '');
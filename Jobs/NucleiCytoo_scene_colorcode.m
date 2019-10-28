[InputFolder MaskFolder] = GENI('NucleiCytoo_GradWaterTilesMerge.jl');
ReportFolder = IRMA(MaskFolder,'.','Objs',2, 1,InputFolder,'*C01*.tif');
ColorCode = '(getResult("Area",ObjIdx) >= 250)+(getResult("Area",ObjIdx) >= 350)';
JOSE(InputFolder,'*_C00*',ReportFolder,'Objs',ReportFolder, 'IJ', 100, ColorCode);
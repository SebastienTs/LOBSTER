[InputFolder, MaskFolder1] = GENI('FISH_nucseg.jl');
[~, MaskFolder2] = GENI('FISH_sptdet.jl');
[~, MaskFolder3] = GENI('FISH_sptdet.jl','','./Results/Images/FISH_spt2/',{'*_C01*.tif','*_C02*.tif'});
ReportFolder1 = IRMA(MaskFolder1,'.','Objs',2,1, {MaskFolder2,MaskFolder3},'*_C01*','*_C02*');
ReportFolder2 = IRMA(MaskFolder2,'.','Spts',2);
ReportFolder3 = IRMA(MaskFolder3,'.','Spts',2);
JOSE(InputFolder,'*_C00*',InputFolder,'*_C01*',InputFolder,'*_C02*',ReportFolder1,'Objs',ReportFolder2,'Spts',ReportFolder3,'Spts',ReportFolder1,'IJ',100,'');
[InputFolder MaskFolder] = GENI('TissuePilar3D_NucDet.jls');
ReportFolder = IRMA(MaskFolder,'.','Spts',[3 3 1],1,InputFolder);
JOSE(InputFolder,'*',ReportFolder,'Spts',ReportFolder,'IJ',300,'');
[InputFolder MaskFolder] = GENI('BloodVessels3D_LocThr3DSkl3D.jls');
ReportFolder = IRMA(MaskFolder,'.','Skls',3,3);
JOSE(InputFolder,'*',MaskFolder,'*',ReportFolder,'IJ',100,'');
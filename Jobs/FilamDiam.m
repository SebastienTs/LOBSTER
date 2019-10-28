[InputFolder MaskFolder1] = GENI('BloodVessels3D_LocThr3D_diam.jls');
[InputFolder MaskFolder2] = GENI('BloodVessels3D_LocThr3DSkl3D.jls');
ReportFolder = IRMA(MaskFolder2,'.','Skls',3,3,MaskFolder1,'*dst*');
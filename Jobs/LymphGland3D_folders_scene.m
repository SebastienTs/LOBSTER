[InputFolder MaskFolder] = GENI('./Journals/jls/extra/LymphGland3D_DetLog3DLocMax3D_folders.jls');
ReportFolder = IRMA(MaskFolder,'.','Spts',3,1,InputFolder,'*');
JOSE(InputFolder,'*',ReportFolder,'Spts',ReportFolder,'IJ',110,'');
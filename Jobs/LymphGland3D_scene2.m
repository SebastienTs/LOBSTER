[InputFolder MaskFolder] = GENI('LymphGland3D_DetLog3DLocMax3D.jls');
ReportFolder = IRMA(MaskFolder,'.','Spts',3);
JOSE(ReportFolder,'Spts',InputFolder,'CellInsight','','');
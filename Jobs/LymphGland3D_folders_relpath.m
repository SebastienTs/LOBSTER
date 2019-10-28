InputFolder = 'E:/LOBSTER/Images/LymphGland3D_folders/';

[InputFolder MaskFolder] = GENI('./Journals/jls/extra/LymphGland3D_DetLog3DLocMax3D_folders.jls',InputFolder,1);
ReportFolder = IRMA(MaskFolder,1,'Spts',3,1,InputFolder,'*');
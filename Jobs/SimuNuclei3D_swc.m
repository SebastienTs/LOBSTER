[InputFolder1 MaskFolder1] = GENI('SimuNuclei3D_LogLocMaxLocThrPropagate3D.jls');
[InputFolder2 MaskFolder2] = GENI('SimuNuclei3D_TrackOvl.jlm');
ReportFolder = IRMA( MaskFolder2, '.', 'Trks',  3, {2, '', '.'} );
[~, MaskFolder1] = GENI('FISH_nucseg.jl');
[~, MaskFolder2] = GENI('FISH_sptdet.jl','','./Results/Images/FISH_spt/');
[~, MaskFolder3] = GENI('FISH_sptdet.jl','','./Results/Images/FISH_spt2/',{'*_C01*.tif','*_C02*.tif'});
ReportFolder1 = IRMA(MaskFolder1,'.','Objs',2,1, {MaskFolder2,MaskFolder3},'*_C01*','*_C02*');





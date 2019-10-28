[InputFolder1 MaskFolder1] = GENI('FISH_nucseg.jl');
[InputFolder2 MaskFolder2] = GENI('FISH_sptdet.jl');
IRMA(MaskFolder1,'.','Objs',2,1, MaskFolder2);
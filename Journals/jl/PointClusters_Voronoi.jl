InputFolder = './Images/PointClusters/';
OutputFolder = './Results/Images/Voronoi/';
Rescale = 1;

@iA = '*.tif';

@fxs_gVoronoi3D [iA] > [G];
params.ovs = 1;
/endf

/show iA >;
/show G >;
/keep G > tif;
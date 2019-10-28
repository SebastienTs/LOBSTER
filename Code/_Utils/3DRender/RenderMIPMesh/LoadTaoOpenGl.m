warning off;

% Add OpenGL TAO  Assemblies
functionname='LoadTaoOpenGl.m';
functiondir=which(functionname);
functiondir=functiondir(1:end-length(functionname));
NET.addAssembly([functiondir '../TaoLight/Tao.OpenGl.dll']);
NET.addAssembly([functiondir '../TaoLight/Tao.Platform.Windows.dll']);

% Add paths
addpath([functiondir '/Functions']);
clc;
delete(gcf);
lobsterver = '1.0';

%% Force path to LOBSTER root on start of JENI / REX
str = which('init');
indxs = find((str=='/')|(str=='\'));
cd(str(1:indxs(end)));

%% Check folders
if ~exist('./Code','dir')
    error('Code folder does not exist in ROOT_LOBSTER');
end
if ~exist('./Journals','dir')
    error('Journals folder does not exist in ROOT_LOBSTER');
end
if ~exist('./Images','dir')
    warning(strcat(['Images folder does not exist in ROOT_LOBSTER, sample journals will not work.' char(10) 'Download archive <a href="https://drive.google.com/uc?export=download&id=18A0sm-69TTEl-19DAprqiLHmO-0nBkg4">here</a>' ' and unzip to an empty folder called Images in LOBSTER_ROOT']));
end
if ~exist('./Results','dir')
    warning(strcat(['Results folder does not exist in ROOT_LOBSTER, sample journals will not work.' char(10) 'Download archive <a href="https://drive.google.com/uc?export=download&id=1GiJd-JfBvOHJcm_WOB1_gAvMuRAZzOy3">here</a>' ' and unzip to an empty folder called Results in LOBSTER_ROOT']));
end

%% List content
numfx = numel(dir(strcat('./Code/_Functions/*.m')));
numfi = numel(dir(strcat('./Images/')))-2;
numjl = numel(dir(strcat('./Journals/jl/*.jl')));
numjls = numel(dir(strcat('./Journals/jls/*.jls')));
numjlm = numel(dir(strcat('./Journals/jlm/*.jlm')));
numjb = numel(dir(strcat('./Jobs/*.m')));
disp(sprintf('LOBSTER version %s',lobsterver));
disp(sprintf('Found %i functions',numfx));
disp(sprintf('Found %i journals',numjl+numjls+numjlm));
disp(sprintf('Found %i jobs',numjb));
disp(sprintf('Found %i datasets',numfi));
if NET.isNETSupported
    disp('Found compatible .NET version, OPENGL 3D renderer should work!');
else
    disp('No compatible .NET version found, 3D renderer will not work (only supported under Windows)');
end

%% Add current path and code subfolders to MATLAB path
addpath(pwd);
cd 'Code'
addpath(genpath(pwd));
cd ..;
cd 'Jobs'
addpath(genpath(pwd));   
cd ..;
cd ..;
cd ..;
cd(str(1:indxs(end)));

%% Display message
disp('LOBSTER successfully initialized!');

%% Display help
disp('To get started, follow <a href="https://sebastients.github.io">LOBSTER Portal and Documentation</a>')
disp('Type >> LOBSTER to launch the Panel or >> JENI to run a journal');
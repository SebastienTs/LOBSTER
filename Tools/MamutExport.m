%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% This script converts LOBSTER CSV results from tracked objects into
%% Trackmate/Mamut file format. Mamut files can also be imported in Mastodon.
%%
%% Select BigDataViewer XML image file (same image as used for tracking)
%% Select LOBSTER report folder (tracking reports CSV files)
%% Set size of the spots to display
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;
close all;
clc;

%% File/folder selection
[ImageXML,pathXML] = uigetfile('*.xml');
RepFolder = uigetdir('','Select LOBSTER report folder');
ExportFileName = [pathXML '/' ImageXML(1:end-4) '_mamut.xml'];

%% Set spot size
prompt = {'Spot size:'};
dlgtitle = 'Input spot size';
dims = [1 32];
definput = {'7'};
answer = inputdlg(prompt,dlgtitle,dims,definput);
RadSpot = str2num(answer{1});

%% Parse image size and voxel size
text = fileread([pathXML '/' ImageXML]);
idx = strfind(text, '<size>');
idx2 = strfind(text, '</size>');
ImageSize = str2num(text(idx(1)+6:idx2(1)-1));
VoxelSize = str2num(text(idx(2)+6:idx2(2)-1));
if ImageSize(3)==1
    Dim = 2;
    XSize = VoxelSize(1);
    YSize = VoxelSize(2);
    ZSize = 1;
else
    Dim = 3;
    XSize = VoxelSize(1);
    YSize = VoxelSize(2);
    ZSize = VoxelSize(3);
end

%% Parse report files and find filename template from _Area CSV 
files = dir([RepFolder '/*.csv']);
if isempty(files)
    error('No CSV files in report folder');
end
FileName = files(1).name;
idx = strfind(FileName,'_Area.csv');
if isempty(idx)
    error('No _Area CSV file in report folder');
end
BaseName = FileName(1:idx-1);

%% Dump LOBSTER results CSV files to arrays
warning('OFF', 'MATLAB:table:ModifiedVarnames');
warning('OFF', 'MATLAB:table:ModifiedAndSavedVarnames');
if exist([RepFolder '\zzz_DivLog.csv'],'file')
    D = table2array(readtable([RepFolder '\zzz_DivLog.csv']));
else
    D = [0 0 0];
end
A = table2array(readtable([RepFolder '\' BaseName '_Area.csv']));
X = table2array(readtable([RepFolder '\' BaseName '_CMx.csv']));
Y = table2array(readtable([RepFolder '\' BaseName '_CMy.csv']));
NTracks = size(X,2);
if Dim == 3
    Z = table2array(readtable([RepFolder '\' BaseName '_CMz.csv']));
else
    Z = ones(size(X));
end

%% Identify spots (objects with nonzero area) + retrieve associated track ID / time points
SpotsIndx = find(A>0);
[PosT, PosID] = ind2sub(size(X),SpotsIndx);
I = zeros(size(X));
I(SpotsIndx) = 1:numel(SpotsIndx);

%% Retrieve spots X, Y, Z information
PosX = X(SpotsIndx)*XSize;
PosY = Y(SpotsIndx)*YSize;
PosZ = Z(SpotsIndx)*ZSize;

%% Create tracks
Tracks = '';
for trk = 1:NTracks
    CurTrkTIndx = find(A(:,trk)>0);
    % Link track to parent track, in case it has one
    idx = find(D(:,3)==trk);
    if ~isempty(idx)
        Tracks{trk} = [I(D(idx,1),D(idx,2));I(CurTrkTIndx,trk)];
    else
        Tracks{trk} = I(CurTrkTIndx,trk);
    end
end

%% Mamut XML header %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
docNode = com.mathworks.xml.XMLUtils.createDocument('TrackMate');
TrackMate = docNode.getDocumentElement;
TrackMate.setAttribute('version','5.2.0');
Model = docNode.createElement('Model');
Model.setAttribute('spatialunits','pixels');
Model.setAttribute('timeunits','frames');
TrackMate.appendChild(Model);
Features = docNode.createElement('FeatureDeclarations');
Model.appendChild(Features);
SpotFeatures = docNode.createElement('SpotFeatures');
Features.appendChild(SpotFeatures);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','QUALITY');
Feature.setAttribute('name','Quality');
Feature.setAttribute('shortname','Quality');
Feature.setAttribute('dimension','QUALITY');
Feature.setAttribute('isint','false');
SpotFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','POSITION_X');
Feature.setAttribute('name','X');
Feature.setAttribute('shortname','X');
Feature.setAttribute('dimension','POSITION');
Feature.setAttribute('isint','false');
SpotFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','POSITION_Y');
Feature.setAttribute('name','Y');
Feature.setAttribute('shortname','Y');
Feature.setAttribute('dimension','POSITION');
Feature.setAttribute('isint','false');
SpotFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','POSITION_Z');
Feature.setAttribute('name','Z');
Feature.setAttribute('shortname','Z');
Feature.setAttribute('dimension','POSITION');
Feature.setAttribute('isint','false');
SpotFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','POSITION_T');
Feature.setAttribute('name','T');
Feature.setAttribute('shortname','T');
Feature.setAttribute('dimension','TIME');
Feature.setAttribute('isint','false');
SpotFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','FRAME');
Feature.setAttribute('name','Frame');
Feature.setAttribute('shortname','Frame');
Feature.setAttribute('dimension','NONE');
Feature.setAttribute('isint','true');
SpotFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','RADIUS');
Feature.setAttribute('name','Radius');
Feature.setAttribute('shortname','R');
Feature.setAttribute('dimension','LENGTH');
Feature.setAttribute('isint','false');
SpotFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','VISIBILITY');
Feature.setAttribute('name','Visibility');
Feature.setAttribute('shortname','Visibility');
Feature.setAttribute('dimension','NONE');
Feature.setAttribute('isint','true');
SpotFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','SOURCE_ID');
Feature.setAttribute('name','Source_ID');
Feature.setAttribute('shortname','Source');
Feature.setAttribute('dimension','NONE');
Feature.setAttribute('isint','true');
SpotFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','CELL_DIVISION_TIME');
Feature.setAttribute('name','Cell division time');
Feature.setAttribute('shortname','Cell div. time');
Feature.setAttribute('dimension','TIME');
Feature.setAttribute('isint','false');
SpotFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','MANUAL_COLOR');
Feature.setAttribute('name','Manual spot color');
Feature.setAttribute('shortname','Spot color');
Feature.setAttribute('dimension','NONE');
Feature.setAttribute('isint','true');
SpotFeatures.appendChild(Feature);
EdgeFeatures = docNode.createElement('EdgeFeatures');
Features.appendChild(EdgeFeatures);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','SPOT_SOURCE_ID');
Feature.setAttribute('name','Source spot ID');
Feature.setAttribute('shortname','Source ID');
Feature.setAttribute('dimension','NONE');
Feature.setAttribute('isint','true');
EdgeFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','SPOT_TARGET_ID');
Feature.setAttribute('name','Target spot ID');
Feature.setAttribute('shortname','Target ID');
Feature.setAttribute('dimension','NONE');
Feature.setAttribute('isint','true');
EdgeFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','LINK_COST');
Feature.setAttribute('name','Link cost');
Feature.setAttribute('shortname','Cost');
Feature.setAttribute('dimension','NONE');
Feature.setAttribute('isint','false');
EdgeFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','VELOCITY');
Feature.setAttribute('name','Velocity');
Feature.setAttribute('shortname','V');
Feature.setAttribute('dimension','VELOCITY');
Feature.setAttribute('isint','false');
EdgeFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','DISPLACEMENT');
Feature.setAttribute('name','Displacement');
Feature.setAttribute('shortname','D');
Feature.setAttribute('dimension','LENGTH');
Feature.setAttribute('isint','false');
EdgeFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','MANUAL_COLOR');
Feature.setAttribute('name','Manual edge color');
Feature.setAttribute('shortname','Edge color');
Feature.setAttribute('dimension','NONE');
Feature.setAttribute('isint','true');
EdgeFeatures.appendChild(Feature);

%% Spots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
AllSpots = docNode.createElement('AllSpots');
AllSpots.setAttribute('nspots',num2str(numel(PosX)));
Model.appendChild(AllSpots);
for f = 1:max(PosT)
    SpotsInFrame = docNode.createElement('SpotsInFrame');
    SpotsInFrame.setAttribute('frame',num2str(f-1));
    AllSpots.appendChild(SpotsInFrame);   
    indx = find(PosT == f);
    for n = 1:numel(indx)
        Spot = docNode.createElement('Spot');
        Spot.setAttribute('ID',num2str(indx(n)));
        Spot.setAttribute('name',['ID' num2str(indx(n))]);
        Spot.setAttribute('VISIBILITY','1');
        Spot.setAttribute('RADIUS',num2str(RadSpot));
        Spot.setAttribute('QUALITY','1.0');
        Spot.setAttribute('SOURCE_ID',num2str(indx(n)));
        Spot.setAttribute('POSITION_T',num2str((f-1),'%f'));
        Spot.setAttribute('POSITION_X',num2str(PosX(indx(n)),'%f'));
        Spot.setAttribute('POSITION_Y',num2str(PosY(indx(n)),'%f'));
        Spot.setAttribute('FRAME',num2str(num2str(f-1)));
        Spot.setAttribute('POSITION_Z',num2str(PosZ(indx(n)),'%f'));
        SpotsInFrame.appendChild(Spot);
    end
end

%% Track Features Section%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TrackFeatures = docNode.createElement('TrackFeatures');
Features.appendChild(TrackFeatures);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','TRACK_INDEX');
Feature.setAttribute('name','Track index');
Feature.setAttribute('shortname','Index');
Feature.setAttribute('dimension','NONE');
Feature.setAttribute('isint','true');
TrackFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','TRACK_ID');
Feature.setAttribute('name','Track ID');
Feature.setAttribute('shortname','ID');
Feature.setAttribute('dimension','NONE');
Feature.setAttribute('isint','true');
TrackFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','TRACK_DURATION');
Feature.setAttribute('name','Duration of track');
Feature.setAttribute('shortname','Duration');
Feature.setAttribute('dimension','TIME');
Feature.setAttribute('isint','false');
TrackFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','TRACK_START');
Feature.setAttribute('name','Track Start');
Feature.setAttribute('shortname','T start');
Feature.setAttribute('dimension','TIME');
Feature.setAttribute('isint','false');
TrackFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','TRACK_STOP');
Feature.setAttribute('name','Track Stop');
Feature.setAttribute('shortname','T stop');
Feature.setAttribute('dimension','TIME');
Feature.setAttribute('isint','false');
TrackFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','TRACK_DISPLACEMENT');
Feature.setAttribute('name','Track displacement');
Feature.setAttribute('shortname','Displacement');
Feature.setAttribute('dimension','LENGTH');
Feature.setAttribute('isint','false');
TrackFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','NUMBER_SPOTS');
Feature.setAttribute('name','Number of spots in track');
Feature.setAttribute('shortname','N spots');
Feature.setAttribute('dimension','NONE');
Feature.setAttribute('isint','true');
TrackFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','NUMBER_GAPS');
Feature.setAttribute('name','Number of gaps');
Feature.setAttribute('shortname','Gaps');
Feature.setAttribute('dimension','NONE');
Feature.setAttribute('isint','true');
TrackFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','LONGEST_GAPS');
Feature.setAttribute('name','Longest gap');
Feature.setAttribute('shortname','Longest gap');
Feature.setAttribute('dimension','NONE');
Feature.setAttribute('isint','true');
TrackFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','NUMBER_SPLITS');
Feature.setAttribute('name','Number of split events');
Feature.setAttribute('shortname','Splits');
Feature.setAttribute('dimension','NONE');
Feature.setAttribute('isint','true');
TrackFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','NUMBER_MERGES');
Feature.setAttribute('name','Number of merge events');
Feature.setAttribute('shortname','Merges');
Feature.setAttribute('dimension','NONE');
Feature.setAttribute('isint','true');
TrackFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','NUMBER_COMPLEX');
Feature.setAttribute('name','Complex points');
Feature.setAttribute('shortname','Complex');
Feature.setAttribute('dimension','NONE');
Feature.setAttribute('isint','true');
TrackFeatures.appendChild(Feature);
Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','DIVISION_TIME_MEAN');
Feature.setAttribute('name','Mean cell division time');
Feature.setAttribute('shortname','Mean div. time');
Feature.setAttribute('dimension','TIME');
Feature.setAttribute('isint','false');
TrackFeatures.appendChild(Feature);Feature = docNode.createElement('Feature');
Feature.setAttribute('feature','DIVISION_TIME_STD');
Feature.setAttribute('name','Std cell division time');
Feature.setAttribute('shortname','Std div. time');
Feature.setAttribute('dimension','TIME');
Feature.setAttribute('isint','false');
TrackFeatures.appendChild(Feature);

%% Tracks %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

AllTracks = docNode.createElement('AllTracks');
Model.appendChild(AllTracks);
for t = 1:numel(Tracks) 
    if ~isempty(Tracks)
        Track = docNode.createElement('Track');
        Track.setAttribute('name',['Track_' num2str(t)]);
        Track.setAttribute('ID',num2str(t));
        Track.setAttribute('TRACK_DURATION','0');
        Track.setAttribute('TRACK_START','0');
        Track.setAttribute('TRACK_STOP','0');
        Track.setAttribute('TRACK_DISPLACEMENT','0');
        Track.setAttribute('NUMBER_SPOTS','0');
        Track.setAttribute('NUMBER_GAPS','0');
        Track.setAttribute('LONGEST_GAP','0');
        Track.setAttribute('NUMBER_SPLITS','0');
        Track.setAttribute('NUMBER_MERGES','0');
        Track.setAttribute('NUMBER_COMPLEX','0');
        Track.setAttribute('DIVISION_TIME_MEAN','0');
        Track.setAttribute('DIVISION_TIME_STD','0');
        AllTracks.appendChild(Track);
        disp(['Track_' num2str(t) ' : ID_' num2str(Tracks{t}(1))]);
        for e = 1:numel(Tracks{t})-1
            Edge = docNode.createElement('Edge');
            Edge.setAttribute('SPOT_SOURCE_ID',num2str(Tracks{t}(e)));
            Edge.setAttribute('SPOT_TARGET_ID',num2str(Tracks{t}(e+1)));
            Edge.setAttribute('LINK_COST','0');
            Edge.setAttribute('VELOCITY','0');
            Edge.setAttribute('DISLACEMENT','0');
            Track.appendChild(Edge);
        end
    end
end

%% Filtered Tracks Section %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FilteredTracks = docNode.createElement('FilteredTracks');
Model.appendChild(FilteredTracks);
%TrackID = docNode.createElement('TrackID');
%TrackID.setAttribute('TRACK_ID','0');
%FilteredTracks.appendChild(TrackID);
Settings = docNode.createElement('Settings');
TrackMate.appendChild(Settings);
ImageData = docNode.createElement('ImageData');
ImageData.setAttribute('filename',ImageXML);
ImageData.setAttribute('folder','');
ImageData.setAttribute('width','0');
ImageData.setAttribute('height','0');
ImageData.setAttribute('slices','0');
ImageData.setAttribute('frames','0');
ImageData.setAttribute('pixelwidth','1.0');
ImageData.setAttribute('pixelheight','1.0');
ImageData.setAttribute('voxeldepth','1.0');
ImageData.setAttribute('timeinterval','1.0');
Settings.appendChild(ImageData);
InitialSpotFilter = docNode.createElement('InitialSpotFilter');
InitialSpotFilter.setAttribute('feature','QUALITY');
InitialSpotFilter.setAttribute('value','0.0');
InitialSpotFilter.setAttribute('isabove','true');
Settings.appendChild(InitialSpotFilter);
SpotFilterCollection = docNode.createElement('SpotFilterCollection');
Settings.appendChild(SpotFilterCollection);
TrackFilterCollection = docNode.createElement('TrackFilterCollection');
Settings.appendChild(TrackFilterCollection);
AnalyzerCollection = docNode.createElement('AnalyzerCollection');
Settings.appendChild(AnalyzerCollection);
SpotAnalyzers = docNode.createElement('SpotAnalyzers');
AnalyzerCollection.appendChild(SpotAnalyzers);
Analyzer = docNode.createElement('Analyzer');
Analyzer.setAttribute('key','Spot Source ID');
SpotAnalyzers.appendChild(Analyzer);
Analyzer = docNode.createElement('Analyzer');
Analyzer.setAttribute('key','CELL_DIVISION_TIME_ON_SPOTS');
SpotAnalyzers.appendChild(Analyzer);
Analyzer = docNode.createElement('Analyzer');
Analyzer.setAttribute('key','MANUAL_SPOT_COLOR_ANALYZER');
SpotAnalyzers.appendChild(Analyzer);
EdgeAnalyzers = docNode.createElement('EdgeAnalyzers');
AnalyzerCollection.appendChild(EdgeAnalyzers);
Analyzer = docNode.createElement('Analyzer');
Analyzer.setAttribute('key','Edge target');
EdgeAnalyzers.appendChild(Analyzer);
Analyzer = docNode.createElement('Analyzer');
Analyzer.setAttribute('key','Edge velocity');
EdgeAnalyzers.appendChild(Analyzer);
Analyzer = docNode.createElement('Analyzer');
Analyzer.setAttribute('key','MANUAL_EDGE_COLOR_ANALYZER');
EdgeAnalyzers.appendChild(Analyzer);
TrackAnalyzers = docNode.createElement('TrackAnalyzers');
AnalyzerCollection.appendChild(TrackAnalyzers);
Analyzer = docNode.createElement('Analyzer');
Analyzer.setAttribute('key','Track index');
TrackAnalyzers.appendChild(Analyzer);
Analyzer = docNode.createElement('Analyzer');
Analyzer.setAttribute('key','Track duration');
TrackAnalyzers.appendChild(Analyzer);
Analyzer = docNode.createElement('Analyzer');
Analyzer.setAttribute('key','Branching analyzer');
TrackAnalyzers.appendChild(Analyzer);
Analyzer = docNode.createElement('Analyzer');
Analyzer.setAttribute('key','CELL_DIVISION_TIME_ANALYZER');
TrackAnalyzers.appendChild(Analyzer);

%% Write XML file %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xmlwrite(ExportFileName,docNode);
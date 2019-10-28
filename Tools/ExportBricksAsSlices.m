BricksFolder = uigetdir(pwd,'Bricks folder');
ExportFolder = uigetdir(pwd,'Slices folder (export)');

Files = dir([BricksFolder '/*.tif']);
FirstBrickName = Files(1).name;
LastBrickName = Files(end).name;

NX = str2num(LastBrickName(6:7))+1;
NY = str2num(LastBrickName(9:10))+1;
inf = imfinfo([BricksFolder '\' FirstBrickName]);
NZ = numel(inf);
W = inf(1).Width;
H = inf(1).Height;
BitDepth = inf(1).BitDepth;
%% Size of last brick (lower right corner), used to compute image field size
inf = imfinfo([BricksFolder '\' LastBrickName]);
Wl = inf(1).Width;
Hl = inf(1).Height;
%% Display information
%disp([NX NY NZ]);
%disp([W H]);

%% Buffer for slices
switch BitDepth
    case 8
       ISlice = uint8(zeros((NY-1)*H+Hl,(NX-1)*W+Wl));
    case 16
       ISlice = uint16(zeros((NY-1)*H+Hl,(NX-1)*W+Wl));
    otherwise
       ISlice = single(zeros((NY-1)*H+Hl,(NX-1)*W+Wl)); 
end

%% Main loop
for z = 1:NZ
    disp(z);
    for x = 1:NX
        for y = 1:NY
            CurrentBrick = LastBrickName;
            CurrentBrick(6:7) = num2str(x-1,'%02i');
            CurrentBrick(9:10) = num2str(y-1,'%02i');
            I = imread([BricksFolder '\' CurrentBrick],z);
            ISlice(1+(y-1)*H:min(y*H,size(ISlice,1)),1+(x-1)*W:min(x*W,size(ISlice,2))) = I;
        end
    end
    imwrite(ISlice,[ExportFolder '\Slice_' num2str(z-1,'%04i') '.tif']);
end
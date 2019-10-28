%% Set path to .csv file from tracking results
%% Select the indices of the objects to plot (use macro OverlayTrackedObjects and read out indices from object contours)
%% Run

[Report path] = uigetfile('.csv','Select .csv file from tracking results');
answer = inputdlg('Type object indices separated by commas','Objects to plot');
ObjIndex = str2num(answer{1});

areaobj = xlsread(strcat([path Report]));

for i = 1:numel(ObjIndex)
    c = ObjIndex(i);
    figure;plot(areaobj(:,c),'b');grid on;title(strcat(['Object ' num2str(ObjIndex(i))]));
end

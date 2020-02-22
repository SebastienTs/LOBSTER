%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% This script plot measurements from a LOBSTER CSV report file for one
%% or several tracked objects.
%%
%% Set path to CSV file from tracking results
%% Select indices of objects to plot separated by commas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[Report path] = uigetfile('.csv','Select .csv file from tracking results');
answer = inputdlg('Type object indices separated by commas','Objects to plot');
ObjIndex = str2num(answer{1});

areaobj = xlsread(strcat([path Report]));

for i = 1:numel(ObjIndex)
    c = ObjIndex(i);
    figure;plot(areaobj(:,c),'b');grid on;title(strcat(['Object ' num2str(ObjIndex(i))]));
end

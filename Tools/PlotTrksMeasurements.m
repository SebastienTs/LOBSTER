%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% This script plot measurements from a LOBSTER CSV report file for one
%% or several tracked objects.
%%
%% Set path to CSV file from tracking results
%% Select indices of objects to plot separated by commas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[Report path] = uigetfile('Results/Reports/*.csv','Select .csv file from tracking results');
answer = inputdlg('Type object indices separated by commas','Objects to plot');
ObjIndex = str2num(answer{1});
color = {'r','g','b','m','c','y','k'};

meas = xlsread(strcat([path Report]));

figure;grid on;title('Object measurements');hold on;
cnt = 1;
for i = 1:numel(ObjIndex)
    c = ObjIndex(i);
    plot(meas(:,c),color{1+mod(cnt,8)});
    cnt = cnt+1;
    lgd{cnt} = num2str(c);
end
legend(lgd);

% Process a journal.
%
% [InputFolder MaskFolder] = JENI(Journal,ForceInputFolder,ForceOutputFolder);
%
% Journal can be the absolute path to a journal or a path (starting by './') relative to LOBSTER_ROOT 
% 
% - For no input argument, a journal can be selected from a file browser
% - ForceInputFolder redirects journal input folder
% - ForceOutputFolder redirects journal output folder (required if ForceInputFolder is set, but can be set to '')
% - ForceChan (ForceInputFolder and ForceOutputFolder can be both set to '' to use it)

% Sample calls:
% JENI;
% JENI('NucleiCytoo_GradWaterTilesMerge.jl');
% [InputFolder OutputFolder] = JENI('NucleiCytoo_GradWaterTilesMerge.jl');
% [InputFolder MaskFolder] = JENI('BloodVessels3D_LocThr3D.jls','E:/LOBSTER_sandbox/Images/BloodVessels3D','E:/LOBSTER_sandbox/Images/BloodVessels3D_o1');
% [InputFolder MaskFolder] = JENI('BloodVessels3D_LocThr3D.jls','E:/LOBSTER_sandbox/Images/BloodVessels3D',1);

function [InputFolder OutputFolder] = JENI(Journal,ForceInputFolder,ForceOutputFolder,ForceChan)
 
    %% Check that imtool3D is in path (init has been performed)
    if ~exist('imtool3D')
        error('LOBSTER has not been initialized yet, type >> init');
    else
        %% Force path to LOBSTER root on startup
        str = which('init');
        indxs = find((str=='/')|(str=='\'));
        cd(str(1:indxs(end)));
    end

    %% Check number of input arguments
    if nargin == 2 || nargin > 4
        error('Incorrect call to JENI: 0, 1, 3 or 4 input arguments');
    end
    
    %% Set/fix forced folder paths
    if nargin > 1
        if ~isempty(ForceInputFolder)
            ForceInputFolder = FixFolderPath(ForceInputFolder);
        end
        if isnumeric(ForceOutputFolder)
            fields = strsplit(ForceInputFolder,{'/','\'});
            if ForceOutputFolder > 0
                %% Single folder back (files in input folder)
                ForceOutputFolder = [ForceInputFolder '../' fields{end-1} '_o' num2str(ForceOutputFolder) '/'];
            else
                %% Two folder back (folders in input folder)
                ForceOutputFolder = [ForceInputFolder '../../' fields{end-2} '_o' num2str(abs(ForceOutputFolder)) '/' fields{end-1} '/'];
            end
        end
        if ~isempty(ForceInputFolder)
            ForceInputFolder = GetFullPath(ForceInputFolder);
        end
        if ~isempty(ForceOutputFolder)
            ForceOutputFolder = GetFullPath(ForceOutputFolder);
        end  
    end
    
	%% Check if JENI was called from JULI
	callers = dbstack;
    callers = {callers.name};
	JULIcall = any(strcmp(callers,'JULI'));
    
	if ~JULIcall
        %% File explorer if no journal file is passed
        if nargin == 0
            JournalPath = [pwd '/Journals/'];
            [Journal, JournalPath] = uigetfile([JournalPath '*.*'],'Select journal to run');
            Journal = [JournalPath Journal];
        end
    else
       if nargin == 0
            error('Journal file must be defined when calling from JULI');
       end
    end
    
    %% Initialization
    clearvars -except 'Journal' 'ForceInputFolder' 'ForceOutputFolder' 'ForceChan';
    close all;
    warning on;
    
    %% Parse file name
    fsep = find((Journal=='/')|(Journal=='\'));
    [filepath, name, ext] = fileparts(Journal);
    
    %% Check journal extension and set default path if journal has no path
    if isempty(fsep)
        switch ext
            case '.jl'
                Journal = [pwd '/Journals/jl/' Journal];
            case '.jls'
                Journal = [pwd '/Journals/jls/' Journal];
            case '.jlm'
                Journal = [pwd '/Journals/jlm/' Journal];
            otherwise
                error('Invalid journal extension');
        end
    end 
    
    %% Process journal
    switch ext
        case '.jl'
            if nargin <2
                [InputFolder, OutputFolder] = JENI_Images(Journal);
            else
                if nargin == 3
                    [InputFolder, OutputFolder] = JENI_Images(Journal,ForceInputFolder,ForceOutputFolder);
                else
                    [InputFolder, OutputFolder] = JENI_Images(Journal,ForceInputFolder,ForceOutputFolder,ForceChan); 
                end
            end
        case '.jls'
            if nargin <2
                [InputFolder, OutputFolder] = JENI_Stacks(Journal);
            else
                [InputFolder, OutputFolder] = JENI_Stacks(Journal,ForceInputFolder,ForceOutputFolder);
            end
        case '.jlm'
            if nargin <2
                [InputFolder, OutputFolder] = JENI_Movie(Journal);
            else
                [InputFolder, OutputFolder] = JENI_Movie(Journal,ForceInputFolder,ForceOutputFolder);
            end
        otherwise
            error('Invalid journal extension');
    end
      
end
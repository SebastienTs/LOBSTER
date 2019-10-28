% Time-lapse journal engine (should be called from JENI!!)
function [InputFolder OutputFolder] = JENI_Movie(Journal,ForceInputFolder,ForceOutputFolder)

    %% Display information to console
    disp(strcat('Journal: <a href="matlab: opentoline(''',Journal,''',1)">',Journal,'</a>-->','<a href="matlab:JENI(''',Journal,''');">Launch</a>'));
    
    global RunProjViewer;
    if ~exist('RunProj','var')
        RunProj = 0;
    end
    RunProjViewer = RunProj;
    
    %% Load journal
    jstring = fileread(Journal);

    %% Launch journal header (until first params)
    indparms = strfind(jstring, 'params.');
    eval(jstring(1:min(indparms)-1));
    
    %% Force input/output folders
    if nargin>1
        InputFolder = ForceInputFolder;
        OutputFolder = ForceOutputFolder;
    end
    InputFolder = FixFolderPath(InputFolder);
    OutputFolder = FixFolderPath(OutputFolder);
    
    %% Display folders information
    disp(strcat('Input Folder:',' <a href="matlab:winopen(''',InputFolder,''')">',InputFolder,'</a>'));
    disp(strcat('Output Folder:',' <a href="matlab:winopen(''',OutputFolder,''')">',OutputFolder,'</a>'));
    
    %% Check / create output folder
    if ~exist(OutputFolder,'dir');
        mkdir(OutputFolder);
        warning('Output folder created');
    else
        if numel(dir(OutputFolder)) > 2
            %warning('Output folder not empty!!');
            %% Empty results folder ONLY if there is 'Results' or '_o' in path (security)
            if ~isempty(strfind(OutputFolder, 'Results')) || ~isempty(strfind(OutputFolder, '_o'))
                rmdir(OutputFolder,'s');
                mkdir(OutputFolder);
            else
                error('Attempt to write results masks to a non empty folder outside a parent folder containing Results or _o');
            end
        end
    end
    
    %% Launch journal (past header)
    eval(jstring(min(indparms)-1:end));
    
    %% Set variables to default values (if not defined in journal)
    if ~exist('Shw','var')
        Shw = -1;
    end
    
    %% Force no image display if JENI was called from JULI
    callers = dbstack;
    callers = {callers.name};
    if any(strcmp(callers,'JULI')) || any(strcmp(callers,'GENI'))
        Shw = -1;
    end
    
    %% Display results
    if Shw > -1
        handle = figure;
        Files = dir(strcat([InputFolder '/*.tif']));
        inf = imfinfo(strcat([InputFolder '/' Files(1).name]));
        
        Stack = zeros(inf.Height,inf.Width,numel(Files));
        for i = 1:numel(Files)
            Stack(:,:,i) = imread(strcat([InputFolder '/' Files(i).name]));
        end
          
        Mask = single(zeros(inf.Height,inf.Width,numel(Files)));
        Files2 = dir(strcat([OutputFolder '/*.tif']));
        for i = 1:numel(Files2)
            Mask(:,:,i) = imread(strcat([OutputFolder '/' Files2(i).name]));
        end
        
        if Shw == 1
            tool = imtool3DLbl(Stack,[0 0 1 1],handle);
            setMask(tool,Mask);
        else
            tool = imtool3D(Mask,[0 0 1 1],handle);
        end
        
    end
    
end
% 2D image journal engine (should be called from JENI!!)
function [InputFolder OutputFolder] = JENI_Images(Journal,ForceInputFolder,ForceOutputFolder,ForceChan)  
    
    %% Display information to console
    disp(strcat('Journal: <a href="matlab: opentoline(''',Journal,''',1)">',Journal,'</a>-->','<a href="matlab:JENI(''',Journal,''');">Launch</a>'));
    
    %% Retrieve screen configuration (image display)
    screensize = get( groot, 'Screensize' );

    %% Load journal to string and parse it
    jstring = fileread(Journal);
    indendl = strfind(jstring, ';');
    indequa = strfind(jstring, '=');
    indopbk = strfind(jstring, '[');
    indclbk = strfind(jstring, ']');
    indsups = strfind(jstring, '>');
    indats = strfind(jstring, '@');
    indendf = strfind(jstring, '/endf');
    indvars = strfind(jstring, '@i');
    indfuncs = findstr(jstring, '@f');
    indkeeps = strfind(jstring, '/keep');
    indshows = strfind(jstring, '/show');

    %% Replace string (force channel)
    if nargin == 4
        jstring = strrep(jstring,ForceChan{1},ForceChan{2});
    end
    
    %% Eval Matlab header code (until right before first @)
    eval(jstring(1:min(indats)-1));
    
    %% Force input/output folders
    if nargin>1
        if ~isempty(ForceInputFolder)
            InputFolder = ForceInputFolder;
        end
    end
    if nargin>2
        if ~isempty(ForceOutputFolder)
            OutputFolder = ForceOutputFolder;
        end
    end
    InputFolder = FixFolderPath(InputFolder);
    OutputFolder = FixFolderPath(OutputFolder);
    
    %% Check definition and existence of input/output folders + display information to console
    if ~exist('InputFolder','var')
        error('Error: No input folder defined');
    else
        if ~exist(InputFolder,'dir')
          error('Input folder does not exist');
        end
        disp(strcat('Input Folder:',' <a href="matlab:winopen(''',InputFolder,''')">',InputFolder,'</a>'));
    end
    if ~exist('OutputFolder','var')
        error('Error: No output folder defined');
    else
        disp(strcat('Output Folder:',' <a href="matlab:winopen(''',OutputFolder,''')">',OutputFolder,'</a>'));
        if ~exist(OutputFolder,'dir')
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
    end

    %% Check that at least one image variable is defined
    if numel(indvars)==0
        error('No image asociated variable defined!');
    end

    %% Set variables to default values (if not defined in journal)
    if ~exist('Lbl','var')
        Lbl = 0;
    else
        if Lbl<0
            Lbl = 0
        end
    end
    if ~exist('Dilate','var')
        Dilate = 0;
    end
    if ~exist('Fill','var')
        Fill = 0;
    end
    if ~exist('Rescale','var')
        Rescale = 1;
    end
    if ~exist('ExportDist','var')
        ExportDist = 0;
    end
    if ~exist('OutputFolder','var')
        warning('No output folder set, results cannot be saved');
    end
    if ~exist('MinLocalFocus','var')
        LocalFocusScore = 0;
        MinLocalFocus = 0;
    end
    if ~exist('LocalFocusBlkSize','var')
        LocalFocusBlkSize = [128 128];
    end
    if ~exist('Min95Percentile','var')
        Min95Percentile = 0;
    end
    if ~exist('MaxSatPixFract','var')
        MaxSatPixFract = 1;
    end
    ShowAnnot = true;
    
    %% Find declared input images
    for i = 1:numel(indvars)
        nxtequa = indequa-indvars(i);nxtequa(nxtequa<0) = [];nxtequa = min(nxtequa);
        nxtendl = indendl-indvars(i);nxtendl(nxtendl<0) = [];nxtendl = min(nxtendl);
        ivars{i} = strtrim(jstring(indvars(i)+1:indvars(i)+nxtequa-1));
        ImgName = strtrim(jstring(indvars(i)+nxtequa+1:indvars(i)+nxtendl-1));
        % Batch processing mode: several images
        if strfind(ImgName,'*')
            Files = dir(strcat(InputFolder,ImgName(2:end-1)));
            % No image grouping
            iname{i} = [];
            for j = 1:numel(Files)
                iname{i}{j} = Files(j).name;
            end
            if i == 1 % Use first channel as reference
                NImages = numel(iname{i});
            else
                if numel(iname{i}) ~= NImages
                    warning(['Channel ' num2str(i) ' images missing, make sure this channel is dropped from index i to end to avoid channel mismatch!']);
                end
            end
            % Mode: single image
        else
            iname{i}{1} = ImgName(2:end-1);
            NImages = 1;
        end
    end

    %% Find functions
    for i = 1:numel(indfuncs)
        nxtopbk = indopbk-indfuncs(i);nxtopbk(nxtopbk<0) = [];nxtopbk = min(nxtopbk);
        nxtclbk = indclbk-indfuncs(i);nxtclbk(nxtclbk<0) = [];nxtclbk = min(nxtclbk);
        nxtsups = indsups-indfuncs(i);nxtsups(nxtsups<0) = [];nxtsups = min(nxtsups);
        nxtendf = indendf-indfuncs(i);nxtendf(nxtendf<0) = [];nxtendf = min(nxtendf);
        nxtendl = indendl-indfuncs(i);nxtendl(nxtendl<0) = [];nxtendl = min(nxtendl);
        functs{i} = strtrim(jstring(indfuncs(i)+1:indfuncs(i)+nxtopbk-1));
        fin{i} = strtrim(jstring(indfuncs(i)+nxtopbk+1:indfuncs(i)+nxtclbk-1));
        fout{i} = strtrim(jstring(indfuncs(i)+nxtsups+1:indfuncs(i)+nxtendl-1));
        fparams{i} = strtrim(jstring(indfuncs(i)+nxtendl+1:indfuncs(i)+nxtendf-1));
    end

    %% Find image exports
    for img = 1:NImages
        for i = 1:numel(indkeeps)
            nxtsups = indsups-indkeeps(i);nxtsups(nxtsups<0) = [];nxtsups = min(nxtsups);
            nxtendl = indendl-indkeeps(i);nxtendl(nxtendl<0) = [];nxtendl = min(nxtendl);
            expiname{i}{img} = strtrim(jstring(indkeeps(i)+6:indkeeps(i)+nxtsups-1));
            expformat{i} = strtrim(jstring(indkeeps(i)+nxtsups+1:indkeeps(i)+nxtendl-1));
        end
    end

	%% Check journal compatibility
	if numel(indkeeps)>1
		error('Multiple images exported, mask folder will not be compatible with IRMA');
	end
	
    %% Find all image show
    for i = 1:numel(indshows)
        nxtsups = indsups-indshows(i);nxtsups(nxtsups<0) = [];nxtsups = min(nxtsups);
        shwi{i} = strtrim(jstring(indshows(i)+6:indshows(i)+nxtsups-1));
        nxtendl = indendl-(indshows(i)+nxtsups+1);nxtendl(nxtendl<0) = [];nxtendl = min(nxtendl);
        ovli{i} = strtrim(jstring(indshows(i)+nxtsups+1:indshows(i)+nxtsups+nxtendl));
    end

    %% Display information to console
    disp('-----------------------------------------------------------------');
    disp(sprintf('Found %i image(s) / group(s)',NImages));
    disp(sprintf('Rescale: %i',Rescale));
    disp(sprintf('MinLocalFocus: %i',MinLocalFocus));
    disp(sprintf('ExportDist: %i',ExportDist));
    disp('-----------------------------------------------------------------');
    
    %% Main loop to process all images from input folder
    clear textprogressbar;
    textprogressbar('processing... '); 
    totaltimecalls = zeros(1,numel(indfuncs));
    cntskip = 0;
    for img = 1:NImages

        %% Show progess bar
        textprogressbar(round(100*img/NImages));

        %% Read input images
        for i = 1:numel(indvars)
            if img <= length(iname{i})
                ImgNameNoPath = iname{i}{img};
                ImgName = strcat(InputFolder,iname{i}{img});
                info = imfinfo(ImgName);
                isize{i} = [info.Height info.Width];
                eval(sprintf('%s = single(imread(ImgName));',ivars{i}));
            else
                eval(sprintf('%s = [];',ivars{i}));
            end
            ImageStrEnd = [0];
            if Rescale > 1
                eval(sprintf('%s = imresize(%s,[isize{i}(1)/%i isize{i}(2)/%i]);',ivars{i},ivars{i},Rescale,Rescale));
            end
            %% Check local focus score and intensity level / clipping
            if i == 1 && ((MinLocalFocus>0)||(Min95Percentile>0)||(MaxSatPixFract<1))
                eval(sprintf('ProcessImage = CheckImageQuality(%s,MinLocalFocus,LocalFocusBlkSize,Min95Percentile,MaxSatPixFract);',ivars{i}));
            else
                if i == 1
                    ProcessImage = 1;
                end
            end
        end

        if ProcessImage

            %% Call pipeline functions
            for i = 1:numel(indfuncs)
                clear params;
                params.OutputFolder = OutputFolder;
                params.ImgName = ImgNameNoPath;
                eval(fparams{i});
                tic;
                eval(sprintf('%s = %s(%s, params);',fout{i},functs{i},fin{i}));
                totaltimecalls(i) = totaltimecalls(i) + toc;
            end

            %% Upscale back to original size (no interpolation) 
            if Rescale > 1
                for i= 1:numel(indkeeps)
                    eval(sprintf('%s = imresize(%s,[isize{i}(1:2)],''nearest'');',expiname{i}{img},expiname{i}{img}));
                    eval(sprintf('%s = imresize(%s,[isize{i}(1:2)],''nearest'');',shwi{i},shwi{i}));
                end
            end

            %% Force no image display if JENI was called from JULI
            callers = dbstack;
            callers = {callers.name};
            if ~any(strcmp(callers,'JULI')) && ~any(strcmp(callers,'GENI'))
            for i = 1:numel(indshows)
                %% Show images
                handle(i) = figure;
                set(handle(i), 'Position', [8 screensize(4)-680 768 512]);
                if Lbl == 0
                    eval(sprintf('if size(%s,3)==1;tool=imtool3D(%s,[0 0 1 1],handle(i));else;imagesc(%s);end;',shwi{i},shwi{i},shwi{i}));
                end
                if Lbl == 1
                    eval(sprintf('if size(%s,3)==1;tool=imtool3DLbl(%s,[0 0 1 1],handle(i));else;imagesc(%s);end;',shwi{i},shwi{i},shwi{i}));
                end
                if isempty(ovli{i})
                    %eval(sprintf('sz = size(%s);',shwi{i}));
                    %Msk = uint8(zeros(sz));
                else
                    if Fill == -1
                        eval(sprintf('Msk = %s;',ovli{i}));
                    end
                    if Fill == 0
                        eval(sprintf('Msk = abs(imdilate(%s, strel(''disk'',Dilate+2))-imdilate(%s, strel(''disk'',Dilate)));',ovli{i},ovli{i}));
                    end
                    if Fill == 1
                        eval(sprintf('Msk = abs(imdilate(%s, strel(''disk'',Dilate)));',ovli{i},ovli{i}));
                    end
                    if isa(Msk,'uint8')
                        setMask(tool,Msk);
                    else
                        setMask(tool,single(Msk));
                    end
                    setAlpha(tool,1);
                end
                if exist('tool','var')
                    set(gcf,'Name',[shwi{i},' (',num2str(img), ') - Press x to continue, (q) interrupt, (m) toggle mask'],'NumberTitle','off');
                else
                    set(gcf,'Name',[shwi{i},' (',num2str(img), ') - Press x to continue, (q) interrupt'],'NumberTitle','off');
                end
                
                %% Automatic key stroke upon windows closing
                set(handle(i),'CloseRequestFcn',['delete(handle(' num2str(i) '));pause(0.05);robot = java.awt.Robot;robot.keyPress(java.awt.event.KeyEvent.VK_ENTER);']);
                
            end
            if numel(indshows)>0
                follow = false;
                while follow == false
                    pause;
                    if isvalid(handle(i))
                        Mode = get(gcf,'CurrentKey');
                        switch Mode
                            case 'm'
                                if exist('tool','var')
                                    %% Toggle annotations
                                    ShowAnnot = ~ShowAnnot;
                                    if ShowAnnot == false
                                        setAlpha(tool,0);
                                    else
                                        setAlpha(tool,1);
                                    end
                                end
                            case 'x'
                                follow = true;
                                for i = 1:numel(indshows)
                                    delete(handle(i));
                                end
                                close all;
                            case 'q'
                                for i = 1:numel(indshows)
                                    delete(handle(i));
                                end
                                close all;
                                error('Program terminated by user');
                            otherwise
                                disp('Press x to continue');
                        end
                    else
                        follow = true;
                    end
                end
                close all;
                pause(0.05);
            end
            
            end
            
        else

            %% Create empty images to export them
            for i = 1:numel(indkeeps)
                eval(sprintf('%s = uint16(zeros(isize{i}(1:2)));',expiname{i}{img}));
            end
            cntskip = cntskip+1;

        end

        %% Export images
        for i = 1:numel(indkeeps)
            ImgName = iname{1}{ImageStrEnd(1)+img};
            ExpImgName = strcat(OutputFolder,ImgName(1:end-4),'_',expiname{i}{img},'.',expformat{i});
            if strcmp(expformat{i},'tif')==1
                eval(sprintf('imwrite(%s,ExpImgName,expformat{i},''Compression'',''deflate'');',expiname{i}{img}));
                if ExportDist == 1
                    ExpImgDstName = strcat(OutputFolder,ImgName(1:end-4),'_',expiname{i}{img},'dst.',expformat{i});
                    eval(sprintf('imwrite(uint16(bwdist(%s>0)),ExpImgDstName,expformat{i},''Compression'',''deflate'');',expiname{i}{img}));
                end
                if ExportDist == 2
                    ExpImgDstName = strcat(OutputFolder,ImgName(1:end-4),'_',expiname{i}{img},'dst.',expformat{i});
                    eval(sprintf('imwrite(uint16(bwdist(%s==0)),ExpImgDstName,expformat{i},''Compression'',''deflate'');',expiname{i}{img}));
                end
            else
                eval(sprintf('imwrite(%s,ExpImgName,expformat{i});',expiname{i}{img}));
                if ExportDist == 1
                    ExpImgDstName = strcat(OutputFolder,ImgName(1:end-4),'_',expiname{i}{img},'dst.',expformat{i});
                    eval(sprintf('imwrite(uint16(bwdist(%s>0)),ExpImgDstName,expformat{i})',expiname{i}{img}));
                end
                if ExportDist == 2
                    ExpImgDstName = strcat(OutputFolder,ImgName(1:end-4),'_',expiname{i}{img},'dst.',expformat{i});
                    eval(sprintf('imwrite(uint16(bwdist(%s==0)),ExpImgDstName,expformat{i})',expiname{i}{img}));
                end
            end
        end

    end

    %% Update progress and display run information
    clear textprogressbar;
    disp(' ');
    if(cntskip>0)
        disp(sprintf('Skipped %i bad quality image(s)',cntskip));
    end

    %% Display processing time report
    for i = 1:numel(indfuncs)
        fprintf('Time spent inside function %s : %.2f s\n',functs{i},totaltimecalls(i));
    end
    fprintf('Total processing time: %.2f s\n',sum(totaltimecalls));
    
end
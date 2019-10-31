% 3D image journal engine (should be called from JENI!!)
function [InputFolder OutputFolder] = JENI_Stacks(Journal,ForceInputFolder,ForceOutputFolder)
 
    %% Display information to console
    disp(strcat('Journal: <a href="matlab: opentoline(''',Journal,''',1)">',Journal,'</a>-->','<a href="matlab:JENI(''',Journal,''');">Launch</a>'));
    
    %% Load journal to string
    jstring = fileread(Journal);
    
    %% Retrieve screen configuration (image display)
    screensize = get( groot, 'Screensize' );

    %% Lauch journal with no image (to retrieve folders)
    I = [];I2 = [];
    eval(jstring);
    
    %% Force input/output folders
    if nargin>1
        if ~isempty(ForceInputFolder)
            InputFolder = ForceInputFolder;
        end
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
    if ~exist('OutputFolder','var') && ~isempty(indkeeps)
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
 
    %% Set variables to default values (if not defined in journal)
    if ~exist('FoldersIn','var')
        FoldersIn = 0;
    end
    if ~exist('Rescale','var')
        Rescale = 1;
    end
    if ~exist('NoFloat','var')
        NoFloat = 0;
    end
    if ~exist('Step','var')
        Step = 1;
    end
    if ~exist('Offset','var')
        Offset = 0;
    end
    if ~exist('SaveOutput','var')
        SaveOutput = 0;
    end
    if ~exist('ExportDist','var')
        ExportDist = 0;
    end
    if ~exist('NCols','var')
        NCols = 16;
    end
    if ~exist('PointSize','var')
        PointSize = 1;
    end
    if ~exist('Shw','var')
        Shw = -1;
    end
    if ~exist('GuardBand','var')
        GuardBand = 64;
    end
    if ~exist('Dilate','var')
        Dilate = 0;
    end
    global RunProjViewer;
    if ~exist('RunProj','var')
        RunProj = 0;
    end
    RunProjViewer = RunProj;
    ShowAnnot = true;
    if ~exist('Brick','var')
        BrickMode = 0;
    else
        BrickMode = 1;
        if GuardBand > Brick/2
            error('GuardBand should not be > Brick/2');
        end
        if exist('FixedInput','var')
            error('Fixed input is not compatible with bricking');
        end
    end
    if (ExportDist>0) & (BrickMode == 1)
        error('Distance map cannot be computed in brick mode');
    end
    
    %% Analyze files in input folder
    if FoldersIn == 1
        Files = dir(InputFolder);
        Files = Files(3:end); % Skip . and ..
    else
        Files = dir(strcat([InputFolder '*.tif'])); 
    end
    num_images = numel(Files);
    
    %% Import fixed input
    if exist('FixedInput','var')
        info = imfinfo_big(FixedInput);
        num_slices = info(1).NFrames;
        Width = info(1).Width;
        Height = info(1).Height;
        BigTIFF = info(1).BigTIFF;
        if NoFloat == 1
            I2 = uint16(zeros(Height,Width,num_slices/Step));
        else
            I2 = single(zeros(Height,Width,num_slices/Step));
        end
        if BigTIFF == 0
            for kf = 1:Step:num_slices
                I2(:,:,1+(kf-1)/Step) = imread(FixedInput, kf+Offset, 'Info', info);
                %I2(:,:,1+(kf-1)/Step) = imread_big_slice(FixedInput, kf+Offset);
            end
        else
            disp('BigTIFF detected');
            I2 = imread_big(FixedInput);
        end
        if Rescale ~= 1
            I2 = imresize(I2, [round(size(I2,1)/Rescale) round(size(I2,2)/Rescale)],'Method','bilinear');
        end
        disp('...');
        if NoFloat == 0
            fprintf('Fixed Input (float) size: %i x %i x %i -> %.f MB\n',size(I2,2),size(I2,1),size(I2,3),prod(size(I2))*4/1048576);
        else
            fprintf('Fixed Input (uint16) size: %i x %i x %i -> %.f MB\n',size(I2,2),size(I2,1),size(I2,3),prod(size(I2))*2/1048576);
        end
    end
     
    %% Display information to console
    disp(sprintf('Found %i stacks in input folder',num_images));    
    sprintf('Processing stacks in folder %s\n',InputFolder); 
    
    %% Main loop to process all images from input folder
    for im = 1:num_images
  
        %% Processing time counter
        totaltime = 0;
        disp('-------------------------------------------');
        
        %% Retrieve image file information
        if FoldersIn == 1
            FilesInFolder = dir(strcat([InputFolder Files(im).name '/*.tif']));
            info = imfinfo(strcat([InputFolder Files(im).name '/' FilesInFolder(1).name]));
            Width = info(1).Width;
            Height = info(1).Height;
            num_slices = numel(FilesInFolder);
        else
            fname = strcat([InputFolder Files(im).name]);
            info = imfinfo_big(fname);
            Width = info(1).Width;
            Height = info(1).Height;
            num_slices = info(1).NFrames;
            BigTIFF = info(1).BigTIFF;
        end

        %% Set constrast settings to default
        if ~exist('MaxDisplay','var')
            switch info(1).BitDepth
                case 8
                    MaxDisplay = 150; 
                case 16
                    MaxDisplay = 5000;
            end
        end

        %% Display input file information
        fname = strcat([InputFolder Files(im).name]);
        if FoldersIn == 1
            if NoFloat == 0
                fprintf('Input folder (float) size: %i x %i x %i -> %.f MB\n',Width,Height,num_slices/Step,Width*Height*num_slices/Step*4/1048576);
            else
                fprintf('Input folder (uint16) size: %i x %i x %i -> %.f MB\n',Width,Height,num_slices/Step,Width*Height*num_slices/Step*2/1048576);
            end
        else
            if NoFloat == 0
                fprintf('Input (float) size: %i x %i x %i -> %.f MB\n',Width,Height,num_slices/Step,Width*Height*num_slices/Step*4/1048576);
            else
                fprintf('Input (uint16) size: %i x %i x %i -> %.f MB\n',Width,Height,num_slices/Step,Width*Height*num_slices/Step*2/1048576);
            end
        end
        
        %% Brick configuration
        if BrickMode == 0
            Brick = max(Width,Height);
            NBrick = 1;
        else
            %% Brick planning
            YBrick = ceil(Height/Brick);
            XBrick = ceil(Width/Brick);
            NBrick = YBrick*XBrick;
            fprintf('Brick tiling: %i x %i\n',YBrick,XBrick);
            if NoFloat == 0
                fprintf('Brick size: %i x %i x %i (%.f MB)\n',Brick,Brick,num_slices,Width*Height*num_slices/NBrick/Step*4/1048576);
            else
                fprintf('Brick size: %i x %i x %i (%.f MB)\n',Brick,Brick,num_slices,Width*Height*num_slices/NBrick/Step*2/1048576);
            end
        end
        
        %% Loop over bricks (no brick --> 1 brick)
        cntbrck = 0;
        for ibrck = 1:Brick:Height
        for jbrck = 1:Brick:Width
        
            %% Display brick processing count
            if BrickMode == 1
                fprintf('Brick %i of %i\n',cntbrck+1,NBrick);
            end
                
            %% Compute brick size
            if BrickMode == 1
                imin = ibrck-GuardBand*(ibrck>1);
                jmin = jbrck-GuardBand*(jbrck>1);
                GBRi = (ibrck+Brick-1+GuardBand)<Height;
                GBRj = (jbrck+Brick-1+GuardBand)<Width;
                imax = min(ibrck+Brick-1+GuardBand*GBRi,Height);
                jmax = min(jbrck+Brick-1+GuardBand*GBRj,Width);
            end
                
            %% Load input image stack
            if FoldersIn == 1
                if BrickMode == 1
                    if NoFloat == 1
                        I = uint16(zeros(imax-imin+1,jmax-jmin+1,num_slices/Step));
                    else
                        I = single(zeros(imax-imin+1,jmax-jmin+1,num_slices/Step));
                    end
                    for kf = 1:Step:num_slices
                        fname = strcat([InputFolder Files(im).name '/' FilesInFolder(kf+Offset).name]);
                        I(:,:,1+(kf-1)/Step) = imread(fname, 'PixelRegion',{[imin,imax],[jmin,jmax]});
                    end
                else
                    if NoFloat == 1
                        I = uint16(zeros(Height,Width,num_slices/Step));
                    else
                        I = single(zeros(Height,Width,num_slices/Step));
                    end
                    for kf = 1:Step:num_slices
                        fname = strcat([InputFolder Files(im).name '/' FilesInFolder(kf+Offset).name]);
                        I(:,:,1+(kf-1)/Step) = imread(fname);
                    end
                end
            else
                if BrickMode == 1
                    if NoFloat == 1
                        I = uint16(zeros(imax-imin+1,jmax-jmin+1,num_slices/Step));
                    else
                        I = single(zeros(imax-imin+1,jmax-jmin+1,num_slices/Step));
                    end
                    if BigTIFF == 0
                        for kf = 1:Step:num_slices
                            I(:,:,1+(kf-1)/Step) = imread(fname, kf+Offset,'PixelRegion',{[imin,imax],[jmin,jmax]});
                            %I(:,:,1+(kf-1)/Step) = imread_big_slice(fname, kf+Offset,jmin,imin,jmax-jmin,imax-imin);
                        end
                    else
                        if Step > 1
                             error('BigTIFF + channels not yet supported');
                        else
                             disp('BigTIFF detected');
                             I = imread_big(fname,jmin-1,imin-1,jmax-jmin+1,imax-imin+1);
                         end
                    end
                else
                    if NoFloat == 1
                        I = uint16(zeros(Height,Width,num_slices/Step));
                    else
                        I = single(zeros(Height,Width,num_slices/Step));
                    end
                    if BigTIFF == 0
                        for kf = 1:Step:num_slices
                            I(:,:,1+(kf-1)/Step) = imread(fname, kf+Offset);
                            %I(:,:,1+(kf-1)/Step) = imread_big_slice(fname, kf+Offset);
                        end
                    else
                         if Step > 1
                             error('BigTIFF + channels not yet supported');
                         else
                             disp('BigTIFF detected');
                             I = imread_big(fname);
                         end
                    end
                end
            end
            
            %% Optionally scale input
            if Rescale ~= 1
                I = imresize(I, [round(size(I,1)/Rescale) round(size(I,2)/Rescale)],'Method', 'bilinear');
            end
            
            %% Launch journal and update processing time
            tic;
            params.MaxDisplay = MaxDisplay;
            eval(jstring);
            totaltime = totaltime+toc;
            
            %% Force input/output folders
            if nargin>1
                InputFolder = ForceInputFolder;
                OutputFolder = ForceOutputFolder;
            end
            InputFolder = FixFolderPath(InputFolder);
            OutputFolder = FixFolderPath(OutputFolder);
    
            %% Force no image display if JENI was called from JULI
            callers = dbstack;
            callers = {callers.name};
            if any(strcmp(callers,'JULI')) || any(strcmp(callers,'GENI'))
                Shw = -1;
            end
            
            %% Re-apply input/output fodlers redirections (lost upon journal call)
            if exist('InputFolderRedirect','var');
                InputFolder = InputFolderRedirect;
            end
            if exist('OutputFolderRedirect','var');
                OutputFolder = OutputFolderRedirect;
            end
            
            %% Save output to file (always variable 'O')
            if SaveOutput == 1
            if ~isempty(O)
                if ~isa(O,'uint8')& ~isa(O,'uint16')
                    error('Output 3D stack should be uint8 or uint16');
                end
                
                %% Save output (bricking)
                if BrickMode == 1
                    
                    if cntbrck == 0
                        if FoldersIn == 1
                            SubFoderName = Files(im).name;
                        else
                            SubFoderName = Files(im).name;
                            SubFoderName = SubFoderName(1:end-4);
                        end
                        OutputSubFoder = strcat(OutputFolder,SubFoderName);
                        if ~exist(OutputSubFoder,'dir')
                            mkdir(OutputSubFoder);
                        else
                            if numel(dir(OutputSubFoder)) > 2
                                pth = pwd;
                                cd(OutputSubFoder);
                                delete Brck_*.tif;
                                cd(pth);
                            end
                        end
                    end
                    
                    %% Crop out Guardbands
                    O = O(1+GuardBand*(imin>1):end-GuardBand*GBRi,1+GuardBand*(jmin>1):end-GuardBand*GBRj,:);
                    
                    %% Save images
                    if FoldersIn == 1
                        imwrite(O(:,:,1),strcat([OutputSubFoder sprintf('/Brck_%02i_%02i_',(jbrck-1)/Brick,(ibrck-1)/Brick) Files(im).name '.tif']),'Compression','deflate');
                        for kf = 2:size(O,3)
                            imwrite(O(:,:,kf),strcat([OutputSubFoder sprintf('/Brck_%02i_%02i_',(jbrck-1)/Brick,(ibrck-1)/Brick) Files(im).name '.tif']),'WriteMode', 'append', 'Compression','deflate');
                        end 
                    else
                        imwrite(O(:,:,1),strcat([OutputSubFoder sprintf('/Brck_%02i_%02i_',(jbrck-1)/Brick,(ibrck-1)/Brick) Files(im).name]),'Compression','deflate');
                        for kf = 2:size(O,3)
                            imwrite(O(:,:,kf),strcat([OutputSubFoder sprintf('/Brck_%02i_%02i_',(jbrck-1)/Brick,(ibrck-1)/Brick) Files(im).name]),'WriteMode', 'append', 'Compression','deflate');
                        end
                    end
                    
                else
                    
                    %% Save output (no bricking)
                    if FoldersIn == 1
                        imwrite(O(:,:,1),strcat([OutputFolder Files(im).name '.tif']),'Compression','deflate');
                        for kf = 2:size(O,3)
                            imwrite(O(:,:,kf),strcat([OutputFolder Files(im).name '.tif']),'WriteMode', 'append', 'Compression','deflate');
                        end
                    else
                        imwrite(O(:,:,1),strcat([OutputFolder Files(im).name]),'Compression','deflate');
                        for kf = 2:size(O,3)
                            imwrite(O(:,:,kf),strcat([OutputFolder Files(im).name]),'WriteMode', 'append', 'Compression','deflate');
                        end
                    end
                    
                    %% Compute and export distance map outside detected objects
                    if ExportDist == 1
                        tic;
                        if exist('M','var')
                            disp('Computing external distance map from M...');
                            D = uint16(resize3D(M>0,[size(M,1) size(M,2) round(size(M,3)*ZRatio)],'nearest'));
                            D = uint16(bwdist(D));
                            D = resize3D(D,size(M),'nearest');
                        else
                            disp('Computing external distance map from O...');
                            D = uint16(resize3D(O>0,[size(O,1) size(O,2) round(size(O,3)*ZRatio)],'nearest'));
                            D = uint16(bwdist(D));
                            D = resize3D(D,size(O),'nearest');
                        end
                        totaltime = totaltime+toc;
                        FileName = Files(im).name;
                        %% Save distance map outside objects
                        imwrite(D(:,:,1),strcat([OutputFolder FileName(1:end-4) '_dst' FileName(end-3:end)]),'Compression','deflate');
                        for kf = 2:num_slices
                            imwrite(D(:,:,kf),strcat([OutputFolder FileName(1:end-4) '_dst' FileName(end-3:end)]),'WriteMode', 'append', 'Compression','deflate');
                        end  
                    end
                    
                    %% Compute and export distance map inside objects
                    if ExportDist == 2
                        tic;
                        if exist('M','var')
                            disp('Computing internal distance map from M...');
                            D = uint16(resize3D(M==0,[size(M,1) size(M,2) round(size(M,3)*ZRatio)],'nearest'));
                            D = uint16(bwdist(D));
                            D = resize3D(D,size(M),'nearest');
                        else
                            disp('Computing internal distance map from O...');
                            D = uint16(resize3D(O==0,[size(O,1) size(O,2) round(size(O,3)*ZRatio)],'nearest'));
                            D = uint16(bwdist(D));
                            D = resize3D(D,size(O),'nearest');
                        end
                        totaltime = totaltime+toc;
                        FileName = Files(im).name;
                        %% Save distance map outside objects
                        imwrite(D(:,:,1),strcat([OutputFolder FileName(1:end-4) '_dst' FileName(end-3:end)]),'Compression','deflate');
                        for kf = 2:num_slices
                            imwrite(D(:,:,kf),strcat([OutputFolder FileName(1:end-4) '_dst' FileName(end-3:end)]),'WriteMode', 'append', 'Compression','deflate');
                        end 
                    end
                end 
            end
            end
            
            %% Visualization (only show the first brick)
            if cntbrck == 0
            
            if BrickMode == 1
                I = I(1+GuardBand*(imin>1):end-GuardBand*(imax<Height),1+GuardBand*(jmin>1):end-GuardBand*(jmax<Width),:);
                if SaveOutput == 0
                    O = O(1+GuardBand*(imin>1):end-GuardBand*(imax<Height),1+GuardBand*(jmin>1):end-GuardBand*(jmax<Width),:);
                end
            end
            
            %% Running Z projection (now performed dynamically)
            if Dilate > 1
                disp('Performing mask dilation...');
                O = imfilter(O,double(strel('disk', Dilate).getnhood()));
            end
            
            %% Display input and output in two stack browser
            if Shw == 0
                
                %% Display input
                hdl2 = figure('Name','Input');
                set(hdl2, 'Position', [8 screensize(4)-680 768 512]);
                set(gcf,'Name','Press x to continue, (q) interrupt, (m) toggle mask, (z) adjust local zproj, (r) send subvolume to renderer','NumberTitle','off');
                tool = imtool3D(I,[0 0 1 1],hdl2);
                setWindowLevel(tool,2*MaxDisplay,MaxDisplay);
                setCurrentSlice(tool,round(size(I,3)/2));
                
                %% Display output
                hdl = figure('Name','Output');
                set(hdl, 'Position', [8 screensize(4)-680 768 512]);
                set(gcf,'Name','Press x to continue, (q) interrupt, (m) toggle mask, (z) adjust local zproj, (r) send subvolume to renderer','NumberTitle','off');
                tool = imtool3D(O,[0 0 1 1],hdl);
                setWindowLevel(tool,2*MaxDisplay,MaxDisplay);
                
                %% Make sure that the image is really a stack (not a projection)                
                if size(O,3)>1
                    setCurrentSlice(tool,round(size(O,3)/2));
                end
            end
            
            %% Display input in as stack browser and output as overlay mask
            if Shw == 1
                hdl = figure('Name','Input + binary mask overlay');
                set(hdl, 'Position', [8 screensize(4)-680 768 512]);
                set(gcf,'Name','Press x to continue, (q) interrupt, (m) toggle mask, (z) adjust local zproj, (r) send subvolume to renderer','NumberTitle','off');
                tool = imtool3D(I,[0 0 1 1],hdl);
                setWindowLevel(tool,2*MaxDisplay,MaxDisplay);
                setCurrentSlice(tool,round(size(I,3)/2));
                if isequal(size(I), size(O))
                    setMask(tool,(255*(logical(O))>0));
                    setAlpha(tool,1);
                end
            end
            
            %% Display input in as stack browser and output as outlined overlay mask
            if Shw == 2
                Markerse = [[0 1 0];[1 1 1];[0 1 0]];
                hdl = figure('Name','Input + binary mask contours overlay');
                set(hdl, 'Position', [8 screensize(4)-680 768 512]);
                set(gcf,'Name','Press x to continue, (q) interrupt, (m) toggle mask, (z) adjust local zproj, (r) send subvolume to renderer','NumberTitle','off');
                tool = imtool3D(I,[0 0 1 1],hdl);
                setWindowLevel(tool,2*MaxDisplay,MaxDisplay);
                setCurrentSlice(tool,round(size(I,3)/2));
                setMask(tool,(255*(imdilate(O,Markerse)-O)>0));
                setAlpha(tool,1);
            end
            
            %% Display input in as stack browser and output as overlay labeled mask
            if Shw == 3
                %% Check if the stack is binary
                if max(O(:))==1
                    disp('Output is binary, performing connected component analysis');
                    O = bwlabeln(O>0);
                end
                if isa(O,'uint16');
                    O = single(O);
                end
                hdl = figure('Name','Input + label mask overlay');
                set(hdl, 'Position', [8 screensize(4)-680 768 512]);
                set(gcf,'Name','Press x to continue, (q) interrupt, (m) toggle mask, (z) adjust local zproj, (r) send subvolume to renderer','NumberTitle','off');
                tool = imtool3DLbl(I,[0 0 1 1],hdl);
                setWindowLevel(tool,2*MaxDisplay,MaxDisplay);
                setCurrentSlice(tool,round(size(I,3)/2));
                setMask(tool,O);
                setAlpha(tool,1);
            end
            
            %% 3D rendering setup
            if Shw >= 4
                %% Find largest XY dimension and compute 3D cube rendering ratio
                maxXYZ = max([ceil(size(I,1)/8)*8 ceil(size(I,2)/8)*8 ceil(size(I,3)/8)*8]);
                CubeRatio = maxXYZ/size(I,3);
                if(exist('ZRatio'))
                    ZRatio = ZRatio/Rescale;
                    ZScale = ZRatio/CubeRatio;
                else
                    disp('...');
                    disp('Warning! ZRatio not set, data mapped to a 3D cube');
                    ZScale = 1;
                end
            end
            
            %% Output 3D rendering
            if Shw == 4    
                
                %% Pad and convert to 8-bit for rendering (avoid XY distortion)
                scl = 255/max(O(:));
                O = uint8(padarray(O,[maxXYZ-size(O,1) maxXYZ-size(O,2)],'pre')*scl); 
                
                %% Render volume
                FV.ZScale = ZScale;
                LoadTaoOpenGl;
                Form1 = Init_OpenGL_Window('new','render3d',O, FV);
                Form1.Text = 'Close window to continue, (m) toggle mask, (c) adjust intensity';
                Form1.WindowState = System.Windows.Forms.FormWindowState.Normal;
            end
            
            %% Input 3D rendering and render output as a colored point cloud
            if Shw == 5
                
                %% Pad and convert to 8-bit for rendering
                scl = 255/max(I(:));
                I = permute(uint8(padarray(I,[maxXYZ-size(I,1) maxXYZ-size(I,2)],'pre')*scl),[2 1 3]);
                O = permute(padarray(O,[maxXYZ-size(O,1) maxXYZ-size(O,2)],'pre'),[2 1 3]);

                %% Find edges
                se(:,:,1) = [0 0 0;0 1 0;0 0 0];
                se(:,:,2) = [0 1 0;1 1 1;0 1 0];
                se(:,:,3) = [0 0 0;0 1 0;0 0 0];
                Oshrink = imerode(O,se);
                Edges = O-Oshrink;

                %% If "O" is binary then analyze connected components for point coloring
                if max(O(:)) == 1
                    disp('Output is binary, performing connected component analysis');
                    O = bwlabeln(O>0);
                end

                %% Compute all surface points and assign color
                ObjIndx = find(Edges>0);	
                LUT = round(linspecer(NCols)*255);
                rng(0);
                LUT = LUT(randperm(NCols),:);
                [i j k] = ind2sub(size(O),ObjIndx);
                FV.vertices = [i j CubeRatio*k];
                FV.vertices = FV.vertices*(2/max(size(I)))-1;
                FV.vertices(:,3) = FV.vertices(:,3)*ZScale;
                FV.faces = repmat((1:numel(i)).',1,3);
                FV.points = 1; %% Point mode (no triangle rendering)
                cols = uint8(LUT(1+mod(O(ObjIndx),NCols),:));
                FV.colors = cols;
                FV.pointsize = PointSize;
                FV.ZScale = ZScale;

                %% Initialize rendering
                LoadTaoOpenGl;
                Form1 = Init_OpenGL_Window('new','render3d_and_mesh',I, FV);
                Form1.Text = 'Close window to continue, (m) toggle mask, (c) adjust intensity';
                Form1.WindowState = System.Windows.Forms.FormWindowState.Normal;
                Form1.TopMost = true;
            end
            
            %% Automatic key stroke upon window closing
            if exist('hdl','var')
                set(hdl,'CloseRequestFcn',['delete(1);pause(0.05);robot = java.awt.Robot;robot.keyPress(java.awt.event.KeyEvent.VK_ENTER);']);
            end
            if exist('hdl2','var')
                set(hdl,'CloseRequestFcn',['delete(2);pause(0.05);robot = java.awt.Robot;robot.keyPress(java.awt.event.KeyEvent.VK_ENTER);']);
            end
            
            %% Wait to continue
            disp(' ');
            disp('Press x to continue');
            if Shw >-1
                
            if Shw >=0 & Shw <=3
                % Prevent closing current figure
                follow = false;
                while follow == false
                    pause;
                    if isvalid(hdl)
                    Mode = get(gcf,'CurrentKey');
                    switch Mode
                        case 'm'
                            %% Toggle annotations
                            ShowAnnot = ~ShowAnnot;
                            if ShowAnnot == false
                                setAlpha(tool,0);
                            else
                                setAlpha(tool,1);
                            end
                        case 'z'
                            str = inputdlg('Set local Z projection depth (max = 64)');
                            RunProjViewer = min([str2double(str(1)) 64]);
                            setAlpha(tool,0);
                            setAlpha(tool,1);
                        case 'r'
                            H = imrect();
                            pos = getPosition(H);
                            ZSpan = max(4,1+floor(RunProjViewer/2));
                            Icrop = I(max(floor(pos(2)),1):min(floor(pos(2)+pos(4)),size(I,1)),max(floor(pos(1)),1):min(floor(pos(1)+pos(3)),size(I,2)),max(getCurrentSlice(tool)-ZSpan,1):min(getCurrentSlice(tool)+ZSpan,size(I,3)));
                            Ocrop = O(max(floor(pos(2)),1):min(floor(pos(2)+pos(4)),size(O,1)),max(floor(pos(1)),1):min(floor(pos(1)+pos(3)),size(O,2)),max(getCurrentSlice(tool)-ZSpan,1):min(getCurrentSlice(tool)+ZSpan,size(O,3)));
                            maxXYZ = max([48 ceil(size(Icrop,1)/8)*8 ceil(size(Icrop,2)/8)*8 ceil(size(Icrop,3)/8)*8]);
                            CubeRatio = maxXYZ/size(Icrop,3);
                            if(exist('ZRatio'))
                                ZRatio = ZRatio/Rescale;
                                ZScale = ZRatio/CubeRatio;
                            else
                                disp('...');
                                disp('Warning! ZRatio not set, data mapped to a 3D cube');
                                ZScale = 1;
                            end
                            %% Pad and convert to 8-bit for rendering
                            scl = 255/max(Icrop(:));
                            Icrop = permute(uint8(padarray(Icrop,[maxXYZ-size(Icrop,1) maxXYZ-size(Icrop,2)],0,'pre')*scl),[2 1 3]);
                            Ocrop = permute(padarray(Ocrop,[maxXYZ-size(Ocrop,1) maxXYZ-size(Ocrop,2)],0,'pre'),[2 1 3]);
                            %% Find edges
                            se(:,:,1) = [0 0 0;0 1 0;0 0 0];
                            se(:,:,2) = [0 1 0;1 1 1;0 1 0];
                            se(:,:,3) = [0 0 0;0 1 0;0 0 0];
                            Ocropshrink = imerode(Ocrop,se);
                            Edges = Ocrop-Ocropshrink;
                            %% If "O" is binary then analyze connected components for point coloring
                            if max(Ocrop(:)) == 1
                                Ocrop = bwlabeln(Ocrop>0);
                            end
                            %% Compute all surface points and assign color
                            ObjIndx = find(Edges>0);	
                            LUT = round(linspecer(NCols)*255);
                            rng(0);
                            LUT = LUT(randperm(NCols),:);
                            [i j k] = ind2sub(size(Ocrop),ObjIndx);
                            FV.vertices = [i j CubeRatio*k];
                            FV.vertices = FV.vertices*(2/max(size(Icrop)))-1;
                            FV.vertices(:,3) = FV.vertices(:,3)*ZScale;
                            FV.faces = repmat((1:numel(i)).',1,3);
                            FV.points = 1; %% Point mode (no triangle rendering)
                            cols = uint8(LUT(1+mod(Ocrop(ObjIndx),NCols),:));
                            FV.colors = cols;
                            FV.pointsize = PointSize;
                            FV.ZScale = ZScale;
                            %% Initialize rendering
                            LoadTaoOpenGl;
                            Form1 = Init_OpenGL_Window('new','render3d_and_mesh',Icrop, FV);
                            Form1.WindowState = System.Windows.Forms.FormWindowState.Normal;
                            Form1.TopMost = true;
                            while Form1.Visible == 1
                                pause(0.05); 
                            end
                            delete(H);
                        case 'x'
                            follow = true;
                            delete(hdl);
                            close all;
                        case 'q'
                            delete(hdl);
                            close all;
                            error('Program terminated by user');
                        otherwise
                            disp('Press x to continue');
                        end
                    else
                        follow = true;
                    end
                end
            else
                disp('Close 3D viewer to continue');
                while Form1.Visible == 1
                    pause(0.05); 
                end
            end
            end
            close all;
            pause(0.05);
            end
            cntbrck = cntbrck + 1;
        end
        end

        fprintf('Time spent for processing: %.2f s (%.2f MB/s)\n',totaltime,(Width*Height*num_slices/Step*4/1048576)/totaltime);
 
    end
    
end
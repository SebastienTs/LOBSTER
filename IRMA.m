function ReportFolder = IRMA(varargin)
    % Perform journal results masks analysis and measurements.
    %
    % Arguments:
    % arg1 -> MaskFolder (output folder from journal)
    % arg2 -> ReportFolder ('': no report, '.': default results folder, number X -> _rX)
    % arg3 -> Analysis mode: 'Spts', 'Skls', 'Objs', 'Trks' or 'Spst'
    % arg4 -> Dim: 2 or 3 (2D or 3D)
    % arg5 -> ZRatio: slice spacing to pixel size ratio / {ZRatio, (skeleton tracing pix step / fraction mesh vertices kept), 'MeshExportFolder', 'SklExportFormat' (optional)} 
    % arg6 -> Channels folder (intensity measurements only)
    % arg7 -> Channel 1 image filter
    % arg8 -> Channel 2 image filter 
    % arg9 -> Channel 3 image filter
    %
    % Sample calls:
    % IRMA('E:\LOBSTER\Results\Images\NucleiCytoo\','.','Objs',2);
    % ReportFolder = IRMA('E:\LOBSTER\Results\Images\NucleiCytoo\','.','Objs',2);
    % IRMA('E:\LOBSTER\Results\Images\NucleiCytoo\','.','Objs',2,1,'E:\LOBSTER\Images\NucleiCytoo\','*C01*.tif');
    % IRMA('E:\LOBSTER\Results\Images\NucleiCytoo\','.','Objs',2,1,'E:\LOBSTER\Images\NucleiCytoo\','*C01*.tif','*C02*.tif');
    % IRMA('E:\LOBSTER\Results\Images\CellPilar3DLbl\','.','Objs',[3 1 0],1,'E:\LOBSTER\Images\CellPilar3D\');
    % IRMA('E:\LOBSTER_sandbox\Images\BloodVessels3D_o1\',1,'Objs',[3 1 0],1);
    % IRMA('E:\LOBSTER\Results\Images\TestSkl','.','Skls',3,4);
    % IRMA('E:\LOBSTER\Results\Images\BloodVessels3DSkl\','.','Skls',3,{3,3,'.'},'E:\LOBSTER\Results\Images\BloodVessels3DSkl\','*_dst*');
    % For other type of masks see job examples in LOBSTER_ROOT/Jobs folder
    % For 3D models exportations see _stl and _swc job examples in LOBSTER_ROOT/Jobs folder
    
    %% Hard coded values for skeleton masks and channel names
    SklValue = 200;
    SklEndpts = 220;
    SklBrcpts = 250;
    SeedsValue = 200;
    
    %% Skeleton analysis: short branch pruning hard coded settings
    MinBrchLgth = 7;
    MaxIter = 3;
    SklExport = 'SWC'; % Default format
    
    %% Default configuration for 3D image + channel input: no slice Z step, no offset
    Step = 1;
    Offsets = 0;
    warning on;
    
    %% Initialization: paths and folders
    %% Check that imtool3D is in path (init has been performed), if not perform it!
    if ~exist('imtool3D')
        init;
    else
        %% Force path to LOBSTER root on startup
        str = which('init');
        indxs = find((str=='/')|(str=='\'));
        cd(str(1:indxs(end)));
    end
    
    %% Initialization: parse function compulsory arguments
    if nargin<4
        error('IRMA: missing input arguments');
    end
    MaskFolder = varargin{1};
    MaskFolder = FixFolderPath(MaskFolder);
    if ~exist(MaskFolder,'dir');
        error('Mask folder does not exist');
    end
    ReportFolder = varargin{2};
    if ~isempty(ReportFolder)
        if isnumeric(ReportFolder)
            fields = strsplit(MaskFolder,{'/','\'});
            if ReportFolder > 0
                ReportFolder = [MaskFolder '../' fields{end-1} '_r' num2str(ReportFolder) '/' fields{end-1} '/']; 
            else
                ReportFolder = [MaskFolder '../../' fields{end-2} '_r' num2str(abs(ReportFolder)) '/' fields{end-1} '/'];  
            end
            ReportFolder = GetFullPath(ReportFolder);
        end
        if strcmp(ReportFolder,'.')
            fields = strsplit(MaskFolder,{'/','\'});
            if strcmp(varargin{3},'Trks')
                ReportFolder = ['./Results/Reports/' fields{end-2} '/' fields{end-1} '/'];
            else
                ReportFolder = ['./Results/Reports/' fields{end-1} '/'];
            end
        end
        ReportFolder = FixFolderPath(ReportFolder);
        if ~exist(ReportFolder,'dir');
            mkdir(ReportFolder);
            warning('Report folder created since it did not exist');
        end
    else
        warning('No report folder defined, reports will not be saved');
    end
    Mode = varargin{3};
    Dim = varargin{4};
    
    %% 3D images: parse slice Step + channel offsets if defined
    if(numel(Dim)>1)
        if(Dim(1) == 3)
            Step = Dim(2);
            if numel(Dim)>2
                Offsets = Dim(3:end);
            end
            Dim = 3;
        else
            error('For 2D images no slice offset/step should be defined');
        end
    end
    
    %% Initialization: parse function optional arguments
    ExportMeshFolder = '';
    if nargin > 4
        if numel(varargin{5})==1
            ZRatio = varargin{5};
            ExportMeshFolder = '';
        else
            ZRatio = varargin{5}{1};
            smp = varargin{5}{2};
            if varargin{5}{3}== '.'
                ExportMeshFolder = ['./Results/Meshes/' fields{end-1} '/'];
            else
                ExportMeshFolder = varargin{5}{3};
            end
            if numel(varargin{5})==4
                SklExport = varargin{5}{4};
            end
            if ~isempty(ExportMeshFolder)
                ExportMeshFolder = FixFolderPath(ExportMeshFolder);
                if~exist(ExportMeshFolder,'dir');
                    mkdir(ExportMeshFolder);
                    warning('Mesh folder created since it did not exist');
                end
            end
        end
    end
    if nargin > 5
        ChanFolder = varargin{6};
        if iscell(ChanFolder) && numel(ChanFolder)==1
            ChanFolder = ChanFolder{1};
        end
        if iscell(ChanFolder)
            for k = 1:numel(ChanFolder)
                ChanFolder{k} = FixFolderPath(ChanFolder{k});
                if ~exist(ChanFolder{k},'dir');
                    error('Some extra channel images folders do not exist');
                end
            end
        else
            ChanFolder = FixFolderPath(ChanFolder);
            if ~exist(ChanFolder,'dir');
                error('Extra channel images folder does not exist');
            end
        end
        
        %% Optional channel image filters for extra channel images
        if nargin > 6
            NChans = nargin-6;
            for c = 1:NChans
                ImageFilter{c} = varargin{6+c};
            end
        else
            %% No channel image filter defined, 2D images: one channel, 3D images: deduce from channel offsets
            if Dim == 2
                ImageFilter{1} = '*.tif';
                NChans = 1;
            else
                for c = 1:numel(Offsets)
                    ImageFilter{c} = '*.tif';
                end
                NChans = numel(Offsets);
            end
        end
        disp(sprintf('Intensity measurements in %i channels',NChans));
        if iscell(ChanFolder)
            for k = 1:numel(ChanFolder)
                disp(sprintf('Intensity channels folders: %s',ChanFolder{k}));
            end
        else
            disp(sprintf('Intensity channels folder: %s',ChanFolder));
        end
    else
        ChanFolder = '';
        NChans = 0;
    end
    
    %% Parse files in mask folder, exclude files containing '_dst.' and 'zzz_'
    Files = dir(MaskFolder);
    %% Exclude '.' and '..'
    Files = Files(3:end);
    Files_dst = strfind({Files.name},'_dst.');
    Files = Files(find(cellfun('isempty', Files_dst)));
    Files_zzz = strfind({Files.name},'zzz_');
    Files = Files(find(cellfun('isempty', Files_zzz)));
    
    %% Parse files in channel folders (applying mask filter)
    num_images = numel(Files);
    if NChans>0
        for c = 1:NChans
            if iscell(ChanFolder)
                FilesChan{c} = dir(strcat(ChanFolder{c},ImageFilter{c}));
            else
                FilesChan{c} = dir(strcat(ChanFolder,ImageFilter{c}));
            end
            %% FoldersIn mode
            if ImageFilter{c} == '*'
                FilesChan{c} = FilesChan{c}(3:end);
            end
        end
    end
    
    %% For 3D image: check mask folder configuration (bricked or non bricked)
    switch Dim
        case 3
            if(sum([Files.isdir])>0)
                if(sum([Files.isdir])~=numel(Files))
                    error('Results folder is a mixture of folders and files');
                end
                BrickMode = 1;
                disp('Brick mode');
                if ~exist([ReportFolder '/Tmp'],'file') && strcmp(Mode,'Objs') ==1
                    mkdir([ReportFolder '/Tmp']);
                end
            else
                BrickMode = 0;
            end
        case 2
            BrickMode = 0;
        otherwise
            error('Dimension must be set to 2 or 3');
    end
    
    %% Non time-lapse mode: each image/folder is an independent dataset
    if strcmp(Mode,'Trks') == 0
        disp(sprintf('Found %i datasets in input folder', num_images));
    else
        % Bricking not supported for time-lapse
        BrickMode = 0;
    end
    
    %% Loop over all mask folder images / folders (bricked mode) 
    disp('-----------------------------------------------');
    Rall = [];
    for i = 1:num_images
        if strcmp(Mode,'Trks') == 0
            disp('-----------------------------------------------');
            disp(sprintf('Processing dataset %i of %i',i,num_images));
        else
            if i == 1
                disp('Processing time-lapse...');
            end
        end
        if NChans>0
            for c = 1:NChans
                if isempty(FilesChan{c})
                    error('Could not find extra channel images');
                end
                if iscell(ChanFolder)
                    cpath{c} = strcat([ChanFolder{c} FilesChan{c}(i).name]);
                else
                    cpath{c} = strcat([ChanFolder FilesChan{c}(i).name]);
                end
            end
        end
        
        %% Brick mode: parse how many bricks are stored in current folder
        if BrickMode == 1
            BrckFiles = dir(strcat([MaskFolder Files(i).name '/*.tif']));
            num_brcks = numel(BrckFiles);
            MaxX = 0;
            MaxY = 0;
            info = imfinfo(strcat([MaskFolder Files(i).name '/' BrckFiles(1).name]));
            num_slices = numel(info);
            BrickWidth = info(1).Width;
            BrickHeight = info(1).Height;
            BitDepth = info(1).BitsPerSample;
            %% Compute brick grid configuration by parsing file names (rows and columns)
            for k = 1:num_brcks
                fpath = strcat([MaskFolder Files(i).name '/' BrckFiles(k).name]);
                fname = BrckFiles(k).name;
                xindx = str2num(BrckFiles(k).name(6:7));
                yindx = str2num(BrckFiles(k).name(9:10));
                if xindx>MaxX
                    MaxX = xindx;
                end
                if yindx>MaxY
                    MaxY = yindx;
                end
            end
            GrdX = MaxX+1;
            GrdY = MaxY+1;
            disp(sprintf('Brick grid size: %i x %i',GrdX,GrdY));
        else
            num_brcks = 1;
        end
        
        %% Initialization for bricked mode
        if BrickMode == 1
            Meas = [];
            Rstore = [];
            brckindx = 0;
            brckindoff = zeros(GrdX+1,GrdY+1);
        end
        
        %% Bricked mode: accumulate results to Rstore, only process current file (non bricked mode)
        for k = 1:num_brcks    
            if BrickMode == 1
				disp(['Brick ' num2str(k) ' of ' num2str(num_brcks)]);
                fpath = strcat([MaskFolder Files(i).name '/' BrckFiles(k).name]);
                fname = BrckFiles(k).name;
                xindx = str2num(BrckFiles(k).name(6:7));
                yindx = str2num(BrckFiles(k).name(9:10));
                XOff = xindx*BrickWidth;
                YOff = yindx*BrickHeight;
            else
                fpath = strcat([MaskFolder Files(i).name]);
                fname = Files(i).name;
            end
            
            %% Load current mask and intensity channels
            if Dim == 2
                info = imfinfo(fpath);
                Width = info(1).Width;
                Height = info(1).Height;
                M = imread(fpath);
                I = uint16(zeros(Height,Width,1+NChans));
                if NChans>0
                    for c = 1:NChans
                        I(:,:,c) = uint16(imread(cpath{c}));
                    end
                end
            else
                info = imfinfo(fpath);
                num_slices = numel(info);
                Width = info(1).Width;
                Height = info(1).Height;
                BitDepth = info(1).BitsPerSample;
                if BitDepth == 8
                    M = uint8(zeros(Height,Width,num_slices));
                else
                    M = uint16(zeros(Height,Width,num_slices));
                end
                for kf = 1:num_slices
                    M(:,:,kf) = imread(fpath, kf);
                end
                if NChans>0
                    I = uint16(zeros(Height,Width,num_slices,NChans));
                    for c = 1:NChans
                        if BrickMode == 1
                            if isdir(cpath{c})
                                %% FoldersIn mode
                                DirFiles = dir([cpath{c} '/*.tif']);
                                for kf = 1:num_slices
                                    I(:,:,kf,c) = imread([cpath{c} '/' DirFiles(Offsets(c)+kf*Step).name],1,'PixelRegion',{[YOff+1,YOff+Height],[XOff+1,XOff+Width]});
                                end 
                            else
                                %% Regular mode mode
                                for kf = 1:num_slices
                                    I(:,:,kf,c) = imread(cpath{c}, 1+(kf-1)*Step+Offsets(c),'PixelRegion',{[YOff+1,YOff+Height],[XOff+1,XOff+Width]});
                                end
                            end
                        else
                            if isdir(cpath{c})
                                %% FoldersIn mode
                                DirFiles = dir([cpath{c} '/*.tif']);
                                for kf = 1:num_slices
                                    I(:,:,kf,c) = imread([cpath{c} '/' DirFiles(Offsets(c)+kf*Step).name]);
                                end
                            else
                                %% Regular mode mode
                                for kf = 1:num_slices
                                    I(:,:,kf,c) = imread(cpath{c}, 1+(kf-1)*Step+Offsets(c));
                                end
                            end
                        end
                    end
                end
            end

            switch Mode
                  
            case 'Objs'
                
                %% Check if input mask is binary or label object mask
                if isa(M,'uint8')
                    %% Binary mask
                    CC = bwconncomp(M>0);
                    L = single(labelmatrix(CC));
                    R  = regionprops(L,'Area','Centroid','BoundingBox');
                    %% Add object indices
                    for l = 1:CC.NumObjects
                        R(l).Indx = L(CC.PixelIdxList{l}(1));
                    end
                else
                    %% Label mask
                    if BrickMode == 1
                        error('Brick mode is incompatible with label mask input');
                    end
                    R = regionprops(M,'Area','Centroid','BoundingBox','PixelIdxList');
                    R([R.Area]==0) = [];
                    CC.PixelIdxList = {R.PixelIdxList};
                    CC.NumObjects = numel(CC.PixelIdxList);
                    R = rmfield(R,'PixelIdxList');
                    %% Add object indices
                    for l = 1:CC.NumObjects
                        R(l).Indx = M(CC.PixelIdxList{l}(1));
                    end
                end

                %% Measure mean intensity and object pixels in intensity channels
                if NChans>0
                    for c = 1:NChans
                        MeanInt = zeros(1,CC.NumObjects);
                        for l = 1:CC.NumObjects
                            R(l).MeanInt(c) = mean(I(CC.PixelIdxList{l}+(c-1)*(prod(size(M)))));
                            R(l).NonNullPix(c) = sum(I(CC.PixelIdxList{l}+(c-1)*(prod(size(M))))>0);
                        end
                    end
 
                    %% Measure overlap between object pixels
                    if NChans > 1
                        IOvl = ones(size(M));
                        if Dim == 2
                            for l = 1:NChans
                                IOvl = IOvl & (I(:,:,l)>0);
                            end
                        end
                        if Dim == 3
                            for l = 1:NChans
                                IOvl = IOvl & (I(:,:,:,l)>0);
                            end
                        end
                        for l = 1:CC.NumObjects
                            R(l).NonNullPixOvl = sum(IOvl(CC.PixelIdxList{l})>0);
                        end
                    end
                end
                
                %% For bricked mode: reconnect objects accross bricks
                if BrickMode == 1
                    
                    %% Update brick object start index, compute object partial measurements & save east, west, south and north brick joints to file
                    brckindoff(xindx+1,yindx+1) = brckindx;
                    
                    %% Store brick object geometry (partial) measurements in Meas matrix 
                    Meas = [Meas ; zeros(numel(R),11+2*NChans)];
                    Meas(brckindx+1:brckindx+numel(R),1) = [R.Area];
                    Meas(brckindx+1:brckindx+numel(R),2:4) = repmat([XOff YOff 0],numel(R),1)+reshape([R.Centroid],3,numel(R)).';
                    Meas(brckindx+1:brckindx+numel(R),5:10) = repmat([XOff YOff 0 0 0 0],numel(R),1)+reshape([R.BoundingBox],6,numel(R)).';          
                    
                    %% Store brick object intensity (partial) measurements in Meas matrix
                    if NChans>0
                        Meas(brckindx+1:brckindx+numel(R),11:10+NChans) = reshape([R.MeanInt],NChans,length([R.MeanInt])/NChans).';
                        Meas(brckindx+1:brckindx+numel(R),11+NChans:10+2*NChans) = reshape([R.NonNullPix],NChans,length([R.MeanInt])/NChans).';       
                    end
                    if NChans>1
                        Meas(brckindx+1:brckindx+numel(R),10+2*NChans+1) = [R.NonNullPixOvl];
                    end
                    brckindx = brckindx + numel(R);
                    
                    %% Export brick joints (used to connect objects across bricks)
                    if ~isempty(ReportFolder)
                        imwrite(squeeze(uint16(L(:,end,:))),strcat([ReportFolder 'Tmp/' sprintf('%02d_%02d',xindx,yindx) '_east.tif']));
                        imwrite(squeeze(uint16(L(end,:,:))),strcat([ReportFolder 'Tmp/' sprintf('%02d_%02d',xindx,yindx) '_south.tif']));
                        imwrite(squeeze(uint16(L(:,1,:))),strcat([ReportFolder 'Tmp/' sprintf('%02d_%02d',xindx,yindx) '_west.tif']));
                        imwrite(squeeze(uint16(L(1,:,:))),strcat([ReportFolder 'Tmp/' sprintf('%02d_%02d',xindx,yindx) '_north.tif']));
                    else
                        error('No report folder defined, temporary files for bricked mode cannot be stored');
                    end
                    
                    %% Wander all East-west and South-north brick joints, store object label links to Lnks cell array
                    if k == num_brcks
                        Lnks = cell(brckindx,1);
                        disp(sprintf('Computing object links for %i bricks...',GrdX*GrdY));
                        for jx = 1:GrdX
                            for jy = 1:GrdY
                                %% East-west
                                if jx+1 <= GrdX
                                    peast = single(imdilate(imread(strcat([ReportFolder 'Tmp/' sprintf('%02d_%02d',jx-1,jy-1) '_east.tif'])),ones(3,3))+brckindoff(jx,jy));
                                    pwest = single(imread(strcat([ReportFolder 'Tmp/' sprintf('%02d_%02d',jx,jy-1) '_west.tif'])))+brckindoff(jx+1,jy);
                                else
                                    if exist('peast','var')
                                        peast = single(zeros(size(peast)));
                                        pwest = single(zeros(size(pwest)));
                                    else
                                        peast = '';
                                        pwest = '';
                                    end
                                end
                                pairew = unique([peast(:) pwest(:)],'rows');
                                for km = 1:size(pairew,1)
                                    if pairew(km,1)>brckindoff(jx,jy) & pairew(km,2)>brckindoff(jx+1,jy)
                                        Lnks{pairew(km,1)} = [Lnks{pairew(km,1)} pairew(km,2)];
                                        Lnks{pairew(km,2)} = [Lnks{pairew(km,2)} pairew(km,1)];
                                    end
                                end
                                %% South-north
                                if jy+1 <= GrdY
                                    psouth = single(imdilate(imread(strcat([ReportFolder 'Tmp\' sprintf('%02d_%02d',jx-1,jy-1) '_south.tif'])),ones(3,3))+brckindoff(jx,jy));
                                    pnorth = single(imread(strcat([ReportFolder 'Tmp\' sprintf('%02d_%02d',jx-1,jy) '_north.tif'])))+brckindoff(jx,jy+1);
                                else
                                    if exist('psouth','var')
                                        psouth = single(zeros(size(psouth)));
                                        pnorth = single(zeros(size(pnorth)));
                                    else
                                        psouth = '';
                                        pnorth = '';
                                    end
                                end
                                pairsn = unique([psouth(:) pnorth(:)],'rows');
                                for km = 1:size(pairsn,1)
                                    if pairsn(km,1)>brckindoff(jx,jy) & pairsn(km,2)>brckindoff(jx,jy+1)
                                        Lnks{pairsn(km,1)} = [Lnks{pairsn(km,1)} pairsn(km,2)];
                                        Lnks{pairsn(km,2)} = [Lnks{pairsn(km,2)} pairsn(km,1)];
                                    end
                                end                           
                            end
                        end
                        
                        %% Wander all object links and compute complete object measurements (keep lowest index for final object index)
                        % Measurements are first accumulated to Meas matrix (lowest part index, that is first wandered)
                        disp('Merging object partial measurements...');    
                        for km = 1:brckindx
                            ObjLst = WanderLks(km,Lnks);
                            % This object part has not been wandered yet
                            if Meas(ObjLst,1)>0
                                %% Geometry measurements
                                SumArea = sum(Meas(ObjLst,1));
                                CMx = sum(Meas(ObjLst,2).*Meas(ObjLst,1))/SumArea;
                                CMy = sum(Meas(ObjLst,3).*Meas(ObjLst,1))/SumArea;
                                CMz = sum(Meas(ObjLst,4).*Meas(ObjLst,1))/SumArea;
                                BBxmin = min(Meas(ObjLst,5));
                                BBymin = min(Meas(ObjLst,6));
                                BBzmin = min(Meas(ObjLst,7));
                                BBxmax = max(Meas(ObjLst,5)+Meas(ObjLst,8));
                                BBymax = max(Meas(ObjLst,6)+Meas(ObjLst,9));
                                BBzmax = max(Meas(ObjLst,7)+Meas(ObjLst,10));
                                %% Intensity measurements
                                if NChans>0
                                    for c = 1:NChans
                                        % Mean intensity
                                        Meas(ObjLst(1),10+c) = sum(Meas(ObjLst,10+c).*Meas(ObjLst,1))/SumArea;
                                        % Sum nonull pixels
                                        Meas(ObjLst(1),10+NChans+c) = sum(Meas(ObjLst,10+NChans+c));
                                    end
                                end
                                if NChans>1
                                    % Sum nonull pixels overlap
                                    Meas(ObjLst(1),11+2*NChans) = sum(Meas(ObjLst,11+2*NChans));
                                end
                                Meas(ObjLst(1),1:10) = [SumArea,CMx,CMy,CMz,BBxmin,BBymin,BBzmin,BBxmax,BBymax,BBzmax];
                                %% Set object parts areas to 0 once agglomerated to object part ObjLst(1)
                                if(length(ObjLst)>1)
                                    Meas(ObjLst(2:end),:) = 0;
                                end
                            end
                        end
                        
                        %% Transfer measurements to Rstore structure
                        NonNullObjIndx = find(Meas(:,1)>0);
                        Rstore.Area = Meas(NonNullObjIndx,1);
                        Rstore.Centroid_1 = Meas(NonNullObjIndx,2);
                        Rstore.Centroid_2 = Meas(NonNullObjIndx,3);
                        Rstore.Centroid_3 = Meas(NonNullObjIndx,4);
                        Rstore.BoundingBox_1 = Meas(NonNullObjIndx,5);
                        Rstore.BoundingBox_2 = Meas(NonNullObjIndx,6);
                        Rstore.BoundingBox_3 = Meas(NonNullObjIndx,7);
                        Rstore.BoundingBox_4 = Meas(NonNullObjIndx,8)-Meas(NonNullObjIndx,5);
                        Rstore.BoundingBox_5 = Meas(NonNullObjIndx,9)-Meas(NonNullObjIndx,6);
                        Rstore.BoundingBox_6 = Meas(NonNullObjIndx,10)-Meas(NonNullObjIndx,7);
                        if NChans > 0
                            Rstore.MeanInt = Meas(NonNullObjIndx,11:10+NChans);
                            Rstore.NonNullPix = Meas(NonNullObjIndx,11+NChans:10+2*NChans);
                        end
                        if NChans > 1
                            Rstore.NonNullPixOvl = Meas(NonNullObjIndx,11+2*NChans);
                        end

                    end  
 
                end
                
                %% Display summary and save results
                if k == num_brcks
                    if BrickMode == 0
                        Rstore = R;
                    end
                    if numel([Rstore.Area]) > 0 
                        if NChans>0
                            disp(sprintf('Number of objs: %8i\tSum area    : %i',numel([Rstore.Area]),sum([Rstore.Area])));
                            IntMeans = mean(reshape([Rstore.MeanInt],NChans,length([Rstore.MeanInt])/NChans),2);
                            TotNonNullPix = sum(reshape([Rstore.NonNullPix],NChans,length([Rstore.NonNullPix])/NChans),2);
                            for c = 1:NChans
                                disp(sprintf('Mean intensity:  %8.2f\tNon null pix: %i', IntMeans(c), TotNonNullPix(c)));
                            end
                            if NChans>1
                                TotNonNullPixOvl = sum([R.NonNullPixOvl]);
                                disp(sprintf('\t\t\t\t\t\t\tAll-chan ovl: %i', TotNonNullPixOvl));
                            end
                        else
                            disp(sprintf('Number of objects: %8i\tTotal area (vox): %i',numel([Rstore.Area]),sum([Rstore.Area])));
                        end
                    else
                        disp('No objects to analysize');
                    end

                    %% Save results
                    if ~isempty(ReportFolder)
                        if BrickMode == 0
                            writetable(struct2table(R), strcat([ReportFolder fname(1:end-4) '.csv']),'Delimiter',',');
                        else
                            writetable(struct2table(Rstore), strcat([ReportFolder fname(12:end-4) '.csv']),'Delimiter',',');
                        end
                    end
  
                end
                
                %% STL export
                if ~isempty(ExportMeshFolder)
                    if k == 1 
                       Fstore = [];
                       Vstore = [];
                       cnt = 0;
                    end
                    disp('Generating STL model...');
                    [y,x,z] = meshgrid(1:size(M,2),1:size(M,1),1:size(M,3));
                    [F,V,col] = MarchingCubes(y,x,z,(M>0),0.5);
                    V(:,3) = ZRatio * V(:,3); 
                    if BrickMode == 1
                        if XOff>0 || YOff>0
                            V = V + repmat([XOff-1*(XOff>0) YOff-1*(YOff>0) 0],size(V,1),1);
                        end
                    end
                    FilePath = [ExportMeshFolder fname(1:end-4) '.stl'];
                    disp(['Mesh vertices fraction kept: ' num2str(smp)]);
                    if smp ~= 1
                        [F, V] = reducepatch(F,V,smp);
                    end
                    Fstore = [Fstore;cnt+F];
                    Vstore = [Vstore;V];
                    cnt = cnt + size(V,1);
                    if k == num_brcks
                        if BrickMode == 0
                            FilePath = [ExportMeshFolder fname(1:end-4) '.stl'];
                        else
                            FilePath = [ExportMeshFolder fname(12:end-4) '.stl'];
                        end
                        stlwrite(FilePath, Fstore, Vstore);
                    end
                end
                
            case 'Skls' %% Only geometrical measurements
                
                %% Initialize measurement accumulators
                if k == 1
                    if BrickMode == 0
                        Rstore.nskl = 0;
                    else
                        Rstore.nskl = nan;
                    end
                    Rstore.sklvol = 0;
                    Rstore.skllgth = 0;
                    Rstore.sklbrpts = 0;
                    Rstore.sklenpts = 0;
                    Rstore.objvol = 0;
                    Rstore.imgvol = 0;
                    if NChans>0
                        Rstore.meanint = 0;
                        Rstore.histint = zeros(1,16);
                    end
                end
 
                %% Accumulate image volume
                Rstore.imgvol = Rstore.imgvol + prod(size(M));
                
                %% Skeletons CC analysis
                S = uint8(M >= SklValue);
                connskl = bwconncomp(S);
                nskl = connskl.NumObjects;
                Rstore.nskl = Rstore.nskl + nskl;
                
                %% Compute skeleton volume
                sklvol = sum(S(:));
                Rstore.sklvol = Rstore.sklvol + sklvol;

                %% !! Assume analyzed skeleton !!
                connep = bwconncomp(M==SklEndpts);
                nep = connep.NumObjects;
                connbp = bwconncomp(M==SklBrcpts);
                nbp = connbp.NumObjects;
                Rstore.sklenpts = Rstore.sklenpts+nep;
                Rstore.sklbrpts = Rstore.sklbrpts+nbp;
                
                %% Overall mask volume
                M = uint8(M > 0);
                Rstore.objvol = Rstore.objvol + sum(M(:));
                
                %% Re-analyze skeleton (note: isolated loops are ignored)
                % link nodes indexed as double, should be fine for brick skeleton
                [~, node, link] = Skel2Graph3D(S,0);
                
                %% Compute total skeleton length
                totBrcLgth = 0;
                for il = 1:length(link)
                   [cY cX cZ] = ind2sub(size(M),link(il).point);
                   if numel(cY) >= 2
                       if length(cY) == 3
                           totBrcLgth = totBrcLgth+arclength(cX,cY,cZ*ZRatio);
                       else
                           totBrcLgth = totBrcLgth+arclength(cX,cY,ones(size(cX)));
                       end
                   end
                end
                Rstore.skllgth = Rstore.skllgth + totBrcLgth;
                
                %% Measure mean intensity and object pixels in intensity channel
                if NChans>0
                    if NChans>1
                        error('Only one intensity channel supported for skeletons');
                    end
                    Chan = I(:,:,:,1);
                    Rstore.meanint = Rstore.meanint + mean(Chan(S>0));
                    Rstore.histint = Rstore.histint + hist(single(Chan(S>0)),1:16);
                end
                
                %% Save results
                if k==num_brcks
                    Rstore.skllgth = round(Rstore.skllgth);
                    if NChans>0
                        Rstore.meanint = Rstore.meanint/num_brcks;
                    end
                    Rstore
                    if ~isempty(ReportFolder)
                        if BrickMode == 0
                            writetable(struct2table(Rstore), strcat([ReportFolder fname(1:end-4) '.csv']),'Delimiter',',');
                        else
                            writetable(struct2table(Rstore), strcat([ReportFolder fname(12:end-4) '.csv']),'Delimiter',',');
                        end
                    end
                end
            
                %% OBJ/SWC export
                if ~isempty(ExportMeshFolder)
                    
                    switch SklExport
                        case 'OBJ'
                            disp('Exporting OBJ model...');
                        case 'SWC'
                            disp('Exporting SWC model...');
                    end
                    
                    %% Translate nodes (bricked mode)
                    if BrickMode == 1
                        for l = 1:numel(node)
                            node(l).comx = node(l).comx+XOff-1*(XOff>0);
                            node(l).comy = node(l).comy+YOff-1*(YOff>0);
                        end
                    else
                        XOff = 0;
                        YOff = 0;
                    end
                    cntnode = int64(numel(node));
                    
                    % Explore links to add intermediary points   
                    node2 = node;   %% New nodes: start with all nodes
                    link2 = [];     %% New links
                    cntlink = int64(0);    %% Used to count new links
                    for l = 1:numel(link)
                        linkinds = link(l).point;
                        if numel(linkinds) < (2*smp+1)
                            %% Link is short: do not add any node
                            cntlink = cntlink + 1;
                            link2(cntlink).n1 = int64(link(l).n1);
                            link2(cntlink).n2 = int64(link(l).n2);
                        else
                            %% Link is long: add intermediary nodes (assuming min. 3 pixels in link)
                            newnodesind = linkinds(1:smp:end);
                            if(newnodesind(end) ~= linkinds(end))
                                newnodesind = [newnodesind linkinds(end)];
                            end
                            currnode = link(l).n1;
                            [ypos xpos zpos] = ind2sub(size(M),newnodesind(2:end-1));
                            for j = 1:numel(xpos)
                                node2(cntnode+j).comx = xpos(j)+XOff; 
                                node2(cntnode+j).comy = ypos(j)+YOff;
                                node2(cntnode+j).comz = zpos(j);
                                link2(cntlink+j).n1 = currnode;
                                link2(cntlink+j).n2 = cntnode+j;
                                currnode = cntnode+j;
                            end
                            link2(cntlink+numel(xpos)+1).n1 = currnode;
                            link2(cntlink+numel(xpos)+1).n2 = int64(link(l).n2);
                            cntnode = cntnode + numel(xpos);
                            cntlink = cntlink + numel(xpos)+1;
                        end
                    end
                    
                    %% Export to OBJ
                    switch SklExport
                    case 'OBJ'
                        if BrickMode == 0
                            cnt = int64(0);
                        end
                        if BrickMode == 1 && k == 1
                            cnt = int64(0);objdatastore = [];
                        end
                        if ~isempty(node2)
                            if ~isempty(link2)
                                objarray = cell(numel(node2)+numel(link2),1);
                                %% Encode all links to OBJ format
                                if NChans == 0
                                    for ni = 1:numel(node2)
                                        objarray{ni} = sprintf('v %d %d %d', round(node2(ni).comy),round(node2(ni).comx),round(node2(ni).comz));
                                    end
                                    for ni = numel(node2)+1:numel(node2)+numel(link2)
                                        objarray{ni} = sprintf('l %i %i',cnt+link2(ni-numel(node2)).n1,cnt+link2(ni-numel(node2)).n2);
                                    end
                                else
                                    inds = sub2ind(size(Chan),[node2([link2.n2]).comy]-(YOff-1*(YOff>0)),[node2([link2.n2]).comx]-(XOff-1*(XOff>0)),[node2([link2.n2]).comz]);
                                    rads = round(Chan(uint32(inds)));
                                    for ni = 1:numel(node2)
                                        objarray{ni} = sprintf('v %d %d %d %d',round(node2(ni).comy),round(node2(ni).comx),round(node2(ni).comz),rads(ni));
                                    end
                                    for ni = numel(node2)+1:numel(node2)+numel(link2)
                                        objarray{ni} = sprintf('l %i %i',cnt+link2(ni-numel(node2)).n1,cnt+link2(ni-numel(node2)).n2);
                                    end
                                end
                                cnt = cnt + numel(node2);
                            else
                                objarray = [];
                            end
                        else
                            objarray = [];
                        end
                        if BrickMode == 1
                            if ~isempty(objarray)
                                objdatastore = [objdatastore;objarray];
                            end
                        end
                        if k == num_brcks
                            if BrickMode == 1
                                objarray = objdatastore;
                            end
                            %% Write information to file
                            if BrickMode == 0
                                FilePath = [ExportMeshFolder fname(1:end-4) '.obj'];
                            else
                                FilePath = [ExportMeshFolder fname(12:end-4) '.obj'];
                            end
                            fid = fopen(FilePath,'wt');
                            fprintf(fid,'%s\n',objarray{:});
                            fclose(fid);
                        end

                    case 'SWC'

                        %% Export to SWC (possibly with ghost nodes)
                        if BrickMode == 1 && k == 1
                            cnt = 0;swcdatastore = [];
                        end
                        if ~isempty(node2)
                            if ~isempty(link2)
                                %% Find all nodes that are not referenced as end links (n2), add them as parents before all existing links
                                notdefined = setdiff(int64(1:numel(node2)),int64([link2.n2])).';
                                swcdataparentnodes = [int64(notdefined) int64(ones(numel(notdefined),1)) int64([node2(notdefined).comx]).' int64([node2(notdefined).comy]).' int64(ZRatio*([node2(notdefined).comz].'-1)+1) int64(ones(numel(notdefined),1)) -int64(ones(numel(notdefined),1))];
                                %% Re-index n2 links based on their actual position in link list 
                                sampleindices = [int64(notdefined) ; int64([link2.n2]).'];
                                [~, mappedsampleindices] = ismember(int64([link2.n1]).',sampleindices);
                                %% Encode all links to SWC format  
                                if NChans == 0
                                    swcdata = [int64([link2.n2]).' int64(7*ones(numel(link2),1)) int64([node2([link2.n2]).comx]).' int64([node2([link2.n2]).comy]).' int64(ZRatio*([node2([link2.n2]).comz].'-1)+1) int64(ones(numel(link2),1)) int64(mappedsampleindices)];
                                else
                                    inds = sub2ind(size(Chan),[node2([link2.n2]).comy],[node2([link2.n2]).comx],[node2([link2.n2]).comz]);
                                    rads = Chan(int64(inds));
                                    swcdata = [int64([link2.n2]).' int64(7*ones(numel(link2),1)) int64([node2([link2.n2]).comx]).' int64([node2([link2.n2]).comy]).' int64(ZRatio*([node2([link2.n2]).comz].'-1)+1) int64(rads).' int64(mappedsampleindices)];
                                end
                                swcdata = [swcdataparentnodes;swcdata];
                            else
                                swcdata = [];
                            end    
                        else
                            swcdata = [];
                        end
                        if BrickMode == 1
                            if ~isempty(swcdata)
                                findnoend = find(swcdata(:,7)>-1);
                                swcdata(findnoend,7) = swcdata(findnoend,7)+cnt;
                                cnt = cnt+ size(swcdata,1);
                                swcdatastore = [swcdatastore ; swcdata];
                            end
                        end
                        if k == num_brcks
                            if BrickMode == 1
                                swcdata = swcdatastore;
                            end
                            %% Write information to file
                            lobver = '1.0';
                            swcheader = sprintf('# ORIGINAL_SOURCE LOBSTER %s\n# SCALE 1.0 1.0 %f\n\n',lobver,4.0);
                            if BrickMode == 0
                                FilePath = [ExportMeshFolder fname(1:end-4) '.swc'];
                            else
                                FilePath = [ExportMeshFolder fname(12:end-4) '.swc'];
                            end
                            fid = fopen(FilePath,'wt');
                            fprintf(fid, swcheader);
                            fclose(fid);
                            %% Renumber links in chronological order
                            swcdata(:,1) = (1:size(swcdata,1)).';
                            dlmwrite(FilePath,swcdata,'-append','delimiter',' ','precision', 18);
                        end
                    end   
                end
                
            case 'Spts' %% Position measurements, intensity measurements in a single channel
                
                if NChans > 1
                    error('In spot mode only one channel is supported');
                end
                
                %% Each seed is an independent CC
                CC = bwconncomp(M == SeedsValue);
                R  = regionprops(CC,'BoundingBox');
 
                 %% Each seed is a foreground voxel
%                 Seeds = find(M == SeedsValue);
%                 CC.NumObjects = numel(Seeds);              
%                 CC.PixelIdxList = cell(CC.NumObjects);
%                 for l = 1:CC.NumObjects
%                     CC.PixelIdxList{l} = Seeds(l);
%                 end
%                 if numel(size(M))==3
%                    [CY CX CZ] = ind2sub(size(M),Seeds);
%                    R = struct('BoundingBox', zeros(CC.NumObjects, 6));
%                    for l = 1:CC.NumObjects
%                         R(l).BoundingBox = [CY(l) CX(l) CZ(l) 1 1 1];
%                    end
%                 else
%                    [CY CX] = ind2sub(size(M),Seeds);
%                    R = struct('BoundingBox', zeros(CC.NumObjects, 4));
%                    for l = 1:CC.NumObjects
%                         R(l).BoundingBox = [CY(l) CX(l) 1 1];
%                    end
%                 end
%                 R = R.';
 
                %% If required compute channel mean intensity
                if NChans>0
                    MeanInt = zeros(1,CC.NumObjects);
                    for l = 1:CC.NumObjects
                        R(l).MeanInt = mean(I(CC.PixelIdxList{l}));
                    end
                end
                
                %% Bricked mode
                if BrickMode == 1
                    for l = 1:numel(R)
                        R(l).BoundingBox = R(l).BoundingBox+[xindx*Width yindx*Height 0 0 0 0];
                    end
                    Rstore = [Rstore;R];
                else
                    Rstore = R;
                end               
                
                %% Save results
                if k == num_brcks
                    if NChans>0
                        disp(sprintf('Number of spots: %8i  Mean intensity: %8.2f', numel(Rstore), mean([Rstore.MeanInt])));
                    else
                        disp(sprintf('Number of spots: %8i',numel(Rstore)));
                    end
                    if ~isempty(ReportFolder)
                        if BrickMode == 0
                            writetable(struct2table(Rstore), strcat([ReportFolder fname(1:end-4) '.csv']),'Delimiter',',');
                        else
                            writetable(struct2table(Rstore), strcat([ReportFolder fname(12:end-4) '.csv']),'Delimiter',',');
                        end
                    end
                end    
                
            case 'Trks' %% Geometry measurements, intensity measurements for all channels, no overlap measurements
            
                %% Analyze label mask
                NumObj = max(M(:));
                R  = regionprops(M,'Area','Centroid','PixelIdxList');
                 
                %% Measure mean intensity in intensity channels
                if NChans>0
                    MeanInt = zeros(1,NumObj);
                    for l = 1:numel(R)
                        for c = 1:NChans
                            switch c
                                case 1
                                    R(l).MeanInt1 = mean(I(R(l).PixelIdxList+(c-1)*(prod(size(M)))));
                                case 2
                                    R(l).MeanInt2 = mean(I(R(l).PixelIdxList+(c-1)*(prod(size(M)))));
                                case 3
                                    R(l).MeanInt3 = mean(I(R(l).PixelIdxList+(c-1)*(prod(size(M)))));
                            end 
                        end
                    end
                end
                
                %% Store time point results to cell array
                Area{i,:} = [R.Area];
                if Dim == 2
                    mt = reshape([R.Centroid],2,NumObj).';
                    XPos{i,:} = mt(:,1);
                    YPos{i,:} = mt(:,2);
                else
                    mt = reshape([R.Centroid],3,NumObj).';
                    XPos{i,:} = mt(:,1);
                    YPos{i,:} = mt(:,2);
                    ZPos{i,:} = mt(:,3);
                end
                if NChans>0
                    for c = 1:NChans
                        switch c
                            case 1
                                CIntstore1{i,:} = [R.MeanInt1];
                            case 2
                                CIntstore2{i,:} = [R.MeanInt2];
                            case 3
                                CIntstore3{i,:} = [R.MeanInt3];
                        end 
                    end
                end
                
                %% Export results when reaching last time point
                if i==num_images
                    if ~isempty(ReportFolder)
                        writetable(cell2table(Area), strcat([ReportFolder fname(1:end-4) '_Area.csv']),'Delimiter',',');
                        writetable(cell2table(XPos), strcat([ReportFolder fname(1:end-4) '_CMx.csv']),'Delimiter',',');
                        writetable(cell2table(YPos), strcat([ReportFolder fname(1:end-4) '_CMy.csv']),'Delimiter',',');
                        if Dim>2
                            writetable(cell2table(ZPos), strcat([ReportFolder fname(1:end-4) '_CMz.csv']),'Delimiter',',');
                        end
                        if NChans>0
                            for c = 1:NChans
                                switch c
                                    case 1
                                        writetable(cell2table(CIntstore1), strcat([ReportFolder fname(1:end-4) '_Int1.csv']),'Delimiter',',');
                                    case 2
                                        writetable(cell2table(CIntstore2), strcat([ReportFolder fname(1:end-4) '_Int2.csv']),'Delimiter',',');
                                    case 3
                                        writetable(cell2table(CIntstore3), strcat([ReportFolder fname(1:end-4) '_Int3.csv']),'Delimiter',',');
                                end  
                            end
                        end
                    end
                               
                    %% SWC export
                    if ~isempty(ExportMeshFolder)
                        
                        %% Load division file
                        if exist([MaskFolder 'zzz_DivLog.csv'],'file')>0
                            Div = csvread([MaskFolder 'zzz_DivLog.csv']);
                        else
                            Div = [];
                            warning('No division file found');
                        end
                        
                        %% Export to SWC
                        lobver = '1.0';
                        swcheader = sprintf('# ORIGINAL_SOURCE LOBSTER %s\n# SCALE 1.0 1.0 %f\n\n',lobver,4.0);
                        active = zeros(1,numel(XPos{end}));
                        color = zeros(1,numel(XPos{end}));
                        swcdata = [];
                        cntlink = 0;
                        for f = 1:numel(XPos)
                            for o = 1:numel(XPos{f})
                                if ~isnan(XPos{f}(o))
                                    cntlink = cntlink + 1;
                                    if active(o) == 0
                                        color(o) = 1+mod(o-1,7);
                                        if Dim == 3
                                            swcdata = [swcdata ; int64([cntlink color(o) XPos{f}(o) YPos{f}(o) ZRatio*(ZPos{f}(o)-1)+1 1 -1])];
                                        else
                                            swcdata = [swcdata ; int64([cntlink color(o) XPos{f}(o) YPos{f}(o) ZRatio*f 1 -1])];
                                        end
                                    else
                                        if Dim == 3
                                            swcdata = [swcdata ; int64([cntlink color(o) XPos{f}(o) YPos{f}(o) ZRatio*(ZPos{f}(o)-1)+1 1 active(o)])];
                                        else
                                            swcdata = [swcdata ; int64([cntlink color(o) XPos{f}(o) YPos{f}(o) ZRatio*f 1 active(o)])];
                                        end
                                    end
                                    active(o) = cntlink;
                                end
                                if ~isempty(Div)
                                    inds = find(Div(:,1)==f);
                                    for d = 1:numel(inds)
                                        cntlink = cntlink + 1;
                                        d1 = Div(inds(d),2);
                                        d2 = Div(inds(d),3);
                                        if Dim == 3
                                            swcdata = [swcdata ; int64([cntlink color(d1) XPos{f}(d1) YPos{f}(d1) ZRatio*(ZPos{f}(d1)-1)+1 1 active(d2)])];
                                        else
                                            swcdata = [swcdata ; int64([cntlink color(d1) XPos{f}(d1) YPos{f}(d1) ZRatio*f 1 active(d2)])];
                                        end
                                        color(d2) = color(d1);
                                    end
                                end
                            end
                        end
                        
                        %% Write information to file
                        FilePath = [ExportMeshFolder fname(1:end-4) '.swc'];
                        fid = fopen(FilePath,'wt');
                        fprintf(fid, swcheader);
                        fclose(fid);
                        %% Renumber links in chronological order
                        swcdata(:,1) = (1:size(swcdata,1)).';
                        dlmwrite(FilePath,swcdata,'-append','delimiter',' ','precision', 18);
                    end
                    
                end
            
            case 'Spst'    
            
                if ~exist('smp','var')
                    smp = 3;
                end
                
                if NChans == 1    
                    
                    Rstore.name = Files(i).name;
                    
                    %% it can be used to threshold M at different levels
                    for it = 1:1
                        
                        Rstore.dil = smp;
                        if(it == 2)
                            R = (M>=SeedsValue);
                        else
                            R = (M>=SklEndpts);
                        end
                        if Dim == 2
                            K = I(:,:,1)>=SeedsValue;
                            if (Rstore.dil) > 0
                                se = strel('disk',Rstore.dil);
                            end
                        else
                            K = I(:,:,:,1)>=SeedsValue;
                            if (Rstore.dil) > 0
                                se = strel3d(Rstore.dil);
                            end
                        end
                        
                        if it == 1
                            
                            N = sum(M(:)>0);
                            Rstore.area = N;
                            
                            %% Dice coefficient                    
                            Rstore.dice = 2*nnz(R&K)/(nnz(R) + nnz(K));
                            
                            %% Clusterization coefficients
                            if (Rstore.dil) > 0
                                Rdil = imdilate(R,se);
                                Kdil = imdilate(K,se);
                            else
                                Rdil = R;
                                Kdil = K;
                            end
                                
                            %% Overlap Dice coefficient
                            Rstore.dice_ovl = 2*nnz(Rdil&Kdil)/(nnz(Rdil) + nnz(Kdil));
                            
                            %% Probabilistic co-localization / uniform distribution
                            NA = sum(R(:));
                            NB = sum(K(:));
                            NC = sum(R(:)&K(:));
                            Rstore.frnd = [NB/N NB N];
                            Rstore.fobs = [NC/NA NC NA];
                            %Rstore.pobs1 = nchoosek(NA,NC)*(NB/N)^NC*(1-NB/N)^(NA-NC);
                            %Rstore.pobs2 = normcdf(NC+0.5,NA*NB/N, NA*NB/N*(1-NB/N)) - normcdf(NC-0.5,NA*NB/N, NA*NB/N*(1-NB/N));
                            Rstore.pobs = cdf('Binomial',NC+0.5,NA,NB/N) - cdf('Binomial',NC-0.5,NA,NB/N);
 
                            %% Probabilistic co-localization / independence
                            NAx = sum(R(:)&~K(:));
                            NBx = sum(K(:)&~R(:));
							ND = sum(~K(:)&~R(:));
                            % P(R+|G+)/P(R+)
                            %Rstore.alpha = NC*N/(NA*NB);
							% P(R+|G+)/P(R+|G-)
							Rstore.alpha = NC*(N-NB)/(NBx*(NB));
							% P(R-|G+)/P(R-)
							%Rstore.beta = NBx*N/(NB*(N-NA));
							% P(R-|G+)/P(R-|G-)
							%Rstore.beta = NBx*(N-NA)/((N-NAx-NBx-NC)*(NC+NBx));
							Rstore.beta = NAx*(N-NB)/((N-NAx-NBx-NC)*(N-NA));
                        end

                        %% TP/FP/FN
                        CCr = bwconncomp(Rdil);
                        CCk = bwconncomp(Kdil);
                        L = uint8(zeros(size(R)));
                        for i = 1:CCk.NumObjects
                            L(CCk.PixelIdxList{i}) = sum(K(CCk.PixelIdxList{i})>0);
                        end
                        TP = 0;FP = 0;FN = 0;
                        for i = 1:CCr.NumObjects
                            A = double(sum(R(CCr.PixelIdxList{i})));
                            B = double(max(L(CCr.PixelIdxList{i})));
                            FP = FP + (B>A)*(B-A);
                            FN = FN + (B<A)*(A-B);  
                        end
                        TP = sum(K(:))-FN-FP;
                        Rstore.FP(it) = FP;
                        Rstore.FN(it) = FN;
                        Rstore.TP(it) = TP;
                        
                        if(it == 1)
                            Rstore.rclustA = NA/CCr.NumObjects;
                            Rstore.rclustB = NB/CCk.NumObjects;
                        end
                        
                    end
                    
                else
                    error('Mask mode requires exactly an extra channel');
                end
                
                Rstore
                Rall = [Rall;Rstore];
                
            otherwise
                
                error('Unknown analysis mode');
                
            end 
        end
    end
    
    if ~isempty(Rall)
        writetable(struct2table(Rall), strcat([ReportFolder 'all.csv']),'Delimiter',',');
    end
    
    %% Display hyperlink shortcuts
    disp('-----------------------------------------------');
    disp(strcat('Masks folder:',' <a href="matlab:winopen(''',MaskFolder,''')">',MaskFolder,'</a>'));
    if iscell(ChanFolder)
        for k = 1:numel(ChanFolder)
            disp(strcat('Chan folder:',' <a href="matlab:winopen(''',ChanFolder{k},''')">',ChanFolder{k},'</a>'));
        end
    else
        disp(strcat('Chan folder:',' <a href="matlab:winopen(''',ChanFolder,''')">',ChanFolder,'</a>'));
    end
    disp(strcat('Reports folder:',' <a href="matlab:winopen(''',ReportFolder,''')">',ReportFolder,'</a>'));
    if ~isempty(ExportMeshFolder)
        disp(strcat('Meshes folder:',' <a href="matlab:winopen(''',ExportMeshFolder,''')">',ExportMeshFolder,'</a>'));
    end
end
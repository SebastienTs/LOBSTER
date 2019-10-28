function [M] = fxgs_lPatchClassify3D(I, Mask, L, params)

    % Classify 3D image patches around seed locations (machine learning).
    %
    % Sample journal: <a href="matlab:JENI('Plaques_LocMaxRadFeatRF3D.jls');">Plaques_LocMaxRadFeatRF3D.jls</a>
    %
    % Input: 3D original image, 3D seed mask, optional 3D label mask (annotations)
    % Output: 3D label mask
    %
    % Parameters:
    % FeatType:             'RadFeat3D' or 'Deep'
    % RadFeat3D
    %   ScanRad:            Radial features radius (pix)
    %   ScanStep:           Radial features step (pix)
    %   NAngles:            Radial features number of theta angles
    %   NAngles2:           Radial features number of phi angles
    % Deep
    %   BoxRad:             Box size used for training/prediction
    %   Expand:             Expand training set by 3 mirror reflections
    % ClassifierType:       Random Forest 'RF', Support Vector Machine 'SVM' or Deep learning 'Deep'
    % ClassifierFile:       Path to .mat file to load/save the classifier
    % ExportAnnotations:    Path to .tif file to save annotations

    %% Parameters: features
    FeatType = params.FeatType;
    MaxDisplay = params.MaxDisplay;
    switch FeatType
        case 'RadFeat3D'
            ScanRad = params.ScanRad;
            ScanStep = params.ScanStep;
            NAngles = params.NAngles;
            NAngles2 = params.NAngles2;
        case 'Deep'
            BoxRad = params.BoxRad;
            Expand = params.Expand;
            params.ClassifierType = 'Deep';
        otherwise
            error('Unknown features');
    end
    ClassifierType = params.ClassifierType;
    ClassifierFile = params.ClassifierFile;
    ExportAnnotations = params.ExportAnnotations;
    
    if  ~isempty(I)  
    
    %% Check if JENI was ran from JULI (control image display)
    callers = dbstack;
    callers = {callers.name};
    JULI = any(strcmp(callers,'JULI'));
    if ~exist(ClassifierFile,'file') && JULI == 1
        error('Classifier not available');
    end    
        
    I = single(I);
    L = single(L);
    
	%% Analyze input mask     
    LocMax = find(Mask == 200);
    [PosY PosX PosZ] = ind2sub(size(Mask),LocMax);
    
    %% Compute radial features
    switch FeatType
        case 'RadFeat3D'
            disp('Computing features...');
            %% Extract features
            Rays = ExtractRays3D(I, LocMax.', ScanRad, ScanStep, NAngles, NAngles2);
            %features = reshape(permute(Rays,[2 1 3]),size(Rays,1)*size(Rays,2),size(Rays,3)).';
            raydff = abs(diff(Rays));
            [mxs inds] = max(raydff);
            inds = squeeze(inds);
            indshist = hist(inds,2:1:ScanRad-1);
            Features = [squeeze(mean(Rays(:,:,:),2)).' indshist.'];
            
            %% Validate features (block inside image)
            validfeatures = find(~isnan(sum(Features,2)));
            Features = Features(validfeatures, :);
            validPoints = [PosX(validfeatures) PosY(validfeatures) PosZ(validfeatures)];
            validLocMax = sub2ind(size(I),validPoints(:,2),validPoints(:,1),validPoints(:,3));
        case 'Deep'
            disp('Gathering images...');
            %% Valid blocks
            validpos = find(PosX > BoxRad & PosX < size(I,2)-BoxRad & PosY > BoxRad & PosY < size(I,1)-BoxRad);
            validLocMax = sub2ind(size(I),PosY(validpos),PosX(validpos),PosZ(validpos));
            
            %% Extract image blocks
            Images = zeros(2*BoxRad + 1,2*BoxRad + 1, 1, numel(validpos));
            cnt = 1;
            for i = 1:numel(validpos)
                Images(:,:,1,cnt) = I(PosY(validpos(i))-BoxRad:PosY(validpos(i))+BoxRad,PosX(validpos(i))-BoxRad:PosX(validpos(i))+BoxRad,PosZ(validpos(i)))/255; 
                cnt = cnt+1;
            end
            
    end

    %% Check for existence of classifier / annotation
    AnnotationFile = ~isempty(L);
    
    %% Initial slice to show
    ShowSlice = round(size(I,3)/2);
    
    %% Check for existence of classifier
    if ~exist(ClassifierFile,'file')
        disp('No classifier file found');
        if AnnotationFile
            use = questdlg('Found annotation image, use it? (or build manual annotation anew)');
            switch use 
                case'Yes'
                    Classes = unique(L(:));
                    Classes(Classes == 0) = [];
                    Classes = numel(Classes);
                    edit = 'No';
                case 'No'
                    switch ClassifierType
                        case 'SVM'
                            answer = inputdlg('Number of classes (max 2)?');
                        case 'RF'
                            answer = inputdlg('Number of classes (max 4)?');
                        case 'Deep'
                            answer = inputdlg('Number of classes (max 4)?');
                    end
                    Classes = str2num(answer{1});
                    L = uint16(zeros(size(I)));
            end
        else
            switch ClassifierType
                case 'SVM'
                    answer = inputdlg('No annotation image found, number of classes (max 2)?');
                case 'RF'
                    answer = inputdlg('No annotation image found, number of classes (max 4)?');
                case 'Deep'
                    answer = inputdlg('No annotation image found, number of classes (max 4)?');
            end
            Classes = str2num(answer{1});
            L = uint16(zeros(size(I)));
        end
        
        %% Check number of classes
        if (Classes>2)&(strcmp(ClassifierType,'SVM')==1)
            error('SVM can only handle 2 classes');
        end
        if (Classes>4)
            error('Only up to 4 classes supported');
        end
        
        %% Manual edition of the annotation mask
        MoreAnnotation = 1;
        while MoreAnnotation

            %% Valid annotations: train + predict
            if max(L(:)) > 0
                
                %% Training classifier
                switch ClassifierType
                    case 'SVM'
                        %% Building training set
                        inds = find(L(validLocMax)>0);
                        group = L(validLocMax(inds));
                        feats = [Features(inds,:)];
                        %% Train classifier
                        disp('Training SVM...');      
                        svmStruct = svmtrain(feats,group,'kernel_function','polynomial','tolkkt',0.001,'kktviolationlevel',0.01);
                    case 'RF'
                        %% Building training set
                        inds = find(L(validLocMax)>0);
                        group = L(validLocMax(inds));
                        feats = [Features(inds,:)];
                        %% Train classifier
                        disp('Training RF...');
                        RFStruct = TreeBagger(50,feats,group,'Method','classification');
                    case 'Deep'
                        %% Prepare annotations for training
                        cnt = 1;cnt2 = 1;selmax = [];
                        Lbl = zeros(numel(validpos),1);
                        for i = 1:numel(validpos)
                            if L(PosY(validpos(i)),PosX(validpos(i)),PosZ(validpos(i))) > 0
                                Lbl(cnt) = L(PosY(validpos(i)),PosX(validpos(i)),PosZ(validpos(i)));
                                selmax = [selmax cnt2];
                                cnt = cnt+1;
                            end
                            cnt2 = cnt2+1;
                        end
                        switch Classes
                            case 2
                                labels = categorical({'1' ; '2'});
                            case 3
                                labels = categorical({'1' ; '2' ; '3'});
                            case 4
                                labels = categorical({'1' ; '2'; '3'; '4'});
                        end  
                        Lbl = labels(Lbl(1:cnt-1));
                        TrainImages = Images(:,:,1,selmax);
                        
                        %% Training set expansion
                        if Expand
                            TrainImages = cat(4,TrainImages,fliplr(Images(:,:,1,selmax)));
                            TrainImages = cat(4,TrainImages,flipud(Images(:,:,1,selmax)));
                            TrainImages = cat(4,TrainImages,fliplr(flipud(Images(:,:,1,selmax))));
                            Lbl = [Lbl;Lbl;Lbl;Lbl];
                        end
                        
                        %% Define deep network
                        if ~exist('layers','var')
                            rng('default');
                            layers = [ ...
                            imageInputLayer([2*BoxRad+1 2*BoxRad+1 1])
                            convolution2dLayer([9 9],100,'Stride',1)
                            reluLayer
                            maxPooling2dLayer(Classes,'Stride',2)
                            convolution2dLayer([5 5],25,'Stride',1)
                            reluLayer
                            maxPooling2dLayer(Classes,'Stride',2)
                            fullyConnectedLayer(Classes)
                            softmaxLayer
                            classificationLayer];
                        end
                        
                        %% Train deep network on valid positions 
                        disp('Training deep network...');
                        options = trainingOptions('sgdm', 'MaxEpochs', 100, 'MiniBatchSize', 8);
                        net = trainNetwork(TrainImages,Lbl,layers,options);
                end
                              
                %% Predict
                switch ClassifierType
                    case 'SVM'
                        disp('SVM prediction...'); 
                        preds = uint16(svmclassify(svmStruct,Features));
                    case 'RF'
                        disp('RF prediction...'); 
                        preds = uint16(cellfun(@str2num,predict(RFStruct,Features)));
                    case 'Deep'
                        disp('Deep network prediction...');
                        preds = classify(net,Images);
                        preds = uint16(grp2idx(preds));
                end
            
            else
                
                preds = uint16(5*ones(size(validLocMax)));
                
            end
                 
            %% Draw prediction
            Msk2 = uint8(zeros(size(I)));
            Msk2(validLocMax) = 200-(preds==5)*20+(preds==1)*20+(preds==3)*22+(preds==4)*24;
            Msk2 = imdilate(Msk2,ones(5,5));
            handle = figure('Name',strcat('Prediction: shift to annotate slice, close window to keep classifier'),'NumberTitle','off');
            tool = imtool3DLbl(I,[0 0 1 1],handle);
            setWindowLevel(tool,2*MaxDisplay,MaxDisplay);
            setCurrentSlice(tool,ShowSlice);
            setMask(tool,Msk2);
            setAlpha(tool,1);
            
            %% Handle user action
            edit = 'Yes';
            w = 0;
            while w == 0
                if isvalid(handle)
                    if strcmp(get(gcf,'CurrentModifier'),'shift');
                        ShowSlice = getCurrentSlice(tool);
                        w = 1; 
                    end
                    pause(0.05);
                else
                    edit = 'No';
                    w = 1;
                end
            end

            switch edit
            case 'Yes'
                
                for c = 1:Classes
                    disp(sprintf('Draw annotation for class %i (slice %i)',c,ShowSlice));
                    stop = 0;
                    Hacc = [];
                    while stop == 0
                        H = imrect();
                        pos = getPosition(H);
                        stop = ((pos(3)<2)|(pos(4)<2));
                        if stop == 0
                            pos = round(pos);
                            L(max(pos(2),1):min(pos(2)+pos(4),size(I,1)),max(pos(1),1):min(pos(1)+pos(3),size(I,2)),ShowSlice) = c;
                        end
                        Hacc = [Hacc H];
                    end
                    delete(Hacc);
                end
                close all;
                
            case 'Cancel'
                close all;
                error('Script was stopped by user');
            
            case 'No'
                edit = questdlg('Save annotation image?');
                switch edit
                    case 'Yes'
                        disp(strcat('Annotation image exported to: ',ExportAnnotations));
                        imwrite(uint16(L(:,:,1)),ExportAnnotations,'tif','Compression','deflate');
                        for i = 2:size(L,3)
                            imwrite(uint16(L(:,:,i)),ExportAnnotations,'tif','WriteMode','append','Compression','deflate');
                        end
                    case 'Cancel'
                        close all;
                        error('Script was stopped by user');
                end
                close all;
                MoreAnnotation = 0;
            end         
        end
        
        %% Save classifier
        switch ClassifierType
            case 'SVM'
                save(ClassifierFile, 'svmStruct');
            case 'RF'
                save(ClassifierFile, 'RFStruct');
            case 'Deep'
                save(ClassifierFile, 'net');      
        end
        
        else
          
            %% Load classifier
            switch ClassifierType
                case 'SVM'
                    load(ClassifierFile, 'svmStruct');
                case 'RF'
                    load(ClassifierFile, 'RFStruct');
                case 'Deep'
                    load(ClassifierFile, 'net');
            end
            
            %% Predict
            switch ClassifierType
                case 'SVM'
                    disp('SVM prediction...');
                    preds = uint16(svmclassify(svmStruct,Features));
                case 'RF'
                    disp('RF prediction...');
                    preds = uint16(cellfun(@str2num,predict(RFStruct,Features)));
                case 'Deep'
                    disp('Deep network prediction...');
                    preds = classify(net,Images);
                    preds = uint16(grp2idx(preds));
            end
        
    end
    
        %% Build result map
        M = uint8(zeros(size(I)));
        M(validLocMax) = 200+(preds==1)*20+(preds==3)*22+(preds==4)*24;
        M = imdilate(M,ones(5,5));
    
    else
        
        M = [];
        
    end

end
function [L] = fxgs_lPatchClassify(I, SigMax, L, params)

    % Classify image patches around seed locations (machine learning).
    %
    % Sample journal: <a href="matlab:JENI('NucleiDAB_LocMaxHoGRF.jl');">NucleiDAB_LocMaxHoGRF.jl</a>
    %
    % Input: 2D original image, 2D seed mask, optional 2D label mask (annotations)
    % Output: 2D label mask
    %
    % Parameters:
    % FeatType:             'RadFeat', 'HoG' or 'Deep'
    % RadFeat
    %   ScanRad:            Radial features radius (pix)
    %   ScanStep:           Radial features step (pix)
    %   NAngles:            Radial features number of angles
    % HoG
    %   BoxSize:            HoG features cell size
    %   Sub:                HoG number of cells by classification block
    %   NumBins:            HoG orientation histogram bins
    % Deep
    %   BoxRad:             Box size used for training/prediction
    %   Expand:             Expand training set by 3 mirror reflection
    % ClassifierType:       Random Forest 'RF', Support Vector Machine 'SVM' or Deep learning 'Deep'
    % ClassifierFile:       Path to .mat file to load/save the classifier
    % ExportAnnotations:    Path to .tif file to save annotations
    
    %% Parameters: features
    FeatType = params.FeatType;
    switch FeatType
        case 'RadFeat'
            ScanRad = params.ScanRad;
            ScanStep = params.ScanStep;
            NAngles = params.NAngles;  
        case 'HoG'
            BoxSize = params.BoxSize;
            Sub = params.Sub;
            NumBins = params.NumBins;
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

    if ~isempty(I)
    
    %% Check if JENI was ran from JULI (control image display)
    callers = dbstack;
    callers = {callers.name};
    JULI = any(strcmp(callers,'JULI'));
    if ~exist(ClassifierFile,'file') && JULI == 1
        error('Classifier not available');
    end      
        
    I = single(I);
    L = uint16(L);
    edit = [];
        
    %% Find positions of local maxima
    LocMax = find(SigMax(:)==200);
    [PosY PosX] = ind2sub(size(SigMax),LocMax);

    switch FeatType
        case 'RadFeat'
            %% Compute radial features
            Rays = ExtractRays(I, LocMax.', ScanRad, ScanStep, NAngles);
            %features = reshape(permute(Rays,[2 1 3]),size(Rays,1)*size(Rays,2),size(Rays,3)).';
            raydff = abs(diff(Rays));
            [mxs inds] = max(raydff);
            inds = squeeze(inds);
            indshist = hist(inds,2:1:ScanRad-1);
            Features = [squeeze(mean(Rays(:,:,:),2)).' indshist.'];
            %% Validate features (block inside image)
            validfeatures = find(~isnan(sum(Features,2)));
            Features = Features(validfeatures, :);
            validPoints = [PosX(validfeatures) PosY(validfeatures)];
            validLocMax = sub2ind(size(I),validPoints(:,2),validPoints(:,1));
        case 'HoG'
            [Features, validPoints, hogVisualization] = extractHOGFeatures(I, [PosX PosY],'CellSize',[BoxSize BoxSize],'BlockSize',[Sub Sub],'NumBins', NumBins, 'UseSignedOrientation', true); 
            Features = [Features zeros(size(Features,1),8)];
            for i = 1:size(validPoints,1)
                Pix = I(ceil(max(validPoints(i,2)-Sub*BoxSize/2,1)):floor(min(validPoints(i,2)+Sub*BoxSize/2,size(I,1))),ceil(max(validPoints(i,1)-Sub*BoxSize/2,1)):floor(min(validPoints(i,1)+Sub*BoxSize/2,size(I,2))));
                Features(i,end-7:end) = hist(Pix(:),[0:32:255]);
            end
            validLocMax = sub2ind(size(I),validPoints(:,2),validPoints(:,1));
            %% Display HoG
            %figure;imagesc(I);colormap(gray);hold on;
            %plot(hogVisualization);
        case 'Deep'
            %% Valid blocks
            validpos = find(PosX > BoxRad & PosX < size(I,2)-BoxRad & PosY > BoxRad & PosY < size(I,1)-BoxRad);
            validLocMax = sub2ind(size(I),PosY(validpos),PosX(validpos));
            
            %% Extract image blocks
            Images = zeros(2*BoxRad + 1,2*BoxRad + 1, 1, numel(validpos));
            cnt = 1;
            for i = 1:numel(validpos)
                Images(:,:,1,cnt) = I(PosY(validpos(i))-BoxRad:PosY(validpos(i))+BoxRad,PosX(validpos(i))-BoxRad:PosX(validpos(i))+BoxRad)/255; 
                cnt = cnt+1;
            end   
    end
    
    %% Check for existence of classifier / annotation
    AnnotationFile = ~isempty(L);
    
    if ~exist(ClassifierFile, 'file')
        disp('No classifier file found');
        Idet = single(I);
        Idet = Idet/max(Idet(:));
        if AnnotationFile == 1
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
            if max(L(:))==0
                edit = 'Yes';
            else
                if isempty(edit)
                    edit = questdlg('Edit annotation image?');
                end
            end
        switch edit
            case 'Yes'
                if MoreAnnotation < 2 %% Else we keep the prediction image
                    close all;
                    Msk = single(zeros(size(I)));
                    Msk(validLocMax) = L(validLocMax)+5*uint16(L(validLocMax)==0);
                    Msk = imdilate(Msk,ones(5,5));
                    indclass = find(Msk>0);
                    Mskclass = Msk(indclass);
                    MergeR = Idet;MergeG = Idet;MergeB = Idet;
                    MergeR(indclass) = (Mskclass == 2)|(Mskclass == 4);
                    MergeG(indclass) = (Mskclass == 2)|(Mskclass == 3)|(Mskclass == 5);
                    MergeB(indclass) = (Mskclass == 1)|(Mskclass == 3)|(Mskclass == 4);
                    rgb(:,:,1) = MergeR;rgb(:,:,2) = MergeG;rgb(:,:,3) = MergeB;    
                    imagesc(rgb);
                    title('Current annotations');
                end
                for c = 1:Classes
                    title(strcat('Draw annotation for class: ',num2str(c)));
                    stop = 0;
                    Hacc = [];
                    while stop == 0
                        H = imrect();
                        pos = getPosition(H);
                        stop = ((pos(3)<2)|(pos(4)<2));
                        if stop == 0
                            pos = round(pos);
                            L(max(pos(2),1):min(pos(2)+pos(4),size(I,1)),max(pos(1),1):min(pos(1)+pos(3),size(I,2))) = c;
                        end
                        Hacc = [Hacc H];
                    end
                    delete(Hacc);
                end   
            case 'Cancel'
                error('Script was stopped by user');       
        end

        %% Training classifier
        switch ClassifierType
            case 'SVM'
                disp('Training SVM...');   
                %% Build training set
                inds = find(L(validLocMax));
                group = L(validLocMax(inds));
                feats = [Features(inds,:)];
                svmStruct = svmtrain(feats,group,'kernel_function','polynomial','tolkkt',0.001,'kktviolationlevel',0.01);
            case 'RF'
                disp('Training RF...');
                %% Build training set
                inds = find(L(validLocMax));
                group = L(validLocMax(inds));
                feats = [Features(inds,:)];
                RFStruct = TreeBagger(50,feats,group,'Method','classification');
            case 'Deep'
                disp('Training RF...');
                %% Prepare annotations for training
                cnt = 1;cnt2 = 1;selmax = [];
                Lbl = zeros(numel(validpos),1);
                for i = 1:numel(validpos)
                    if L(PosY(validpos(i)),PosX(validpos(i))) > 0
                        Lbl(cnt) = L(PosY(validpos(i)),PosX(validpos(i)));
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
                options = trainingOptions('sgdm', 'MaxEpochs', 100, 'MiniBatchSize', 16);
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
        
        %% Draw prediction
        close all;
        Msk = single(zeros(size(I)));
        Msk(validLocMax) = preds;
        Msk = imdilate(Msk,ones(5,5));
        indclass = find(Msk>0);
        Mskclass = Msk(indclass);
        MergeR = Idet;MergeG = Idet;MergeB = Idet;
        MergeR(indclass) = (Mskclass == 2)|(Mskclass == 4);
        MergeG(indclass) = (Mskclass == 2)|(Mskclass == 3);
        MergeB(indclass) = (Mskclass == 1)|(Mskclass == 3)|(Mskclass == 4);
        rgb(:,:,1) = MergeR;rgb(:,:,2) = MergeG;rgb(:,:,3) = MergeB;
        imagesc(rgb);
        title('Current prediction (left click to proceed)');
        waitforbuttonpress;
        edit = questdlg('Edit annotation image?');
        
        switch edit
            case 'Yes'
                MoreAnnotation = 2;
            case 'Cancel'
                error('Script was stopped by user');
            otherwise
                disp(strcat('Annotation image exported to ',ExportAnnotations));
                imwrite(uint16(L),ExportAnnotations,'tif','Compression','deflate');
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
    
    %% Compute accuracy if annotation file was provided
    if AnnotationFile == 1
        inds = find(L(validLocMax));
        group = L(validLocMax(inds));
        disp(sprintf('\n'));
        disp(100-100*sum(abs(group-preds(inds)))/numel(group));
        C = confusionmat(preds(inds),group);
        disp(sprintf('\n'));
        disp(C);
    end
    
    %% Build result map
    L = uint8(zeros(size(I)));
    L(validLocMax) = 200+(preds==1)*20+(preds==3)*22+(preds==4)*24;

    else
       
        L = [];
        
    end
    
end
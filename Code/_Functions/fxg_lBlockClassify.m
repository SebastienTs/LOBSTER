function M = fxg_lBlockClassify(I, L, params)

    % Subdivide image in blocks, extract block features and classify blocks (supervised machine learning).
    %
    % Sample journal: <a href="matlab:JENI('Kidney_BlockClassify.jl');">Kidney_BlockClassify.jl</a>
    % 
    % Input: 2D grasycale image
    % Output: 2D label mask
    %
    % Parameters:
    % BlckSize:             Block size (pix)
    % Feat:                 'mnstd' 'hist' 'mnstdlbphf' 'mnstdlpqdsc' 'mnstdriglcm' 'mnstdbifs'
    % ClassifierType:       'RF' Random Forest or 'SVM' Support Vector Machine
    % ClassifierFile:       Path to .mat file to load/save the classifier
    % ExportAnnotations:    Path to .tif image to save annotations
    
    %% Parameters
    BlckSize = params.BlckSize;
    Feat = params.Feat;
    ClassifierType = params.ClassifierType;
    ClassifierFile = params.ClassifierFile;
    ExportAnnotations = params.ExportAnnotations;
    
    glcmoffs = [ 0 1; 0 2; 0 3; 0 4;...
           -1 1; -2 2; -3 3; -4 4;...
           -1 0; -2 0; -3 0; -4 0;...
           -1 -1; -2 -2; -3 -3; -4 -4];
       
    if ~isempty(I)   
       
        I = double(I);
        L = uint16(L);   

        %% Set block positions
        [X,Y] = meshgrid(round(BlckSize/2):BlckSize:size(I,2)-round(BlckSize/2),round(BlckSize/2):BlckSize:size(I,1)-round(BlckSize/2));

        %% Compute radial features
        switch Feat
             case 'mnstd'
                Features = zeros(numel(X),2);
             case 'hist'
                Features = zeros(numel(X),8);
             case 'mnstdlbphf'
                lbpmapping9 = getmaplbphf(9);
                Features = zeros(numel(X),45); 
             case 'mnstdlpqdsc'
                 Features = zeros(numel(X),34);
                 LPQfilters = createLPQfilters(7,36);
             case 'mnstdriglcm'
                 Features = zeros(numel(X),2*numel(glcmoffs)/2+2); 
             case 'mnstdbifs'   
                 Features = zeros(numel(X),30);
            otherwise
                 error('Unknown features');
        end 

        for i = 1:numel(X)
            PatchA = I(Y(i)-round(BlckSize/2)+1:Y(i)+round(BlckSize/2)-1,X(i)-round(BlckSize/2)+1:X(i)+round(BlckSize/2)-1);
            switch Feat
                case 'mnstd'
                    Features(i,:) = [mean(PatchA(:)) std(PatchA(:))];
                case 'hist'
                    Features(i,:) = [hist(PatchA(:),0:32:255)];
                case 'mnstdlbphf'
                    h2 = lbp(PatchA,2,9,lbpmapping9,'nh');
                    lbp_hf_features2 = constructhf(h2,lbpmapping9);
                    Features(i,:) = [mean(PatchA(:)) std(PatchA(:)) lbp_hf_features2];
                case 'mnstdlpqdsc'
                    LPQdesc = ri_lpq(PatchA,LPQfilters,'','nh');
                    mat = reshape(LPQdesc,8,32);
                    Features(i,:) = [mean(PatchA(:)) std(PatchA(:)) sum(mat)];
                case 'mnstdriglcm'
                    glcm = graycomatrix(PatchA,'GrayLimits',[0 255],'NumLevels',32,'Offset',glcmoffs,'Symmetric',true);
                    glcmstats = graycoprops(glcm, {'Contrast','Correlation','Energy','Homogeneity'});
                    glcmvec = [glcmstats.Contrast glcmstats.Correlation glcmstats.Energy glcmstats.Homogeneity];
                    glcmmat = reshape(glcmvec,4,numel(glcmvec)/4);
                    glcmmeanstdvec = [mean(glcmmat) range(glcmmat)];
                    Features(i,:) = [mean(PatchA(:)) std(PatchA(:)) glcmmeanstdvec];
                 case 'mnstdbifs'
                    [bifs1,jet] = computeBIFs(PatchA, 1, 0.03);
                    [bifs2,jet] = computeBIFs(PatchA, 2, 0.03);
                    [bifs4,jet] = computeBIFs(PatchA, 4, 0.03);
                    [bifs8,jet] = computeBIFs(PatchA, 8, 0.03);
                    Features(i, :) = [mean(PatchA(:)) std(PatchA(:)) hist(bifs1(:),1:7) hist(bifs2(:),1:7) hist(bifs4(:),1:7) hist(bifs8(:),1:7)];      
            end        
        end

        %% Index of valid maxima
        validLocMax = sub2ind(size(I),Y,X);

        %% Check for existence of classifier / annotation
        edit = [];
        if ~isempty(L)
            AnnotationFile = 1;
        else
            AnnotationFile = 0;
        end
        if ~exist(ClassifierFile)
            Idet = single(I);
            Idet = Idet/max(Idet(:));
            if AnnotationFile == 1
                use = questdlg('Found annotation image, use it?');
                switch use 
                    case'Yes'
                        Classes = unique(L(:));
                        Classes(Classes == 0) = [];
                        Classes = numel(Classes);
                    case 'No'
                        answer = inputdlg('Number of classes (max 4)?');
                        Classes = str2num(num2str(answer{1})); 
                        L = uint16(zeros(size(I)));
                end
            else
                answer = inputdlg('Number of classes (max 4)?');
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

            %% Build training set
            inds = find(L(validLocMax));
            group = L(validLocMax(inds));
            feats = [Features(inds,:)];

            %% Training classifier
            switch ClassifierType
                case 'SVM'
                    disp('Training SVM...');      
                    svmStruct = svmtrain(feats,group,'kernel_function','polynomial','tolkkt',0.001,'kktviolationlevel',0.01);
                case 'RF'
                    disp('Training RF...');
                    RFStruct = TreeBagger(50,feats,group,'Method','classification');
            end

            %% Predict
            switch ClassifierType
                case 'SVM'
                    disp('SVM prediction...'); 
                    preds = uint16(svmclassify(svmStruct,Features));
                case 'RF'
                    disp('RF prediction...'); 
                    preds = uint16(cellfun(@str2num,predict(RFStruct,Features)));
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
            title('Current prediction (click image to proceed)');
            waitforbuttonpress;
            edit = questdlg('Edit annotation image?');

            switch edit
                case 'Yes'
                    MoreAnnotation = 2;
                case 'Cancel'
                    error('Script was stopped by user');
                otherwise
                    edit = questdlg('Save annotation image?');
                    switch edit
                        case 'Yes'
                            disp(strcat('Annotation image exported to ',ExportAnnotations));
                            imwrite(uint16(L),ExportAnnotations,'tif','Compression','deflate');
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
            end

        else

            %% Load classifier
            switch ClassifierType
                case 'SVM'
                    load(ClassifierFile, 'svmStruct');
                case 'RF'
                    load(ClassifierFile, 'RFStruct');
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
        M = uint8(zeros(size(I)));
        M(validLocMax) = 200+(preds==1)*20+(preds==3)*22+(preds==4)*24;
    
    else
       
        M = [];
        
    end

end
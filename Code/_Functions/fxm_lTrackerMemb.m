function [] = fxm_lTrackerMemb(InputFolder,OutputFolder,params)

    % Track tissue packing cells in binary mask.
    %
    % Sample journal: <a href="matlab:JENI('TissueSimpleMovie_TrackMemb.jlm');">TissueSimpleMovie_TrackMemb.jlm</a>
    %
    % Input: 2D+T binary mask, 2D+T label mask
    % Output: None (write results to files)
    %
    % Parameters:
    % ShareAreaFrc:     Minimum area fraction overlap for particle linking (1 to 1 overlap)
    % WinAreaFrc:       Minimum area fraction overlap for particle (n to n overlap)

    %% TODO: handle divisions relabelling 

    %% Parameters
    ShareAreaFrc = params.ShareAreaFrc;
    WinAreaFrc = params.WinAreaFrc;

    se = strel('square',3);  % Structure element used for overlap map dilations (outside objects and inside particles)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    Files = dir(strcat([InputFolder '*.tif']));
    num_images = numel(Files);

    Export = 1;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    clear textprogressbar;
    textprogressbar('Processing...');

    for kf = 1:num_images

        textprogressbar(round(100*kf/num_images));

        A = imread(strcat([InputFolder Files(kf).name]));
        A = (A > 0);
        A = imclearborder(A); % Remove objects touching the edges

        %% Connected particles at current iteration
        CC = bwconncomp(A==1, 8);
        Particles = CC.PixelIdxList;    
        Npart = length(Particles);

        %% Fill particle label map + compute particle statistics
        PartLbl = zeros(size(A));
        AreaPart = zeros(1,Npart);
        for i = 1:Npart
            PartLbl(Particles{i}) = i; 
            AreaPart(i) = length(Particles{i});
        end

        if kf > 1

            %% Compute particle overlap map
            OvlMap = zeros(size(A));
            for i = 1:Npart
                OvlMap(Particles{i}) = ObjLbl(Particles{i});
            end

        end

        if kf == 1
            %% all particles --> objects (first frame)
            ObjLbl = PartLbl;
            AreaObj = AreaPart;
            LastAreaObj = AreaObj;
            Nobj = Npart;
            ScaleImg = Nobj;

        else

            %% Find subparticles (same object label) and compute their statistics 
            PartObjIndx = cell(1,Npart);
            PartObjArea = cell(1,Npart);
            for i = 1:Npart
                Indx = OvlMap(Particles{i}).';
                UniqueIndx = unique(Indx);
                UniqueIndx = unique(Indx);
                UniqueIndx(UniqueIndx==0) = [];

                PartObjIndx{i} = UniqueIndx;
                AreaVector = zeros(1,length(UniqueIndx));
                for k =1:length(UniqueIndx)
                    Msk = (Indx==UniqueIndx(k));
                    AreaVector(k) = sum(Msk);
                end
                PartObjArea{i} = AreaVector;
            end

            %% Assign object label based on dominant overlapping object
            ObjLbl = OvlMap;
            ObjMult = zeros(1,Nobj);
            for i = 1:Npart
                AreaVec = PartObjArea{i};
                Indx = PartObjIndx{i};
                [mx indmx] = max(AreaVec);
                if(not(isempty(Indx)))
                    IndmxObj = Indx(indmx);
                    % One object is largely dominant
                    if (mx>WinAreaFrc*AreaPart(i)) || (mx>ShareAreaFrc*AreaPart(i) && length(Indx)==1)  
                        ObjLbl(Particles{i}) = IndmxObj;
                        ObjMult(IndmxObj) = ObjMult(IndmxObj)+1;
                    end
                end   
            end

            % Find shared particles (under-segmentation)
            for i = 1:Npart
                AreaVec = PartObjArea{i};
                Indx = PartObjIndx{i};
                [mx indmx] = max(AreaVec);
                IndmxObj = Indx(indmx);
                if(~(isempty(Indx)))
                    IndRmObj = Indx;
                    IndRmObj(indmx)=[];
                    if ObjMult(IndmxObj) == 0 % Not assigned as dominant object
                        if (mx<ShareAreaFrc*AreaPart(i))
                            ObjLbl(Particles{i}) = 0;
                        else 
                            if isempty(find(ObjMult(IndRmObj)==0)) % All other objects overlapping the particle have already been already assigned
                                ObjLbl(Particles{i}) = IndmxObj;
                                ObjMult(IndmxObj) = ObjMult(IndmxObj)+1;
                            else % sharing
                                ObjMult(Indx) = ObjMult(Indx)+1;
                            end
                        end 

                    end

                end
            end

            %% Expand objects to particle borders
            Mask = imclose(PartLbl>0,se); % interior: particles + edges 
            test = 1;
            cnt = 0;
            while test>0
                ObjLblBuf = imdilate(ObjLbl,se).*(PartLbl>0);
                ObjLblNew = (ObjLbl==0).*ObjLblBuf+(ObjLbl>0).*ObjLbl;
                ObjLblNew = ObjLblNew.*Mask;
                Dif = ObjLblNew-ObjLbl;
                test = any(Dif(:));
                cnt = cnt+1;
                ObjLbl = ObjLblNew;
            end
            %disp(strcat('Iteration performed:',num2str(cnt))); 

            %% Handle object merging
            ObjLblClosed = imclose(ObjLbl,se);
            for i=1:Nobj
                %if ObjMult(i)>1 % various particles assigned to the same object  
                    CC = bwconncomp(ObjLblClosed==i, 8);
                    %if CC.NumObjects==1 % particles are closely touching: candidate merging
                    for j=1:CC.NumObjects
                        ObjLbl(CC.PixelIdxList{j}) = i;
                    end
                    %end
                %end
            end

            %% Handle object appearances
            ObjLblDilate = imdilate(ObjLbl,se);
            DiffMask = imclose(((PartLbl>0)-(ObjLblDilate>0))>0,se);
            if any(any(DiffMask,1))
                CC = bwconncomp(DiffMask, 8);
                for i=1:CC.NumObjects
                    NewArea = length(CC.PixelIdxList{i});
                    Nobj = Nobj+1;
                    IndxObj = Nobj;
                    ObjLbl(CC.PixelIdxList{i}) = IndxObj;
                    AreaObj(IndxObj) = NewArea;
                end
            end

            %% Redraw boundaries
            ObjDilate = imdilate(ObjLbl,se);
            ObjLblBnd = ObjLbl;
            ObjLblBnd(ObjDilate~=ObjLbl) = 0;
            ObjLbl = ObjLblBnd;

        end

        %% Export object label map
        if Export==1
            imwrite(uint16(ObjLbl), strcat(OutputFolder,Files(kf).name), 'Compression','deflate');
        end

    end

    clear textprogressbar;
    disp(' ');

end
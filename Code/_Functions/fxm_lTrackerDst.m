
function [] = fxm_lTrackerDst(InputFolder,OutputFolder,params)

    % Track objects in binary mask time-lapse by locally minimizing centers of mass displacements.
    %
    % Sample journal: <a href="matlab:JENI('FakeTrackMovie_TrackDst.jlm');">FakeTrackMovie_TrackDst.jlm</a>
    %
    % Input: 2D+T binary mask, 2D+T label mask
    % Output: None (write results to files)
    %
    % Parameters:
    % MinPartArea:          Minimum particle area (pix)
    % MaxAreaVar:           Maximum object relative area variation (fraction)
    % MaxDisp:              Maximum object displacement (pix)
    % MaxRescue:            Maximum number of frames for object rescue (clumping / disapearance)
    % EnforceOverlap:       If set to 1 two particles must overlap from frame to frame to be linked

    %% Parameters
    MinPartArea = params.MinPartArea;
    MaxAreaVar = params.MaxAreaVar;
    MaxDisp = params.MaxDisp;
    MaxRescue = params.MaxRescue;
    RemoveEdgeObj = params.RemoveEdgeObj;
    EnforceOverlap = params.EnforceOverlap;
    se = strel('disk',1); % Structure element for dilation
    % Options
    Graph = 0;           % Plot results 
    Export = 1;          % Export result to file
    Debug = 0;           % Show event messages
    MaxLblPlot = 255;    % Maximum label used for plotting
    Xplot = 2;
    Yplot = 2;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    Files = dir(strcat([InputFolder '*.tif']));
    num_images = numel(Files);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if Graph == 1
        FigObjects = figure;
    end

    clear textprogressbar;
    textprogressbar('Processing...');
    DivLog = [];

    % Main loop (frames)
    for kf = 1:num_images

        textprogressbar(round(100*kf/num_images));

        A = imread(strcat([InputFolder Files(kf).name]));
        A = (A > 0);
        if ~(MinPartArea == Inf)
            A = bwareaopen(A, MinPartArea)*255; % Remove small particles
        end
        if RemoveEdgeObj == 1
            A = imclearborder(A); % Remove particles touching an edge
        end

        %% Find connected particles 
        CC = bwconncomp(A == 255, 8);
        Particles = CC.PixelIdxList;    
        Nprt = length(Particles);

        %% Generate dilated map
        DilateA = imdilate(A,se);
        DilateCC = bwconncomp(DilateA == 255, 8);  
        DilatedMap = labelmatrix(DilateCC);

        %% Compute particle properties
        PrtArea = zeros(1,Nprt);
        PrtCMX = zeros(1,Nprt); 
        PrtCMY = zeros(1,Nprt);
        for i = 1:Nprt
            PrtArea(i) = numel(Particles{i});
            [Y X] = ind2sub(size(A),Particles{i});
            PrtCMX(i) = mean(X);
            PrtCMY(i) = mean(Y); 
        end

        %% First frame: All particles --> objects
        if (kf == 1)
            ObjArea = PrtArea;
            ObjCMX = PrtCMX;
            ObjCMY = PrtCMY;
            ObjLup = kf*ones(1,Nprt); % Object last update (frame)
            MaxObjLbl = Nprt;

            %disp(strcat(['frame_' num2str(kf) '_max_obj_lbl_' num2str(MaxObjLbl)]));

            %% Object label map for first frame
            ObjLbl = zeros(size(A));
            for i = 1:Nprt
                ObjLbl(Particles{i}) = i; 
            end

        end

        %% Other frames
        if kf>1

            %% Disable old objects
            ActiveObjects = find(((kf-ObjLup) <= MaxRescue) == 1);
            %disp(strcat(['frame_' num2str(kf) '_max_lbl_' num2str(MaxObjLbl) '_active_objects_' num2str(numel(ActiveObjects))]));

            %% Compute particle to object distance matrix
            DstPrtObj = NaN(Nprt,MaxObjLbl);
            for i = ActiveObjects
                DstPrtObj(:,i) = (PrtCMX - ObjCMX(i)).^2 + (PrtCMY - ObjCMY(i)).^2;
            end

            %% For each object, find particle(s) this object is closest to (particle(s) voting for object) --> ObjPrtVote
            %% For each particle, find second closest object (second closest object voted by particle) --> PrtObjVote2
            ObjPrtVote = cell(1,MaxObjLbl);
            PrtObjVote2 = zeros(1,Nprt);
            for i = 1:Nprt
                [SortedDst SortedLbl] = sort(DstPrtObj(i,:));
                Lbl1 = SortedLbl(1);
                Lbl2 = SortedLbl(2);
                if EnforceOverlap == 1
                    tst = isempty(find(ObjLbl(Particles{i}) == Lbl1)) && isempty(find(ObjLbl(Particles{i}) == 65535));  
                else
                    tst = 0;
                end
                if(SortedDst(1) <= MaxDisp) && tst == 0
                    ObjPrtVote{Lbl1} = [ObjPrtVote{Lbl1} i];
                end   
                if(SortedDst(2) <= MaxDisp)
                    PrtObjVote2(i) = Lbl2;
                else
                    PrtObjVote2(i) = 0;
                end
            end       

            %% Two-way particle exchange optimization
            for i = ActiveObjects
                if length(ObjPrtVote{i}) == 2
                    PrtInd1 = ObjPrtVote{i}(1);
                    PrtInd2 = ObjPrtVote{i}(2);
                    PrtInd = -1;
                    if PrtObjVote2(PrtInd1)>0 && PrtObjVote2(PrtInd2)>0
                    if (length(ObjPrtVote{PrtObjVote2(PrtInd1)}) == 0) && (length(ObjPrtVote{PrtObjVote2(PrtInd2)}) == 0)
                        %% Find orphaned object
                        if PrtObjVote2(PrtInd1) == i
                            ObjIndx = PrtObjVote2(PrtInd2);
                        else
                            ObjIndx = PrtObjVote2(PrtInd1);
                        end
                        %% Estimate which of the two particles is most likely to correspond to the orphaned object
                        if(DstPrtObj(PrtInd1,ObjIndx) > DstPrtObj(PrtInd2,ObjIndx))
                        %if abs(PrtArea(PrtInd1)-ObjArea(ObjIndx)) > abs(PrtArea(PrtInd2)-ObjArea(ObjIndx))
                            ObjPrtVote{i}(2) = [];
                            ObjPrtVote{PrtObjVote2(PrtInd2)} = PrtInd2;
                            PrtInd = PrtInd2;
                        else
                            ObjPrtVote{i}(1) = [];
                            ObjPrtVote{PrtObjVote2(PrtInd1)} = PrtInd1;
                            PrtInd = PrtInd1;
                        end
                    else
                        if (length(ObjPrtVote{PrtObjVote2(PrtInd1)}) == 0)
                            ObjPrtVote{i}(1) = [];
                            ObjPrtVote{PrtObjVote2(PrtInd1)} = PrtInd1;
                            PrtInd = PrtInd1;
                        end
                        if (length(ObjPrtVote{PrtObjVote2(PrtInd2)}) == 0)
                            ObjPrtVote{i}(2) = [];
                            ObjPrtVote{PrtObjVote2(PrtInd2)} = PrtInd2;
                            PrtInd = PrtInd2;
                        end
                    end
                    end
                    if Debug == 1 && PrtInd > -1
                        disp(strcat('obj_',num2str(i),'_vote_reassigned_to_obj_',num2str(PrtObjVote2(PrtInd))));
                    end
                end
            end

            %% Initialize variables
            RelArea = NaN(1,MaxObjLbl);
            CMShift = Inf(1,MaxObjLbl);    
            ObjState = -1*ones(1,MaxObjLbl);
            NewObjCMX = ObjCMX;
            NewObjCMY = ObjCMY;
            NewObjLup = ObjLup;
            NewObjArea = ObjArea;
            NewMaxObjLbl = MaxObjLbl;
            ObjLbl = (A > 0)*65535;

            % First pass: Regular transition/fragmentation/division/appearance
            for i = ActiveObjects

                Votes = ObjPrtVote{i}; % Particle votes for this object

                % Single/multiple assignation
                if length(Votes) >= 1

                    % Area conservation check
                    NewArea = sum(PrtArea(Votes));
                    RelArea(i) = round(100*(NewArea-ObjArea(i))/ObjArea(i)); 

                    % Centroid displacement check
                    NewCMX = mean(PrtCMX(Votes));
                    NewCMY = mean(PrtCMY(Votes));
                    CMShift(i) = max(DstPrtObj(Votes,i));

                    % Regular transition or fragmentation
                    FrgTst = -1;
                    if (abs(RelArea(i)) <= MaxAreaVar) && (CMShift(i) <= MaxDisp)
                        NewObjArea(i) = NewArea;
                        NewObjCMX(i) = NewCMX;
                        NewObjCMY(i) = NewCMY;
                        NewObjLup(i) = kf;
                        for j = 1:length(Votes)
                            ObjLbl(ind2sub(size(A),Particles{Votes(j)})) = i;
                        end
                        if (kf-ObjLup(i)) > 1 && Debug == 1
                            %disp(strcat('obj_',num2str(i),'_reappears'));
                        end
                        if length(Votes) > 1
                            FrgTst = 1;
                            FirstLbl = DilatedMap(round(PrtCMY(Votes(1))),round(PrtCMX(Votes(1))));
                            for j = 2:length(Votes)
                                if DilatedMap(round(PrtCMY(Votes(j))),round(PrtCMX(Votes(j)))) ~= FirstLbl
                                    FrgTst = -1;
                                end
                            end
                            if FrgTst == 1
                                ObjState(i) = 2;
                                if Debug == 1 
                                    disp(strcat('obj_',num2str(i),'_fragments'));
                                end
                            end
                        else
                            ObjState(i) = 1;
                        end
                    end

                    % Check for object appearance
                    if (length(Votes) > 1) && (ObjState(i) == -1) 

                        % Find the particle which is closest to an edge (candidate appearing object)
                        DstEdgeMat = reshape([PrtCMX(Votes) abs(PrtCMX(Votes)-size(A,2)) PrtCMY(Votes) abs(PrtCMY(Votes)-size(A,1))],length(Votes),4);
                        [minval,ind] = min(DstEdgeMat(:)); 
                        [ind1,ind2] = ind2sub([size(DstEdgeMat,1) size(DstEdgeMat,2)],ind);

                        % Check area conservation when candidate appearing object is removed from current object
                        VotesRem = Votes(Votes ~= Votes(ind1));
                        AreaTest = sum(PrtArea(VotesRem));
                        RelAreaTest = round(100*(AreaTest-ObjArea(i))/ObjArea(i));          
                        CMShiftTest = max(DstPrtObj(VotesRem,i));

                        % Valid appearance
                        if (DstEdgeMat(ind1,ind2) < MaxDisp) && (abs(RelAreaTest) <= MaxAreaVar)  && (CMShiftTest <= MaxDisp)
                            NewMaxObjLbl = NewMaxObjLbl+1;
                            NewObjArea(NewMaxObjLbl) = PrtArea(Votes(ind1));
                            NewObjCMX(NewMaxObjLbl) = PrtCMX(Votes(ind1));
                            NewObjCMY(NewMaxObjLbl) = PrtCMY(Votes(ind1));
                            NewObjLup(NewMaxObjLbl) = kf;
                            ObjState(NewMaxObjLbl) = 4;
                            ObjLbl(ind2sub(size(A),Particles{Votes(ind1)})) = NewMaxObjLbl;

                            NewObjArea(i) = AreaTest;
                            NewObjCMX(i) = mean(PrtCMX(VotesRem));
                            NewObjCMY(i) = mean(PrtCMY(VotesRem));
                            NewObjLup(i) = kf;
                            ObjState(i) = 1;
                            for j = 1:length(Votes)
                                if j ~= ind1
                                    ObjLbl(ind2sub(size(A),Particles{Votes(j)})) = i;
                                end
                            end

                            if Debug == 1
                                disp(strcat('obj_',num2str(NewMaxObjLbl),'_appears_in_vicinity_of_obj_',num2str(i)));
                            end
                        end
                    end

                    % Check for division (no area conservation test)
                    if (CMShift(i) <= MaxDisp) && (FrgTst == -1) && (length(Votes) > 1) && (ObjState(i) == -1)  

                        % Select most likely mother candidate
                        %DifArea = abs(ObjArea(i) - PrtArea(Votes));
                        %[valmin ind1] = min(DifArea);
                        Dst = DstPrtObj(Votes,i);
                        [valmin ind1] = min(Dst);

                        for j = 1:length(Votes)
                            if(j~=ind1)
                                NewMaxObjLbl = NewMaxObjLbl+1;
                                NewObjArea(NewMaxObjLbl) = PrtArea(Votes(j));
                                NewObjCMX(NewMaxObjLbl) = PrtCMX(Votes(j));
                                NewObjCMY(NewMaxObjLbl) = PrtCMY(Votes(j));
                                NewObjLup(NewMaxObjLbl) = kf;
                                ObjLbl(ind2sub(size(A),Particles{Votes(j)})) = NewMaxObjLbl;
                                ObjState(NewMaxObjLbl) = 3;
                                if Debug == 1 
                                    disp(strcat('obj_',num2str(i),'_divides_and_gives_birth_to_obj_',num2str(NewMaxObjLbl)));
                                end 
                            end
                        end
                        ObjState(i) = 3;
                        NewObjLup(i) = kf;
                        NewObjArea(i) = PrtArea(Votes(ind1));
                        NewObjCMX(i) = PrtCMX(Votes(ind1));
                        NewObjCMY(i) = PrtCMY(Votes(ind1));
                        ObjLbl(ind2sub(size(A),Particles{Votes(ind1)})) = i;                                            
                    end

                end
            end

            % Second pass: Clumping/disappearance
            for i = ActiveObjects
                Votes = ObjPrtVote{i};
                % No vote for this object: Clumped or disappeared 
                if length(Votes) == 0
                    for j = 1:MaxObjLbl
                        Dst = (ObjCMX(i) - ObjCMX(j))^2+(ObjCMY(i) - ObjCMY(j))^2;
                        if Dst <= MaxDisp
                            VotesCand = ObjPrtVote{j};
                            %% Clumps
                            if (RelArea(j) > MaxAreaVar) && (length(VotesCand == 2))                          
                                if (kf-ObjLup(i)) == MaxRescue
                                    ObjLbl(ind2sub(size(A),Particles{VotesCand(1)})) = 65535;
                                    ObjState(i) = -2;
                                    ObjState(j) = -2;
                                else
                                    ObjLbl(ind2sub(size(A),Particles{VotesCand(1)})) = randsample([i j],numel(Particles{VotesCand(1)}),1);
                                    ObjState(i) = 5;
                                    ObjState(j) = 5;
                                end
                                if Debug == 1 
                                    disp(strcat('obj_',num2str(i),'_and_', num2str(j),'_clump'));
                                end
                            end
                        end
                    end
                    if ObjState(i) == -1
                        DstEdge = min([ObjCMX(i) abs(ObjCMX(i)-size(A,2)) ObjCMY(i) abs(ObjCMY(i)-size(A,1))]);
                        % Disappears
                        NewObjLup(i) = -Inf;
                        if DstEdge < MaxDisp
                            if Debug == 1 
                                disp(strcat('obj_',num2str(i),'_disappears'));
                            end
                            ObjState(i) = 6;   
                        end 
                    end
                end
            end

            %% Third pass: Rescue objects from unassigned particles pool, create new objects and report errors
            for i = ActiveObjects
                Votes = ObjPrtVote{i}; % Particle votes for this object
                if (ObjState(i) == -1) && (length(Votes) >= 1)
                    ind1 = Votes(1);
                    if (ObjLbl(Particles{ind1}(1)) == 65535)

                            % Centroid displacement check
                            NewCMX = PrtCMX(ind1);
                            NewCMY = PrtCMY(ind1);
                            CMShift(i) = DstPrtObj(ind1,i); 

                            % Regular transition or fragmentation
                            if (CMShift(i) <= MaxDisp)
                                NewObjArea(i) = PrtArea(ind1);
                                NewObjCMX(i) = NewCMX;
                                NewObjCMY(i) = NewCMY;
                                NewObjLup(i) = kf;
                                ObjLbl(ind2sub(size(A),Particles{ind1})) = i;
                                ObjState(i) = 7;
                                if Debug == 1
                                    disp(strcat('obj_',num2str(i),'_rescued'));
                                end
                            end
                    end
                end   
                if (ObjState(i) == -1)    
                    if Debug == 1
                        disp(strcat('obj_',num2str(i),'_error'));
                    end
                end
            end
            for i = 1:Nprt
                if (ObjLbl(Particles{i}(1)) == 65535)
                    NewMaxObjLbl = NewMaxObjLbl+1;
                    NewObjArea(NewMaxObjLbl) = PrtArea(i);
                    NewObjCMX(NewMaxObjLbl) = PrtCMX(i);
                    NewObjCMY(NewMaxObjLbl) = PrtCMY(i);
                    NewObjLup(NewMaxObjLbl) = kf;
                    ObjLbl(ind2sub(size(A),Particles{i})) = NewMaxObjLbl;
                    ObjState(i) = 8;
                    if Debug == 1
                        disp(strcat('dummy_obj_',num2str(NewMaxObjLbl),'_created'));
                    end
                end
            end


            %% Update object properties 
            ObjCMX = NewObjCMX;
            ObjCMY = NewObjCMY;
            ObjArea = NewObjArea;
            ObjLup = NewObjLup;
            MaxObjLbl = NewMaxObjLbl;

        end

        %% Display object label map
        if Graph==1
            figure(FigObjects);
            subplot(Xplot,Yplot,mod(kf-1,Xplot*Yplot)+1);
            imagesc(ObjLbl,[0 MaxLblPlot]);
            set(gca,'XTick',[]);
            set(gca,'YTick',[]);
            title(strcat('Frame-',num2str(kf)));
        end

        %% Export object label map
        if Export==1
            imwrite(uint16(ObjLbl), strcat(OutputFolder,Files(kf).name), 'Compression','deflate');
        end
    end

    clear textprogressbar;
    disp(' ');

end
function LOBSTER

  %% Check that imtool3D is in path (init has been performed)
  if ~exist('imtool3D')
    error('LOBSTER has not been initialized yet, type >> init');
  else
    %% Force path to LOBSTER root on startup
    str = which('init');
    indxs = find((str=='/')|(str=='\'));
    cd(str(1:indxs(end)));
  end
  
  indxst = [];
  indxen = [];
  indxpar = [];
  indxcoma = [];
  indxequal = [];
  funct1params = [];
  funct1argin = [];
  funct1argout = [];
  global S;
  global InputFolder;
  global OutputFolder;
  global ReportFolder;
  global ExportMeshFolder;
  global Files;
  global CallJOSE;
  global Interface;
  global Script;
  global images;
  global I;
  global R;
  global coords;
  global f;
  global pre;
  figh = figure(10);
  set(figh,'MenuBar','none','Name','LOBSTER Panel','NumberTitle','off');
  set(figh,'CloseRequestFcn',[]);
  Interface = findobj(figh,'Enable','on');
  Dim = uicontrol('Style','ToggleButton','String','2D','Position',[20,400,60,20],'ToolTipString','2D/3D Image','CallBack', @DimButtonPressed);
  TL = uicontrol('Style','ToggleButton','String','-','Position',[20,380,60,20],'ToolTipString','Set to TL if Journal 2 is time-lapse','CallBack', @TLButtonPressed);
  SklFormat = uicontrol('Style','ToggleButton','String','SWC','Position',[260,380,60,20],'ToolTipString','Exportation format for filament network','CallBack', @SklFormatButtonPressed);
  ZRatio = uicontrol('Style','Edit','String','1','Position',[140,400,60,20],'ToolTipString','Image ZRatio (3D only)','Enable','off');
  Export = uicontrol('Style','ToggleButton','String','NoExport','Position',[80,400,60,20],'ToolTipString','Export to 3D model','CallBack', @ExportButtonPressed);
  MeshDSRatio = uicontrol('Style','Edit','String','0.25','Position',[200,400,60,20],'ToolTipString','STL mesh vertex keep fraction (0 - 1, Export only)','Enable','off');
  SamplingStep = uicontrol('Style','Edit','String','4','Position',[260,400,60,20],'ToolTipString','SWC/OBJ filament network sampling step (pix, Export only)','Enable','off');
  ChanFolderButton = uicontrol('Style','PushButton','String','C1','Position',[80,380,20,20],'ToolTipString','Possible source folder for intensity channel','CallBack', @ChannelFolderPressed);
  ChanFolderSet = uicontrol('Style','Edit','String','','ToolTipString','Placeholder for intensity measurement channel folder','Position',[100,380,160,20]);
  SaveButton = uicontrol('Style','PushButton','String','Save','Position',[360,400,60,20],'ToolTipString','Save project','CallBack', @saveState);
  LoadButton = uicontrol('Style','PushButton','String','Load','Position',[420,400,60,20],'ToolTipString','Load project','CallBack', @loadState);
  ExitButton = uicontrol('Style','PushButton','String','Exit','Position',[480,400,60,20],'ForegroundColor',[1 1 1],'BackgroundColor',[0.8 0.25 0.25],'CallBack', @ExitPressed);
  InputFolderButton1 = uicontrol('Style','PushButton','String','I1','Position',[20,340,20,20],'ToolTipString','Set image input folder from file browser','CallBack', @InputFolderPressed1);
  InputFolderPath1 = uicontrol('Style','Edit','String','','ToolTipString','Image input folder','Position',[40,340,240,20]);
  OutputFolderButton1 = uicontrol('Style','PushButton','String','O1','ToolTipString','Set image output folder from file browser','Position',[20,280,20,20],'CallBack', @OutputFolderPressed1);
  OutputFolderPath1 = uicontrol('Style','Edit','String','','ToolTipString','Image output folder','Position',[40,280,240,20]);
  InputFolderButton2 = uicontrol('Style','PushButton','String','I2','ToolTipString','Set image input folder from file browser','Position',[280,340,20,20],'CallBack', @InputFolderPressed2);
  InputFolderPath2 = uicontrol('Style','Edit','String','','ToolTipString','Image input folder','Position',[300,340,240,20]);
  OutputFolderButton2 = uicontrol('Style','PushButton','String','O2','ToolTipString','Set image output folder from file browser','Position',[280,280,20,20],'CallBack', @OutputFolderPressed2);
  OutputFolderPath2 = uicontrol('Style','Edit','String','','ToolTipString','Image output folder','Position',[300,280,240,20]);
  Journal1Select = uicontrol('Style','PushButton','String','Journal1','ToolTipString','Select Journal 1','Position',[20,320,260,20],'CallBack', @Journals1Select);
  Journal2Select = uicontrol('Style','PushButton','String','Journal2','ToolTipString','Select Journal 2','Position',[280,320,260,20],'CallBack', @Journals2Select);
  Journal1Name = uicontrol('Style','Edit','String','','Position',[20,300,260,20],'Enable','off');
  Journal2Name = uicontrol('Style','Edit','String','','Position',[280,300,260,20],'Enable','off');
  Journal1Edit = uicontrol('Style','PushButton','String','Edit','ToolTipString','Edit Journal 1','Position',[20,260,260,20],'CallBack', @Journals1Edit);
  Journal2Edit = uicontrol('Style','PushButton','String','Edit','ToolTipString','Edit Journal 2','Position',[280,260,260,20],'CallBack', @Journals2Edit);
  Journal1Run = uicontrol('Style','PushButton','String','Run Journal 1','Position',[20,240,260,20],'CallBack', @Journals1Run);
  Journal2Run = uicontrol('Style','PushButton','String','Run Journal 2','Position',[280,240,260,20],'CallBack', @Journals2Run);
  Journal1In = uicontrol('Style','PushButton','String','Show In','ToolTipString','Show Journal 1 input folder','Position',[20,220,130,20],'CallBack', @Journals1InPressed);
  Journal2In = uicontrol('Style','PushButton','String','Show In','ToolTipString','Show Journal 2 input folder','Position',[280,220,130,20],'CallBack', @Journals2InPressed);
  Journal1Out = uicontrol('Style','PushButton','String','Show Out','ToolTipString','Show Journal 1 output folder','Position',[150,220,130,20],'CallBack', @Journals1OutPressed);
  Journal2Out = uicontrol('Style','PushButton','String','Show Out','ToolTipString','Show Journal 1 output folder','Position',[410,220,130,20],'CallBack', @Journals2OutPressed);
  IRMA1Mask = uicontrol('Style','popupmenu','String',{'O1','O2'},'ToolTipString','Mask folder (objects to measure)','Position',[20,175,40,20]);
  IRMA1Chan = uicontrol('Style','popupmenu','String',{'-','I1','I2','O1','O2','C1'},'ToolTipString','Channel folder (intensity measure)','Position',[20,150,40,20]);
  IRMA1Flt = uicontrol('Style','Edit','String','*.tif','ToolTipString','Channel images filter','Position',[65,150,120,20]);
  IRMA1Mode = uicontrol('Style','popupmenu','String',{'-','Objs','Skls','Spts','Trks'},'ToolTipString','Measurements type','Position',[20,125,60,20]);
  ReportFolderButton1 = uicontrol('Style','PushButton','String','R1','Position',[20,80,20,20],'CallBack', @ReportFolderPressed1);
  ReportFolderPath1 = uicontrol('Style','Edit','String','','String','.','Position',[40,80,240,20]);
  ReportFolderButton2 = uicontrol('Style','PushButton','String','R2','Position',[280,80,20,20],'CallBack', @ReportFolderPressed2);
  ReportFolderPath2 = uicontrol('Style','Edit','String','','String','.','Position',[300,80,240,20]);
  IRMA2Mask = uicontrol('Style','popupmenu','String',{'O2','O1'},'ToolTipString','Mask folder (objects to measure)','Position',[280,175,40,20]);
  IRMA2Chan = uicontrol('Style','popupmenu','String',{'-','I2','I1','O2','O1','C1'},'ToolTipString','Channel folder (intensity measure)','Position',[280,150,40,20]);
  IRMA2Flt = uicontrol('Style','Edit','String','*.tif','ToolTipString','Channel images filter','Position',[325,150,120,20]);
  IRMA2Mode = uicontrol('Style','popupmenu','String',{'-','Objs','Skls','Spts','Trks'},'ToolTipString','Measurement type','Position',[280,125,60,20]);
  IRMA1Run = uicontrol('Style','PushButton','String','Run Measure 1','Position',[20,100,260,20],'CallBack', @IRMARunPressed1);
  IRMA2Run = uicontrol('Style','PushButton','String','Run Measure 2','Position',[280,100,260,20],'CallBack', @IRMARunPressed2);
  IRMA1Show = uicontrol('Style','PushButton','String','Show Reports','Position',[20,60,260,20],'CallBack', @IRMAShow1);
  IRMA2Show = uicontrol('Style','PushButton','String','Show Reports','Position',[280,60,260,20],'CallBack', @IRMAShow2);
  ToolsButton = uicontrol('Style','PushButton','String','TOOLS','ToolTipString','Open LOBSTER Tools folder','Position',[20,10,60,20],'CallBack', @ToolsPressed);
  RunAllButton = uicontrol('Style','PushButton','String','Run All','Position',[130,10,80,20],'ForegroundColor',[1 1 1],'BackgroundColor',[0.25 0.8 0.25],'ToolTipString','Run all steps sequentially','CallBack', @RunAllPressed);
  Disp = uicontrol('Style','ToggleButton','String','Batch','Position',[210,10,80,20],'ToolTipString','Hide/Show journal output','CallBack', @DispButtonPressed);
  State = uicontrol('Style','Edit','String','','Position',[290,10,120,20],'Enable','off');
  Documentation = uicontrol('Style','PushButton','String','HELP','Position',[460,10,80,20],'ToolTipString','Open LOBSTER tutorial','CallBack', @DocumentationPressed);
  S.Disp = Disp;
  S.Dim = Dim;
  S.Export = Export;
  S.ZRatio = ZRatio;
  S.TL = TL;
  S.MeshDSRatio = MeshDSRatio;
  S.SamplingStep = SamplingStep;
  S.InputFolderPath1 = InputFolderPath1;
  S.OutputFolderPath1 = OutputFolderPath1;
  S.InputFolderPath2 = InputFolderPath2;
  S.OutputFolderPath2 = OutputFolderPath2;
  S.Journal1Name = Journal1Name;
  S.Journal2Name = Journal2Name;
  S.IRMA1Mask = IRMA1Mask;
  S.IRMA1Chan = IRMA1Chan;
  S.IRMA1Flt = IRMA1Flt;
  S.IRMA1Mode = IRMA1Mode;
  S.ReportFolderPath1 = ReportFolderPath1;
  S.ReportFolderPath2 = ReportFolderPath2;
  S.IRMA2Mask = IRMA2Mask;
  S.IRMA2Chan = IRMA2Chan;
  S.IRMA2Flt = IRMA2Flt;
  S.IRMA2Mode = IRMA2Mode;
  S.ChanFolderSet = ChanFolderSet;
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
  function InputFolderPressed1(h, eventdata)
      folder_name = uigetdir('./Images/');
      if folder_name ~= 0
        set(InputFolderPath1, 'String', folder_name);
      end
  end
    
  function OutputFolderPressed1(h, eventdata)
      folder_name = uigetdir('./Results/Images/');
      if folder_name ~= 0
        set(OutputFolderPath1, 'String', folder_name);
      end
  end
  
  function InputFolderPressed2(h, eventdata) 
      folder_name = uigetdir('./Images/');
      if folder_name ~= 0
        set(InputFolderPath2, 'String', folder_name);
      end
  end
    
  function OutputFolderPressed2(h, eventdata)
      folder_name = uigetdir('./Results/Images/');
      if folder_name ~= 0
        set(OutputFolderPath2, 'String', folder_name);
      end
  end

  function ChannelFolderPressed(h, eventdata)
      folder_name = uigetdir('./Images/');
      if folder_name ~= 0
        set(ChanFolderSet, 'String', folder_name);
      end
  end

  function ReportFolderPressed1(h, eventdata)
      folder_name = uigetdir('./Results/Reports/');
      if folder_name ~= 0
        set(ReportFolderPath1, 'String', folder_name);
      end
  end

  function ReportFolderPressed2(h, eventdata)
      folder_name = uigetdir('./Results/Reports/');
      if folder_name ~= 0
        set(ReportFolderPath2, 'String', folder_name);
      end
  end

  function Journals1Select(h, eventdata)  
      switch Dim.String
          case '2D'
            str = 'E:/LOBSTER/Journals/jl/';
            [FileName,PathName] = uigetfile('E:/LOBSTER/Journals/jl/*.jl','Select 2D Journal');
            set(Journal1Name, 'String', FileName);
          case '3D'
            str = 'E:/LOBSTER/Journals/jls/';
            [FileName,PathName] = uigetfile('E:/LOBSTER/Journals/jls/*.jls','Select 3D Journal');
            set(Journal1Name, 'String', FileName);
      end
      fid = fopen(strcat([str FileName]),'r');
      if fid>-1
          in = fgetl(fid);
          out = fgetl(fid);
          inds = strfind(in,'''');
          if(numel(inds) == 2)
              set(InputFolderPath1, 'String', in(inds(1)+1:inds(2)-1));
          end
          inds = strfind(out,'''');
          if(numel(inds) == 2)
              set(OutputFolderPath1, 'String', out(inds(1)+1:inds(2)-1));
          end
          fclose(fid);
      end
  end

  function Journals2Select(h, eventdata)  
      if TL.Value == 1
        str = 'E:/LOBSTER/Journals/jlm/';
        [FileName,PathName] = uigetfile('E:/LOBSTER/Journals/jlm/*.jlm','Select 2D Journal');
        set(Journal2Name, 'String', FileName);
      else
          switch Dim.String
              case '2D'
                str = 'E:/LOBSTER/Journals/jl/';
                [FileName,PathName] = uigetfile('E:/LOBSTER/Journals/jl/*.jl','Select 2D Journal');
                set(Journal2Name, 'String', FileName);
              case '3D'
                str = 'E:/LOBSTER/Journals/jls/';
                [FileName,PathName] = uigetfile('E:/LOBSTER/Journals/jls/*.jls','Select 3D Journal');
                set(Journal2Name, 'String', FileName);
          end
      end
      fid = fopen(strcat([str FileName]),'r');
      if fid>-1
          in = fgetl(fid);
          out = fgetl(fid);
          inds = strfind(in,'''');
          if(numel(inds) == 2)
              set(InputFolderPath2, 'String', in(inds(1)+1:inds(2)-1));
          end
          inds = strfind(out,'''');
          if(numel(inds) == 2)
              set(OutputFolderPath2, 'String', out(inds(1)+1:inds(2)-1));
          end
          fclose(fid);
      end
  end

  function Journals1Edit(h, eventdata)  
      if ~isempty(Journal1Name.String)
      switch Dim.String
          case '2D'
            open(strcat(['E:/LOBSTER/Journals/jl/' Journal1Name.String]));
          case '3D'
            open(strcat(['E:/LOBSTER/Journals/jls/' Journal1Name.String]));
      end
      end
  end

  function Journals2Edit(h, eventdata)
      if ~isempty(Journal2Name.String)
      if TL.Value == 1
        open(strcat(['E:/LOBSTER/Journals/jlm/' Journal2Name.String]));
      else
      switch Dim.String
          case '2D'
            open(strcat(['E:/LOBSTER/Journals/jl/' Journal2Name.String]));
          case '3D'
            open(strcat(['E:/LOBSTER/Journals/jls/' Journal2Name.String]));
      end
      end
      end
  end

  function Journals1Run(h, eventdata)  
      if ~isempty(Journal1Name.String)
          OutputFolder = OutputFolderPath1.String;
          set(h,'ForegroundColor',[1 0 0]);
          set(State, 'String', 'Processing Journal1...');
          pause(0.05);
          set(Interface,'Enable','off');
          try
            switch Disp.String
              case 'Show'
                eval('[InputFolder OutputFolder] = JENI(Journal1Name.String,InputFolderPath1.String,OutputFolder);');
                Script = strcat([Script char(10) 'JENI(''' Journal1Name.String ''',''' InputFolderPath1.String ''',''' OutputFolder ''');']); 
              case 'Batch'
                eval('[InputFolder OutputFolder] = GENI(Journal1Name.String,InputFolderPath1.String,OutputFolder);');
                Script = strcat([Script char(10) 'GENI(''' Journal1Name.String ''',''' InputFolderPath1.String ''',''' OutputFolder ''');']);  
            end
            if TL.Value == 1 && Dim.Value == 0
                handle = figure('Name','First time point');
                images = dir([OutputFolder '*.tif']);
                I = imread([OutputFolder images(1).name]);
                imagesc(I);truesize(gcf);
                coords = ones(1,4);
                while coords(3)>0 && coords(4)>0
                    coords = round(getPosition(imrect())); 
                    BW = roipoly(I,[coords(1) coords(1) coords(1)+coords(3) coords(1)+coords(3)],[coords(2) coords(2)+coords(4) coords(2)+coords(4) coords(2)]);
                    f = @(x) imdilate(x,strel('disk',1));
                    I = roifilt2(I,BW,f);
                    f = @(x) imerode(x,strel('disk',1));
                    I = roifilt2(I,BW,f);
                    imagesc(I);
                end
                close();
                imwrite(I,[OutputFolder images(1).name]);
            end
            set(h,'ForegroundColor',[0 0 0]);
            set(State, 'String', '');
          catch
              set(State, 'String', 'Error');
          end
          set(Interface,'Enable','on');
      end
  end

  function Journals2Run(h, eventdata)  
      if ~isempty(Journal2Name.String)
          OutputFolder = OutputFolderPath2.String;
          set(h,'ForegroundColor',[1 0 0]);
          set(State, 'String', 'Processing Journal2...');
          pause(0.05);
          set(Interface,'Enable','off');
          try
              switch Disp.String
                  case 'Show'
                    eval('[InputFolder OutputFolder] = JENI(Journal2Name.String,InputFolderPath2.String,OutputFolder);');
                    Script = strcat([Script char(10) 'JENI(''' Journal2Name.String ''',''' InputFolderPath2.String ''',''' OutputFolder ''');']); 
                  case 'Batch'
                    eval('[InputFolder OutputFolder] = GENI(Journal2Name.String,InputFolderPath2.String,OutputFolder);');
                    Script = strcat([Script char(10) 'GENI(''' Journal2Name.String ''',''' InputFolderPath2.String ''',''' OutputFolder ''');']); 
              end
              set(h,'ForegroundColor',[0 0 0]);
              set(State, 'String', '');
          catch
              set(State, 'String', 'Error');
          end
          set(Interface,'Enable','on');
      end
  end

  function IRMARunPressed1(h, eventdata)
      switch IRMA1Mask.Value
          case 1
              MaskFolder = OutputFolderPath1.String;
          case 2
              MaskFolder = OutputFolderPath2.String;
      end
      Mode = IRMA1Mode.String{IRMA1Mode.Value};
      if ~isempty(MaskFolder) & ~strcmp(Mode,'-')
      switch IRMA1Chan.Value
        case 1
            ChanFolder = '';
        case 2
            ChanFolder = InputFolderPath1.String;
        case 3
            ChanFolder = InputFolderPath2.String;
        case 4
            ChanFolder = OutputFolderPath1.String;
        case 5
            ChanFolder = OutputFolderPath2.String;
        case 6
            ChanFolder = ChanFolderSet.String;
      end
      ChanFlt = IRMA1Flt.String;
      ImDim = Dim.Value+2;
      ImZRatio = str2num(ZRatio.String);
      ReportFolder = ReportFolderPath1.String;
      if isempty(ReportFolder)
        ReportFolder = '.';
      end
      set(h,'ForegroundColor',[1 0 0]);
      set(State, 'String', 'Measuring 1...');
      pause(0.05);
      CallJOSE = 0;
      if ImDim ==3
      switch Export.String
          case 'NoExport'
            Script = strcat([Script char(10) 'IRMA(''' MaskFolder ''',''' ReportFolder ''',''' Mode ''',' num2str(ImDim) ',' num2str(ImZRatio) ');']);
          case 'Export'
              switch Mode
                  case 'Skls'
                    Script = strcat([Script char(10) 'IRMA(''' MaskFolder ''',''' ReportFolder ''',''' Mode ''', ' num2str(ImDim) ',{' num2str(ImZRatio) ',' SamplingStep.String ',''' ReportFolder ''',''' SklFormat.String '''});']);
                    ImZRatio = {ImZRatio,str2num(SamplingStep.String),ReportFolder, SklFormat.String};
                  case 'Objs'
                    Script = strcat([Script char(10) 'IRMA(''' MaskFolder ''',''' ReportFolder ''',''' Mode ''', ' num2str(ImDim) ',{' num2str(ImZRatio) ',' MeshDSRatio.String ',''' ReportFolder '''});']);
                    ImZRatio = {ImZRatio,str2num(MeshDSRatio.String),ReportFolder}; 
                  case 'Spts'
                    CallJOSE = 1;
                    Script = strcat([Script char(10) 'IRMA(''' MaskFolder ''',''' ReportFolder ''',''' Mode ''',' num2str(ImDim) ',' num2str(ImZRatio) ');']);
              end
      end
      end
      try
          if isempty(ChanFolder)
              eval('[ReportFolder ExportMeshFolder] = IRMA(MaskFolder,ReportFolder,Mode,ImDim,ImZRatio);');
          else
              eval('[ReportFolder ExportMeshFolder] = IRMA(MaskFolder,ReportFolder,Mode,ImDim,ImZRatio,ChanFolder,ChanFlt);');
          end
          if CallJOSE == 1
            JOSE(ReportFolder,'Spts',InputFolderPath1.String,'CellInsight','','');
            Script = strcat([Script char(10) 'JOSE(''' ReportFolder ''',''Spts'',''' InputFolderPath1.String ''',''CellInsight'','''','''');']); 
            ExportMeshFolder = InputFolderPath1.String;
          end
          set(State, 'String', '');
          set(h,'ForegroundColor',[0 0 0]);
          %winopen(GetFullPath(ReportFolder));
          if ~isempty(ExportMeshFolder)
            winopen(GetFullPath(ExportMeshFolder));
          end
      catch
        set(State, 'String', 'Error');
      end  
      end
  end
  
  function IRMARunPressed2(h, eventdata)
      switch IRMA2Mask.Value
          case 1
              MaskFolder = OutputFolderPath2.String;
          case 2
              MaskFolder = OutputFolderPath1.String;
      end
      Mode = IRMA2Mode.String{IRMA2Mode.Value};
      if ~isempty(MaskFolder) & ~strcmp(Mode,'-')
      switch IRMA2Chan.Value
        case 1
            ChanFolder = '';
        case 2
            ChanFolder = InputFolderPath2.String;
        case 3
            ChanFolder = InputFolderPath1.String;
        case 4
            ChanFolder = OutputFolderPath2.String;
        case 5
            ChanFolder = OutputFolderPath1.String;
        case 6
            ChanFolder = ChanFolderSet.String;
      end
      ChanFlt = IRMA2Flt.String;
      ImDim = Dim.Value+2;
      ImZRatio = str2num(ZRatio.String);
      ReportFolder = ReportFolderPath2.String;
      if isempty(ReportFolder)
        ReportFolder = '.';
      end
      set(h,'ForegroundColor',[1 0 0]);
      set(State, 'String', 'Measuring 2...');
      pause(0.05);
      CallJOSE = 0;
      if ImDim ==3 | strcmp(Mode,'Trks')
      switch Export.String 
          case 'NoExport'
              Script = strcat([Script char(10) 'IRMA(''' MaskFolder ''',''' ReportFolder ''',''' Mode ''',' num2str(ImDim) ',' num2str(ImZRatio) ');']);
          case 'Export'      
              switch Mode
                  case 'Skls'
                    Script = strcat([Script char(10) 'IRMA(''' MaskFolder ''',''' ReportFolder ''',''' Mode ''', ' num2str(ImDim) ',{' num2str(ImZRatio) ',' SamplingStep.String ',''' ReportFolder ''',''' SklFormat.String '''});']);
                    ImZRatio = {ImZRatio,num2str(SamplingStep.String),ReportFolder,SklFormat.String};
                  case 'Objs'
                      Script = strcat([Script char(10) 'IRMA(''' MaskFolder ''',''' ReportFolder ''',''' Mode ''', ' num2str(ImDim) ',{' num2str(ImZRatio) ',' MeshDSRatio.String ',''' ReportFolder '''});']);
                      ImZRatio = {ImZRatio,str2num(MeshDSRatio.String),ReportFolder};
                  case 'Spts'
                    CallJOSE = 1;
                    Script = strcat([Script char(10) 'IRMA(''' MaskFolder ''',''' ReportFolder ''',''' Mode ''',' num2str(ImDim) ',' num2str(ImZRatio) ');']);
                  case 'Trks'
                    Script = strcat([Script char(10) 'IRMA(''' MaskFolder ''',''' ReportFolder ''',''' Mode ''', ' num2str(ImDim) ',{' num2str(ImZRatio) ','''',''' ReportFolder '''});']);
                    ImZRatio = {ImZRatio,'','.'};
              end
      end
      end
      try
          if isempty(ChanFolder)
              eval('[ReportFolder ExportMeshFolder] = IRMA(MaskFolder,ReportFolder,Mode,ImDim,ImZRatio);');
          else
              eval('[ReportFolder ExportMeshFolder] = IRMA(MaskFolder,ReportFolder,Mode,ImDim,ImZRatio,ChanFolder,ChanFlt);');
          end
          if CallJOSE == 1
            JOSE(ReportFolder,'Spts',InputFolderPath2.String,'CellInsight','','');
            Script = strcat([Script char(10) 'JOSE(''' ReportFolder ''',''Spts'',''' InputFolderPath2.String ''',''CellInsight'','''','''');']); 
            ExportMeshFolder = InputFolderPath2.String;
          end
          set(State, 'String', '');
          set(h,'ForegroundColor',[0 0 0]);
          %winopen(GetFullPath(ReportFolder));
          if ~isempty(ExportMeshFolder)
            winopen(GetFullPath(ExportMeshFolder));
          end
      catch
          set(State, 'String', 'Error');
      end
      end
  end

  function IRMAShow1(h, eventdata)
    try
        if numel(ReportFolderPath1.String)>1
            eval('winopen(GetFullPath(ReportFolderPath1.String))');
        end
    catch    
    end
  end

  function IRMAShow2(h, eventdata)
    try
        if numel(ReportFolderPath2.String)>1
            eval('winopen(GetFullPath(ReportFolderPath2.String))');
        end
    catch    
    end
  end

  function Journals1InPressed(h, eventdata)
    if ~isempty(InputFolderPath1.String) & ~isempty(OutputFolderPath1.String)
        eval('winopen(InputFolderPath1.String)');
    end
  end

  function Journals2InPressed(h, eventdata)
    if ~isempty(InputFolderPath2.String) & ~isempty(OutputFolderPath2.String)
        eval('winopen(InputFolderPath2.String)');
    end
  end

  function Journals1OutPressed(h, eventdata)
    if ~isempty(InputFolderPath1.String) & ~isempty(OutputFolderPath1.String)
        eval('winopen(OutputFolderPath1.String)');
    end
  end

  function Journals2OutPressed(h, eventdata)
    if ~isempty(InputFolderPath2.String) & ~isempty(OutputFolderPath2.String)
        eval('winopen(OutputFolderPath2.String)');
    end
  end

  function DimButtonPressed(h, eventdata)
    if get(Dim, 'Value') == 0
      set(Dim, 'String', '2D');
      set(ZRatio,'Enable','off');
      set(MeshDSRatio,'Enable','off');
      set(SamplingStep,'Enable','off');
    else
      set(Dim, 'String', '3D');
      set(ZRatio,'Enable','on');
      set(MeshDSRatio,'Enable','on');
      set(SamplingStep,'Enable','on');
    end
  end

  function DispButtonPressed(h, eventdata)
    if get(Disp, 'Value') == 0
      set(Disp, 'String', 'Batch');
    else
      set(Disp, 'String', 'Show');
    end  
  end

  function ExportButtonPressed(h, eventdata)
    if get(Export, 'Value') == 0
      set(Export, 'String', 'NoExport');
    else
      set(Export, 'String', 'Export');
    end  
  end

  function SklFormatButtonPressed(h, eventdata)
    if get(SklFormat, 'Value') == 0
      set(SklFormat, 'String', 'SWC');
    else
      set(SklFormat, 'String', 'OBJ');
    end  
  end

  function TLButtonPressed(h, eventdata)
    if get(TL, 'Value') == 0
      set(TL, 'String', '-');
    else
      set(TL, 'String', 'TL');
    end  
  end

  function saveState(h, eventdata)
    [file,path] = uiputfile('./Projects/.mat','Save project');
    if file ~= 0
        out = saveGUIstate(S);
        save(strcat([path '/' file]),'out');
    end
  end

  function loadState(h, eventdata)
     [file,path] = uigetfile('./Projects/.mat','Load project');
     if file ~= 0
         load(strcat([path '/' file]),'out');
         loadGUIstate(out, S);
         %% Fix toggle button states
         switch get(Dim, 'Value')
             case 0
                set(Dim, 'String', '2D');
                set(ZRatio,'Enable','off');
                set(MeshDSRatio,'Enable','off');
                set(SamplingStep,'Enable','off');
             case 1
                set(Dim, 'String', '3D');
                set(ZRatio,'Enable','on');
                set(MeshDSRatio,'Enable','on');
                set(SamplingStep,'Enable','on');
         end 
         switch get(Disp, 'Value')
             case 0
                set(Disp, 'String', 'Batch');
             case 1
                set(Disp, 'String', 'Show');
         end
         switch get(Export, 'Value')
             case 0
                set(Export, 'String', 'NoExport');
             case 1
                set(Export, 'String', 'Export');
         end
         switch get(TL, 'Value')
             case 0
                set(TL, 'String', '-');
             case 1
                set(TL, 'String', 'TL');
         end
         switch get(SklFormat, 'Value')
             case 0
                set(SklFormat, 'String', 'SWC');
             case 1
                set(SklFormat, 'String', 'OBJ');
         end
     end
  end

  function RunAllPressed(h, eventdata)
    Script = '';
    set(Interface,'Enable','off');
    Journals1Run(h, eventdata);
    while strcmp(get(State, 'String'),'Processing Journal1...') == 1; 
        pause(0.05);
    end
    Journals2Run(h, eventdata);
    while strcmp(get(State, 'String'),'Processing Journal2...') == 1; 
        pause(0.05);
    end
    IRMARunPressed1(h, eventdata);
    while strcmp(get(State, 'String'),'Measuring1...') == 1;
        pause(0.05);
    end
    IRMARunPressed2(h, eventdata);
    while strcmp(get(State, 'String'),'Measuring2...') == 1;
        pause(0.05);
    end
    set(Interface,'Enable','on');
    disp(Script);
  end
      
  function DocumentationPressed(h, eventdata)
    web('https://sebastients.github.io/user_guide.html');
  end

  function ToolsPressed(h, eventdata)
    eval('winopen(GetFullPath(''./Tools''))');
  end

  function ExitPressed(h, eventdata)
    close all force;
  end

end
function JSB

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
  global Files;
  fighandle = figure(10);
  set(fighandle,'MenuBar','none','Name','Job Script Builder','NumberTitle','off');
  set(fighandle,'CloseRequestFcn',[]);
  Disp = uicontrol('Style','ToggleButton','String','Hide','Position',[20,400,60,20],'CallBack', @DispButtonPressed);
  Dim = uicontrol('Style','ToggleButton','String','2D','Position',[80,400,60,20],'CallBack', @DimButtonPressed);
  ZRatio = uicontrol('Style','PushButton','String','1','Position',[140,400,60,20],'Enable','off','CallBack', @ZRatioButtonPressed);
  MeshDSRatio = uicontrol('Style','PushButton','String','0.5','Position',[200,400,60,20],'Enable','off','CallBack', @MeshDSButtonPressed);
  SamplingStep = uicontrol('Style','PushButton','String','4','Position',[260,400,60,20],'Enable','off','CallBack', @SamplingStepButtonPressed);
  SaveButton = uicontrol('Style','PushButton','String','Save','Position',[360,400,60,20],'CallBack', @saveState);
  LoadButton = uicontrol('Style','PushButton','String','Load','Position',[420,400,60,20],'CallBack', @loadState);
  ExitButton = uicontrol('Style','PushButton','String','Exit','Position',[480,400,60,20],'CallBack', @ExitPressed);
  InputFolderButton1 = uicontrol('Style','PushButton','String','I1','Position',[20,340,20,20],'CallBack', @InputFolderPressed1);
  InputFolderPath1 = uicontrol('Style','Edit','String','','Position',[40,340,240,20]);
  OutputFolderButton1 = uicontrol('Style','PushButton','String','O1','Position',[20,320,20,20],'CallBack', @OutputFolderPressed1);
  OutputFolderPath1 = uicontrol('Style','Edit','String','.','Position',[40,320,240,20]);
  InputFolderButton2 = uicontrol('Style','PushButton','String','I2','Position',[280,340,20,20],'CallBack', @InputFolderPressed2);
  InputFolderPath2 = uicontrol('Style','Edit','String','.','Position',[300,340,240,20]);
  OutputFolderButton2 = uicontrol('Style','PushButton','String','O2','Position',[280,320,20,20],'CallBack', @OutputFolderPressed2);
  OutputFolderPath2 = uicontrol('Style','Edit','String','','Position',[300,320,240,20]);
  Journal1Select = uicontrol('Style','PushButton','String','Journal1','Position',[20,300,260,20],'CallBack', @Journals1Select);
  Journal2Select = uicontrol('Style','PushButton','String','Journal2','Position',[280,300,260,20],'CallBack', @Journals2Select);
  Journal1Name = uicontrol('Style','Edit','String','','Position',[20,280,260,20]);
  Journal2Name = uicontrol('Style','Edit','String','','Position',[280,280,260,20]);
  Journal1Edit = uicontrol('Style','PushButton','String','Edit','Position',[20,260,260,20],'CallBack', @Journals1Edit);
  Journal2Edit = uicontrol('Style','PushButton','String','Edit','Position',[280,260,260,20],'CallBack', @Journals2Edit);
  Journal1Run = uicontrol('Style','PushButton','String','Run Journal 1','Position',[20,240,260,20],'CallBack', @Journals1Run);
  Journal2Run = uicontrol('Style','PushButton','String','Run Journal 2','Position',[280,240,260,20],'CallBack', @Journals2Run);
  Journal1InOut = uicontrol('Style','PushButton','String','Show In/Out','Position',[20,220,260,20],'CallBack', @Journals1InOutPressed);
  Journal2InOut = uicontrol('Style','PushButton','String','Show In/Out','Position',[280,220,260,20],'CallBack', @Journals2InOutPressed);
  IRMA1Mask = uicontrol('Style','popupmenu','String',{'O1','O2'},'Position',[20,180,40,20]);
  IRMA1Chan = uicontrol('Style','popupmenu','String',{'-','I1','I2','O1','O2'},'Position',[20,155,40,20]);
  IRMA1Flt = uicontrol('Style','Edit','String','*.tif','Position',[65,155,120,20]);
  IRMA1Mode = uicontrol('Style','popupmenu','String',{'Objs','Skls','Spts','Trks','Spst'},'Position',[20,130,60,20]);
  ReportFolderButton1 = uicontrol('Style','PushButton','String','R1','Position',[20,100,20,20],'CallBack', @ReportFolderPressed1);
  ReportFolderPath1 = uicontrol('Style','Edit','String','','String','.','Position',[40,100,240,20]);
  ReportFolderButton2 = uicontrol('Style','PushButton','String','R2','Position',[280,100,20,20],'CallBack', @ReportFolderPressed2);
  ReportFolderPath2 = uicontrol('Style','Edit','String','','String','.','Position',[300,100,240,20]);
  IRMA2Mask = uicontrol('Style','popupmenu','String',{'O2','O1'},'Position',[280,180,40,20]);
  IRMA2Chan = uicontrol('Style','popupmenu','String',{'-','I2','I1','O2','O1'},'Position',[280,155,40,20]);
  IRMA2Flt = uicontrol('Style','Edit','String','*.tif','Position',[325,155,120,20]);
  IRMA2Mode = uicontrol('Style','popupmenu','String',{'Objs','Skls','Spts','Trks','Spst'},'Position',[280,130,60,20]);
  IRMA1Run = uicontrol('Style','PushButton','String','Measure 1','Position',[20,80,260,20],'CallBack', @IRMARunPressed1);
  IRMA2Run = uicontrol('Style','PushButton','String','Measure 2','Position',[280,80,260,20],'CallBack', @IRMARunPressed2);
  IRMA1Show = uicontrol('Style','PushButton','String','Show some Reports','Position',[20,60,260,20],'CallBack', @IRMAShow1);
  IRMA2Show = uicontrol('Style','PushButton','String','Show some Reports','Position',[280,60,260,20],'CallBack', @IRMAShow2);
  S.Disp = Disp;
  S.Dim = Dim;
  S.ZRatio = ZRatio;
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
  S.IRMA1Mode = IRMA1Mode;
  S.ReportFolderPath1 = ReportFolderPath1;
  S.ReportFolderPath2 = ReportFolderPath2;
  S.IRMA2Mask = IRMA2Mask;
  S.IRMA2Chan = IRMA2Chan;
  S.IRMA2Mode = IRMA2Mode;
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
  function InputFolderPressed1(h, eventdata)
      folder_name = uigetdir('./Images/');
      set(InputFolderPath1, 'String', folder_name);
  end
    
  function OutputFolderPressed1(h, eventdata)
      folder_name = uigetdir('./Results/Images/');
      set(OutputFolderPath1, 'String', folder_name);
  end
  
  function InputFolderPressed2(h, eventdata)
      folder_name = uigetdir('./Images/');
      set(InputFolderPath2, 'String', folder_name);
  end
    
  function OutputFolderPressed2(h, eventdata)
      folder_name = uigetdir('./Results/Images/');
      set(OutputFolderPath2, 'String', folder_name);
  end

  function ReportFolderPressed1(h, eventdata)
      folder_name = uigetdir('./Results/Reports/');
      set(ReportFolderPath1, 'String', folder_name);
  end

  function ReportFolderPressed2(h, eventdata)
      folder_name = uigetdir('./Results/Reports/');
      set(ReportFolderPath2, 'String', folder_name);
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
      disp(strcat([str FileName]));
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
      disp(strcat([str FileName]));
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
      switch Dim.String
          case '2D'
            open(strcat(['E:/LOBSTER/Journals/jl/' Journal2Name.String]));
          case '3D'
            open(strcat(['E:/LOBSTER/Journals/jls/' Journal2Name.String]));
      end
      end
  end

  function Journals1Run(h, eventdata)  
      if ~isempty(Journal1Name.String)
          set(OutputFolderPath1, 'String', 'Processing...');
          pause(0.05);
          switch Disp.String
              case 'Show'
                eval('[InputFolder OutputFolder] = JENI(Journal1Name.String);');
              case 'Hide'  
                eval('[InputFolder OutputFolder] = GENI(Journal1Name.String);');  
          end
          set(OutputFolderPath1, 'String', OutputFolder);
      end
  end

  function Journals2Run(h, eventdata)  
      if ~isempty(Journal2Name.String)
          set(OutputFolderPath2, 'String', 'Processing...');
          pause(0.05);
          switch Disp.String
              case 'Show'
                eval('[InputFolder OutputFolder] = JENI(Journal2Name.String);');
              case 'Hide'
                eval('[InputFolder OutputFolder] = GENI(Journal2Name.String);');
          end
          set(OutputFolderPath2, 'String', OutputFolder);
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
      end
      ChanFlt = IRMA1Flt.String;
      ImDim = Dim.Value+2;
      ImZRatio = str2num(ZRatio.String);
      ReportFolder = ReportFolderPath1.String;
      set(ReportFolderPath1, 'String', 'Processing...');
      pause(0.05);
      if isempty(ChanFolder)
          eval('ReportFolder = IRMA(MaskFolder,ReportFolder,Mode,ImDim,ImZRatio);');
      else
          eval('ReportFolder = IRMA(MaskFolder,ReportFolder,Mode,ImDim,ImZRatio,ChanFolder,ChanFlt);');  
      end
      set(ReportFolderPath1, 'String', ReportFolder);
  end
  
  function IRMARunPressed2(h, eventdata)
      switch IRMA2Mask.Value
          case 1
              MaskFolder = OutputFolderPath2.String;
          case 2
              MaskFolder = OutputFolderPath1.String;
      end
      Mode = IRMA2Mode.String{IRMA2Mode.Value};
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
      end
      ChanFlt = IRMA2Flt.String;
      ImDim = Dim.Value+2;
      ImZRatio = str2num(ZRatio.String);
      ReportFolder = ReportFolderPath2.String;
      set(ReportFolderPath2, 'String', 'Processing...');
      pause(0.05);
      if isempty(ChanFolder)
          eval('ReportFolder = IRMA(MaskFolder,ReportFolder,Mode,ImDim,ImZRatio);');
      else
          eval('ReportFolder = IRMA(MaskFolder,ReportFolder,Mode,ImDim,ImZRatio,ChanFolder,ChanFlt);');
      end
      set(ReportFolderPath2, 'String', ReportFolder);
  end

  function IRMAShow1(h, eventdata)
    Files = dir(strcat([ReportFolderPath1.String '*.csv']));
    for i = 1:min(numel(Files),3)
        open(strcat([pwd '/' ReportFolderPath1.String Files(i).name]));
    end
  end

  function IRMAShow2(h, eventdata)
    Files = dir(strcat([ReportFolderPath2.String '*.csv']));
    for i = 1:min(numel(Files),3)
        open(strcat([pwd '/' ReportFolderPath2.String Files(i).name]));
    end
  end

  function Journals1InOutPressed(h, eventdata)
    eval('winopen(InputFolderPath1.String)');
    eval('winopen(OutputFolderPath1.String)');
  end

  function Journals2InOutPressed(h, eventdata)
    eval('winopen(InputFolderPath2.String)');
    eval('winopen(OutputFolderPath2.String)');
  end

  function DimButtonPressed(h, eventdata)
    if get(Dim, 'Value') == 0
      set(Dim, 'String', '2D');
    else
      set(Dim, 'String', '3D');
    end;  
  end

  function DispButtonPressed(h, eventdata)
    if get(Disp, 'Value') == 0
      set(Disp, 'String', 'Hide');
    else
      set(Disp, 'String', 'Show');
    end;  
  end

  function saveState(h, eventdata)
    [file,path] = uiputfile('./Projects/.mat','Save project');
    out = saveGUIstate(S);
    save(strcat([path '/' file]),'out');
  end

  function loadState(h, eventdata)
     [file,path] = uigetfile('./Projects/.mat','Load project');
     load(strcat([path '/' file]),'out');
     loadGUIstate(out, S);
  end

  function ExitPressed(h, eventdata)
    close all force;
  end

end
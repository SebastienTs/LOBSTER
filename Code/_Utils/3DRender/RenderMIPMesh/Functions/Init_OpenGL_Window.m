function Form1 = Init_OpenGL_Window(action,hObject,V,FV,eventdata,id)

% OpenGL_Window, this function creates a window for rendering 
% OpenGL graphics with mouse controlled camera.
% 
% OpenGL_Window(Action,Options);
%
% Left mouse button, Rotate
% Center mouse button, Translate
% Right mous button, Zoom
%
% Start an OpenGL Window with
%
% OpenGL_Window('new', name_of_PaintFunction)
%
% Function is written by D.Kroon University of Twente (April 2009)

if(strcmpi(action,'new')), Form1 = make_new_window(hObject,V,FV); return; end

% From id to stored variable name 
StoreName=['OpenGL' num2str(id)];
data=getappdata(0,[StoreName '_data']);
data.FirstRender = false;

% Save the data
setappdata(0,[StoreName '_data'],data);

% Initialize window view matrix
setOpenGLViewingMatrix(data.viewmatrix,data.zoom,data.Width,data.Height);

% Draw Polygons
eval([data.paint_function_name '(id,V)']);

% Swap buffers
refresh_screen(id);

function Form1=make_new_window(paint_function_name, V, FV)
    % addpath, so if you change folder, callbacks still work.
    functionname='OpenGL_Window.m';
    functiondir=which(functionname);
    functiondir=functiondir(1:end-length(functionname));
    try addpath(functiondir); catch me, disp(me.message); end

    %% Set the default options
    defaultoptions=struct( ...
        'Width', 512, ...
        'Height', 512);

    %% Check the input options
    if(~exist('options','var')), 
        options=defaultoptions; 
    else
        tags = fieldnames(defaultoptions);
        for i=1:length(tags)
             if(~isfield(options,tags{i})),  options.(tags{i})=defaultoptions.(tags{i}); end
        end
        if(length(tags)~=length(fieldnames(options))), 
            warning('Render:unknownoption','unknown options found');
        end
    end

    % Add the needed Windows  Assemblies
    NET.addAssembly('System');
    NET.addAssembly('System.Windows.Forms');

    % Make A new Form (.NET window)
    Form1=System.Windows.Forms.Form;
    Form1.Width=options.Width;
    Form1.Height=options.Height;
    Form1.Visible=true;
   
    % Make an simple Opengl Control for the .NET window
    simpleOpenGlControl1 = Tao.Platform.Windows.SimpleOpenGlControl;

    % Set all OpenGL Control parameters
    simpleOpenGlControl1.AccumBits = 0; 
    simpleOpenGlControl1.AutoCheckErrors = false;
    simpleOpenGlControl1.AutoFinish = false;
    simpleOpenGlControl1.AutoMakeCurrent = true;
    simpleOpenGlControl1.AutoSwapBuffers = false;
    simpleOpenGlControl1.BackColor = System.Drawing.Color.Black;
    simpleOpenGlControl1.ColorBits = 32;
    simpleOpenGlControl1.DepthBits = 24;
    simpleOpenGlControl1.Location = System.Drawing.Point(0, 0);
    simpleOpenGlControl1.Name = 'simpleOpenGlControl1';
    simpleOpenGlControl1.Size = System.Drawing.Size(Form1.Width, Form1.Height);
    simpleOpenGlControl1.StencilBits = 0;
    simpleOpenGlControl1.TabIndex = 0;

    % Add the control to the figure,
    Form1.Controls.Add(simpleOpenGlControl1);

    % Initialize the Control
    simpleOpenGlControl1.InitializeContexts();
    
    % Generate an id
    id=round(rand(1)*100000); 
    str_id=num2str(id);
            
    % Add Mouse listeners
    addlistener(simpleOpenGlControl1,'MouseDown',eval(['@(src,evnt)OpenGL_Window(''MouseDown'',src,evnt,' str_id ')']));
    addlistener(simpleOpenGlControl1,'MouseMove',eval(['@(src,evnt)OpenGL_Window(''MouseMove'',src,evnt,' str_id ')']));
    addlistener(Form1,'FormClosing',eval(['@(src,evnt)OpenGL_Window(''FormClosing'',src,evnt,' str_id ')']));
    addlistener(Form1,'FormClosed',eval(['@(src,evnt)OpenGL_Window(''FormClosed'',src,evnt,' str_id ')']));
    addlistener(Form1,'SizeChanged',eval(['@(src,evnt)OpenGL_Window(''SizeChanged'',src,evnt,' str_id ')']));
    addlistener(simpleOpenGlControl1,'KeyPress',eval(['@(src,evnt)OpenGL_Window(''KeyPress'',src,evnt,' str_id ')']));
    
    % The initial (Identity) viewmatrix 
    viewmatrix=[1 0 0 0;0 -1 0 0; 0 0 1 0;0 0 0 1];
    
    % Use a struct as data container
    data.viewmatrix=viewmatrix;
    data.Width=options.Width;
    data.Height=options.Height;
    data.LastXY=[0 0];
    data.zoom=2;
    data.FirstRender=true;
    data.RenderWidth = simpleOpenGlControl1.Size.Width;
    data.RenderHeight = simpleOpenGlControl1.Size.Height;
    data.paint_function_name=paint_function_name;
            
    % Store all data for this OpenGL window
    % (Store also OpenGL control object, otherwise listeners are disposed)
    StoreName=['OpenGL' num2str(id)];
    setappdata(0,[StoreName '_Control'],simpleOpenGlControl1);
    setappdata(0,[StoreName '_Form'],Form1);
    setappdata(0,[StoreName '_data'],data);
    
    % Initialize window view matrix
    setOpenGLViewingMatrix(data.viewmatrix,data.zoom,data.Width,data.Height);
    % Draw Polygons
    if isempty(FV)
        eval([data.paint_function_name '(id,V)']);
    else
        eval([data.paint_function_name '(id,V,FV)']);
    end
    % Swap buffers
    refresh_screen(id);

function refresh_screen(id)
    % Swap buffer to the new rendered image
    StoreName=['OpenGL' num2str(id)];
    simpleOpenGlControl1=getappdata(0,[StoreName '_Control']);
    simpleOpenGlControl1.SwapBuffers(); 

function setOpenGLViewingMatrix(viewmatrix,zoom,Width,Height)
    % Allow to use GL functions without prefixing with Tao.Opengl.
    import Tao.OpenGl.*

    % Set projection matrix
    Gl.glMatrixMode(Gl.GL_PROJECTION);
    Gl.glLoadIdentity();
   
    % Screen coordinates are set from 0,0 to 1,1
    tx=0.5*(2^zoom);
    ty=0.5*(2^zoom)*(Height/Width);
    Gl.glOrtho(0.5-tx, 0.5+tx, 0.5-ty, 0.5+ty, 0.001, 5);
    
    % Align viewmatrix before the viewer screen
    viewmatrix=TranslateMatrix([0.5 0.5 -2.5])*viewmatrix;
    viewarray=NET.convertArray(viewmatrix(:), 'System.Double',16);
    Gl.glMultMatrixd(viewarray);
    
    % The Model matrix (no changes)
    Gl.glMatrixMode(Gl.GL_MODELVIEW);
    Gl.glLoadIdentity();

    % Initial Depth buffer value of all pixels
    Gl.glClearDepth(1);

    % Set to default Depth Testing
    Gl.glDepthFunc(Gl.GL_LEQUAL);  
    
    % Set viewport to fit opengl window
    Gl.glViewport(0, 0, Width, Height);
    	
function M=TranslateMatrix(t)
	M=[1 0 0 t(1);
	   0 1 0 t(2);
	   0 0 1 t(3);
	   0 0 0 1];
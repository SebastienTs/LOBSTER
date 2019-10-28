function OpenGL_Window(action,hObject, eventdata, id)
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

    % From id to stored variable name 
    StoreName=['OpenGL' num2str(id)];

    data=getappdata(0,[StoreName '_data']);
    
    switch(action)

        case 'MouseMove'
            button=[];
            if(eventdata.Button==System.Windows.Forms.MouseButtons.Left), button='Left'; end
            if(eventdata.Button==System.Windows.Forms.MouseButtons.None), button='None'; end
            if(eventdata.Button==System.Windows.Forms.MouseButtons.Right), button='Right'; end
            if(eventdata.Button==System.Windows.Forms.MouseButtons.Middle), button='Middle'; end
            if(eventdata.Button==System.Windows.Forms.MouseButtons.XButton1), button='XButton1'; end
            if(eventdata.Button==System.Windows.Forms.MouseButtons.XButton2), button='XButton2'; end
            XY=double([eventdata.X eventdata.Y]);
            diffXY=XY-data.LastXY;
             switch(button)
                case 'Left'
                     R=RotationMatrix([diffXY(2) diffXY(1) 0]);
                     data.viewmatrix(1:3,1:3)=R(1:3,1:3)*data.viewmatrix(1:3,1:3);
                case 'Right'
                     data.zoom=data.zoom+8*diffXY(2)/data.Width;
                case 'Middle'
                    t=[data.zoom*diffXY(1)/data.Width -data.zoom*diffXY(2)/data.Width 0];
                    T=[0 0 0 t(1);
                       0 0 0 t(2);
                       0 0 0 t(3);
                       0 0 0 0];
                     data.viewmatrix=data.viewmatrix+T;
                otherwise
                return
             end
            data.LastXY=XY;
        case 'MouseDown'
             data.LastXY=double([eventdata.X eventdata.Y]);
        case 'MouseUp'
        case 'KeyPress'
            switch eventdata.KeyChar
                case ' '
                    data.viewmatrix=[1 0 0 0;0 1 0 0;0 0 1 0;0 0 0 1];
                    data.program_mip_id = loadOpenGLShader('fragment_mip_render.glsl',[],data.LOWVAL,data.HGHVAL);
                case 'c'
                    prompt = {'Low value:','High value:'};
                    dlg_title = 'LUT';
                    num_lines = 1;
                    defaultans = {data.LOWVAL,data.HGHVAL};
                    answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
                    if (str2num(answer{1}) < 0) || (str2num(answer{1}) > 1)
                        answer{1} = '0.0';
                    end
                    if (str2num(answer{2}) < 0) || (str2num(answer{2}) > 1)
                        answer{2} = '1.0';
                    end
                    if length(answer{1})<3
                        answer{1} = '0.0';
                    end
                    if length(answer{2})<3
                        answer{2} = '1.0';
                    end
                    data.program_mip_id = loadOpenGLShader('fragment_mip_render.glsl',[],answer{1},answer{2});
                    data.LOWVAL = answer{1};
                    data.HGHVAL = answer{2};
                case 'm'
                    data.showmesh = ~data.showmesh;
            end
            setappdata(0,[StoreName '_data'],data);
        case 'FormClosing'
            % Remove OpenGL control
            simpleOpenGlControl1=getappdata(0,[StoreName '_Control']);
            simpleOpenGlControl1.Dispose();
            rmappdata(0,[StoreName '_Control']);
            return;
        case 'FormClosed'
            % Remove Form and Window data
            rmappdata(0,[StoreName '_Form']);
            rmappdata(0,[StoreName '_data']);
            return;
        case 'SizeChanged'
            simpleOpenGlControl1=getappdata(0,[StoreName '_Control']);
            Form1=getappdata(0,[StoreName '_Form']);
            data.Width=double(Form1.Width);
            data.Height=double(Form1.Height);
            simpleOpenGlControl1.Size = System.Drawing.Size(Form1.Width, Form1.Height);
            % Get Render (window) size
            data.RenderWidth = simpleOpenGlControl1.Size.Width;
            data.RenderHeight = simpleOpenGlControl1.Size.Height;
        otherwise      
    end
    
    switch(action)
         case 'SizeChanged'
            data.WindowsizeChanged = 1;
         otherwise
            data.WindowsizeChanged = 0;
    end
    
    data.FirstRender=false;

    % Save the data
    setappdata(0,[StoreName '_data'],data);

    % Initialize window view matrix
    setOpenGLViewingMatrix(data.viewmatrix,data.zoom,data.Width,data.Height);

    % Draw scene
    eval([data.paint_function_name '(id)']);

    % Swap buffers
    refresh_screen(id);
   
end

function refresh_screen(id)
    % Swap buffer to the new rendered image
    StoreName=['OpenGL' num2str(id)];
    simpleOpenGlControl1=getappdata(0,[StoreName '_Control']);
    simpleOpenGlControl1.SwapBuffers(); 
end

function setOpenGLViewingMatrix(viewmatrix,zoom,Width,Height)
    % Allow to use GL functions without prefixing with Tao.Opengl.
    import Tao.OpenGl.*

    % Set projection matrix
    Gl.glMatrixMode(Gl.GL_PROJECTION);
    Gl.glLoadIdentity();
   
    % Screen coordinates are set from 0,0 to 1,1
    tx=0.5*(2^zoom);
    ty=0.5*(2^zoom)*(Height/Width);
    Gl.glOrtho(0.5-tx, 0.5+tx, 0.5-ty, 0.5+ty, 0.001,5);
    
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
end

function M=ResizeMatrix(s)
	M=[s(1) 0 0 0;
	   0 s(2) 0 0;
	   0 0 s(3) 0;
	   0 0 0 1];
end

function R=RotationMatrix(r)
% Determine the rotation matrix (View matrix) for rotation angles xyz ...
    Rx=[1 0 0 0; 0 cosd(r(1)) -sind(r(1)) 0; 0 sind(r(1)) cosd(r(1)) 0; 0 0 0 1];
    Ry=[cosd(r(2)) 0 sind(r(2)) 0; 0 1 0 0; -sind(r(2)) 0 cosd(r(2)) 0; 0 0 0 1];
    Rz=[cosd(r(3)) -sind(r(3)) 0 0; sind(r(3)) cosd(r(3)) 0 0; 0 0 1 0; 0 0 0 1];
    R=Rx*Ry*Rz;
end

function M=TranslateMatrix(t)
	M=[1 0 0 t(1);
	   0 1 0 t(2);
	   0 0 1 t(3);
	   0 0 0 1];
end
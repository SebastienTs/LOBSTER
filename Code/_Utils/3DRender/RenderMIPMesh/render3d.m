function render3d(id,V,FV)
    % Function is written by D.Kroon University of Twente (April 2009)

    % From id get the render data
    StoreName=['OpenGL' num2str(id)];
    data = getappdata(0,[StoreName '_data']);

    % Allow to use GL functions without prefixing with Tao.Opengl.
    import Tao.OpenGl.*

    if(data.FirstRender)
       % Load texture
       data.TextureID = loadOpenGLTexture(V,Gl.GL_ALPHA,Gl.GL_ALPHA8,'linear');
       % Load shaders
       data.LOWVAL = '0.0';
       data.HGHVAL = '1.0';
       data.WindowsizeChanged = 0;
       data.program_mip_id = loadOpenGLShader('fragment_mip_render.glsl',[],data.LOWVAL,data.HGHVAL);
       data.program_depth_id = loadOpenGLShader('fragment_depth_texture.glsl',[],0,0);
       data.ZScale = FV.ZScale;
       setappdata(0,[StoreName '_data'],data);
    end   
    
    % Set depth testing enabled
    Gl.glEnable(Gl.GL_DEPTH_TEST);

    % Compute depth texture
    data = makeDepthTexture(data);

    % Set background clear color to black
    Gl.glClearColor(0.0, 0.0, 0.0, 0.0);  
    
    % Clear the color and depth buffer
    Gl.glClear(int32(bitor(uint32(Gl.GL_COLOR_BUFFER_BIT),uint32(Gl.GL_DEPTH_BUFFER_BIT)))); 
    
    % Sent variables to shader, in this case Window size
    uniform_WindowSize = Gl.glGetUniformLocation(data.program_mip_id,char2string('WindowSize'));

    % Enable shader program
    Gl.glUseProgramObjectARB(data.program_mip_id);

    % Set window size
    Gl.glUniform2f(uniform_WindowSize, data.RenderWidth, data.RenderHeight);

    % Enable culling
    Gl.glEnable(Gl.GL_CULL_FACE);
    Gl.glCullFace(Gl.GL_FRONT);

    % Select an texture unit
    % Select first texture unit
    Gl.glActiveTexture(Gl.GL_TEXTURE0);
    Gl.glBindTexture(Gl.GL_TEXTURE_3D, data.TextureID);
    texture_3d = Gl.glGetUniformLocationARB(data.program_mip_id, 'texture_3d');
    Gl.glUniform1iARB(texture_3d,0);

    % Select second texture unit
    Gl.glActiveTexture(Gl.GL_TEXTURE1);
    Gl.glBindTexture(Gl.GL_TEXTURE_2D, data.FrameBufferTextureID);
    texture_depth = Gl.glGetUniformLocationARB(data.program_mip_id, 'texture_depth');
    Gl.glUniform1iARB(texture_depth,1);

    % Draw vertices
    DrawCube(data.ZScale);

    % Disable culling
    Gl.glDisable(Gl.GL_CULL_FACE);

    % Flush the pipeline, update the graphics buffer
    Gl.glFlush();

    % Disable shaderprogram
    Gl.glUseProgram(0);

    % Store the render data
    setappdata(0,[StoreName '_data'],data);
end

function data = makeDepthTexture(data)
    % Allow to use GL functions without prefixing with Tao.Opengl.
    import Tao.OpenGl.*

    % Make a new external framebuffer if windows size has changed
    if(data.WindowsizeChanged)
        if(isfield(data,'FrameBufferTextureID'))
            % Delete the framebuffer texture
            Gl.glDeleteTextures(1, data.FrameBufferTextureID);
            % Delete the external framebuffer
            Gl.glDeleteFramebuffersEXT(1, data.FrameBufferID);
        end
    end
    
    % Set FrameBuffer if window size has changed or during first rendering
    if((data.FirstRender)||(data.WindowsizeChanged))
        [data.FrameBufferTextureID, data.FrameBufferID] = makeRender2Texture(data.RenderWidth ,data.RenderHeight);
    end
    
    % Bind frame buffer id to extern
    Gl.glBindFramebufferEXT(Gl.GL_FRAMEBUFFER_EXT, data.FrameBufferID);
    
    % Enable shader program
    Gl.glUseProgram(data.program_depth_id);

    % Enable culling
    Gl.glEnable(Gl.GL_CULL_FACE);
    Gl.glCullFace(Gl.GL_BACK);

    % Set background clear color to black
    Gl.glClearColor(1.0, 0.0, 0.0, 0.0);  

    % Clear the color and depth buffer
    Gl.glClear(int32(bitor(uint32(Gl.GL_COLOR_BUFFER_BIT),uint32(Gl.GL_DEPTH_BUFFER_BIT)))); 

    % Enable texture rendering
    Gl.glEnable(Gl.GL_TEXTURE_2D);

    % Also bind texture of frame buffer
    Gl.glBindTexture(Gl.GL_TEXTURE_2D, data.FrameBufferTextureID);

    % Draw vertices
    DrawCube(data.ZScale);
    
    % Flush the pipeline, update the graphics buffer
    Gl.glFlush();

    % Disable texture rendering
    Gl.glDisable(Gl.GL_TEXTURE_2D);

    % Unbind the FBO for now
    Gl.glBindFramebufferEXT(Gl.GL_FRAMEBUFFER_EXT, 0); 

    % Disable shaderprogram
    Gl.glUseProgram(0);

    % Wait for completion and measure time to completion
    %tic;
    Gl.glFinish();
    %t = toc;
    %disp(1/t);
    
end

function DrawCube(ZScale)
    % Allow to use GL functions without prefixing with Tao.Opengl.
    import Tao.OpenGl.*

    cornersx=[-1  1 -1  1 -1  1 -1  1];
    cornersy=[-1 -1  1  1 -1 -1  1  1];
    cornersz=[-ZScale -ZScale  -ZScale -ZScale  ZScale  ZScale  ZScale  ZScale];
    cornersxt=[0 1 0 1 0 1 0 1];
    cornersyt=[0 0 1 1 0 0 1 1];
    cornerszt=[0 0 0 0 1 1 1 1];

    Gl.glBegin(Gl.GL_QUADS);
    % 1e Face
    Gl.glTexCoord3f(cornersxt(1), cornersyt(1), cornerszt(1));
    Gl.glVertex3f(cornersx(1), cornersy(1), cornersz(1));
    Gl.glTexCoord3f(cornersxt(2), cornersyt(2), cornerszt(2));
    Gl.glVertex3f(cornersx(2), cornersy(2), cornersz(2));				
    Gl.glTexCoord3f(cornersxt(4), cornersyt(4), cornerszt(4));
    Gl.glVertex3f(cornersx(4), cornersy(4), cornersz(4));				
    Gl.glTexCoord3f(cornersxt(3), cornersyt(3), cornerszt(3));
    Gl.glVertex3f(cornersx(3), cornersy(3), cornersz(3));		
    % 2e Face
    Gl.glTexCoord3f(cornersxt(7), cornersyt(7), cornerszt(7));
    Gl.glVertex3f(cornersx(7), cornersy(7), cornersz(7));				
    Gl.glTexCoord3f(cornersxt(8), cornersyt(8), cornerszt(8));
    Gl.glVertex3f(cornersx(8), cornersy(8), cornersz(8));				
    Gl.glTexCoord3f(cornersxt(6), cornersyt(6), cornerszt(6));
    Gl.glVertex3f(cornersx(6), cornersy(6), cornersz(6));				
    Gl.glTexCoord3f(cornersxt(5), cornersyt(5), cornerszt(5));
    Gl.glVertex3f(cornersx(5), cornersy(5), cornersz(5));
    % 3e Face
    Gl.glTexCoord3f(cornersxt(1), cornersyt(1), cornerszt(1));
    Gl.glVertex3f(cornersx(1), cornersy(1), cornersz(1));				
    Gl.glTexCoord3f(cornersxt(5), cornersyt(5), cornerszt(5));
    Gl.glVertex3f(cornersx(5), cornersy(5), cornersz(5));				
    Gl.glTexCoord3f(cornersxt(6), cornersyt(6), cornerszt(6));
    Gl.glVertex3f(cornersx(6), cornersy(6), cornersz(6));				
    Gl.glTexCoord3f(cornersxt(2), cornersyt(2), cornerszt(2));
    Gl.glVertex3f(cornersx(2), cornersy(2), cornersz(2));
    % 4e Face
    Gl.glTexCoord3f(cornersxt(3), cornersyt(3), cornerszt(3));
    Gl.glVertex3f(cornersx(3), cornersy(3), cornersz(3));				
    Gl.glTexCoord3f(cornersxt(4), cornersyt(4), cornerszt(4));
    Gl.glVertex3f(cornersx(4), cornersy(4), cornersz(4));				
    Gl.glTexCoord3f(cornersxt(8), cornersyt(8), cornerszt(8));
    Gl.glVertex3f(cornersx(8), cornersy(8), cornersz(8));				
    Gl.glTexCoord3f(cornersxt(7), cornersyt(7), cornerszt(7));
    Gl.glVertex3f(cornersx(7), cornersy(7), cornersz(7));
    % 5e Face
    Gl.glTexCoord3f(cornersxt(4), cornersyt(4), cornerszt(4));
    Gl.glVertex3f(cornersx(4), cornersy(4), cornersz(4));				
    Gl.glTexCoord3f(cornersxt(2), cornersyt(2), cornerszt(2));
    Gl.glVertex3f(cornersx(2), cornersy(2), cornersz(2));				
    Gl.glTexCoord3f(cornersxt(6), cornersyt(6), cornerszt(6));
    Gl.glVertex3f(cornersx(6), cornersy(6), cornersz(6));				
    Gl.glTexCoord3f(cornersxt(8), cornersyt(8), cornerszt(8));
    Gl.glVertex3f(cornersx(8), cornersy(8), cornersz(8));
    % 6e Face
    Gl.glTexCoord3f(cornersxt(7), cornersyt(7), cornerszt(7));
    Gl.glVertex3f(cornersx(7), cornersy(7), cornersz(7));
    Gl.glTexCoord3f(cornersxt(5), cornersyt(5), cornerszt(5));
    Gl.glVertex3f(cornersx(5), cornersy(5), cornersz(5));				
    Gl.glTexCoord3f(cornersxt(1), cornersyt(1), cornerszt(1));
    Gl.glVertex3f(cornersx(1), cornersy(1), cornersz(1));				
    Gl.glTexCoord3f(cornersxt(3), cornersyt(3), cornerszt(3));
    Gl.glVertex3f(cornersx(3), cornersy(3), cornersz(3));				
    Gl.glEnd();
end

function str = char2string(tline)
    str = NET.createArray('System.String',1); 
    str.Set(0,tline);
    str = str.Get(0);
end
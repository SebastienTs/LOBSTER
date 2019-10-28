function [TextureID, FrameBufferID] = makeRender2Texture(Width,Height)
    % makeRender2Texture, this function generates an extern framebuffer which
    % is connected to an texture in an texture unit
    %
    %  [FrameBufferTextureID, FrameBufferID] = makeRender2Texture(Width,Height);
    % 
    % inputs,
    %   Width: width of framebuffer current opengl render window and texture
    %   Height: height of framebuffer and texture
    %
    % outputs,
    %   FrameBufferTextureID : The OpenGl ID of the texture binded to the external framebuffer
    %   FrameBufferID : The OpenGL ID of the external framebuffer
    %
    % Function is written by D.Kroon University of Twente (April 2009)

    % Allow to use GL functions without prefixing with Tao.Opengl.
    import Tao.OpenGl.*

    % First Flush the openGL pipeline
    Gl.glFlush();
    
    % Generate Extern frame buffer id
    FrameBufferID = Gl.glGenFramebuffersEXT(1);

    % Bind frame buffer id to extern
    Gl.glBindFramebufferEXT(Gl.GL_FRAMEBUFFER_EXT, FrameBufferID);
    
    % Create the render buffer for the depth
    FB_depthBuffer = Gl.glGenRenderbuffersEXT(1);
    Gl.glBindRenderbufferEXT(Gl.GL_RENDERBUFFER_EXT, FB_depthBuffer);
    
    % Reserve memory to store the buffer
    Gl.glRenderbufferStorageEXT(Gl.GL_RENDERBUFFER_EXT, Gl.GL_DEPTH_COMPONENT, Width, Height);
    
    % Now setup a texture to render to
    TextureID = Gl.glGenTextures(1);
    Gl.glBindTexture(Gl.GL_TEXTURE_2D, TextureID);

    % Set texture parameters 
    Gl.glTexParameterf(Gl.GL_TEXTURE_2D, Gl.GL_TEXTURE_WRAP_S, Gl.GL_CLAMP_TO_EDGE);
    Gl.glTexParameterf(Gl.GL_TEXTURE_2D, Gl.GL_TEXTURE_WRAP_T, Gl.GL_CLAMP_TO_EDGE);
    Gl.glTexParameterf(Gl.GL_TEXTURE_2D, Gl.GL_TEXTURE_MAG_FILTER, Gl.GL_LINEAR);
    Gl.glTexParameterf(Gl.GL_TEXTURE_2D, Gl.GL_TEXTURE_MIN_FILTER, Gl.GL_LINEAR);

    % Set type of texture data
    Gl.glTexImage2D(Gl.GL_TEXTURE_2D, 0, Gl.GL_RGBA8, Width, Height, 0, Gl.GL_RGBA, Gl.GL_UNSIGNED_BYTE, []);

    % And attach it to the FBO so we can render to it
    Gl.glFramebufferTexture2DEXT(Gl.GL_FRAMEBUFFER_EXT, Gl.GL_COLOR_ATTACHMENT0_EXT, Gl.GL_TEXTURE_2D, TextureID, 0);

    % Attach the depth render buffer to the FBO as it's depth attachment
    Gl.glFramebufferRenderbufferEXT(Gl.GL_FRAMEBUFFER_EXT, Gl.GL_DEPTH_ATTACHMENT_EXT, Gl.GL_RENDERBUFFER_EXT, FB_depthBuffer);

    status = Gl.glCheckFramebufferStatusEXT(Gl.GL_FRAMEBUFFER_EXT);
    if (status ~= Gl.GL_FRAMEBUFFER_COMPLETE_EXT)
      error('The card may not be compatible with Framebuffers. Try another bit depth.');
    end

    % Unbind the FBO for now
    Gl.glBindFramebufferEXT(Gl.GL_FRAMEBUFFER_EXT, 0);
end
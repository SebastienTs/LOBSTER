function TextureID=loadOpenGLTexture(I,TextureFormat,TextureInternalFormat,TextureInterpolation)
    %  Load Matlab Image data 2D or 3D into a texture
    %
    %  TextureID=loadOpenGLTexture(I,TextureFormat,TextureInternalFormat,TextureInterpolation)
    % 
    %  inputs,
    %   I : The matlab image data 2D or 3D (for example, m x n x 3 uint8)
    %   TextureFormat : Gl.GL_RGB, Gl.GL_ALPHA or some other format. 
    %   TextureInternalFormat: Gl.GL_RGB8, Gl.GL_ALPHA32F_ARB or some other format
    %   TextureInterpolation : 'nearest' or 'linear'
    %
    %  outputs,
    %   TextureID : The internal id of the texture, need to to bind the texture
    %           like Gl.glEnable(Gl.GL_TEXTURE_2D); Gl.glBindTexture(Gl.GL_TEXTURE_2D, TextureID);
    %
    %
    %  Example,
    %   I=imread('texture.png');
    %   TextureID=loadOpenGLTexture(I,Gl.GL_RGB,Gl.GL_RGB8,'linear');
    %
    % Function is written by D.Kroon University of Twente (April 2009)

    % Allow to use GL functions without prefixing with Tao.Opengl.
    import Tao.OpenGl.*

    % Determine if 2D or 3D texture
    Texture_is_2D = (size(I,3) == 1);

    % Grayscale images
    if(Texture_is_2D)
        TextureWidth=int32(size(I,1)); 
        TextureHeight=int32(size(I,2));       
    else
        % Set texture size to size of image
        TextureWidth=int32(size(I,1)); 
        TextureHeight=int32(size(I,2));
        TextureDepth=int32(size(I,3));
    end

    % Convert the data to .NET datatype
    switch class(I),
        case 'uint8'
            TextureDataType=Gl.GL_UNSIGNED_BYTE;
        case 'uint16'
            TextureDataType=Gl.GL_UNSIGNED_SHORT;
        otherwise
        error('loadOpenGLTexture:inputs','Not yet supported');
    end

    switch (TextureInterpolation)
        case 'nearest'
             TextureInterpolation=Gl.GL_NEAREST;
        case 'linear'
             TextureInterpolation=Gl.GL_LINEAR;
    end

    % Display no border
    TextureBorder = 0;

    % Check if multiple of 2
    if(mod(TextureWidth,2)), error('loadOpenGLTexture:inputs','Texture Width must be 2*n+2'); end
    if(mod(TextureHeight,2)), error('loadOpenGLTexture:inputs','Texture Height must be 2*n+2'); end

    % First flush the openGL pipeline
    Gl.glFlush();

    if(Texture_is_2D)
        % Enable 2D texturing
        Gl.glEnable(Gl.GL_TEXTURE_2D);
        % Create Texture id
        TextureID=Gl.glGenTextures(1);                            
        % tell OpenGL we're going to be setting up the texture name it gave us	
        Gl.glBindTexture(Gl.GL_TEXTURE_2D, TextureID);
        % when this texture needs to be shrunk to fit on small polygons, use linear interpolation of the texels to determine the color
        Gl.glTexParameteri(Gl.GL_TEXTURE_2D, Gl.GL_TEXTURE_MIN_FILTER, TextureInterpolation);
        % when this texture needs to be magnified to fit on a big polygon, use linear interpolation of the texels to determine the color
        Gl.glTexParameteri(Gl.GL_TEXTURE_2D, Gl.GL_TEXTURE_MAG_FILTER, TextureInterpolation);
        % Check if texture fits in video memory
        Gl.glTexImage2D(Gl.GL_PROXY_TEXTURE_2D, 0, TextureInternalFormat, TextureWidth, TextureHeight, TextureBorder, TextureFormat, TextureDataType, []);
        EnoughMemory=Gl.glGetTexLevelParameterfv(Gl.GL_PROXY_TEXTURE_2D, 0, Gl.GL_TEXTURE_WIDTH); EnoughMemory=double(EnoughMemory)>0;
        % Read the data into the texture structure
        if(EnoughMemory)
            Gl.glTexImage2D(Gl.GL_TEXTURE_2D, 0, TextureInternalFormat, TextureWidth, TextureHeight, TextureBorder, TextureFormat, TextureDataType, I(:));
        else
            warning('loadOpenGLTexture:Load','Texture dimensions are to large, or not enough memory');
        end 
        % For now disable Texture 2D
        Gl.glDisable(Gl.GL_TEXTURE_2D);
    else
        % Enable 3D texturing
        Gl.glEnable(Gl.GL_TEXTURE_3D);
        % Create Texture id
        TextureID=Gl.glGenTextures(1);  
        % tell OpenGL we're going to be setting up the texture name it gave us	
        Gl.glBindTexture(Gl.GL_TEXTURE_3D,  TextureID);
        % when this texture needs to be shrunk to fit on small polygons, use linear interpolation of the texels to determine the color
        Gl.glTexParameteri(Gl.GL_TEXTURE_3D, Gl.GL_TEXTURE_MIN_FILTER, TextureInterpolation);
        % when this texture needs to be magnified to fit on a big polygon, use linear interpolation of the texels to determine the color
        Gl.glTexParameteri(Gl.GL_TEXTURE_3D, Gl.GL_TEXTURE_MAG_FILTER, TextureInterpolation);
        % we want the texture to repeat over the S axis, so if we specify coordinates out of range we still get textured.
        Gl.glTexParameteri(Gl.GL_TEXTURE_3D, Gl.GL_TEXTURE_WRAP_S, Gl.GL_CLAMP_TO_EDGE);
        %  same as above for T axis
        Gl.glTexParameteri(Gl.GL_TEXTURE_3D, Gl.GL_TEXTURE_WRAP_T, Gl.GL_CLAMP_TO_EDGE);
        %  same as above for R axis
        Gl.glTexParameteri(Gl.GL_TEXTURE_3D, Gl.GL_TEXTURE_WRAP_R, Gl.GL_CLAMP_TO_EDGE);
        % Check if texture fits in video memory
        Gl.glTexImage3D(Gl.GL_PROXY_TEXTURE_3D, 0, TextureInternalFormat, TextureWidth, TextureHeight, TextureDepth, TextureBorder, TextureFormat, TextureDataType, []);
        EnoughMemory=Gl.glGetTexLevelParameterfv(Gl.GL_PROXY_TEXTURE_3D, 0, Gl.GL_TEXTURE_WIDTH); EnoughMemory=double(EnoughMemory)>0;
        % Read the data into the 3D texture structure
        if(EnoughMemory)
            I = typecast(I(:),'Int64');
            I2 = NET.convertArray(I(:),'System.Int64',numel(I));
            Gl.glTexImage3D(Gl.GL_TEXTURE_3D, 0, TextureInternalFormat, TextureWidth, TextureHeight, TextureDepth, TextureBorder, TextureFormat, TextureDataType, I2);
        else
            warning('loadOpenGLTexture:Load','Texture dimensions are to large, or not enough memory');
        end
        % For now disable Texture 3D
        Gl.glDisable(Gl.GL_TEXTURE_3D);
    end

    erc=Gl.glGetError();
    if(erc~=0)
        disp(erc);
        disp('Error loading texture, try multiple of two dimensions - or more favorably power of two like 32 or 128');
    end
end
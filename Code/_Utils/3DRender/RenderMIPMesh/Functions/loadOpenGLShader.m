function program_id=loadOpenGLShader(filename_fs,filename_vs,LOWVAL,HGHVAL)
    % loadOpenGLShader will load a vertex and fragment shader in to a GLSL
    % program.
    %
    % program_id = loadOpenGLShader(filename_FragmentShader,filename_VertexShader)
    %
    % inputs,
    %   filename_FragmentShader : The filename of the fragmentShader or [] in
    %                                   case of only needing a vertex shader.
    %   filename_VertexShader : The filename of the vertexShader 
    %
    % ouputs,
    %   program_id : The id of a GLSL program. (Gl.glUseProgram(program_id))
    %                           
    % example,
    %   program_id=loadOpenGLShader('fragment_program.glsl','vertex_program.glsl');
    %   % Use / Enable the shader code
    %   Gl.glUseProgram(program_id);
    %
    % Function is written by D.Kroon University of Twente (April 2009)

    import Tao.OpenGl.*

    % Process inputs
    if(~exist('filename_fs','var')), filename_fs=[]; end
    if(~exist('filename_vs','var')), filename_vs=[]; end

    % Create program (id)
    program_id = Gl.glCreateProgram();

    % Process fragment shader
    if(~isempty(filename_fs))
        % The shader code in cell array (textfile2cellarray also removes
        % comment and empty lines, otherwise, shadercode will 
        % compile but does not work, escape character / ???)

        fsShader_mat = textfile2cellarray(filename_fs,LOWVAL,HGHVAL);

        % Conver matlab cell arrays with char arrays inside to String (arrays)
        fsShader = NET.createArray('System.String', length(fsShader_mat)); 
        for i=1:length(fsShader_mat), fsShader.Set(i-1, fsShader_mat{i}); end

        % Create shader id
        fragment_id = Gl.glCreateShader(Gl.GL_FRAGMENT_SHADER);

        % Specify shader source
        Gl.glShaderSource(fragment_id, fsShader.Length, fsShader, []);

        % Compile the shader code
        Gl.glCompileShader(fragment_id);

        % Get compiler errors and warnings
        errorBuffer= System.Text.StringBuilder;
        messageLength=NET.createArray('System.Int32', 1); 
        Gl.glGetShaderInfoLog(fragment_id,8192,messageLength,errorBuffer);
        messageLength=double(messageLength);
        if(messageLength>0)
                disp(errorBuffer.ToString)
                disp('The shader code');
                for i=1:length(fsShader_mat), disp([num2str(i) ' : '  fsShader_mat{i}]); end
        end

        % Attach shader to the program
        Gl.glAttachShader(program_id, fragment_id );
    end

    % Links program object (create executable for GPU)
    Gl.glLinkProgram(program_id);

    % Validate Program
    Gl.glValidateProgram(program_id);
    succes=Gl.glGetProgramiv(program_id,Gl.GL_VALIDATE_STATUS);
    Gl.glFinish();

    if(succes==0)
       error('loadOpenGLShader:Shader', 'Program does not validate / execute');
    end

end

function cellarray=textfile2cellarray(filename,LOWVAL,HGHVAL)
    % Open text file
    fid=fopen(filename,'r');
    % Check if file can be read
    if(fid<0), error('tloadOpenGLShader:textfile2cellary','shader file not found'); end
    % cell array index
    i=0;
    % Loop through the lines
    while true
        % Get text line
        tline = fgetl(fid);
        % Break if end of file reached
        if ~ischar(tline), break, end
        % Remove comment from shader code (important otherwise shader code
        % compiles, but will not work...)
        c_pos=strfind(tline,'//');
        if(~isempty(c_pos))
            if(c_pos>1)
                tline=tline(1:c_pos-1);
            else
                tline=[];
            end
        end
        tline = strrep(tline, 'LOWVAL', LOWVAL);
        tline = strrep(tline, 'HGHVAL', HGHVAL);

        % Tabs to spaces
        tline(uint8(tline)==9)=' ';
        % Remove lines with only spaces
        if(nnz(tline==' ')==length(tline)), tline=[]; end

        % Add line to cell array if not empty
        if(~isempty(tline)), i=i+1; cellarray{i}=tline; end
    end
    % Close the text file
    fclose(fid);
end
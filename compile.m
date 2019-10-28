CurrentPath = pwd;

try
    %% Test if files are compiled in BIF folder
    cd('.\Code\_Utils\BIF');
    if ispc
        CompiledFiles = dir('*.mexw64');
    end
    if ismac
        CompiledFiles = dir('*.mexmaci64');
    end
    if isunix
        CompiledFiles = dir('*.mexglx');
    end
    if ~isempty(CompiledFiles)
        answer = questdlg('Files seems to be already compiled, continue?','Compile?');
    end
    switch answer
        case 'Yes'
            answer = questdlg('MATLAB compiler with mex configured for an OpenMP compatible compiler is required to compile functions. These files come bundled for Windows only. Continue?','Compile?');
        case 'No'
    end
    % Handle response
    switch answer
        case 'Yes'
            cd('.\Code\_Utils');
            FilesToCompile = dir('*.cpp');
            for i = 1:length(FilesToCompile)    
                switch FilesToCompile(i).name
                    case 'LocMax3D_thr.cpp'
                        if ispc
                            disp('Compiling LocMax3D_thr.cpp');
                            mex -v COMPFLAGS="$COMPFLAGS /openmp" LocMax3D_thr.cpp
                        end
                        if isunix
                            disp('Compiling LocMax3D_thr.cpp');
                            mex -v CFLAGS='$CFLAGS -fopenmp' -LDFLAGS='$LDFLAGS -fopenmp' LocMax3D_thr.cpp
                        end
                        if ismac
                            disp('Compiling LocMax3D_thr.cpp');
                            mex -v CFLAGS='$CFLAGS -fopenmp' -LDFLAGS='$LDFLAGS -fopenmp' LocMax3D_thr.cpp
                        end
                    otherwise
                        disp(['Compiling' FilesToCompile(i).name]);
                        mex(FilesToCompile(i).name);
                end
            end
            cd(CurrentPath);
            cd('.\Code\_Utils\BIF');
            disp('compiling oBIFsQuantization');
            mex oBIFsQuantization.cpp
            cd(CurrentPath);
            cd('.\Code\_Utils\shortestpath');
            disp('compiling rk4');
            mex rk4.c
            cd(CurrentPath);
            cd('.\Tools\LOBSTER_Annotator\functions\RF\Random_Forests\cartree\mx_files');
            disp('Compiling RF');
            run('mx_compile_cartree.m');
        otherwise
    end
catch    
    disp('Error');
    cd(CurrentPath);  
end
cd(CurrentPath);
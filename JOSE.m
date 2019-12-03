% Create an IJ or CellInsight scene.
%
% JOSE(ChanFolder1, ChanFlt1, ChanFolder2, ChanFlt2, ... , ReportFolder1, ObjMeasType1, ReportFolder2,ObjMeasType2, ..., Env, Config, ColorCode);
%
% ChanFoldern:      Folder of the channel n to display
% ChanFltn:         Image name string filter of the channel n to display
% ReportFoldern:    Report folder of the objects n to overlay
% ObjMeasTypen:     Measurement type of the objects n to overlay ('Spts', 'Skls' or 'Objs')
% Env:              'IJ' or 'CellInsight'
% Config:           3 digits flags: cfm
%                   c: Number of channels of input image (only for 3D images with interleaved channels)
%                   f: Input 3D images are folders of tif image sequence (0/1)
%                   m: Input image is a time-lapse (0/1)
% ColorCode:        '' or string of the type '(getResult("Area",ObjIdx) >= 250)+(getResult("Area",ObjIdx) >= 350)';
% 
% See LOBSTER_ROOT/Jobs for sample jobs building scenes

function ExportFolder = JOSE(varargin)

    %% Check that imtool3D is in path (init has been performed)
    if ~exist('imtool3D')
        error('LOBSTER has not been initialized yet, type >> init');
    else
        %% Force path to LOBSTER root on startup
        str = which('init');
        indxs = find((str=='/')|(str=='\'));
        cd(str(1:indxs(end)));
    end

    %% Image dimensionality, exportation environment and scene exportation folder
    ColorCode = varargin{nargin};
    Config = varargin{nargin-1};
    Env = varargin{nargin-2};
    ExportFolder = varargin{nargin-3};
    
    %% How many channel filters?
    NChan = 0;
    for i = 1:nargin-4
        NChan = NChan + (varargin{i}(1) == '*');
    end
    NAnno = (nargin-3-2*NChan)/2;
    
    %% Environmnent switch
    switch Env
        
        case 'IJ'
            
            %% Configuration
            Str = ['Configuration\n'];
            Str = [Str num2str(Config) '\n'];
            
            %% Channels section
            Str = [Str 'Channels\n'];
            cnt = 1;
            for i = 1:NChan
                Str = [Str strrep(GetFullPath(varargin{cnt}),'\','\\') '\n' strrep(varargin{cnt+1},'*','') '\n'];
                cnt = cnt+2;
            end
            
            %% Annotations section
            Str = [Str 'Annotations\n'];
            for i = 1:NAnno
                %% TODO: Implement report filter, e.g. 'Objs_L', for now no filter
                if numel(varargin{cnt+1})<4
                    error('Invalid annotation type');
                end
                if varargin{cnt+1}(1:4) == 'Objs' | varargin{cnt+1}(1:4) == 'Spts'
                    Str = [Str strrep(GetFullPath(varargin{cnt}),'\','\\') '\n' '' '\n'];
                    cnt = cnt+2;
                else
                    if varargin{cnt+1}(1:4) == 'Skls' | varargin{cnt+1}(1:4) == 'Trks'
                        error('Unsupported annotation type for IJ');
                    else
                        error('Invalid annotation type');
                    end
                end
            end
            
            if ~isempty(ColorCode)
                Str = strcat(Str,'ColorCode\nreturn toString(',ColorCode,');');
            end
    
            %% Export IJ scene file
            fid = fopen([ExportFolder '/zzz_Jobscene.sce'],'wt');
            fprintf(fid, Str);
            fclose(fid);
         
        case 'CellInsight'
            
            %% Erase files
            cnt = 1;
            Files = dir(strcat([varargin{cnt} '*.csv']));
            for f = 1:numel(Files)
                CurrentFile = Files(f).name;
                if exist([ExportFolder '/' CurrentFile(1:end-4) '.xls'], 'file')==2
                    delete([ExportFolder '/' CurrentFile(1:end-4) '.xls']);
                end
            end
                
            %% Annotations section
            for i = 1:NAnno
                if numel(varargin{cnt+1})<4
                    error('Invalid annotation type');
                end
                if varargin{cnt+1}(1:4) == 'Spts'
                    Files = dir(strcat([varargin{cnt} '*.csv']));
                    for f = 1:numel(Files)
                        CurrentFile = Files(f).name;
                        M = readtable(strcat([varargin{cnt} CurrentFile]));
                        fid = fopen([ExportFolder '/' CurrentFile(1:end-4) '.xls'],'a+');
                        if i == 1
                            Str = 'Label\tPointS\tPointX\tPointY\tPointZ\tPointF\n';
                            fprintf(fid, Str);
                        end
                        for l = 1:size(M,1)
                            Str = ['Annotations' sprintf('%i',i) '\t' sprintf('%i',i) '\t' sprintf('%i',round(M{l,1})) '\t' sprintf('%i',round(M{l,2})) '\t' sprintf('%i',round(M{l,3})) '\t1\n'];
                            fprintf(fid, Str);
                        end
                        fclose(fid); 
                    end
                    cnt = cnt+2;
                else
                    error('Unsupported annotation type for CellInsight');
                end
            end
            
        otherwise
            
            error('Unupported environment');
            
    end

    
    
end
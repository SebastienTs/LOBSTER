function Transfer(InputFolder,OutputFolder)
    % Transfer source binary masks from input folder to target masks from output folder
    % Object pixels from source masks are only copied to null pixels of target masks, 
    % and set to grayscale level 100

    %% Check that imtool3D is in path (init has been performed), if not perform it
    if ~exist('imtool3D')
        init;
    else
        %% Force path to LOBSTER root on startup
        str = which('init');
        indxs = find((str=='/')|(str=='\'));
        cd(str(1:indxs(end)));
    end
    
    %% Fix folder paths
    InputFolder = FixFolderPath(InputFolder);
    OutputFolder = FixFolderPath(OutputFolder);
    
    %% Check definition and existence of input/output folders + display information to console
    if ~exist('InputFolder','var')
        error('Error: No input folder defined');
    else
        if ~exist(InputFolder,'dir')
          error('Input folder does not exist');
        end  
    end
    if ~exist('OutputFolder','var')
        error('Error: No output folder defined');
    else
        if ~exist(OutputFolder,'dir')
          error('Output folder does not exist');
        end
    end
    
    %% Display information
    disp('-----------------------------------------------');
    disp(strcat('Transfering masks from Input Folder:',InputFolder,' to masks from output folder:',OutputFolder));
    disp('-----------------------------------------------');
    
    %% Parse files in input/output folders
    Files = dir(strcat([InputFolder '*.tif'])); 
    Files2 = dir(strcat([OutputFolder '*.tif']));
    num_images = numel(Files);
    num_images2 = numel(Files2);
    if num_images ~= num_images2
        error('Input and output folders do not hold the same number of images');
    end

    for im = 1:num_images

        %% Read masks
        fname = strcat([InputFolder Files(im).name]);
        info = imfinfo(fname);
        Width = info(1).Width;
        Height = info(1).Height;
        num_slices = numel(info); 
        
        I = uint8(zeros(Height,Width,num_slices));
        for kf = 1:num_slices
            I(:,:,kf) = imread(fname,kf);
        end
        fname = strcat([OutputFolder Files2(im).name]);
        O = uint8(zeros(Height,Width,num_slices));
        for kf = 1:num_slices
            O(:,:,kf) = imread(fname,kf);
        end
        
        %% Transfer masks
        Msk = find(I > 0);
        O(Msk) = O(Msk).*uint8(O(Msk)>0) + 100*uint8(O(Msk)==0);
        
        %% Write masks
        imwrite(O(:,:,1),strcat([OutputFolder Files2(im).name]),'Compression','deflate');
        for kf = 2:size(O,3)
            imwrite(O(:,:,kf),strcat([OutputFolder Files2(im).name]),'WriteMode', 'append', 'Compression','deflate');
        end
        
    end
    
end
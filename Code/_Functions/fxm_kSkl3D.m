function [It] = fxm_kSkl3D(M, params)

    % Skeletonize binary mask by isthmus based skeletonization.
    %
    % Sample journal: <a href="matlab:JENI('BloodVessels3D_LocThr3DSkl3D.jls');">BloodVessels3D_LocThr3DSkl3D.jls</a>
    %
    % Input: 3D binary mask
    % Output: 3D skeleton mask
    %
    % Parameters:
    % ClosePreRad:      Morphological closing radius (preprocessing, pix)      
    % Min2DHolesArea:   Maximum volume for hole closing (preprocessing, vox)
    % MinVol:           Minimum skeletons volume (vox)

    PreCloseRad = params.PreCloseRad;
    Min2DHolesArea = params.Min2DHolesArea;
    MinVol = params.MinVol;
    
    if ~isempty(M)
        
        %% Keep current folder
        currentpath = pwd;
        
        %% Morphological closing
        if PreCloseRad > 0
            sw = (2*PreCloseRad-1)/2; 
            ses2 = ceil(2*PreCloseRad/2); 
            [y,x,z] = meshgrid(-sw:sw, -sw:sw, -sw:sw); 
            m = sqrt(x.^2 + y.^2 + z.^2); 
            b = (m <= m(ses2, ses2, 2*PreCloseRad)); 
            se = strel('arbitrary', b);
            M = imclose(M,se);
        end
        
        %% Fill small 2D holes (slice by slice)
        if Min2DHolesArea > 0
            for i = 1:size(M,3)
                M(:,:,i) = M(:,:,i)|~(bwareaopen(~M(:,:,i),Min2DHolesArea));
            end
        else
            M = uint8(M>0);
        end

        %% Set border pixels to 0
        M(1,:,:) = 0;M(end,:,:) = 0;M(:,1,:) = 0;M(:,end,:) = 0;M(:,:,1) = 0;M(:,:,end) = 0;

        %% Thinning
        cd Code/_Utils/isthmus_thinning;  % Required since function reads tables locally
        It = isthmusthinning(M);
        cd(currentpath);
        
        %% Remove small isolated skeletons
        if MinVol > 0
            It = bwareaopen(It>0,MinVol,26);
        end
        
        %% Create skeleton mask
        It = uint8(200*It)+100*uint8((M>0)&(It==0));
        
    else
        It = [];
    end
    
end
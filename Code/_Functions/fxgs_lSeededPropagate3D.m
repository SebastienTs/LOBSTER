function [L] = fxgs_lSeededPropagate3D(I,L,M,params)
    
    % Propagate seeds through low intensity variation regions.
    %
    % Sample journal: <a href="matlab:JENI('CellPilar3D_LogLocMaxLocThrPropagate3D.jls');">CellPilar3D_LogLocMaxLocThrPropagate3D.jls</a>
    %
    % Input: 3D original image, 3D binary or label mask, optional 3D binary mask
    % Output: 3D label mask or 3D binary mask
    %
    % Parameters:
    % Power:                Apply power law to intensity image prior to processing
    % SeedsDilRad:          Seed pre-dilation radius (merge closeby seeds, pix) 
    % AnalyzeCC:            Set to 0 for input label mask is passed, 1 for binary mask
    % MinVol:               Minimum object volume (voxels)
    % BinaryOut:            Force output to be binary (touching particles with different labels are split apart)
    
    %% Parameters
    BckSeedLvl = params.BckSeedLvl;
    Power = params.Power;
	SeedsDilRad = params.SeedsDilRad;
    AnalyzeCC = params.AnalyzeCC;
    MinVol = params.MinVol;
    BinaryOut = params.BinaryOut;
    
    if ~isempty(I)
    
        disp('Propagate...');
        
        %% Optionally dilate seeds
        if SeedsDilRad > 0
            L = imdilate(L,ones(SeedsDilRad,SeedsDilRad,SeedsDilRad));
        end
        
        %% Optionally analyze CC
		if AnalyzeCC
            L = single(bwlabeln(L,6));
        else
            L = single(L);
        end
        
        %% Optionally add background seeds
        if BckSeedLvl > 0
            L(L>0) = L(L>0)+1;
            L = single((I < BckSeedLvl).*(L==0)) + L;
            M = logical(ones(size(L)));
        end
        
        %% Set mask borders to 0 since no image border check is performed in Propgate_3D
        M(1,:,:) = 0;M(end,:,:) = 0;M(:,1,:) = 0;M(:,end,:) = 0;M(:,:,1) = 0;M(:,:,end) = 0;
   
        %% Propagate
        if Power ~= 1
            L = uint16(Propagate_3D_single(L,(I).^Power,logical(M),single(size(I,3))));
        else
            L = uint16(Propagate_3D_single(L,I,logical(M),single(size(I,3))));
        end
        L = reshape(L,size(I));
        
        %% Remove small particles
        if MinVol>0
            L = L.*uint16(bwareaopen(L>0, MinVol));
        end
        
        %% Account for background seeds
        if BckSeedLvl > 0
            L = L - 1;
        end
        
        %% Binary output
        if BinaryOut == 1
            Ldil = imdilate(L,ones(3,3,3));
            L = 255*uint8(L>0)-255*uint8((Ldil-L)&(L>0));
        end
        
    else
        
        L = [];
    
    end
    
end
function [I I2 I3] = fx_SplitChans(I)

    % Enhance anisotropic structures + threshold + skeletonize.
    %
    % Sample journal: <a href="matlab:JENI('EyeVesselsSpots_IsoScanFilamRep.jl');">EyeVesselsSpots_IsoScanFilamRep.jl</a>
    %
    % Input: Multi-channel 3D image
    % Output: 3D images
    
    if ~isempty(I)
    
        switch nargout
            
            case 2
            
                I3 = [];
                I2 = I(:,:,2:2:end);
                I = I(:,:,1:2:end);
                
            case 3
                
                I3 = I(:,:,3:3:end);
                I2 = I(:,:,2:3:end);
                I = I(:,:,1:3:end);
                
        end
        
    else
        
        I2 = [];
        I3 = [];
        
    end
    
end
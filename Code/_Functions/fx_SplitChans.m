function [I I2 I3] = fx_SplitChans(I)

    % Split the 2 or 3 channels of a 3D stack
    %
    % Sample journal: <a href="matlab:JENI('TissuePilar3D_LocThrFitSurf3D_all_chans.jls');">TissuePilar3D_LocThrFitSurf3D_all_chans.jls</a>
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
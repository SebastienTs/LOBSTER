function [Votes] = fxg_gRestoreFilam(I, params)

    % Enhance filaments and close small gaps. 
    %
    % Sample journal: <a href="matlab:JENI('CellJunctions_RestoreFilam.jl');">CellJunctions_RestoreFilam.jl</a>
    % 
    % Input: 2D grayscale image
    % Output: 2D grayscale image (8-bit) !! Intensity rescaled to 255 !!
    %
    % Parameters:
    % FrangiScale       Frangi filter scales (estimate direction of mininum intensity variation)
    % Rmin              Minimum vote distance
    % Rmax              Maximum vote distance
    % GaussianVoteRad   Vote spread (Gaussian sigma)
    % ThrVote           Thresholds to cast vote from a given pixel at each iteration (0-1, vector)
    % NAngles           Number of possible vote angles
    % Delta             Vote opening angle at each iteration (radian, vector)
    % DScale            Vote radius scaling at each iteration (0-1, vector)
    % PowerLaw          Apply power law to result image (set to 1 to disable)
    %
    % Note: Number of iterations is set by length of vector Delta
    
    %% Retrieve parameters
    FrangiScale = params.FrangiScale;
    Rmin = params.Rmin;
    Rmax = params.Rmax;
    GaussianVoteRad = params.GaussianVoteRad ;
    ThrVote = params.ThrVote;
    NAngles = params.NAngles;
    Delta = params.Delta;
    DScale = params.DScale;
    PowerLaw = params.PowerLaw;
    
    if ~isempty(I)
    
        %% Initialize filters, masks and variables
        A = cell(NAngles,length(Delta),length(DScale));
        K = cell(NAngles,length(Delta),length(DScale));
        for k = 1:length(DScale)
            Gvote = fspecial('gaussian',[2*Rmax 2*Rmax],GaussianVoteRad*DScale(k));
            for j = 1:length(Delta)
                tempa = double(roipoly(2*Rmax,2*Rmax, Rmax+[Rmin*tan(Delta(j)) Rmax*tan(Delta(j)) -Rmax*tan(Delta(j)) -Rmin*tan(Delta(j))], [Rmax+Rmin 2*Rmax 2*Rmax Rmin+Rmax]));
                tempk = tempa.*Gvote;
                tempa = tempa+flipud(tempa);
                tempa(tempa == 0) = nan;
                tempk = tempk+flipud(tempk);
                for i = 1:NAngles
                    A{i,j,k} = imrotate(tempa,-(180*(i-1)/NAngles),'crop','bilinear');
                    K{i,j,k} = imrotate(tempk,-(180*(i-1)/NAngles),'crop','bilinear');
                end
            end
        end
        L = 2*Rmax-1;
        Ref = Rmax+1;
        DRef = (Rmax+Rmin)/2;

        %% Compute image maximum
        Imax = max(I(:));

        %% Frangi filter to estimate direction of minimum intensity variation
        options.FrangiScaleRange = FrangiScale;
        options.FrangiScaleRatio = [1];
        [Iv,Ivscl,IvDir] = FrangiFilter2D(-I,options);
        
        %% Initialize angle map
        Alpha = IvDir;
        AlphaNCur = 1+mod(floor((Alpha)/pi*NAngles),NAngles); %% Current estimated angle at each pixel
        %% Main iteration
        
        for it = 1:length(Delta)

            %% Voting from significant points
            [Yv Xv] = ind2sub(size(Iv),find(Iv>ThrVote(it)));
            Votes = zeros(size(I)+2*Rmax+1);
            for i = 1:length(Xv)
                X = Xv(i);
                Y = Yv(i);
                if AlphaNCur(Y,X)>0  
                    Votes(Y:Y+L,X:X+L) = Votes(Y:Y+L,X:X+L)+Iv(Y,X)*K{AlphaNCur(Y,X),it,it};
                end
            end

            %% Call Frangi filter to restimate vote direction, this time from vote image (except at last iteration)
            if it<length(Delta)
                options.FrangiScaleRange = FrangiScale;
                options.FrangiScaleRatio = [1];
                Votes = Votes(Rmax+1:end-Rmax-1,Rmax+1:end-Rmax-1);
                Votes = Imax/max(Votes(:))*Votes;
                [Iv,Ivscl,IvDir] = FrangiFilter2D(-Votes,options);
                AlphaBuf = IvDir;
                AlphaNCur = 1+mod(floor((AlphaBuf)/pi*NAngles),NAngles);
            end

        end

        %% Crop Votes map
        Votes = Votes(1+Rmax:end-Rmax-1,1+Rmax:end-Rmax-1);
        
        %% Power law and normalize
        if PowerLaw ~= 1
            Votes = Votes.^PowerLaw;
        end
        Votes = uint8(255*Votes/max(Votes(:)));
        
    else
        
        Votes = [];
       
    end
    
end
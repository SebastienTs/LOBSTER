function ProcessImage = CheckImageQuality(I,MinLocalFocus,LocalFocusBlkSize,Min95Percentile,MaxSatPixFract)

    %% Local functions
    fun1 = @(block_struct) std(block_struct.data(:))^2;
    fun2 = @(block_struct) mean(block_struct.data(:));
    
    %% Color images
    if size(I,3)>1
        I = max(I,[],3);
    end
    
    %% Check focus
    if MinLocalFocus>0
        LocalFocusMap = blockproc(I,LocalFocusBlkSize,fun1)./blockproc(I,LocalFocusBlkSize,fun2);
        LocalFocusScore = max(LocalFocusMap(:));
    else
        LocalFocusScore = MinLocalFocus
    end
    
    %% Check intensity level
    if Min95Percentile > 0
        sortI = sort(I(:));
        Ipercent95 = sortI(round(numel(I)*0.95));
    else
        Ipercent95 = Min95Percentile;
    end
    
    %% Check intensity clipping
    if MaxSatPixFract < 1
        SatPixFract = sum(I(:)==(2^ceil(log2(max(I(:))+1)) - 1))/numel(I);
    else
        SatPixFract = MaxSatPixFract;
    end

    %% Combine all tests
    ProcessImage = (LocalFocusScore >=MinLocalFocus)&&(Ipercent95 >= Min95Percentile)&&(SatPixFract < MaxSatPixFract);
    
end
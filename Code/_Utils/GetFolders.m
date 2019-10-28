function [RootInputFolders, NFolders] = GetFolders(RootInput)
    RootInput = FixFolderPath(RootInput);
    FoldersNames = dir(RootInput);
    FoldersNames = FoldersNames(3:end);
    NFolders = length(FoldersNames);
    RootInputFolders = cell(NFolders);
    for i = 1:NFolders
        RootInputFolders{i} = [RootInput FoldersNames(i).name '/'];
    end
end
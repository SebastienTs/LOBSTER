function copyfiles(psource,pdest,pattern)

sourceDir = dir(fullfile(psource, pattern));
sourceDir([sourceDir.isdir]) = [];

for k = 1:numel(sourceDir)
    sourceFile = fullfile(psource, sourceDir(k).name);
    destFile   = fullfile(pdest, sourceDir(k).name);
    copyfile(sourceFile, destFile);
end
function [Folder] = FixFolderPath(Folder)
    if Folder(end)~='/' & Folder(end)~='\'
        Folder = [Folder '/'];
    end
    Folder = strrep(Folder,'\','/');
end
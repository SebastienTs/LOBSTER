% See JENI, same but no image displayed and no user interactions triggered

function [InputFolder OutputFolder] = GENI(Journal,ForceInputFolder,ForceOutputFolder,ForceChan);

    switch nargin
        case 0
            [InputFolder OutputFolder] = JENI;
        case 1
            [InputFolder OutputFolder] = JENI(Journal);
        case 2
            error('Incorrect call to GENI: 0, 1, 3 or 4 input arguments');
        case 3   
            [InputFolder OutputFolder] = JENI(Journal,ForceInputFolder,ForceOutputFolder);
        case 4
            [InputFolder OutputFolder] = JENI(Journal,ForceInputFolder,ForceOutputFolder,ForceChan);
        otherwise
            error('Incorrect call to GENI: 0, 1, 3 or 4 input arguments');
    end
    
end
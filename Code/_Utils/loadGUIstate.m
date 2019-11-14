function loadGUIstate(GUIstate, h)
% Write better documentation here <-
%
% Input is a structure containing the saved GUI state output by
% saveGUIstate along with the handles structure of the target GUI.
% This function modifies the GUI handles directly so there is no output
%
% Assumes the GUI state is being loaded into the same GUI that it was saved
% from

savedobjlist = fieldnames(GUIstate);

for ii = 1:length(savedobjlist)
    % Verify that our saved handle is part of the passed handles structure,
    % otherwise ignore it
    if isfield(h, savedobjlist{ii}) && ~isempty(GUIstate.(savedobjlist{ii}))
        % set can address properties of multiple objects at the same time,
        % which is useful for nested structure arrays of handles (e.g. 3 
        % sliders stored as h.slider(1), h.slider(2), ...)
        nsubhandles = length(h.(savedobjlist{ii}));
        
        % set can also set multiple properties at once, where each row of
        % the passed cell array is the value to pass for each object
        % handle. This syntax will not be utilized until a robust method
        % for generating the cell array is developed. Get something 
        % functional first, then prettify...
        propstoset = fieldnames(GUIstate.(savedobjlist{ii}));
        for jj = 1:length(propstoset)
            if nsubhandles == 1
                ValueArray = {GUIstate.(savedobjlist{ii}).(propstoset{jj})};
            elseif nsubhandles > 1
                ValueArray = GUIstate.(savedobjlist{ii}).(propstoset{jj});
            end
            set(h.(savedobjlist{ii}), propstoset(jj), ValueArray);
        end
    end
end
end
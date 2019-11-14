function [output] = saveGUIstate(h)
% Write better documentation here <-
%
% Input is a structure array of handles from programmatic or GUIDE GUIs
% Output is a structure of the handles with nested structures for each
% property to store.
%
% Assumes all structure arrays with the same field name are of the same 
% object type (e.g. 3 sliders stored as h.slider(1), h.slider(2), ...) so 
% the user can utilize the return of set/get natively.

propertystruct = initializeproperties();

objectlist = fieldnames(h);
for ii = 1:length(objectlist)
    objtype = get(h.(objectlist{ii}), 'Type');
    if iscell(objtype)
        % Structure array length is non-singular, so get returns a cell
        % array where each cell corresponds to the property of an
        % individual object in the array.
        objtype = objtype{1};
    end
    fieldtest = isfield(propertystruct, objtype); % See if our field exists
    
    % If we have a uicontrol object, adjust the object type string to
    % include the 'Style' property as well so the properties to output
    % structure can be addressed directly
    isuicontrol = strcmpi(objtype, 'uicontrol');
    if isuicontrol
        uicontrolstyle = get(h.(objectlist{ii}), 'Style');
        if iscell(uicontrolstyle)
            % Structure array length is non-singular, so get returns a cell
            % array where each cell corresponds to the property of an
            % individual object in the array.
            uicontrolstyle = uicontrolstyle{1};
        end
        
        % isfield doesn't support nested fields, so we need to test the
        % uicontrol substructure directly
        fieldtest = isfield(propertystruct.uicontrol, uicontrolstyle);
    end
    
    % Field exists, and there is data to save, save it
    if fieldtest
        % Need a in/else statement because you can't use dynamic field
        % references on nested structures
        if isuicontrol
            propstopull = propertystruct.uicontrol.(uicontrolstyle);
        else
            propstopull = propertystruct.(objtype);
        end
        
        if ~isempty(propstopull)
            % Pull properties and save to output structure
            % Structure is currently not preallocated, need to revisit
            % later to figure out a robust method to preallocate for speed
            if iscell(propstopull)
                for jj = 1:length(propstopull)
                    output.(objectlist{ii}).(propstopull{jj}) = ...
                        get(h.(objectlist{ii}), propstopull{jj});
                end
            else
                output.(objectlist{ii}).(propstopull) = ...
                    get(h.(objectlist{ii}), propstopull);
            end
        end
    end
end
end

function [propertystruct] = initializeproperties()
% Initialize structure containing the default properties to save.
% Fieldnames of propertystruct should match the 'Type' property of the UI
% object to save. If the object has multiple types (e.g. uicontrol), then
% nest the types under their overall object type (e.g. uicontrol.edit).
%
% Strings (single or cell array) must match the property name(s).

propertystruct.figure = {'Units', 'Position'};
propertystruct.axes = '';  % Nothing to save currently
propertystruct.uipanel = '';  % Nothing to save currently
propertystruct.uitabgroup = '';  % Nothing to save currently, introduced in R2014b
propertystruct.uitab = '';  % Nothing to save currently, introduced in R2014b
propertystruct.uitable = '';  % Nothing to save currently
propertystruct.actxcontrol = '';  % Nothing to save currently
propertystruct.uicontrol.togglebutton = 'Value';
propertystruct.uicontrol.radiobutton = 'Value';
propertystruct.uicontrol.checkbox = 'Value';
propertystruct.uicontrol.edit = 'String';
propertystruct.uicontrol.slider = {'Value', 'Min', 'Max', 'SliderStep'};
propertystruct.uicontrol.listbox = {'String', 'Value', 'Min', 'Max'};
propertystruct.uicontrol.popupmenu = {'String', 'Value'};
propertystruct.uicontrol.text = '';  % Nothing to save currently
end
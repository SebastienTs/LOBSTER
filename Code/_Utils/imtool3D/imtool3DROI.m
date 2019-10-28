classdef imtool3DROI < handle
    %This is an abstract class for the ROI tools used in imtool3D
    
    properties
        imageHandle
        axesHandle
        figureHandle
        graphicsHandles
    end
    
    methods
        
        %Constructor
        function ROI = imtool3DROI(imageHandle,graphicsHandles,menuLabels,menuFunction)
            
            %Set the properties
            ROI.imageHandle = imageHandle;
            ROI.graphicsHandles = graphicsHandles;
            
            %Get the parent axes of the image
            ROI.axesHandle = get(imageHandle,'Parent');
            
            %Find the parent figure of the object
            ROI.figureHandle = getParentFigure(imageHandle);
            
            %create the context menu
            c = uicontextmenu;
            
            %set the graphics handles to use the context menu
            for i=1:length(graphicsHandles)
                set(graphicsHandles(i),'UIContextMenu',c)
            end
            
            %create each of the menu items and set their callback
            %functions
            menuFunction = @(source,callbackdata) menuFunction(source,callbackdata,ROI);
            for i=1:length(menuLabels)
                uimenu('Parent',c,'Label',menuLabels{i},'Callback',menuFunction);
            end
            
            
            
        end
        
    end
    
end

function fig = getParentFigure(fig)
% if the object is a figure or figure descendent, return the
% figure. Otherwise return [].
while ~isempty(fig) & ~strcmp('figure', get(fig,'type'))
  fig = get(fig,'parent');
end
end
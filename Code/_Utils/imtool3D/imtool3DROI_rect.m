classdef imtool3DROI_rect < imtool3DROI
    
    properties
        textHandle
    end
    
    properties (SetAccess = protected, GetAccess = protected)
        position        %defines the center of the box and its width/height [cx cy width height]
        tbuff           %amount of space (in pixels) to place the text above the ROI
        listenerHandle  %handle to the listener put on the ROI
    end
    
    methods
        
        %constructor
        function ROI = imtool3DROI_rect(varargin)
            
            switch nargin
                case 0  %use the current figure
                    
                    %let the user draw the ROI
                    h = imrect;
                    
                    %get the parent axes
                    ha = get(h,'Parent');
                    
                    %get the handle of the image
                    hi = imhandles(ha);
                    if length(hi)>1
                        for i=1:length(hi)
                            if ndims(get(hi(i),'CData'))<3
                                imageHandle = hi(i);
                            end
                        end
                    end
                    
                    %get the position
                    pos = getPosition(h);
                    position = [pos(1)+pos(3)/2 pos(2)+pos(4)/2 pos(3) pos(4)];
                    
                    %delete the imroi object
                    delete(h);
                case 1 %user inputs only the handle to the image
                    imageHandle = varargin{1};
                    parent = get(imageHandle,'Parent');
                    h = imrect(parent);
                    pos = getPosition(h);
                    position = [pos(1)+pos(3)/2 pos(2)+pos(4)/2 pos(3) pos(4)];
                    delete(h);
                case 2 %user inputs both the parent handle and a position
                    imageHandle = varargin{1};
                    position = varargin{2};
            end
            
            %get the parent axis handle
            parent = get(imageHandle,'Parent');
            
            %find the top left corner of the box
            pos = [position(1)-position(3)/2 position(2)-position(4)/2 position(3) position(4)];
            
            %Draw the rectangle at the desired spot
            graphicsHandles(1) = rectangle('Position',pos,'Parent',parent,'EdgeColor','r','LineWidth',1.5,'Curvature',[0 0]);
            
            %Draw a cross at the center of the box and sqaures on the sides
            nextPlot = get(parent,'NextPlot');  %make sure the new graphics don't delete the old ones
            set(parent,'NextPlot','add');
            graphicsHandles(2) = plot(position(1),position(2),'+r','MarkerSize',12,'Parent',parent); %middle cross
            graphicsHandles(3) = plot(pos(1),pos(2),'sr','MarkerSize',8,'Parent',parent,'MarkerFaceColor','r'); %top left corner
            graphicsHandles(4) = plot(pos(1)+pos(3),pos(2),'sr','MarkerSize',8,'Parent',parent,'MarkerFaceColor','r'); %top right corner
            graphicsHandles(5) = plot(pos(1),pos(2)+pos(4),'sr','MarkerSize',8,'Parent',parent,'MarkerFaceColor','r'); %bottom left corner
            graphicsHandles(6) = plot(pos(1)+pos(3),pos(2)+pos(4),'sr','MarkerSize',8,'Parent',parent,'MarkerFaceColor','r'); %bottom right corner
            graphicsHandles(7) = plot(pos(1),position(2),'sr','MarkerSize',8,'Parent',parent,'MarkerFaceColor','r'); %left
            graphicsHandles(8) = plot(pos(1)+pos(3),position(2),'sr','MarkerSize',8,'Parent',parent,'MarkerFaceColor','r'); %right
            graphicsHandles(9) = plot(position(1),pos(2),'sr','MarkerSize',8,'Parent',parent,'MarkerFaceColor','r'); %top
            graphicsHandles(10) = plot(position(1),pos(2)+pos(4),'sr','MarkerSize',8,'Parent',parent,'MarkerFaceColor','r'); %bottom
            set(graphicsHandles,'Clipping','off')
            set(parent,'NextPlot',nextPlot);
            
            %Define the context menu options (i.e., what happens when you
            %right click on the ROI)
            menuLabels = {'Export stats','Delete'};
            menuFunction = @contextMenuCallback;
            
            %create the ROI object from the superclass
            ROI@imtool3DROI(imageHandle,graphicsHandles,menuLabels,menuFunction);
            
            %Create the text box
            I = get(ROI.imageHandle,'CData');
            ROI.tbuff = .02*size(I,1);
            ROI.textHandle = text(pos(1),pos(2)-ROI.tbuff,'text','Parent',parent,'Color','w','FontSize',10,'EdgeColor','w','BackgroundColor','k','HorizontalAlignment','Left','VerticalAlignment','bottom','Clipping','on');
            
            %Set the position property of the ROI
            ROI.position = position;
            
            %Set the button down functions of the graphics
            for i=1:length(graphicsHandles)
                fun = @(hObject,evnt) ButtonDownFunction(hObject,evnt,ROI,i); set(graphicsHandles(i),'ButtonDownFcn',fun);
            end
            
            %add a listener for changes in the image. This automatically
            %updates the ROI text when the image changes
            ROI.listenerHandle = addlistener(ROI.imageHandle,'CData','PostSet',@ROI.handlePropEvents);
            
            %update the text
            newPosition(ROI,position)
            
        end
        
        %destructor
        function delete(ROI)
            delete(ROI.graphicsHandles);
            delete(ROI.textHandle);
            delete(ROI.listenerHandle);
        end
        
        function position = getPosition(ROI)
            position = ROI.position;
        end
        
        function newPosition(ROI,position)
            
            %set the position property of the ROI
            ROI.position = position;
            
            %find the top left corner of the box
            pos = [position(1)-position(3)/2 position(2)-position(4)/2 position(3) position(4)];
            
            %get the graphics handles
            graphicsHandles = ROI.graphicsHandles;
            
            %set the new position of the rectangle and other graphics
            %objects
            set(graphicsHandles(1),'Position',pos);
            set(graphicsHandles(2),'Xdata',position(1),'Ydata',position(2));
            set(graphicsHandles(3),'Xdata',pos(1),'Ydata',pos(2));
            set(graphicsHandles(4),'Xdata',pos(1)+pos(3),'Ydata',pos(2));
            set(graphicsHandles(5),'Xdata',pos(1),'Ydata',pos(2)+pos(4));
            set(graphicsHandles(6),'Xdata',pos(1)+pos(3),'Ydata',pos(2)+pos(4));
            set(graphicsHandles(7),'Xdata',pos(1),'Ydata',position(2));
            set(graphicsHandles(8),'Xdata',pos(1)+pos(3),'Ydata',position(2));
            set(graphicsHandles(9),'Xdata',position(1),'Ydata',pos(2));
            set(graphicsHandles(10),'Xdata',position(1),'Ydata',pos(2)+pos(4));
            
            %get the ROI measurements
            stats = getMeasurements(ROI);
            
            %set the textbox
            str = {['Mean: ' num2str(stats.mean,'%+.2f')], ['STD:     ' num2str(stats.STD,'%.2f')]};
            set(ROI.textHandle,'String',str,'Position',[pos(1) pos(2)-ROI.tbuff]);
            
            
        end
        
        function stats = getMeasurements(ROI)
            %get the position
            position = ROI.position;
            
            %find the top left corner of the box
            pos = [position(1)-position(3)/2 position(2)-position(3)/2 position(3) position(4)];
            
            %make the polygon
            x = [pos(1) pos(1)+pos(3) pos(1)+pos(3) pos(1) pos(1)];
            y = [pos(2) pos(2) pos(2)+pos(4) pos(2)+pos(4) pos(2)];
            
            im = get(ROI.imageHandle,'CData');
            
            m = size(im,1);
            n = size(im,2);
            
            mask = poly2mask(x,y,m,n);
            
            im = im(mask);
            
            stats.mean = mean(im);
            stats.STD = std(im);
            stats.min = min(im);
            stats.max = max(im);
            stats.mask = mask;
            stats.position = position;
            
        end
        
        function handlePropEvents(ROI,src,evnt)
            position = getPosition(ROI);
            newPosition(ROI,position);
        end
    end
        
end

function ButtonDownFunction(hObject,evnt,ROI,n)

%get the parent figure handle
fig = ROI.figureHandle;

%get the current button motion and button up functions of the figure
WBMF_old = get(fig,'WindowButtonMotionFcn');
WBUF_old = get(fig,'WindowButtonUpFcn');

%set the new window button motion function and button up function of the figure
fun = @(src,evnt) ButtonMotionFunction(src,evnt,ROI,n);
fun2=@(src,evnt)  ButtonUpFunction(src,evnt,ROI,WBMF_old,WBUF_old);
set(fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2);

end

function ButtonMotionFunction(src,evnt,ROI,n)
cp = get(ROI.axesHandle,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];

position = getPosition(ROI);

switch n
    case 2                                          %middle cross
        position(1) = cp(1); position(2) = cp(2);
        
    case 3                                          %top left corner
        %find the right edge
        right = position(1)+position(3)/2;
        %find the new width
        width = right-cp(1);
        if width>1
            %find the new center
            cx = cp(1)+width/2;
            position(1) = cx;
            position(3) = width;
        end
        %find the bottom edge
        bottom = position(2)+position(4)/2;
        %get the new height
        height = bottom - cp(2);
        if height>1
            cy = cp(2)+height/2;
            position(2) = cy;
            position(4) = height;
        end
        
    case 4                                          %top right corner
        %find the left edge
        left = position(1)-position(3)/2;
        %find the new width
        width = cp(1) - left;
        if width>1
            cx = cp(1)-width/2;
            position(1) = cx;
            position(3) = width;
        end
        %find the bottom edge
        bottom = position(2)+position(4)/2;
        %get the new height
        height = bottom - cp(2);
        if height>1
            cy = cp(2)+height/2;
            position(2) = cy;
            position(4) = height;
        end
        
    case 5                                          %bottom left corner
        %find the right edge
        right = position(1)+position(3)/2;
        %find the new width
        width = right-cp(1);
        if width>1
            %find the new center
            cx = cp(1)+width/2;
            position(1) = cx;
            position(3) = width;
        end
        %find the top edge
        top = position(2)-position(4)/2;
        %get the new height
        height = cp(2) - top;
        if height>1
            cy = cp(2)-height/2;
            position(2) = cy;
            position(4) = height;
        end
        
    case 6                                          %bottom right corner
        %find the left edge
        left = position(1)-position(3)/2;
        %find the new width
        width = cp(1) - left;
        if width>1
            cx = cp(1)-width/2;
            position(1) = cx;
            position(3) = width;
        end
        %find the top edge
        top = position(2)-position(4)/2;
        %get the new height
        height = cp(2) - top;
        if height>1
            cy = cp(2)-height/2;
            position(2) = cy;
            position(4) = height;
        end
        
    case 7                                          %left
        %find the right edge
        right = position(1)+position(3)/2;
        %find the new width
        width = right-cp(1);
        if width>1
            %find the new center
            cx = cp(1)+width/2;
            position(1) = cx;
            position(3) = width;
        end
        
    case 8                                          %right
        %find the left edge
        left = position(1)-position(3)/2;
        %find the new width
        width = cp(1) - left;
        if width>1
            cx = cp(1)-width/2;
            position(1) = cx;
            position(3) = width;
        end
        
    case 9                                          %top
        %find the bottom edge
        bottom = position(2)+position(4)/2;
        %get the new height
        height = bottom - cp(2);
        if height>1
            cy = cp(2)+height/2;
            position(2) = cy;
            position(4) = height;
        end
        
    case 10                                         %bottom
        %find the top edge
        top = position(2)-position(4)/2;
        %get the new height
        height = cp(2) - top;
        if height>1
            cy = cp(2)-height/2;
            position(2) = cy;
            position(4) = height;
        end
        
end

newPosition(ROI,position);

end

function ButtonUpFunction(src,evnt,ROI,WBMF_old,WBUF_old)
fig = ROI.figureHandle;
set(fig,'WindowButtonMotionFcn',WBMF_old,'WindowButtonUpFcn',WBUF_old);
end

function contextMenuCallback(source,callbackdata,ROI)

switch get(source,'Label')
    case 'Delete'
        delete(ROI);
    case 'Export stats'
        stats = getMeasurements(ROI);
        name = inputdlg('Enter variable name');
        name=name{1};
        assignin('base', name, stats)
end


end
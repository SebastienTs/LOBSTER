classdef imtool3DROI_ellipse < imtool3DROI_rect
    
    properties (SetAccess = protected, GetAccess = protected)
        nPoints = 20;   %number of points to use to define the polygon that makes the elliptical mask 
    end
    
    methods
        %constructor
        function ROI = imtool3DROI_ellipse(varargin)
            
            switch nargin
                case 0  %use the current figure
                    
                    %let the user draw the ROI
                    h = imellipse;
                    
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
                    h = imellipse(parent);
                    pos = getPosition(h);
                    position = [pos(1)+pos(3)/2 pos(2)+pos(4)/2 pos(3) pos(4)];
                    delete(h);
                case 2 %user inputs both the parent handle and a position
                    imageHandle = varargin{1};
                    position = varargin{2};
            end
            
            %contruct the rect ROI
            ROI@imtool3DROI_rect(imageHandle,position)
            
            %make the rectangle an ellipse
            set(ROI.graphicsHandles(1),'Curvature',[1 1]);
            
            %update the position
            newPosition(ROI,position)
            
            %Set the button down functions of the graphics
            for i=1:length(ROI.graphicsHandles)
                fun = @(hObject,evnt) ButtonDownFunction(hObject,evnt,ROI,i); set(ROI.graphicsHandles(i),'ButtonDownFcn',fun);
            end
            
        end
        
        function newPosition(ROI,position)
            
            %set the position property of the ROI
            ROI.position = position;
            
            %find the top left corner of the box
            pos = [position(1)-position(3)/2 position(2)-position(4)/2 position(3) position(4)];
            
            %get the graphics handles
            graphicsHandles = ROI.graphicsHandles;
            
            %get the corner positions
            t = pi/4:pi/2:2*pi-pi/4;
            [x,y] = getEllipsePoints(position,t,'');
            
            %set the new position of the rectangle and other graphics
            %objects
            set(graphicsHandles(1),'Position',pos);
            set(graphicsHandles(2),'Xdata',position(1),'Ydata',position(2));
            set(graphicsHandles(3),'Xdata',x(3),'Ydata',y(3));
            set(graphicsHandles(4),'Xdata',x(4),'Ydata',y(4));
            set(graphicsHandles(5),'Xdata',x(2),'Ydata',y(2));
            set(graphicsHandles(6),'Xdata',x(1),'Ydata',y(1));
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
            [x,y] = getEllipsePoints(position,ROI.nPoints,'nPoints');
            
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
        
    end
    
    
end

function [x,y] = getEllipsePoints(position,t,mode)
%This function returns a list of vertices of an elliptical polygon with
%nPoints number of vertices;
if strcmp(mode,'nPoints')
    t=linspace(0,2*pi,t); %elliptical equation is parameterized by t
end
a = position(3)/2;
b = position(4)/2;
x = a*cos(t); x = x+position(1);
y = b*sin(t); y = y+position(2);
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
        %find the x and y for the current position
        [x,y] = getEllipsePoints(position,5*pi/4,'');
        dx = x-cp(1); dy = y-cp(2);
        cp(1) = position(1)-(position(3)/2+dx); cp(2) = position(2)-(position(4)/2+dy);
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
        %find the x and y for the current position
        [x,y] = getEllipsePoints(position,7*pi/4,'');
        dx = cp(1)-x; dy = y-cp(2);
        cp(1) = position(1)+(position(3)/2+dx); cp(2) = position(2)-(position(4)/2+dy);
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
        %find the x and y for the current position
        [x,y] = getEllipsePoints(position,3*pi/4,'');
        dx = x-cp(1); dy = cp(2)-y;
        cp(1) = position(1)-(position(3)/2+dx); cp(2) = position(2)+(position(4)/2+dy);
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
        %find the x and y for the current position
        [x,y] = getEllipsePoints(position,pi/4,'');
        dx = cp(1)-x; dy = cp(2)-y;
        cp(1) = position(1)+(position(3)/2+dx); cp(2) = position(2)+(position(4)/2+dy);
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
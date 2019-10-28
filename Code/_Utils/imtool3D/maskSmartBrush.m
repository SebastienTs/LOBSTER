classdef maskSmartBrush < maskPaintBrush
    
    properties
        windowing = true;
    end
    
    methods
        function brush = maskSmartBrush(tool) %constructor
            %contruct the brush
            brush@maskPaintBrush(tool)
            
            %Set the mouse click function
            fun=@(hObject,eventdata) buttonDownFunction(hObject,eventdata,brush);
            set(brush.handles.circle,'ButtonDownFcn',fun)
        end
    end
end

function buttonUpFunction(hObject,eventdata,WBMF_old,WBUF_old,brush)
set(hObject,'WindowButtonMotionFcn',WBMF_old,'WindowButtonUpFcn',WBUF_old);
notify(brush.handles.tool,'maskChanged')

end

function buttonDownFunction(hObject,eventdata,brush)

WBMF_old = get(brush.handles.fig,'WindowButtonMotionFcn');
WBUF_old = get(brush.handles.fig,'WindowButtonUpFcn');
switch get(brush.handles.fig,'SelectionType')
    case 'normal'   %left click (paint on the mask)
        fun = @(src,evnt) ButtonMotionFunction(src,evnt,brush,'Left Click',[]);
        fun2=@(src,evnt) buttonUpFunction(src,evnt,WBMF_old,WBUF_old,brush);
        set(brush.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
        fun([],[]);     
        
    case 'alt'      %right click
        fun = @(src,evnt) ButtonMotionFunction(src,evnt,brush,'Right Click',[]);
        fun2=@(src,evnt) buttonUpFunction(src,evnt,WBMF_old,WBUF_old,brush);
        set(brush.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
        fun([],[]);     
    case 'extend'   %center click
        data.bp=get(0,'PointerLocation');
        data.r = brush.position(3);
        fun = @(src,evnt) ButtonMotionFunction(src,evnt,brush,'Middle Click',data);
        fun2=@(src,evnt) buttonUpFunction(src,evnt,WBMF_old,WBUF_old,brush);
        set(brush.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
        fun([],[]);
end

end

function ButtonMotionFunction(src,evnt,brush,tag,data)

switch tag
        
    case 'Left Click'
        %moves the circle
        cp = get(brush.handles.parent,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];
        brush.position = [cp(1) cp(2) brush.position(3)];
        
        %get the mask for the new brush position
        mask = getBrushMask(brush);
        
        %get the current mask of the imtool3D object
        maskOld = getCurrentMaskSlice(brush.handles.tool);
        
        %Get the image pixels of the current slice
        slice = getCurrentImageSlice(brush.handles.tool);
        
        %convert image range to 0-1
        if brush.windowing
            [W,L] = getWindowLevel(brush.handles.tool);
            slice = mat2gray(slice,[L-W/2 L+W/2]);
        else
            slice =mat2gray(slice);
        end
        
        %Get the otsu threshold mask
        level = graythresh(slice(mask));
        BW = im2bw(slice,level) & mask;
        
        %use BW mask that has the largest number of elements (either BW or 
        if sum(BW(BW)) < sum(mask(mask))/2
            BW= ~BW & mask;
        end
        
        %Combine the two masks
        mask = BW | maskOld;
        
        %Update the mask of the tool
        setCurrentMaskSlice(brush.handles.tool,mask)
        
    case 'Right Click'
        %moves the circle
        cp = get(brush.handles.parent,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];
        brush.position = [cp(1) cp(2) brush.position(3)];
        
        %get the mask for the new brush position
        mask = getBrushMask(brush);
        
        %get the current mask of the imtool3D object
        maskOld = getCurrentMaskSlice(brush.handles.tool);
        
        %Combine the two masks
        mask = maskOld   &   ~(mask & maskOld);
        
        %Update the mask of the tool
        setCurrentMaskSlice(brush.handles.tool,mask)
        
    case 'Middle Click'
        %get the current mouse position 
        cp = get(0,'PointerLocation');
       
        %get the difference in the y direction
        d = .25*(data.bp(2)-cp(2));
        
        rnew = data.r+d;
        if rnew<1
            rnew=1;
        end
        
        brush.position(3)=rnew;
        
end

end
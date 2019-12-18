classdef imtool3D < handle
    %This is a image slice viewer with built in scroll, contrast, zoom and
    %ROI tools.
    %
    %   Use this class to place a self-contained image viewing panel within
    %   a GUI (or any figure). Similar to imtool but with slice scrolling.
    %   Only designed to view grayscale (intensity) images. Use the mouse
    %   to control how the image is displayed. A left click allows window
    %   and leveling, a right click is for panning, and a middle click is
    %   for zooming. Also the scroll wheel can be used to scroll through
    %   slices.
    %----------------------------------------------------------------------
    %Inputs:
    %
    %   I           An m x n x k image array of grayscale values. Default
    %               is a 100x100x3 random noise image.
    %   position    The position of the panel containing the image and all
    %               the tools. Format is [xmin ymin width height]. Default
    %               position is [0 0 1 1] (units = normalized). See the
    %               setPostion and setUnits methods to change the postion
    %               or units.
    %   h           Handle of the parent figure. If no handles is provided,
    %               a new figure will be created.
    %   range       The display range of the image. Format is [min max].
    %               The range can be adjusted with the contrast tool or
    %               with the setRange method. Default is [min(I) max(I)].
    %----------------------------------------------------------------------
    %Output:
    %
    %   tool        The imtool3D object. Use this object as input to the
    %               class methods described below.
    %----------------------------------------------------------------------
    %Constructor Syntax
    %
    %tool = imtool3d() creates an imtool3D panel in the current figure with
    %a random noise image. Returns the imtool3D object.
    %
    %tool = imtool3d(I) sets the image of the imtool3D panel.
    %
    %tool = imtool3D(I,position) sets the position of the imtool3D panel
    %within the current figure. The default units are normalized.
    %
    %tool = imtool3D(I,position,h) puts the imtool3D panel in the figure
    %specified by the handle h.
    %
    %tool = imtool3D(I,position,h,range) sets the display range of the
    %image according to range=[min max].
    %
    %tool = imtool3D(I,position,h,range,tools) lets the scroll wheel
    %properly sync if you are displaying multiple imtool3D objects in the
    %same figure.
    %
    %tool = imtool3D(I,position,h,range,tools,mask) allows you to overlay a
    %semitransparent binary mask on the image data.
    %
    %Note that you can pass an empty matrix for any input variable to have
    %the constructor use default values. ex. tool=imtool3D([],[],h,[]).
    %----------------------------------------------------------------------
    %Methods:
    %
    %   setImage(tool, I) displays a new image.
    %
    %   I = getImage(tool) returns the image being shown by the tool
    %
    %   setMask(tool,mask) replaces the overlay mask with a new one
    %
    %   setAlpha(tool,alpha) sets the transparency of the overlaid mask
    %
    %   alpha = getAlpha(tool) gets the current transparency of the
    %   overlaid mask
    %
    %   setPostion(tool,position) sets the position of tool.
    %
    %   position = getPosition(tool) returns the position of the tool
    %   relative to its parent figure.
    %
    %   setUnits(tool,Units) sets the units of the position of tool. See
    %   uipanel properties for possible unit strings.
    %
    %   units = getUnits(tool) returns the units of used for the position
    %   of the tool.
    %
    %   handles = getHandles(tool) returns a structured variable, handles,
    %   which contains all the handles to the various objects used by
    %   imtool3D.
    %
    %   setDisplayRange(tool,range) sets the display range of the image.
    %   see the 'Clim' property of an Axes object for details.
    %
    %   range=getDisplayRange(tool) returns the current display range of
    %   the image.
    %
    %   setWindowLevel(tool,W,L) sets the display range of the image in
    %   terms of its window (diff(range)) and level (mean(range)).
    %
    %   [W,L] = getWindowLevel(tool) returns the display range of the image
    %   in terms of its window (W) and level (L)
    %
    %   setCurrentSlice(tool,slice) sets the current displayed slice.
    %
    %   slice = getCurrentSlice(tool) returns the currently displayed
    %   slice number.
    %
    %----------------------------------------------------------------------
    %Notes:
    %
    %   Author: Justin Solomon, July, 26 2013 (Latest update April, 16,
    %   2016)
    %
    %   Contact: justin.solomon@duke.edu
    %
    %   Current Version 2.4
    %   Version Notes:
    %                   1.1-added method to get information about the
    %                   currently selected ROI.
    %
    %                   2.0- Completely redesigned the tool. Window and
    %                   leveleing, pan, and zoom are now done with the
    %                   mouse as is standard in most medical image viewers.
    %                   Also the overall astestic design of the tool is
    %                   improved with a new black theme. Added ability to
    %                   change the colormap of the image. Also when
    %                   resizing the figure, the tool behaves better and
    %                   maintains maximum viewing area for the image while
    %                   keeping the tool buttons correctly sized.
    %                   IMPORTANT: Any code that worked with the version
    %                   1.0 may not be compatible with version 2.0.
    %
    %                   2.1- Added crop tool, help button, and button that
    %                   resets the pan and zoom settings to show the entire
    %                   image (useful when you're zoomed in and you just
    %                   want to zoom out quickly. Also made the window and
    %                   level adjustable by draging the lines on the
    %                   histogram
    %
    %                   2.2- Added support for Matlab 2014b. Added ability
    %                   to overlay a semi-transparent binary mask on the
    %                   image data. Useful to visiulize segmented data.
    %
    %                   2.3- Simplified the ROI tools. imtool3D no longer
    %                   relies on MATLAB'S imroi classes, rather I've made
    %                   a set of ROI classes just for imtool3D. This
    %                   greatly simplifies the integration of the ROI
    %                   tools. You can export and delete the ROIs directly
    %                   from their context menus.
    %
    %                   2.3.1- Make sure the figure is centered when
    %                   creating an imtool3D object in a new figure
    % 
    %                   2.3.2- Squished a few bugs for older Matlab
    %                   versions. Added method to set and get the
    %                   transparency of the overlaid mask. Refined the
    %                   panning and zooming.
    %
    %                   2.3.3- Fixed a bug with the cropping function
    %
    %                   2.3.4- Added check box to toggle on and off the
    %                   mask overlay. Fixed a bug with the interactive
    %                   window and leveling using the histogram view. Added
    %                   a paint brush to allow user to quickly segment
    %                   something
    %
    %                   2.4- Added methods to get the min, max, and range
    %                   of pixel values. Updated the window and leveling to
    %                   be adaptive to the dynamic range of the image data.
    %                   Should work well if the range is small or large.
    %
    %                   2.4.1- fixed a small bug related to windowing with
    %                   the mouse.
    %
    %                   2.4.2- Added a "smart" paint brush which helps to
    %                   segment borders cleanly.
    %   
    %   Created in MATLAB_R2015b
    %
    %   Requires the image processing toolbox
    
    properties (SetAccess = private, GetAccess = private)
        I           %Image data (MxNxK) matrix of image data   
        mask        %Binary mask that can be overlaid on the image data
        maskColor   %1x3 vector specifying the RGB color of the overlaid mask. Default is red (i.e., [1 0 0]);
        handles     %Structured variable with all the handles
        centers     %list of bin centers for histogram
        alpha       %transparency of the overlaid mask (default is .2)
        aspectRatio = [1 1];
    end
    
    properties
        windowSpeed=2; %Ratio controls how fast the window and level change when you change them with the mouse
    end
    
    events
        newImage
        maskChanged
    end
     
    methods
        
        function tool = imtool3D(varargin)  %Constructor
            
            %Check the inputs and set things appropriately
            switch nargin
                case 0  %tool = imtool3d()
                    I=random('unif',-50,50,[100 100 3]);
                    position=[0 0 1 1]; h=[];
                    range=[-50 50]; tools=[]; mask=false(size(I));
                case 1  %tool = imtool3d(I)
                    I=varargin{1}; position=[0 0 1 1]; h=[];
                    range=[min(I(:)) max(I(:))]; tools=[]; mask=false(size(I));
                case 2  %tool = imtool3d(I,position)
                    I=varargin{1}; position=varargin{2}; h=[];
                    range=[min(I(:)) max(I(:))]; tools=[]; mask=false(size(I));
                case 3  %tool = imtool3d(I,position,h)
                    I=varargin{1}; position=varargin{2}; h=varargin{3};
                    range=[min(I(:)) max(I(:))]; tools=[]; mask=false(size(I));
                case 4  %tool = imtool3d(I,position,h,range)
                    I=varargin{1}; position=varargin{2}; h=varargin{3};
                    range=varargin{4}; tools=[]; mask=false(size(I));
                case 5  %tool = imtool3d(I,position,h,range,tools)
                    I=varargin{1}; position=varargin{2}; h=varargin{3};
                    range=varargin{4}; tools=varargin{5}; mask=false(size(I));
                case 6  %tool = imtool3d(I,position,h,range,tools,mask)
                    I=varargin{1}; position=varargin{2}; h=varargin{3};
                    range=varargin{4}; tools=varargin{5}; mask=varargin{6};
            end
            
            
            if isempty(I)
                I=random('unif',-50,50,[100 100 3]);
            end
            
            if islogical(I)
                I=double(I);
                range = [0 1];
            end
            
            if isempty(position)
                position=[0 0 1 1];
            end
            
            if isempty(h)
                h=figure;
                set(h,'Toolbar','none','Menubar','none','NextPlot','new')
                set(h,'Units','Pixels');
                pos=get(h,'Position');
                Af=pos(3)/pos(4);   %input Ratio of the figure
                AI=size(I,2)/size(I,1); %input Ratio of the image
                if Af>AI    %Figure is too wide, make it taller to match
                   pos(4)=pos(3)/AI; 
                elseif Af<AI    %Figure is too long, make it wider to match
                    pos(3)=AI*pos(4);
                end
                %make sure the figure is centered
                screensize = get(0,'ScreenSize');
                pos(1) = ceil((screensize(3)-pos(3))/2);
                pos(2) = ceil((screensize(4)-pos(4))/2); 
                set(h,'Position',pos)
                set(h,'Units','normalized');
            end
            
            if isempty(range)
                range=[min(I(:)) max(I(:))];
            end
            
            if isempty(mask)
                mask=logical(zeros(size(I)));
            end
            
            %find the parent figure handle if the given parent is not a
            %figure
            if ~strcmp(get(h,'type'),'figure')
                fig = getParentFigure(h);
            else
                fig = h;
            end
            
            %--------------------------------------------------------------
            tool.I      = I;
            tool.mask   =mask;
            tool.handles.fig=fig;
            tool.handles.parent = h;
            tool.maskColor = [1 0 0];
            tool.alpha = .2;
            
            %Create the panels and slider
            w=30; %Pixel width of the side panels
            h=110; %Pixel height of the histogram panel
            wbutt=20; %Pixel size of the buttons
            tool.handles.Panels.Large   =   uipanel(tool.handles.parent,'Position',position,'Title','','Tag','imtool3D'); set(tool.handles.Panels.Large,'Units','Pixels'); pos=get(tool.handles.Panels.Large,'Position'); set(tool.handles.Panels.Large,'Units','normalized');
            tool.handles.Panels.Hist   =   uipanel(tool.handles.Panels.Large,'Units','Pixels','Position',[w pos(4)-w-h pos(3)-2*w h],'Title','');
            tool.handles.Panels.Image   =   uipanel(tool.handles.Panels.Large,'Units','Pixels','Position',[w w pos(3)-2*w pos(4)-2*w],'Title','');
            tool.handles.Panels.Tools   =   uipanel(tool.handles.Panels.Large,'Units','Pixels','Position',[0 pos(4)-w pos(3) w],'Title','');
            tool.handles.Panels.ROItools    =   uipanel(tool.handles.Panels.Large,'Units','Pixels','Position',[pos(3)-w  w w pos(4)-2*w],'Title','');
            tool.handles.Panels.Slider  =   uipanel(tool.handles.Panels.Large,'Units','Pixels','Position',[0 w w pos(4)-2*w],'Title','');
            tool.handles.Panels.Info   =   uipanel(tool.handles.Panels.Large,'Units','Pixels','Position',[0 0 pos(3) w],'Title','');
            try
                set(cell2mat(struct2cell(tool.handles.Panels)),'BackgroundColor','k','ForegroundColor','w','HighlightColor','k')
            catch
                objarr=struct2cell(tool.handles.Panels);
                objarr=[objarr{:}];
                set(objarr,'BackgroundColor','k','ForegroundColor','w','HighlightColor','k');
            end
            
            
            %Create Slider for scrolling through image stack
            tool.handles.Slider         =   uicontrol(tool.handles.Panels.Slider,'Style','Slider','Units','Normalized','Position',[0 0 1 1],'TooltipString','Change Slice (can use scroll wheel also)');
            setupSlider(tool)
            fun=@(scr,evnt)multipleScrollWheel(scr,evnt,[tool tools]);
            set(tool.handles.fig,'WindowScrollWheelFcn',fun);
           
            
            %Create image axis
            tool.handles.Axes           =   axes('Position',[0 0 1 1],'Parent',tool.handles.Panels.Image,'Color','none');
            tool.handles.I              =   imshow(I(:,:,1),range,'Parent',tool.handles.Axes); hold on; set(tool.handles.I,'Clipping','off')
            set(tool.handles.Axes,'XLimMode','manual','YLimMode','manual','Clipping','off');
            
            
            %Set up the binary mask viewer
            im=zeros(size(I,1),size(I,2),3);
            im(:,:,1)=tool.maskColor(1); im(:,:,2)=tool.maskColor(2); im(:,:,3)=tool.maskColor(3);
            tool.handles.mask           =   imshow(im);
            set(tool.handles.mask,'AlphaData',.3*tool.mask(:,:,1))
            set(tool.handles.Axes,'Position',[0 0 1 1],'Color','none','XColor','r','YColor','r','GridLineStyle','--','LineWidth',1.5,'XTickLabel','','YTickLabel','');
            axis off
            grid off
            axis fill
            
            
            %Set up image info display
            tool.handles.Info=uicontrol(tool.handles.Panels.Info,'Style','text','String','(x,y) val','Units','Normalized','Position',[0 .1 .5 .8],'BackgroundColor','k','ForegroundColor','w','FontSize',12,'HorizontalAlignment','Left');
            fun=@(src,evnt)getImageInfo(src,evnt,tool);
            set(tool.handles.fig,'WindowButtonMotionFcn',fun);
            tool.handles.SliceText=uicontrol(tool.handles.Panels.Tools,'Style','text','String',['1/' num2str(size(I,3))],'Units','Normalized','Position',[.5 .1 .48 .8],'BackgroundColor','k','ForegroundColor','w','FontSize',12,'HorizontalAlignment','Right');
            
            
            %Set up mouse button controls
            fun=@(hObject,eventdata) imageButtonDownFunction(hObject,eventdata,tool);
            set(tool.handles.mask,'ButtonDownFcn',fun)
            set(tool.handles.I,'ButtonDownFcn',fun)
            
            %create the tool buttons
            wp=w;
            w=wbutt;
            buff=(wp-w)/2;
            
            %Create the histogram plot
            tool.handles.HistAxes           =   axes('Position',[.025 .15 .95 .55],'Parent',tool.handles.Panels.Hist);
            im=tool.I(:,:,1);
            centers=linspace(double(min(I(:))),double(max(I(:))),256); 
            nelements=hist(im(:),centers); nelements=nelements./max(nelements);
            tool.handles.HistLine=plot(centers,nelements,'-w','LineWidth',1);
            set(tool.handles.HistAxes,'Color','none','XColor','w','YColor','w','FontSize',9,'YTick',[])
            axis on
            hold on
            axis fill
            xlim(get(gca,'Xlim'))
            tool.handles.Histrange(1)=plot([range(1) range(1) range(1)],[0 .5 1],'.-r');
            tool.handles.Histrange(2)=plot([range(2) range(2) range(2)],[0 .5 1],'.-r');
            tool.handles.Histrange(3)=plot([mean(range) mean(range) mean(range)],[0 .5 1],'.--r');
            tool.handles.HistImageAxes           =   axes('Position',[.025 .75 .95 .2],'Parent',tool.handles.Panels.Hist);
            set(tool.handles.HistImageAxes,'Units','Pixels'); pos=get(tool.handles.HistImageAxes,'Position'); set(tool.handles.HistImageAxes,'Units','Normalized');
            tool.handles.HistImage=imshow(repmat(centers,[round(pos(4)) 1]),range);
            set(tool.handles.HistImageAxes,'XColor','w','YColor','w','XTick',[],'YTick',[])
            axis on;
            box on;
            axis normal
            tool.centers=centers;
            fun = @(hObject,evnt)histogramButtonDownFunction(hObject,evnt,tool,1);
            set(tool.handles.Histrange(1),'ButtonDownFcn',fun);
            fun = @(hObject,evnt)histogramButtonDownFunction(hObject,evnt,tool,2);
            set(tool.handles.Histrange(2),'ButtonDownFcn',fun);
            fun = @(hObject,evnt)histogramButtonDownFunction(hObject,evnt,tool,3);
            set(tool.handles.Histrange(3),'ButtonDownFcn',fun);
            
            %Create histogram checkbox
            tool.handles.Tools.Hist     =   uicontrol(tool.handles.Panels.Tools,'Style','Checkbox','String','Hist?','Position',[buff buff 2.5*w w],'TooltipString','Show Histogram','BackgroundColor','k','ForegroundColor','w');
            fun=@(hObject,evnt) ShowHistogram(hObject,evnt,tool,wp,h);
            set(tool.handles.Tools.Hist,'Callback',fun)
            lp=buff+2.5*w;
            
            
            %Set up the resize function
            fun=@(x,y) panelResizeFunction(x,y,tool,wp,h,wbutt);
            set(tool.handles.Panels.Large,'ResizeFcn',fun)

            
            %Create window and level boxes
            tool.handles.Tools.TW       =   uicontrol(tool.handles.Panels.Tools,'Style','text','String','W','Position',[lp+buff buff w w],'BackgroundColor','k','ForegroundColor','w','TooltipString','Window Width');
            tool.handles.Tools.W        =   uicontrol(tool.handles.Panels.Tools,'Style','Edit','String',num2str(range(2)-range(1)),'Position',[lp+buff+w buff 2*w w],'TooltipString','Window Width','BackgroundColor',[.2 .2 .2],'ForegroundColor','w'); 
            tool.handles.Tools.TL       =   uicontrol(tool.handles.Panels.Tools,'Style','text','String','L','Position',[lp+2*buff+3*w buff w w],'BackgroundColor','k','ForegroundColor','w','TooltipString','Window Level');
            tool.handles.Tools.L        =   uicontrol(tool.handles.Panels.Tools,'Style','Edit','String',num2str(mean(range)),'Position',[lp+2*buff+4*w buff 2*w w],'TooltipString','Window Level','BackgroundColor',[.2 .2 .2],'ForegroundColor','w');
            lp=lp+buff+7*w;
            
            %Creat window and level callbacks
            fun=@(hobject,evnt) WindowLevel_callback(hobject,evnt,tool);
            set(tool.handles.Tools.W,'Callback',fun);
            set(tool.handles.Tools.L,'Callback',fun);
            
            %Create view restore button
            tool.handles.Tools.ViewRestore           =   uicontrol(tool.handles.Panels.Tools,'Style','pushbutton','String','','Position',[lp buff w w],'TooltipString','Reset Pan and Zoom');
            [iptdir, MATLABdir] = ipticondir;
            icon_save = makeToolbarIconFromPNG([iptdir '/overview_zoom_in.png']);
            set(tool.handles.Tools.ViewRestore,'CData',icon_save);
            fun=@(hobject,evnt) resetViewCallback(hobject,evnt,tool);
            set(tool.handles.Tools.ViewRestore,'Callback',fun)
            lp=lp+w+2*buff;
            
            %Create grid checkbox and grid lines
            axes(tool.handles.Axes)
            tool.handles.Tools.Grid           =   uicontrol(tool.handles.Panels.Tools,'Style','checkbox','String','Grid?','Position',[lp buff 2.5*w w],'BackgroundColor','k','ForegroundColor','w');
            nGrid=7;
            nMinor=4;
            x=linspace(1,size(I,2),nGrid);
            y=linspace(1,size(I,1),nGrid);
            hold on;
            tool.handles.grid=[];
            gColor=[255 38 38]./256;
            mColor=[255 102 102]./256;
            for i=1:nGrid
                tool.handles.grid(end+1)=plot([.5 size(I,2)-.5],[y(i) y(i)],'-','LineWidth',1.2,'HitTest','off','Color',gColor);
                tool.handles.grid(end+1)=plot([x(i) x(i)],[.5 size(I,1)-.5],'-','LineWidth',1.2,'HitTest','off','Color',gColor);
                if i<nGrid
                    xm=linspace(x(i),x(i+1),nMinor+2); xm=xm(2:end-1);
                    ym=linspace(y(i),y(i+1),nMinor+2); ym=ym(2:end-1);
                    for j=1:nMinor
                        tool.handles.grid(end+1)=plot([.5 size(I,2)-.5],[ym(j) ym(j)],'-r','LineWidth',.9,'HitTest','off','Color',mColor);
                        tool.handles.grid(end+1)=plot([xm(j) xm(j)],[.5 size(I,1)-.5],'-r','LineWidth',.9,'HitTest','off','Color',mColor);
                    end
                end
            end
            tool.handles.grid(end+1)=scatter(.5+size(I,2)/2,.5+size(I,1)/2,'r','filled');
            set(tool.handles.grid,'Visible','off')
            fun=@(hObject,evnt) toggleGrid(hObject,evnt,tool);
            set(tool.handles.Tools.Grid,'Callback',fun)
            set(tool.handles.Tools.Grid,'TooltipString','Toggle Gridlines')
            lp=lp+2.5*w;
            
            %Create the mask view switch
            tool.handles.Tools.Mask           =   uicontrol(tool.handles.Panels.Tools,'Style','checkbox','String','Mask?','Position',[lp buff 3*w w],'BackgroundColor','k','ForegroundColor','w','TooltipString','Toggle Binary Mask','Value',1);
            fun=@(hObject,evnt) toggleMask(hObject,evnt,tool);
            set(tool.handles.Tools.Mask,'Callback',fun)
            lp=lp+3*w;
            
            %Create colormap pulldown menu
            mapNames={'Gray','Hot','Jet','HSV','Cool','Spring','Summer','Autumn','Winter','Bone','Copper','Pink','Lines','colorcube','flag','prism','white'};
            tool.handles.Tools.Color          =   uicontrol(tool.handles.Panels.Tools,'Style','popupmenu','String',mapNames,'Position',[lp buff 3.5*w w]);
            fun=@(hObject,evnt) changeColormap(hObject,evnt,tool);
            set(tool.handles.Tools.Color,'Callback',fun)
            set(tool.handles.Tools.Color,'TooltipString','Select a colormap')
            lp=lp+3.5*w;
            
            %Create save button
            tool.handles.Tools.Save           =   uicontrol(tool.handles.Panels.Tools,'Style','pushbutton','String','','Position',[lp buff w w]);
            icon_save = makeToolbarIconFromPNG([MATLABdir '/file_save.png']);
            set(tool.handles.Tools.Save,'CData',icon_save);
            lp=lp+w;
            tool.handles.Tools.SaveOptions    =   uicontrol(tool.handles.Panels.Tools,'Style','popupmenu','String',{'as slice','as stack'},'Position',[lp buff 5*w w]);
            fun=@(hObject,evnt) saveImage(hObject,evnt,tool);
            set(tool.handles.Tools.Save,'Callback',fun)
            set(tool.handles.Tools.Save,'TooltipString','Save image as slice or tiff stack')
            
            %Create Circle ROI button
            tool.handles.Tools.CircleROI           =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','','Position',[buff buff w w],'TooltipString','Create Elliptical ROI');
            icon_ellipse = makeToolbarIconFromPNG([MATLABdir '/tool_shape_ellipse.png']);
            set(tool.handles.Tools.CircleROI,'Cdata',icon_ellipse)
            fun=@(hObject,evnt) measureImageCallback(hObject,evnt,tool,'ellipse');
            set(tool.handles.Tools.CircleROI,'Callback',fun)
            
            %Create Square ROI button
            tool.handles.Tools.SquareROI           =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','','Position',[buff buff+w w w],'TooltipString','Create Rectangular ROI');
            icon_rect = makeToolbarIconFromPNG([MATLABdir '/tool_shape_rectangle.png']);
            set(tool.handles.Tools.SquareROI,'Cdata',icon_rect)
            fun=@(hObject,evnt) measureImageCallback(hObject,evnt,tool,'rectangle');
            set(tool.handles.Tools.SquareROI,'Callback',fun)
            
            %Create Polygon ROI button
            tool.handles.Tools.PolyROI             =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','\_/','Position',[buff buff+2*w w w],'TooltipString','Create Polygon ROI');
            fun=@(hObject,evnt) measureImageCallback(hObject,evnt,tool,'polygon');
            set(tool.handles.Tools.PolyROI,'Callback',fun)
            
            %Create line profile button
            tool.handles.Tools.Ruler             =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','','Position',[buff buff+3*w w w],'TooltipString','Measure Distance');
            icon_distance = makeToolbarIconFromPNG([MATLABdir '/tool_line.png']);
            set(tool.handles.Tools.Ruler,'CData',icon_distance);
            fun=@(hObject,evnt) measureImageCallback(hObject,evnt,tool,'profile');
            set(tool.handles.Tools.Ruler,'Callback',fun)
            
            %Paint brush tool button
            tool.handles.Tools.PaintBrush        = uicontrol(tool.handles.Panels.ROItools,'Style','togglebutton','String','','Position',[buff buff+4*w w w],'TooltipString','Paint Brush Tool');
            icon_profile = makeToolbarIconFromPNG([MATLABdir '/tool_data_brush.png']);
            set(tool.handles.Tools.PaintBrush ,'Cdata',icon_profile)
            fun=@(hObject,evnt) PaintBrushCallback(hObject,evnt,tool,'Normal');
            set(tool.handles.Tools.PaintBrush ,'Callback',fun)
            tool.handles.PaintBrushObject=[];
            
            %Smart Paint brush tool button
            tool.handles.Tools.SmartBrush        = uicontrol(tool.handles.Panels.ROItools,'Style','togglebutton','String','','Position',[buff buff+5*w w w],'TooltipString','Smart Brush Tool');
            set(tool.handles.Tools.SmartBrush ,'Cdata',icon_profile)
            fun=@(hObject,evnt) PaintBrushCallback(hObject,evnt,tool,'Smart');
            set(tool.handles.Tools.SmartBrush ,'Callback',fun)
            
            
            %Create Crop tool button
            tool.handles.Tools.Crop             =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','','Position',[buff buff+6*w w w],'TooltipString','Crop Image');
            icon_profile = makeToolbarIconFromPNG([iptdir '/crop_tool.png']);
            set(tool.handles.Tools.Crop ,'Cdata',icon_profile)
            fun=@(hObject,evnt) CropImageCallback(hObject,evnt,tool);
            set(tool.handles.Tools.Crop ,'Callback',fun)
            
            
            %Create Help Button
            pos=get(tool.handles.Panels.ROItools,'Position');
            tool.handles.Tools.Help             =   uicontrol(tool.handles.Panels.ROItools,'Style','pushbutton','String','?','Position',[buff pos(4)-w-buff w w],'TooltipString','Help with imtool3D');
            fun=@(hObject,evnt) displayHelp(hObject,evnt,tool);
            set(tool.handles.Tools.Help,'Callback',fun)
            
            %Set font size of all the tool objects
            try
                set(cell2mat(struct2cell(tool.handles.Tools)),'FontSize',9,'Units','Pixels')
            catch
                objarr=struct2cell(tool.handles.Tools);
                objarr=[objarr{:}];
                set(objarr,'FontSize',9,'Units','Pixels')
            end
            
            set(tool.handles.fig,'NextPlot','new')
            
            %run the reset view callback
            resetViewCallback([],[],tool)
            
        end
        
        function setPosition(tool,position)
            set(tool.handles.Panels.Large,'Position',position)
        end
        
        function position = getPosition(tool)
            position = get(tool.handles.Panels.Large,'Position');
        end
        
        function setUnits(tool,units)
            set(tool.handles.Panels.Large,'Units',units)
        end
        
        function units = getUnits(tool)
            units = get(tool.handles.Panels.Large,'Units');
        end
        
        function setMask(tool,mask)
            tool.mask=mask;
            showSlice(tool)
            notify(tool,'maskChanged')
        end
        
        function mask = getMask(tool)
            mask = tool.mask;
        end
        
        function setMaskColor(tool,maskColor)
            
            if ischar(maskColor)
                switch maskColor
                    case 'y'
                        maskColor = [1 1 0];
                    case 'm'
                        maskColor = [1 0 1];
                    case 'c'
                        maskColor = [0 1 1];
                    case 'r'
                        maskColor = [1 0 0];
                    case 'g'
                        maskColor = [0 1 0];
                    case 'b'
                        maskColor = [0 0 1];
                    case 'w'
                        maskColor = [1 1 1];
                    case 'k'
                        maskColor = [0 0 0];
                end
            end
            
            
            C = get(tool.handles.mask,'CData');
            C(:,:,1) = maskColor(1);
            C(:,:,2) = maskColor(2);
            C(:,:,3) = maskColor(3);
            set(tool.handles.mask,'CData',C);
            
        end
        
        function maskColor = getMaskColor(tool)
            maskColor = tool.maskColor;
        end
        
        function setImage(varargin)
            switch nargin
                case 1
                    tool=varargin{1}; I=random('unif',-50,50,[100 100 3]);
                    range=[-50 50]; mask=false(size(I));
                case 2
                    tool=varargin{1}; I=varargin{2};
                    range=[min(I(:)) max(I(:))]; mask=false(size(I));
                case 3
                    tool=varargin{1}; I=varargin{2};
                    range=varargin{3}; mask=false(size(I));
                case 4
                    tool=varargin{1}; I=varargin{2};
                    range=varargin{3}; mask=varargin{4};
            end
            
            if isempty(I)
                I=random('unif',-50,50,[100 100 3]);
            end
            if isempty(range)
                range=[min(I(:)) max(I(:))];
            end
            
            tool.I=I;
            tool.mask=mask;
            
            
            %Update the histogram
            im=tool.I(:,:,1);
            tool.centers=linspace(min(I(:)),max(I(:)),256);
            nelements=hist(im(:),tool.centers); nelements=nelements./max(nelements);
            set(tool.handles.HistLine,'XData',tool.centers,'YData',nelements);
            axes(tool.handles.HistAxes);
            try
                xlim([tool.centers(1) tool.centers(end)])
            catch
                xlim([tool.centers(1) tool.centers(end)+.1])
            end
            axis fill
            
            %Update the window and level
            setWL(tool,diff(range),mean(range))

            %Update the image
            %set(tool.handles.I,'CData',im)
            axes(tool.handles.Axes);
            xlim([0 size(I,2)])
            ylim([0 size(I,1)])
            
            %Update the gridlines
            axes(tool.handles.Axes);
            delete(tool.handles.grid)
            nGrid=7;
            nMinor=4;
            x=linspace(1,size(I,2),nGrid);
            y=linspace(1,size(I,1),nGrid);
            hold on;
            tool.handles.grid=[];
            gColor=[255 38 38]./256;
            mColor=[255 102 102]./256;
            for i=1:nGrid
                tool.handles.grid(end+1)=plot([.5 size(I,2)-.5],[y(i) y(i)],'-','LineWidth',1.2,'HitTest','off','Color',gColor,'Parent',tool.handles.Axes);
                tool.handles.grid(end+1)=plot([x(i) x(i)],[.5 size(I,1)-.5],'-','LineWidth',1.2,'HitTest','off','Color',gColor,'Parent',tool.handles.Axes);
                if i<nGrid
                    xm=linspace(x(i),x(i+1),nMinor+2); xm=xm(2:end-1);
                    ym=linspace(y(i),y(i+1),nMinor+2); ym=ym(2:end-1);
                    for j=1:nMinor
                        tool.handles.grid(end+1)=plot([.5 size(I,2)-.5],[ym(j) ym(j)],'-r','LineWidth',.9,'HitTest','off','Color',mColor,'Parent',tool.handles.Axes);
                        tool.handles.grid(end+1)=plot([xm(j) xm(j)],[.5 size(I,1)-.5],'-r','LineWidth',.9,'HitTest','off','Color',mColor,'Parent',tool.handles.Axes);
                    end
                end
            end
            tool.handles.grid(end+1)=scatter(.5+size(I,2)/2,.5+size(I,1)/2,'r','filled','Parent',tool.handles.Axes);
            toggleGrid(tool.handles.Tools.Grid,[],tool)
            
            %update the mask cdata (in case it has changed size)
            C=zeros(size(I,1),size(I,2),3);
            C(:,:,1)=tool.maskColor(1); C(:,:,2)=tool.maskColor(2); C(:,:,3)=tool.maskColor(3);
            set(tool.handles.mask,'CData',C);
            
            %Update the slider
            setupSlider(tool)
            
            %Show the first slice
            showSlice(tool)
            
            %Broadcast that the image has been updated
            notify(tool,'newImage')
            notify(tool,'maskChanged')
            
            
        end
        
        function I = getImage(tool)
            I=tool.I;
        end
        
        function m = max(tool)
            m = max(tool.I(:));
        end
        
        function m = min(tool)
            m = min(tool.I(:));
        end
        
        function r = range(tool)
            r = range(tool.I(:));
        end
        
        function handles=getHandles(tool)
            handles=tool.handles;
        end
        
        function setAspectRatio(tool,psize)
            %This sets the proper aspect ratio of the viewer for cases
            %where you have non-square pixels
            set(tool.handles.Axes,'DataAspectRatio',1./psize)
        end
        
        function setDisplayRange(tool,range)
            W=diff(range);
            L=mean(range);
            setWL(tool,W,L);
        end
        
        function range=getDisplayRange(tool)
            range=get(tool.handles.Axes,'Clim');
        end
        
        function setWindowLevel(tool,W,L)
            setWL(tool,W,L);
        end
        
        function [W,L] = getWindowLevel(tool)
            range=get(tool.handles.Axes,'Clim');
            W=diff(range);
            L=mean(range);
        end
        
        function setCurrentSlice(tool,slice)
            showSlice(tool,slice)
        end
        
        function slice = getCurrentSlice(tool)
            slice=round(get(tool.handles.Slider,'value'));
        end
        
        function mask = getCurrentMaskSlice(tool)
            slice = getCurrentSlice(tool);
            mask=tool.mask(:,:,slice);
        end
        
        function setCurrentMaskSlice(tool,mask)
            slice = getCurrentSlice(tool);
            tool.mask(:,:,slice)=mask;
            showSlice(tool,slice)
        end
        
        function im = getCurrentImageSlice(tool)
            slice = getCurrentSlice(tool);
            im = tool.I(:,:,slice);
        end
        
        function setAlpha(tool,alpha)
            if alpha <=1 && alpha >=0
                tool.alpha = alpha;
                slice = getCurrentSlice(tool);
                showSlice(tool,slice)
            else
                warning('Alpha value should be between 0 and 1')
            end
        end
        
        function alpha = getAlpha(tool)
            alpha = tool.alpha;
        end
        
        function S = getImageSize(tool)
            S=size(tool.I);
        end
        
        function addImageValues(tool,im,lims)
            %this function adds im to the image at location specified by
            %lims . Lims defines the box in which the new data, im, will be
            %inserted. lims = [ymin ymax; xmin xmax; zmin zmax];
            
            tool.I(lims(1,1):lims(1,2),lims(2,1):lims(2,2),lims(3,1):lims(3,2))=...
                tool.I(lims(1,1):lims(1,2),lims(2,1):lims(2,2),lims(3,1):lims(3,2))+im;
            showSlice(tool);
        end
        
        function im = getImageValues(tool,lims)
            im = tool.I(lims(1,1):lims(1,2),lims(2,1):lims(2,2),lims(3,1):lims(3,2));
        end
        
        function createBrushObject(tool,style)
            switch style
                case 'Normal'
                    tool.handles.PaintBrushObject=maskPaintBrush(tool);
                case 'Smart'
                    tool.handles.PaintBrushObject=maskSmartBrush(tool);
            end
        end
        
        function removeBrushObject(tool)
            try
                delete(tool.handles.PaintBrushObject)
                
            end
            tool.handles.PaintBrushObject=[];
        end
        
        function delete(tool)
            try
                delete(tool.handles.Panels.Large)
            end
        end
     
    end
    
    methods (Access = private)
                
        function showSlice(varargin)
            switch nargin
                case 1
                    tool=varargin{1};
                    n=round(get(tool.handles.Slider,'value'));
                case 2
                    tool=varargin{1};
                    n=varargin{2};
                    set(tool.handles.Slider,'value',n);
                otherwise
                    tool=varargin{1};
                    n=round(get(tool.handles.Slider,'value'));    
            end
            
            if n < 1
                n=1;
            end
            
            if n > size(tool.I,3)
                n=size(tool.I,3);
            end
            %% Modified by Seb to show local Z projection
            global RunProjViewer;
            if RunProjViewer > 1
                %CurrMask = max(tool.mask(:,:,max(n-floor((RunProjViewer-1)/2),1):min(n+floor((RunProjViewer-1)/2),size(tool.mask,3))),[],3);
                CurrMask = 0.25*max(tool.mask(:,:,max(n-floor((RunProjViewer-1)/2),1):min(n+floor((RunProjViewer-1)/2),size(tool.mask,3))),[],3)+0.75*tool.mask(:,:,n);
            else
                CurrMask = tool.mask(:,:,n);
            end
            set(tool.handles.I,'AlphaData',1)
            set(tool.handles.I,'CData',tool.I(:,:,n))
            set(tool.handles.mask,'AlphaData',tool.alpha*CurrMask)
            set(tool.handles.SliceText,'String',[num2str(n) '/' num2str(size(tool.I,3))])
            if get(tool.handles.Tools.Hist,'value')
                im=tool.I(:,:,n);
                nelements=hist(im(:),tool.centers); nelements=nelements./max(nelements);
                set(tool.handles.HistLine,'YData',nelements);
            end
            
        end
        
        function setupSlider(tool)
            n=size(tool.I,3);
            if n==1
                set(tool.handles.Slider,'visible','off');
            else
                set(tool.handles.Slider,'visible','on');
                set(tool.handles.Slider,'min',1,'max',size(tool.I,3),'value',1)
                set(tool.handles.Slider,'SliderStep',[1/(size(tool.I,3)-1) 1/(size(tool.I,3)-1)])
                fun=@(hobject,eventdata)showSlice(tool,[],hobject,eventdata);
                set(tool.handles.Slider,'Callback',fun);
            end
              
        end
        
        function setWL(tool,W,L)
            try
                set(tool.handles.Axes,'Clim',[L-W/2 L+W/2])
                set(tool.handles.Tools.W,'String',num2str(W));
                set(tool.handles.Tools.L,'String',num2str(L));
                set(tool.handles.HistImageAxes,'Clim',[L-W/2 L+W/2])
                set(tool.handles.Histrange(1),'XData',[L-W/2 L-W/2 L-W/2])
                set(tool.handles.Histrange(2),'XData',[L+W/2 L+W/2 L+W/2])
                set(tool.handles.Histrange(3),'XData',[L L L])
            end
        end
                                                    
    end

    
end

function PaintBrushCallback(hObject,evnt,tool,style)
%Remove any old brush
removeBrushObject(tool);

if get(hObject,'Value')
    switch style
        case 'Normal'
            set(tool.handles.Tools.SmartBrush,'Value',0);
        case 'Smart'
            set(tool.handles.Tools.PaintBrush,'Value',0);
    end
    createBrushObject(tool,style);    
end

end

function CropImageCallback(hObject,evnt,tool)
[I2 rect] = imcrop(tool.handles.Axes);
rect=round(rect);
mask = getMask(tool);
range=getDisplayRange(tool);
setImage(tool, tool.I(rect(2):rect(2)+rect(4)-1,rect(1):rect(1)+rect(3)-1,:),range,mask(rect(2):rect(2)+rect(4)-1,rect(1):rect(1)+rect(3)-1,:))

end

function measureImageCallback(hObject,evnt,tool,type)

switch type
    case 'ellipse'
        h = getHandles(tool);
        ROI = imtool3DROI_ellipse(h.I);
    case 'rectangle'
        h = getHandles(tool);
        ROI = imtool3DROI_rect(h.I);
    case 'polygon'
        h = getHandles(tool);
        ROI = imtool3DROI_poly(h.I);
    case 'profile'
        h = getHandles(tool);
        ROI = imtool3DROI_line(h.I);
    otherwise
end


end

function varargout = imageButtonDownFunction(hObject,eventdata,tool)
switch nargout
    case 0
        bp = get(0,'PointerLocation');
        WBMF_old = get(tool.handles.fig,'WindowButtonMotionFcn');
        WBUF_old = get(tool.handles.fig,'WindowButtonUpFcn');
        switch get(tool.handles.fig,'SelectionType')
            case 'normal'   %Adjust window and level
                CLIM=get(tool.handles.Axes,'Clim');
                W=CLIM(2)-CLIM(1);
                L=mean(CLIM);
                %make the contrast icon for the pointer
                icon = zeros(16);
                x = 1:16; [X,Y]= meshgrid(x,x); R = sqrt((X-8).^2 + (Y-8).^2);
                icon(Y>8) = 1;
                icon(Y<=8) = 2;
                icon(R>8) = nan;
                set(tool.handles.fig,'PointerShapeCData',icon);
                set(tool.handles.fig,'Pointer','custom')
                fun=@(src,evnt) adjustContrastMouse(src,evnt,bp,tool.handles.Axes,tool,W,L);
                fun2=@(src,evnt) buttonUpFunction(src,evnt,tool,WBMF_old,WBUF_old);
                set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
            case 'extend'  %Zoom
                xlims=get(tool.handles.Axes,'Xlim');
                ylims=get(tool.handles.Axes,'Ylim');
                bpA=get(tool.handles.Axes,'CurrentPoint');
                bpA=[bpA(1,1) bpA(1,2)];
                setptr(tool.handles.fig,'glass');
                fun=@(src,evnt) adjustZoomMouse(src,evnt,bp,tool.handles.Axes,tool,xlims,ylims,bpA);
                fun2=@(src,evnt) buttonUpFunction(src,evnt,tool,WBMF_old,WBUF_old);
                set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
            case 'alt' %pan
                xlims=get(tool.handles.Axes,'Xlim');
                ylims=get(tool.handles.Axes,'Ylim');
                oldUnits =  get(tool.handles.Axes,'Units'); set(tool.handles.Axes,'Units','Pixels');
                pos = get(tool.handles.Axes,'Position'); 
                set(tool.handles.Axes,'Units',oldUnits);
                axesPixels = pos(3:end);
                imagePixels = [diff(xlims) diff(ylims)];
                scale = imagePixels./axesPixels;
                scale = scale(1);
                setptr(tool.handles.fig,'closedhand');
                fun=@(src,evnt) adjustPanMouse(src,evnt,bp,tool.handles.Axes,xlims,ylims,scale);
                fun2=@(src,evnt) buttonUpFunction(src,evnt,tool,WBMF_old,WBUF_old);
                set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
        end
    case 2
        bp=get(tool.handles.Axes,'CurrentPoint');
        x=bp(1,1); y=bp(1,2);
        varargout{1}=x; varargout{2}=y;
end
end

function resetViewCallback(hObject,evnt,tool)
set(tool.handles.Axes,'Xlim',get(tool.handles.I,'XData'))
set(tool.handles.Axes,'Ylim',get(tool.handles.I,'YData'))
end

function toggleGrid(hObject,eventdata,tool)
if get(hObject,'Value')
    set(tool.handles.grid,'Visible','on')
else
    set(tool.handles.grid,'Visible','off')
end
end

function toggleMask(hObject,eventdata,tool)
if get(hObject,'Value')
    set(tool.handles.mask,'Visible','on')
else
    set(tool.handles.mask,'Visible','off')
end

end

function changeColormap(hObject,eventdata,tool)
n=get(hObject,'Value');
maps=get(hObject,'String');
colormap(maps{n})
end

function WindowLevel_callback(hobject,evnt,tool)
range=get(tool.handles.Axes,'Clim');
Wold=range(2)-range(1); Lold=mean(range);
W=str2num(get(tool.handles.Tools.W,'String'));
if isempty(W) || W<=0
    W=Wold;
    set(tool.handles.Tools.W,'String',num2str(W))
end
L=str2num(get(tool.handles.Tools.L,'String'));
if isempty(L)
    L=Lold;
    set(tool.handles.Tools.L,'String',num2str(L))
end
setWL(tool,W,L)
end
        
function histogramButtonDownFunction(hObject,evnt,tool,line)

WBMF_old = get(tool.handles.fig,'WindowButtonMotionFcn');
WBUF_old = get(tool.handles.fig,'WindowButtonUpFcn');

switch line
    case 1 %Lower limit of range
        fun=@(src,evnt) newLowerRangePosition(src,evnt,tool.handles.HistAxes,tool);
        fun2=@(src,evnt) buttonUpFunction(src,evnt,tool,WBMF_old,WBUF_old);
        set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
    case 2 %Upper limt of range
        fun=@(src,evnt) newUpperRangePosition(src,evnt,tool.handles.HistAxes,tool);
        fun2=@(src,evnt) buttonUpFunction(src,evnt,tool,WBMF_old,WBUF_old);
        set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
    case 3 %Middle line
        fun=@(src,evnt) newLevelRangePosition(src,evnt,tool.handles.HistAxes,tool);
        fun2=@(src,evnt) buttonUpFunction(src,evnt,tool,WBMF_old,WBUF_old);
        set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
end
end

function scrollWheel(scr,evnt,tool)
    newSlice=get(tool.handles.Slider,'value')-evnt.VerticalScrollCount;
    if newSlice>=1 && newSlice <=size(tool.I,3)
        set(tool.handles.Slider,'value',newSlice);
        showSlice(tool);
    end
end

function multipleScrollWheel(scr,evnt,tools)
for i=1:length(tools)
    scrollWheel(scr,evnt,tools(i))
end
end

function newLowerRangePosition(src,evnt,hObject,tool)
cp = get(hObject,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];
range=get(tool.handles.Axes,'Clim');
Xlims=get(hObject,'Xlim');
r=tool.range;
ord = round(log10(single(r)));
if ord>1
    cp(1)=round(cp(1));
end
range(1)=cp(1);
W=diff(range);
L=mean(range);
if W>0 && range(1)>=Xlims(1)
    setWL(tool,W,L)
end
end

function newUpperRangePosition(src,evnt,hObject,tool)
cp = get(hObject,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];
range=get(tool.handles.Axes,'Clim');
Xlims=get(hObject,'Xlim');
r=tool.range;
ord = round(log10(single(r)));
if ord>1
    cp(1)=round(cp(1));
end
range(2)=cp(1);
W=diff(range);
L=mean(range);
if W>0 && range(2)<=Xlims(2)
    setWL(tool,W,L)
end
end

function newLevelRangePosition(src,evnt,hObject,tool)
cp = get(hObject,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];
range=get(tool.handles.Axes,'Clim');
Xlims=get(hObject,'Xlim');
r=tool.range;
ord = round(log10(single(r)));
if ord>1
    cp(1)=round(cp(1));
end
L=cp(1);
W=diff(range);
if L>=Xlims(1) && L<=Xlims(2)
    setWL(tool,W,L)
end
end

function adjustContrastMouse(src,evnt,bp,hObject,tool,W,L)
cp = get(0,'PointerLocation');
SS=get( 0, 'Screensize' ); SS=SS(end-1:end); %Get the screen size
d=round(cp-bp)./SS;
r=tool.range;
WS=tool.windowSpeed;
W2=W+r*d(1)*WS; L=L-r*d(2)*WS;
if W2>0
    W=W2;
else
    W=.001*W;
end
ord = round(log10(single(r)));
if ord>1
    W=ceil(W);
    L=round(L);
end

setWL(tool,W,L)
end

function adjustZoomMouse(src,evnt,bp,hObject,tool,xlims,ylims,bpA)

%get the zoom factor
cp = get(0,'PointerLocation');
d=cp(2)-bp(2);  %
zfactor = 1; %zoom percentage per change in screen pixels
resize = 100 + d*zfactor;   %zoom percentage

%get the old center point
cold = [xlims(1)+diff(xlims)/2 ylims(1)+diff(ylims)/2];

%get the direction vector from old center to the clicked point
dir = cold-bpA;
pfactor = 100; %zoom percentage at which clicked point becomes the new center

%rescale the dir vector according to ratio between resize and pfactor
dir = (dir*((resize-100)/pfactor));

%get the new center
cx = cold(1) + dir(1);
cy = cold(2) + dir(2);

%get the new width
newXwidth = diff(xlims)* (resize/100);
newYwidth = diff(ylims)* (resize/100);

%set the new axis limits
xlims = [cx-newXwidth/2 cx+newXwidth/2];
ylims = [cy-newYwidth/2 cy+newYwidth/2];
if resize > 0
    set(hObject,'Xlim',xlims,'Ylim',ylims)
end

end

function adjustPanMouse(src,evnt,bp,hObject,xlims,ylims,scale)
cp = get(0,'PointerLocation');
d=scale*(bp-cp);
set(hObject,'Xlim',xlims+d(1),'Ylim',ylims-d(2))
end

function buttonUpFunction(src,evnt,tool,WBMF_old,WBUF_old)

setptr(tool.handles.fig,'arrow');
set(src,'WindowButtonMotionFcn',WBMF_old,'WindowButtonUpFcn',WBUF_old);

end

function getImageInfo(src,evnt,tool)
pos=round(get(tool.handles.Axes,'CurrentPoint'));
pos=pos(1,1:2);
Xlim=get(tool.handles.Axes,'Xlim');
Ylim=get(tool.handles.Axes,'Ylim');
n=round(get(tool.handles.Slider,'value'));
if n==0
    n=1;
end

if pos(1)>0 && pos(1)<=size(tool.I,2) && pos(1)>=Xlim(1) && pos(1) <=Xlim(2) && pos(2)>0 && pos(2)<=size(tool.I,1) && pos(2)>=Ylim(1) && pos(2) <=Ylim(2)
    set(tool.handles.Info,'String',['(' num2str(pos(1)) ',' num2str(pos(2)) ') ' num2str(tool.I(pos(2),pos(1),n)) ',' num2str(tool.mask(pos(2),pos(1),n))])
else
    set(tool.handles.Info,'String','(x,y) val valmsk')
end



end

function panelResizeFunction(hObject,events,tool,w,h,wbutt)
units=get(tool.handles.Panels.Large,'Units');
set(tool.handles.Panels.Large,'Units','Pixels')
pos=get(tool.handles.Panels.Large,'Position');
set(tool.handles.Panels.Large,'Units',units)
if get(tool.handles.Tools.Hist,'value')
    set(tool.handles.Panels.Image,'Position',[w w pos(3)-2*w pos(4)-2*w-h])
else
    set(tool.handles.Panels.Image,'Position',[w w pos(3)-2*w pos(4)-2*w])
end
%set(tool.handles.Panels.Image,'Position',[w w pos(3)-2*w pos(4)-2*w])
set(tool.handles.Panels.Hist,'Position',[w pos(4)-w-h pos(3)-2*w h])
set(tool.handles.Panels.Tools,'Position',[0 pos(4)-w pos(3) w])
set(tool.handles.Panels.ROItools,'Position',[pos(3)-w  w w pos(4)-2*w])
set(tool.handles.Panels.Slider,'Position',[0 w w pos(4)-2*w])
set(tool.handles.Panels.Info,'Position',[0 0 pos(3) w])
axis(tool.handles.Axes,'fill');
buff=(w-wbutt)/2;
pos=get(tool.handles.Panels.ROItools,'Position');
set(tool.handles.Tools.Help,'Position',[buff pos(4)-wbutt-buff wbutt wbutt]);
set(tool.handles.Axes,'XLimMode','manual','YLimMode','manual');

end

function icon = makeToolbarIconFromPNG(filename)
% makeToolbarIconFromPNG  Creates an icon with transparent
%   background from a PNG image.

%   Copyright 2004 The MathWorks, Inc.  
%   $Revision: 1.1.8.1 $  $Date: 2004/08/10 01:50:31 $

  % Read image and alpha channel if there is one.
  [icon,map,alpha] = imread(filename);

  % If there's an alpha channel, the transparent values are 0.  For an RGB
  % image the transparent pixels are [0, 0, 0].  Otherwise the background is
  % cyan for indexed images.
  if (ndims(icon) == 3) % RGB

    idx = 0;
    if ~isempty(alpha)
      mask = alpha == idx;
    else
      mask = icon==idx; 
    end
    
  else % indexed
    
    % Look through the colormap for the background color.
    for i=1:size(map,1)
      if all(map(i,:) == [0 1 1])
        idx = i;
        break;
      end
    end
    
    mask = icon==(idx-1); % Zero based.
    icon = ind2rgb(icon,map);
    
  end
  
  % Apply the mask.
  icon = im2double(icon);
  
  for p = 1:3
    
    tmp = icon(:,:,p);
    if ndims(mask)==3
        tmp(mask(:,:,p))=NaN;
    else
        tmp(mask) = NaN;
    end
    icon(:,:,p) = tmp;
    
  end

end

function saveImage(hObject,evnt,tool)
cmap = colormap;
switch get(tool.handles.Tools.SaveOptions,'value')
    case 1 %Save just the current slice
        I=get(tool.handles.I,'CData'); lims=get(tool.handles.Axes,'CLim');
        I=gray2ind(mat2gray(I,lims),256);
        [FileName,PathName] = uiputfile({'*.png';'*.tif';'*.jpg';'*.bmp';'*.gif';'*.hdf'; ...
            '*.jp2';'*.pbm';'*.pcx';'*.pgm'; ...
            '*.pnm';'*.ppm';'*.ras';'*.xwd'},'Save Image');
        
        if FileName == 0
        else
            imwrite(I,cmap,[PathName FileName])
        end
    case 2
        lims=get(tool.handles.Axes,'CLim');
        [FileName,PathName] = uiputfile({'*.tif'},'Save Image Stack');
        if FileName == 0
        else
            for i=1:size(tool.I,3)
                imwrite(gray2ind(mat2gray(tool.I(:,:,i),lims),256),cmap, [PathName FileName], 'WriteMode', 'append',  'Compression','none');
            end
        end
end
end

function ShowHistogram(hObject,evnt,tool,w,h)
set(tool.handles.Panels.Large,'Units','Pixels')
pos=get(tool.handles.Panels.Large,'Position');
set(tool.handles.Panels.Large,'Units','normalized')

if get(tool.handles.Tools.Hist,'value')
    set(tool.handles.Panels.Image,'Position',[w w pos(3)-2*w pos(4)-2*w-h])
else
    set(tool.handles.Panels.Image,'Position',[w w pos(3)-2*w pos(4)-2*w])
end
axis(tool.handles.Axes,'fill');
showSlice(tool)

end

function fig = getParentFigure(fig)
% if the object is a figure or figure descendent, return the
% figure. Otherwise return [].
while ~isempty(fig) & ~strcmp('figure', get(fig,'type'))
    fig = get(fig,'parent');
end
end

function overAxes = isMouseOverAxes(ha)
%This function checks if the mouse is currently hovering over the axis in
%question. hf is the handle to the figure, ha is the handle to the axes.
%This code allows the axes to be embedded in any size heirarchy of
%uipanels.

point = get(ha,'CurrentPoint');
x = point(1,1); y = point(1,2);
xlims = get(ha,'Xlim');
ylims = get(ha,'Ylim');

overAxes = x>=xlims(1) & x<=xlims(2) & y>=ylims(1) & y<=ylims(2);



end





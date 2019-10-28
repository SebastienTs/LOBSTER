///////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Name:	CellInsight
// Author: 	Sébastien Tosi (IRB/ADMCF)
// Version:	2.27
// Date:	25-10-2019	
//	
// Description: Annotation tool similar to IJ CellCounter but with extended functionalities.
//
// Usage: 	See documentation.
//
// Note:	Requires the macro GetString.ijm to be copied to FIJI "macros" folder.
////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Dashboard parameters: can be adjusted
NPages = 1; // Number of pages in the dashboard
NSubGp = 4; // Number of subgroups (recommended: 3 --> 8)

// "Option" defaults
ViewDepth = 3;
ViewFrame = 2;
MeasBox = 7;
ThumbWidth = 2;
ThumbHeight = 2;
MaxSelDist = 5;
SizeShape = 9;
RefSquare = 25;
OptiSquare = 15;
OptiDepth = 5;
OnlyCM = false;
FlagRender = false;
ThumbShow = true;
autosyncslice = true;
autosyncframe = true;
autoincframe = false;
showcar = false;
NewName = "";
LastTimer = 0;
DoubleClickMaxTime = 300; // milliseconds

showMessage("Select Group + Double Click: Add point\nSelect Group + Shift: Wander points\nSelect Points + Alt: Delete points\nSelect Points + Select Group + Move: Move points to group\nCL: Clear current point selection\nIV: Invert current point selection within selected group\nImport: Import .xls project\nExport: Export .xls project\nDraw: Draw points to stack\nMeasure: Measure point intensity in different channels");

// Information from main image and initialization
if(nImages>1)waitForUser("Selet the image to annotate");
ImageTitle = getTitle();
Fname = replace(ImageTitle, ".tif", ".xls");
if(ImageTitle == "Dashboard")exit("Dashboard cannot be selected as image");
ImageId = getImageID();
ImgDir = getInfo("image.directory");
getVoxelSize(vxw, vxh, vxd, unit);
ZRatio = vxd/vxh;
Stack.getPosition(channel, slice, frame);
Stack.getDimensions(width, height, channels, slices, frames);
if(channels>1)run("Make Composite");
Stack.setPosition(channel, round(slices/2), 1);
resetMinAndMax();
run("Remove Overlay");

// Fixed parameters
MaxGp = 7;		// Number of groups by page
HSubGp = 14;		// Height of subgroups (pix) advised: 14 --> 16 
FontSizeName = 9; 	// SubGp names font size
FontSizeCnt = 11;	// Counters font size

GpHeight = HSubGp*NSubGp;
GpSubHeight = GpHeight/NSubGp;
ColorTableBase = newArray("blue","cyan","green","yellow","orange","red","white");
ColorTableDimBase = newArray("#ff00007f","#ff007f7f","#ff007f00","#ff7f7f00","#ffff7f00","#ff7f0000","#ff7f7f7f");
ButtonsText = newArray("Move","CL IV","Meas","Draw","Import","Export","Option","Exit");
// Mouse and keyboard events
leftButton=16;
rightButton=4;
shift=1;
ctrl=2; 
alt=8;

// Initialize IJ settings and variables
run("Colors...", "foreground=white background=black selection=black");
run("Set Measurements...", "  mean standard min redirect=None decimal=2");
run("Line Width...", "line=1");
setTool("hand");
setForegroundColor(255, 255, 255);
setBackgroundColor(0, 0, 0);
setColor("white");
CurrentSlice = slice;
CurrentFrame = frame;
var PointX = newArray(0);
var PointY = newArray(0);
var PointZ = newArray(0);
var PointF = newArray(0);
var PointS = newArray(0);
var PointSx = newArray(0);
ortho = false;
Ngroups = 0;
OldSelsb = -1;
Selsb = 0;
sgp = 0;
PointCnt = 0;
SelCnt = 0;
slicesturned = 0;
CurrentDashSlice = 0;
SubGpOffset = 0;
PointNewLock = true;
SubGpSwitch = false;
LastX = -1;
LastY = -1;
SubGpName = newArray(MaxGp*NSubGp*NPages);
SubGpShow = newArray(MaxGp*NSubGp*NPages);
SubGpRefPos = newArray(MaxGp*NSubGp*NPages);
for(i=0;i<lengthOf(SubGpShow);i++)
{
	SubGpShow[i] = 1;
	SubGpRefPos[i] = -1;
}
SCnt = newArray(MaxGp*NSubGp*NPages);
buf = newArray(1);

// Initialize Dashboard
if(isOpen("Dashboard"))
{
	selectWindow("Dashboard");
	run("Close");
}
newImage("Dashboard", "8-bit black", GpHeight*(MaxGp+1), GpHeight*(MaxGp+1), NPages);
DashBoardID = getImageID();
TurnedId = 0;
run("Select All");
run("Clear", "slice");
run("Select None");
run("16 colors");
for(k=0;k<NPages;k++)
{
	if(k>0)
	{
		ColorTable = Array.concat(ColorTable,ColorTableBase);
		ColorTableDim = Array.concat(ColorTableDim,ColorTableDimBase);
	}
	else
	{
		ColorTable = ColorTableBase;
		ColorTableDim = ColorTableDimBase;
	}
	Ngroups = 0;
	Stack.setPosition(1,k+1,1);	
	// Create MaxGp squares
	for(i=0;i<MaxGp;i++)
	{
		setColor(32+Ngroups*32);
		drawRect(0, Ngroups*GpHeight, GpHeight*4, GpHeight);			
		Ngroups = Ngroups+1;
	}
	// Create 8 function buttons
	setColor(255);
	for(i=0;i<8;i++)drawRect(GpHeight*i, getHeight()-GpHeight, GpHeight, GpHeight);
	setFont("SansSerif", 11+(NSubGp-3)*3);
	for(i=0;i<8;i++)drawString(ButtonsText[i],GpHeight/6+GpHeight*i,getHeight()-GpHeight/3);
	// Create subgroup show/hide toggles
	for(i=0;i<MaxGp*NSubGp;i++)
	{
		sg = 1+i%NSubGp;			
		makePoly(2+sg, 5,i*GpSubHeight+5, 7, 1);
		run("Draw", "slice");
	} 
	run("Select None");
}
setFont("SansSerif", 11);
setSlice(1);

// Main loop
Stop = false;
sttime = getTime();
while(Stop == false)
{
	// Show status in Fiji bar
	if(Selsb>0)
	{
		cntgp = 0;
		gp = floor((Selsb-1)/NSubGp);
		for(i=NSubGp*gp;i<NSubGp*(gp+1);i++)cntgp += SCnt[i];
		showStatus(d2s(x,0)+" , "+d2s(y,0)+" , "+d2s(z,0)+"    /    "+d2s(cntgp,0)+" point(s) in group "+d2s(gp+1,0)+"    /    "+d2s(SelCnt,0)+" point(s) selected");
	}
	
	// Wait to minimize CPU usage
	wait(20);
	getCursorLoc(x, y, z, flags);

	// Read image sliders position if image active
	if(isActive(ImageId))Stack.getPosition(channel, slice, frame);

	// ortho view mode only
	if(ortho == true)
	{
		// Check if ortho view has been closed
		if(!isOpen(TurnedId))
		{
			ortho = false;
			TurnedId = 0;
		}
		// Read ortho view sliders
		if(isActive(TurnedId))
		{
			Stack.getPosition(channelt, slicet, framet);
			if( ((slicet!=CurrentSlicet) || (framet!=CurrentFramet))  ) // Slider update on turned image
			{
				OverlayRefresh(ImageId, SubGpShow, NSubGp, PointCnt, ViewDepth, ViewFrame, CurrentFrame, SizeShape, CurrentSlice, ortho, ZRatio, slicesturned, SubGpName, showcar);
				CurrentSlicet = slicet;
				CurrentFramet = framet;
			}	
		}
	}
	
	// Read dasboard slider position
	if(isActive(DashBoardID))
	{
		DashSlice = getSliceNumber();
		if(DashSlice != CurrentDashSlice)
		{
			Overlay.remove;
			Selsb = 0;
			OldSelsb = -1;
		}
		CurrentDashSlice = DashSlice;
	}

	// "Alt" key stroke: Delete selection
	if(isKeyDown("alt")&&(isActive(ImageId)||isActive(TurnedId)))
	{
		while(isKeyDown("alt"));
		setTool("hand");
		if(SelCnt>0)
		{
			NewPointX = newArray(lengthOf(PointX)-SelCnt);
			NewPointY = newArray(lengthOf(PointX)-SelCnt);
			NewPointZ = newArray(lengthOf(PointX)-SelCnt);
			NewPointF = newArray(lengthOf(PointX)-SelCnt);
			NewPointS = newArray(lengthOf(PointX)-SelCnt);
			cnt = 0;
			for(i=0;i<PointCnt;i++)
			{
				if(PointSx[i] == 0)
				{
					NewPointX[cnt] = PointX[i];
					NewPointY[cnt] = PointY[i];
					NewPointZ[cnt] = PointZ[i];
					NewPointF[cnt] = PointF[i];
					NewPointS[cnt] = PointS[i];
					cnt++;
				}
				else 
				{
					SCnt[PointS[i]-1] = SCnt[PointS[i]-1]-1;
					if(SCnt[PointS[i]-1] > 0)SubGpRefPos[PointS[i]-1] = SCnt[PointS[i]-1]-1;
					else SubGpRefPos[PointS[i]-1] = -1;
				}
			}
			PointX = NewPointX;
			PointY = NewPointY;
			PointZ = NewPointZ;
			PointF = NewPointF;
			PointS = NewPointS;
			PointSx = newArray(lengthOf(PointX));
			SelCnt = 0;
			PointCnt = cnt;
			OverlayRefresh(ImageId, SubGpShow, NSubGp, PointCnt, ViewDepth, ViewFrame, CurrentFrame, SizeShape, CurrentSlice, ortho, ZRatio, slicesturned, SubGpName, showcar);
			DashboardRefresh(SCnt,Ngroups,NSubGp,GpHeight,GpSubHeight,Selsb);
		}
	}

	// "Space" key stroke: Cycle through points of selected subgroup
	if((isKeyDown("space"))||(isKeyDown("shift"))) // ||SubGpSwitch --> highlight on SubGp switch
	{
		if(Selsb>0)
		{
		if(SubGpShow[Selsb-1] == true)
		{
			selectImage(ImageId);
			cnt = -1;
			Found = 0;
			if(SubGpSwitch == false)
			{
				if(isKeyDown("shift")) SubGpRefPos[Selsb-1] = SubGpRefPos[Selsb-1]-1;
				else SubGpRefPos[Selsb-1] = SubGpRefPos[Selsb-1]+1;
				if(SubGpRefPos[Selsb-1] < 0)SubGpRefPos[Selsb-1] = SCnt[Selsb-1]-1;
				SubGpRefPos[Selsb-1] = SubGpRefPos[Selsb-1]%(SCnt[Selsb-1]);
			}
			for(i=0;i<PointCnt;i++)
			{
				if(PointS[i] == Selsb)cnt++;
				if(cnt == SubGpRefPos[Selsb-1])
				{
					Found = true;
					Foundi = i;
					Stack.getPosition(channel, dummy1, dummy2);
					Stack.setPosition(channel, PointZ[i], PointF[i]);
					slice = PointZ[i];
					frame = PointF[i];
					CurrentSlice = slice;
					CurrentFrame = frame;
					i = PointCnt;
				}
			}
			if(Found == true)
			{
				if(ortho == true)
				{
					selectImage(TurnedId);
					Stack.getPosition(dummy1, dummy2, dummy3);
					Stack.setPosition(dummy1, 1+slicesturned-PointX[Foundi], PointF[Foundi]);
					selectImage(ImageId);
				}
				OverlayRefresh(ImageId, SubGpShow, NSubGp, PointCnt, ViewDepth, ViewFrame, CurrentFrame, SizeShape, CurrentSlice, ortho, ZRatio, slicesturned, SubGpName, showcar);
				selectImage(ImageId);
				setColor(255,255,255);
				Overlay.drawRect(PointX[Foundi]-RefSquare/2,PointY[Foundi]-RefSquare/2,RefSquare ,RefSquare);
				Overlay.show;
				if(ortho == true)
				{
					selectImage(TurnedId);
					Overlay.drawRect(ZRatio*(slice-1)-RefSquare/2,PointY[Foundi]-RefSquare/2,RefSquare,RefSquare);
					Overlay.show;
					selectImage(ImageId);
				}
			}
		}
		}
		SubGpSwitch = false;
	}

	// Dashboard or image selected or turned image selected + left click or image sliders update 
	if( ((flags >= 16) || (slice!=CurrentSlice) || (frame!=CurrentFrame)) && (isActive(DashBoardID) || (isActive(ImageId)) || (isActive(TurnedId)) ) ) // Left click or slider update
	{
		if(isActive(DashBoardID)) // Click on dashboard
		{
			if((x<=GpHeight*4)&&(y<=getWidth()-GpHeight)) // Subgroups panel
			{
			if(flags == leftButton)
			{
				if(x<=16) // Subgroup hide/show
				{
					SubGpShow[floor(y/GpSubHeight)+(getSliceNumber()-1)*NSubGp*MaxGp] = 1-SubGpShow[floor(y/GpSubHeight)+(getSliceNumber()-1)*NSubGp*MaxGp];
					DashboardRefreshNames(SubGpName,SubGpShow,GpHeight,Ngroups,NSubGp,GpSubHeight);
					OverlayRefresh(ImageId, SubGpShow, NSubGp, PointCnt, ViewDepth, ViewFrame, CurrentFrame, SizeShape, CurrentSlice, ortho, ZRatio, slicesturned, SubGpName, showcar);
				}
				else
				{
					NewName = "";
					Selsb = 1+floor(y/GpSubHeight)+(getSliceNumber()-1)*NSubGp*MaxGp;
					lg = lengthOf(SubGpName[Selsb-1]);	
					if( ((OldSelsb == Selsb) ||  (lg == 1) ) && (x>16) )
					{
						if(lengthOf(SubGpName[Selsb-1])==1)DefaultName = "Subgroup"+d2s(Selsb,0);
						else DefaultName = SubGpName[Selsb-1];
						NewName = runMacro("GetString", DefaultName);
						if(NewName != "[aborted]")
						{
							if(lengthOf(NewName)<2)NewName = NewName+"_";
							SubGpName[Selsb-1] = NewName;
						}
						else Selsb = OldSelsb;	
					}
					if(NewName != "[aborted]")
					{
						if(SCnt[Selsb-1]>0)SubGpSwitch = true;
						OldSelsb = Selsb;
					}
				}
				if(NewName != "[aborted]")
				{
					OverlayRefresh(ImageId, SubGpShow, NSubGp, PointCnt, ViewDepth, ViewFrame, CurrentFrame, SizeShape, CurrentSlice, ortho, ZRatio, slicesturned, SubGpName, showcar);
					DashboardRefresh(SCnt,Ngroups,NSubGp,GpHeight,GpSubHeight,Selsb);
					DashboardRefreshNames(SubGpName,SubGpShow,GpHeight,Ngroups,NSubGp,GpSubHeight);
				}
				NewName = "";	
			}
			}
			if( (y>(getHeight()-GpHeight)) && (x<GpHeight) ) // Button panel: Move selection
			{		
				if((SelCnt>0)&&(Selsb>0))
				{
					for(i=0;i<PointCnt;i++)
					{
						if(PointSx[i] == 1)
						{
							SCnt[Selsb-1] = SCnt[Selsb-1]+1;
							SCnt[PointS[i]-1] = SCnt[PointS[i]-1]-1;
							if(SCnt[PointS[i]-1] > 0)SubGpRefPos[PointS[i]-1] = SCnt[PointS[i]-1]-1;
							else SubGpRefPos[PointS[i]-1] = -1;
							PointS[i] = Selsb;
							PointSx[i] = 0;
						}
					}
					SelCnt = 0;
					SubGpRefPos[Selsb-1] = 0;
					OverlayRefresh(ImageId, SubGpShow, NSubGp, PointCnt, ViewDepth, ViewFrame, CurrentFrame, SizeShape, CurrentSlice, ortho, ZRatio, slicesturned, SubGpName, showcar);
					DashboardRefresh(SCnt,Ngroups,NSubGp,GpHeight,GpSubHeight,Selsb);
					selectImage("Dashboard");
				}
			}
			if( (y>(getHeight()-GpHeight)) && (x>GpHeight) && (x<(getWidth()-6*GpHeight)) ) // Button panel: Invert selection
			{
				if(Selsb>0)
				{
					if(x > GpHeight*1.5)
					{
					for(i=0;i<PointCnt;i++)
					{
						if(PointS[i] == Selsb)
						{
							if(PointSx[i] == 1)
							{
								PointSx[i] = 0;
								SelCnt = SelCnt-1;
							}
							else
							{
								PointSx[i] = 1;
								SelCnt = SelCnt+1;
							}
						}
					}
					}
					else 
					{
						for(i=0;i<PointCnt;i++)PointSx[i] = 0;
						SelCnt = 0;
					}
					OverlayRefresh(ImageId, SubGpShow, NSubGp, PointCnt, ViewDepth, ViewFrame, CurrentFrame, SizeShape, CurrentSlice, ortho, ZRatio, slicesturned, SubGpName, showcar);
					DashboardRefresh(SCnt,Ngroups,NSubGp,GpHeight,GpSubHeight,Selsb);
				}
			}
			if( (y>(getHeight()-GpHeight)) && (x>2*GpHeight) && (x<(getWidth()-5*GpHeight)) ) // Button panel: Measure intensity
			{
				run("Clear Results");
				SCnt2 = newArray(MaxGp*NSubGp*NPages);
				selectImage(ImageId);
				Stack.getPosition(channel, slice, frame);
				for(i=0;i<PointCnt;i++)
				{
					for(j=0;j<channels;j++)
					{
						Stack.setPosition(j+1, PointZ[i], PointF[i]);
						makeRectangle(PointX[i]-floor(MeasBox/2),PointY[i]-floor(MeasBox/2),MeasBox,MeasBox);
						selectImage(ImageId);
						run("Measure");
						setResult("Group", nResults-1, 1+floor(PointS[i]/NSubGp));
						setResult("Subgroup", nResults-1, PointS[i]);
						setResult("SubgroupIndex", nResults-1, SCnt2[PointS[i]-1]);
						setResult("Channel", nResults-1, j+1);
						setResult("Frame", nResults-1, PointF[i]);
						setResult("Label", nResults-1, SubGpName[PointS[i]-1]);
					}
					SCnt2[PointS[i]-1] = SCnt2[PointS[i]-1]+1;
				}
				updateResults();
				selectImage(ImageId);
				Stack.setPosition(channel, slice, frame);
				run("Select None");
				selectImage("Dashboard");
				makeRectangle(GpHeight*4+29, 0, getWidth()-(GpHeight*4+29), getHeight()-GpHeight);
				run("Set...", "value=0 stack");
				run("Select None");
				if(ThumbShow == true)
				{
				cslice = getSliceNumber();
				for(i=0;i<NPages;i++)
				{
					setSlice(i+1);
					for(j=0;j<MaxGp*NSubGp;j++)
					{
						setColor(32+32*floor((j%(MaxGp*NSubGp))/NSubGp));
						drawRect(GpHeight*4+29, GpSubHeight*j, getWidth()-(GpHeight*4+30), GpSubHeight);
					}
				}
				setSlice(cslice);
				for(i=0;i<nResults;i++)
				{
					Subgpi = (getResult("Subgroup",i)-1);
					Subgpimod = Subgpi%(MaxGp*NSubGp);
					SubGpindx = getResult("SubgroupIndex",i);
					chani = (getResult("Channel",i)-1);
					meani = round(getResult("Mean",i));
					if(SubGpShow[Subgpi] == 1)
					{
						setZCoordinate(floor(Subgpi/(MaxGp*NSubGp)));
						for(k=0;k<ThumbWidth;k++)
						{
							for(l=0;l<ThumbHeight;l++)
							{
								setPixel(GpHeight*4+30+SubGpindx*ThumbWidth+k,1+Subgpimod*GpSubHeight+chani*ThumbHeight+l,meani);
							}
						}
					}
				}
				updateDisplay();
				}
				selectWindow("Results");
				IJ.renameResults(replace("meas_"+ImageTitle, ".tif", ".xls"));
				selectImage(ImageId);
			}
			if( (y>(getHeight()-GpHeight)) && (x>3*GpHeight) && (x<(getWidth()-4*GpHeight)) ) // Button panel: Draw map
			{
				if(isOpen("Map"))
				{
					selectImage("Map");
					close();
				}
				selectImage(ImageId);
				newImage("Map3", "8-bit black", getWidth(), getHeight(), slices*frames);
				run("Stack to Hyperstack...", "order=xyczt(default) channels=1 slices="+d2s(slices,0)+" frames="+d2s(frames,0)+" display=Color");
				selectImage("Map3");
				run("16 colors");
				Size = 16;
				if(OnlyCM == true)
				{
					// CM computation ignores frame membership
					PointCntDraw = 0;
					SInd = newArray(NSubGp*Ngroups*NPages);
					PointSCnt = newArray(NSubGp*Ngroups*NPages);
					PointSDraw = newArray(NSubGp*Ngroups*NPages);
					for(i=0;i<NSubGp*Ngroups*NPages;i++)
					{
						if(SCnt[i]>0)
						{
							SInd[i] = PointCntDraw;
							PointSDraw[PointCntDraw] = i+1;
							PointSCnt[PointCntDraw] = SCnt[i];
							PointCntDraw++;
						}
					}				
					PointFDraw = newArray(PointCntDraw);
					PointXDraw = newArray(PointCntDraw);
					PointYDraw = newArray(PointCntDraw);
					PointZDraw = newArray(PointCntDraw);
					for(i=0;i<PointCnt;i++)
					{
						PointXDraw[SInd[PointS[i]-1]] = PointXDraw[SInd[PointS[i]-1]] + PointX[i];
						PointYDraw[SInd[PointS[i]-1]] = PointYDraw[SInd[PointS[i]-1]] + PointY[i];
						PointZDraw[SInd[PointS[i]-1]] = PointZDraw[SInd[PointS[i]-1]] + PointZ[i];
					}
					for(i=0;i<PointCntDraw;i++)
					{
						PointXDraw[i] = round(PointXDraw[i]/PointSCnt[i]);
						PointYDraw[i] = round(PointYDraw[i]/PointSCnt[i]);
						PointZDraw[i] = round(PointZDraw[i]/PointSCnt[i]);
						PointFDraw[i] = 1;
					}
				}
				else
				{
					PointSDraw = PointS;
					PointFDraw = PointF;
					PointXDraw = PointX;
					PointYDraw = PointY;
					PointZDraw = PointZ;
					PointCntDraw = PointCnt;
				}
				for(i=0;i<PointCntDraw;i++)
				{
					if(SubGpShow[PointSDraw[i]-1] == 1)
					{
						Stack.setPosition(0, PointZDraw[i], PointFDraw[i]);
						sg = 1+(PointSDraw[i]-1)%NSubGp;
						makePoly(2+sg, PointXDraw[i], PointYDraw[i], Size, 1);
						run("Set...", "value="+d2s(32+32*floor(((PointSDraw[i]-1)%(MaxGp*NSubGp))/NSubGp),0)+" slice");
					}
				}				
				run("TransformJ Turn", "z-angle=0 y-angle=0 x-angle=90");
				rename("Map2");
				run("16 colors");
				selectImage("Map3");
				close();
				selectImage("Map2");
				Size = 16;
				for(i=0;i<PointCntDraw;i++)
				{
					if(SubGpShow[PointSDraw[i]-1] == 1)
					{
						Stack.setPosition(0, PointYDraw[i], PointFDraw[i]);
						sg = 1+(PointSDraw[i]-1)%NSubGp;
						makePoly(2+sg, PointXDraw[i], slices-PointZDraw[i], Size, 1/ZRatio);
						run("Set...", "value="+d2s(32+32*floor(((PointSDraw[i]-1)%(MaxGp*NSubGp))/NSubGp),0)+" slice");
					}
				}
				run("TransformJ Turn", "z-angle=0 y-angle=0 x-angle=270");
				rename("Map");
				selectImage("Map2");
				close();
				selectImage("Map");
				run("Select None");
				setVoxelSize(vxw, vxh, vxd, unit);
				run("16 colors");
				if(FlagRender == true)
				{
					run("3D Viewer");
					call("ij3d.ImageJ3DViewer.setCoordinateSystem", "false");
					call("ij3d.ImageJ3DViewer.add", "Map", "None", "Map", "0", "true", "true", "true", "1", "0");
				}
				selectImage("Dashboard");
			}
			if( (y>(getHeight()-GpHeight)) && (x>4*GpHeight) && (x<(getWidth()-3*GpHeight)) ) // Button panel: Import project
			{
				if(File.exists(ImgDir+Fname))open(ImgDir+Fname);
				else open();	
				SelCnt = 0;
				PointCnt = nResults;
				PointX = newArray(nResults);
				PointY = newArray(nResults);
				PointZ = newArray(nResults);
				PointF = newArray(nResults);
				PointS = newArray(nResults);
				PointSx = newArray(nResults);
				SCnt = newArray(MaxGp*NSubGp*NPages);
				Overflow = false;
				SubGpName = newArray(MaxGp*NSubGp*NPages);
				SubGpShow = newArray(MaxGp*NSubGp*NPages);
				SubGpRefPos = newArray(MaxGp*NSubGp*NPages);
				for(i=0;i<lengthOf(SubGpShow);i++)
				{
					SubGpShow[i] = 1;
					SubGpRefPos[i] = -1;
				}
				for(i=0;i<nResults;i++)
				{
					Sread = getResult("PointS",i);
					if(Sread <= MaxGp*NSubGp*NPages)
					{
						PointX[i] = getResult("PointX",i);
						PointY[i] = getResult("PointY",i);
						PointZ[i] = getResult("PointZ",i);
						PointF[i] = getResult("PointF",i);
						PointS[i] = Sread;
						SCnt[PointS[i]-1] = SCnt[PointS[i]-1]+1;
						SubGpName[PointS[i]-1] = getResultLabel(i);
						SubGpShow[PointS[i]-1] = true;
						SubGpRefPos[PointS[i]-1] = 0;
					}
					else Overflow = true;
				}
				if(Overflow == true)waitForUser("The project imported had more multi-pages\nthan currently configured.\nIt is recommended to restart the macro\nwith the correct number of multi-pages.");
				OverlayRefresh(ImageId, SubGpShow, NSubGp, PointCnt, ViewDepth, ViewFrame, CurrentFrame, SizeShape, CurrentSlice, ortho, ZRatio, slicesturned, SubGpName, showcar);
				selectImage("Dashboard");
				for(k=0;k<NPages;k++)
				{
					setSlice(k+1);
					DashboardRefresh(SCnt,Ngroups,NSubGp,GpHeight,GpSubHeight,Selsb);
					DashboardRefreshNames(SubGpName,SubGpShow,GpHeight,Ngroups,NSubGp,GpSubHeight);
				}
				if(isOpen("Results"))
				{
					selectWindow("Results");
					run("Close");	
				}
				selectImage("Dashboard");
			}
			if( (y>(getHeight()-GpHeight)) && (x>5*GpHeight) && (x<(getWidth()-2*GpHeight)) ) // Button panel: Export project
			{
				if(PointCnt>0)
				{
				Array.show("Results", PointS, PointX, PointY, PointZ, PointF);
				for(i=0;i<PointCnt;i++)setResult("Label", i, SubGpName[PointS[i]-1]);
				updateResults();
				if(File.exists(ImgDir+Fname))File.copy(ImgDir+Fname, ImgDir+Fname+".bck");
				saveAs("Results", ImgDir+Fname);
				if(isOpen("Results"))
				{
					selectWindow("Results");
					run("Close");
				}
				selectImage("Dashboard");
				}
				else waitForUser("No point recorded, project not exported");
			}
			if( (y>(getHeight()-GpHeight)) && (x>6*GpHeight) && (x<(getWidth()-GpHeight)) ) // Button panel: Options
			{
				Dialog.create("Options");
				Dialog.addNumber("Depth of view", ViewDepth);
				Dialog.addNumber("Frame span", ViewFrame);
				Dialog.addNumber("Measurement box size", MeasBox);
				Dialog.addNumber("Measurement thumbnails width", ThumbWidth);
				Dialog.addNumber("Measurement thumbnails height", ThumbHeight);
				Dialog.addNumber("Selection maximum distance", MaxSelDist);
				Dialog.addNumber("Marker size", SizeShape);
				Dialog.addNumber("Reference box size", RefSquare);
				Dialog.addNumber("Intensity optimization box size", OptiSquare);
				Dialog.addNumber("Intensity optimization max. depth", OptiDepth);
				Dialog.addCheckbox("Only draw centroids of subgroups", OnlyCM);
				Dialog.addCheckbox("3D render", FlagRender);
				Dialog.addCheckbox("Show thumbnails", ThumbShow);
				Dialog.addCheckbox("Orthogonal view", ortho);
				Dialog.addCheckbox("Increment frame on new point", autoincframe);
				Dialog.addCheckbox("Synchronize frame", autosyncframe);
				Dialog.addCheckbox("Synchronize slice", autosyncslice);
				Dialog.addCheckbox("Show labels", showcar);
				Dialog.addCheckbox("Sort subgroups z-order", false);
				Dialog.addCheckbox("Sort subgroups t-order", false);
				Dialog.addString("Project import/export Name", Fname);
				Dialog.show();
				ViewDepth = Dialog.getNumber();
				ViewFrame = Dialog.getNumber();
				MeasBox = Dialog.getNumber();
				ThumbWidth = Dialog.getNumber();
				ThumbHeight = Dialog.getNumber();
				MaxSelDist = Dialog.getNumber();
				SizeShape = Dialog.getNumber();
				RefSquare = Dialog.getNumber();
				OptiSquare = Dialog.getNumber();
				OptiDepth = Dialog.getNumber();
				OnlyCM = Dialog.getCheckbox();
				FlagRender = Dialog.getCheckbox();
				ThumbShow = Dialog.getCheckbox();
				ortho = Dialog.getCheckbox();
				autoincframe = Dialog.getCheckbox();
				autosyncframe = Dialog.getCheckbox();
				autosyncslice = Dialog.getCheckbox();
				showcar = Dialog.getCheckbox();
				sortz = Dialog.getCheckbox();
				sortt = Dialog.getCheckbox();
				Fname = Dialog.getString();
				ThumbWidth = maxOf(1,ThumbWidth);
				ThumbHeight = maxOf(1,ThumbHeight);
				if((ortho == false)&&(isOpen(TurnedId)))
				{
					selectImage(TurnedId);
					close();
				}
				if((ortho == true)&&(!isOpen(TurnedId)))
				{
					selectImage(ImageId);
					waitForUser("You can open the turned view now\nor it will be computed");
					if(getImageID() == ImageId)
					{
						run("TransformJ Turn", "z-angle=0 y-angle=90 x-angle=0");
						TmpID = getImageID();
						run("Scale...", "x="+d2s(vxd/vxh,2)+" y=1.0 z=1.0 interpolation=Bilinear process create title=Turned");
						TurnedId = getImageID();
						selectImage(TmpID);
						close();	
					}
					else TurnedId = getImageID();
					selectImage(TurnedId);
					Stack.getDimensions(widthturned, heightturned, channelsturned, slicesturned, framesturned);
					Stack.getPosition(dummy1, CurrentSlicet, dummy1);
					slicet = CurrentSlicet;
					Stack.setPosition(dummy1, round(slicesturned/2), CurrentFrame);
					CurrentFramet = CurrentFrame;
					framet = CurrentFrame; 
					CurrentSlicet = round(slicesturned/2);
					selectImage(ImageId);
					getLocationAndSize(xwin1, ywin1, widthwin1, heightwin1);
					getLocationAndSize(xwin2, ywin2, widthwin2, heightwin2);
					selectImage(TurnedId);
					setLocation(xwin1+widthwin1, ywin1, widthwin2, heightwin2);
					run("View 100%");	
					selectImage(ImageId);
					run("View 100%");
				}
				if(sortz == true)
				{
					SortSubgp(0);
					sortz = false;
				}
				if(sortt == true)
				{
					SortSubgp(1);
					sortt = false;
				}
				OverlayRefresh(ImageId, SubGpShow, NSubGp, PointCnt, ViewDepth, ViewFrame, CurrentFrame, SizeShape, CurrentSlice, ortho, ZRatio, slicesturned, SubGpName, showcar);
				selectImage("Dashboard");
			}
			if( (y>(getHeight()-GpHeight)) && (x>7*GpHeight) ) // Button panel: Exit macro
			{
				Stop = 1;
			}	
		}
		else if(isActive(ImageId) || isActive(TurnedId) ) // Click on image or image sliders
		{
			if(flags>=16) // Click on image
			{
				
					// Read position
					if(isActive(ImageId))
					{
						framep = frame;
						zp = slice;
					}
					else
					{
						framep = framet;
						zp = 1+round(x/ZRatio);
						x = slicesturned-slicet;
					}
					NewPoint = 1;

					// Only select if distance lower than MaxSelDist and subgroup is shown
					for(i=0;i<PointCnt;i++)
					{
						if(SubGpShow[PointS[i]-1])
						{
						if((abs(zp-PointZ[i])<=ViewDepth)&&(CurrentFrame == PointF[i]))
						{
							Dist = sqrt(pow(x-PointX[i],2)+pow(y-PointY[i],2));
							if(Dist<MaxSelDist)
							{
								NewPoint = 0;
								Indx = i;
								i = PointCnt;
							}
						}
						}	
					}
					
					if(NewPoint == 0) // Closeby point: select
					{
						if(PointSx[Indx] == 0)
						{
							PointSx[Indx] = 1;
							SelCnt = SelCnt+1;
						}
						else
						{
							PointSx[Indx] = 0;
							SelCnt = SelCnt-1;
						}
						OverlayRefresh(ImageId, SubGpShow, NSubGp, PointCnt, ViewDepth, ViewFrame, CurrentFrame, SizeShape, CurrentSlice, ortho, ZRatio, slicesturned, SubGpName, showcar);
					}
					else // Unlock new point / new point
					{	
						if(Selsb>0) 
						{			
						if(SubGpShow[Selsb-1] == true)
						{
						if((PointNewLock == false)&&(LastX == x)&&(LastY == y)&&((getTime()-LastTimer)<DoubleClickMaxTime))
						{						
							buf[0] = x;PointX = Array.concat(PointX,buf);
							buf[0] = y;PointY = Array.concat(PointY,buf);
							buf[0] = zp;PointZ = Array.concat(PointZ,buf);				
							buf[0] = framep;PointF = Array.concat(PointF,buf);
							buf[0] = Selsb;PointS = Array.concat(PointS,buf);
							buf[0] = 0;PointSx = Array.concat(PointSx,buf);
							PointCnt++;
							SCnt[Selsb-1] = SCnt[Selsb-1]+1;
							SubGpRefPos[Selsb-1] = SCnt[Selsb-1]-1;
							PointNewLock == true;
							LastX = -1;
							LastY = -1;
							// Auto increment frame on new point (tracking mode)
							if(autoincframe == true)
							{
								Stack.getPosition(dummy1, dummy2, dummy3);
								Stack.setPosition(dummy1, dummy2, minOf(dummy3+1,frames));
								if(isActive(ImageId))CurrentFrame = minOf(dummy3+1,frames);
								if(isActive(TurnedId))CurrentFramet = minOf(dummy3+1,frames);
							}
							DashboardRefresh(SCnt,Ngroups,NSubGp,GpHeight,GpSubHeight,Selsb);
						}
						else 
						{
							LastX = x;
							LastY = y;
							LastTimer = getTime();
							PointNewLock = false;
							if(((flags & ctrl)>0)&&(isActive(ImageId)))
							{
								slt = Optimize(x,y,zp,OptiSquare,OptiDepth);
								Stack.getPosition(dummy1, dummy2, dummy3);
								Stack.setPosition(dummy1, slt, dummy3);
							}
						}
						
						// Synchronize orthoview and main image slices
						if((autosyncslice == true)&&(ortho == true))
						{
							if(isActive(ImageId))
							{
								selectImage(TurnedId);
								Stack.getPosition(dummy1, dummy2, dummy3);
								Stack.setPosition(dummy1, 1+slicesturned-x, dummy3);
								selectImage(ImageId);
							}
							else
							{
								selectImage(ImageId);
								Stack.getPosition(dummy1, dummy2, dummy3);
								Stack.setPosition(dummy1, zp, dummy3);
								selectImage(TurnedId);
							}
						}
						// Synchronize orthoview and main image frames
						if((autosyncframe)&&(ortho == true))
						{
							if(CurrentFramet != CurrentFrame)
							{
								if(isActive(ImageId))
								{
									selectImage(TurnedId);
									Stack.getPosition(dummy1, dummy2, dummy3);
									Stack.setPosition(dummy1, dummy2, CurrentFrame);
									CurrentFramet = CurrentFrame;
									selectImage(ImageId);
								}
								if(isActive(TurnedId))
								{
									selectImage(ImageId);
									Stack.getPosition(dummy1, dummy2, dummy3);
									Stack.setPosition(dummy1, dummy2, CurrentFramet);
									CurrentFrame = CurrentFramet;
									selectImage(TurnedId);
								}
							}
						}
						}
						}
						else waitForUser("No subgroup selected!");
						
						// Refresh overlay
						OverlayRefresh(ImageId, SubGpShow, NSubGp, PointCnt, ViewDepth, ViewFrame, CurrentFrame, SizeShape, CurrentSlice, ortho, ZRatio, slicesturned, SubGpName, showcar);
				}	
			}
			else // Sliders moves
			{
				Stack.getPosition(channel, slice, frame);
				CurrentSlice = slice;
				CurrentFrame = frame;		
				OverlayRefresh(ImageId, SubGpShow, NSubGp, PointCnt, ViewDepth, ViewFrame, CurrentFrame, SizeShape, CurrentSlice, ortho, ZRatio, slicesturned, SubGpName, showcar);
			}
		}
	}

	// wait for left mouse button release
	while((flags&16) > 0)getCursorLoc(x, y, z, flags);	
}

// Exit
run("Colors...", "foreground=white background=black selection=yellow");
selectImage(ImageId);
run("Remove Overlay");
selectImage("Dashboard");
close();
if(isOpen(TurnedId))
{
	selectImage(TurnedId);
	close();
}
exit;

// Functions

function OverlayRefresh(ImageId, SubGpShow, NSubGp, PointCnt, ViewDepth, ViewFrame, CurrentFrame, SizeShape, CurrentSlice, ortho, ZRatio, slicesturned, SubGpName, showcar)
{
	CurrentID = getImageID();
	selectImage(ImageId);
	Overlay.remove;
	Stack.getPosition(channel, slice, frame);
	setColor("white");
	setFont("SansSerif", 11);
	for(i=0;i<PointCnt;i++)
	{
		Dist = abs(PointZ[i] - slice);
		if((Dist <= ViewDepth)&&(abs(frame - PointF[i])<ViewFrame))
		{
			sg = 1+(PointS[i]-1)%NSubGp;
			sgp = PointS[i]-1;
			if(SubGpShow[sgp] == 1)
			{
				if(frame == PointF[i])col = ColorTable[floor(sgp/NSubGp)];
				else col = ColorTableDim[floor(sgp/NSubGp)]; 
				Size = maxOf(SizeShape-Dist*(round(SizeShape/4)),2);
				makePoly(2+sg, PointX[i], PointY[i], Size, 1);		
				if(PointSx[i] == 1)Overlay.addSelection("", 0, col);
				else Overlay.addSelection(col);
				if(showcar == true)
				{
					Name = SubGpName[sgp];
					Overlay.drawString(substring(Name,0,2), PointX[i]-7, PointY[i]+7);
				}
			}
		}	
	}
	run("Select None");
	Overlay.show;
	if(ortho == true)
	{
		selectImage(TurnedId);
		Stack.getPosition(channelt, slicet, framet);
		Overlay.remove;
		makeLine(round(ZRatio*(slice-1)),0,round(ZRatio*(slice-1)),getHeight());
		Overlay.addSelection("yellow");
		for(i=0;i<PointCnt;i++)
		{
			Dist = abs(PointX[i] - slicesturned + slicet)/ZRatio;
			if((Dist <= ViewDepth)&&(abs(framet - PointF[i])<ViewFrame))
			{
				sg = 1+(PointS[i]-1)%NSubGp;
				sgp = PointS[i]-1;
				if(SubGpShow[PointS[i]-1] == 1)
				{
					if(framet == PointF[i])col = ColorTable[floor(sgp/NSubGp)];
					else col = ColorTableDim[floor(sgp/NSubGp)]; 
					Size = maxOf(SizeShape-Dist*(round(SizeShape/4)),2);
					makePoly(2+sg, round((PointZ[i]-1)*ZRatio), PointY[i], Size, 1);
					if(PointSx[i] == 1)Overlay.addSelection("", 0, col);
					else Overlay.addSelection(col);
					if(showcar == true)
					{
						Name = SubGpName[sgp];
						Overlay.drawString(substring(Name,0,2), round(PointZ[i]*ZRatio)-7, PointY[i]+7);
					}
				}
			}	
		}
		run("Select None");
		Overlay.show;
		selectImage(ImageId);
	}
	if(ortho == true)
	{
		makeLine(slicesturned-slicet,0,slicesturned-slicet,getHeight());
		Overlay.addSelection("yellow");
		run("Select None");
		Overlay.show;
	}
	selectImage(CurrentID);
}
function DashboardRefresh(SCnt,Ngroups,NSubGp,GpHeight,GpSubHeight,Selsb)
{
	CurrentID = getImageID();
	selectImage("Dashboard");
	SubGpOffset = (getSliceNumber()-1)*MaxGp*NSubGp;
	makeRectangle(GpHeight*4, 0, 24, getHeight()-GpHeight);
	run("Set...", "value=0 slice");
	setColor(255);
	setFont("SansSerif", FontSizeCnt);
	for(j=0;j<Ngroups*NSubGp;j++)drawString(IJ.pad(SCnt[j+SubGpOffset],4), GpHeight*4+2, (j+1)*GpSubHeight);
	Overlay.remove;
	setColor(255);
	makeRectangle(17, 1+((Selsb-1)%(MaxGp*NSubGp))*GpSubHeight, GpHeight*4-18, GpSubHeight-2);
	Overlay.addSelection("white");
	run("Select None");
	Overlay.show;
	selectImage(CurrentID);
}
function DashboardRefreshNames(SubGpName,SubGpShow,GpHeight,Ngroups,NSubGp,GpSubHeight)
{
	CurrentID = getImageID();
	selectImage("Dashboard");
	SubGpOffset = (getSliceNumber()-1)*MaxGp*NSubGp;
	setFont("SansSerif", FontSizeName);
	for(j=0;j<Ngroups*NSubGp;j++)
	{
		if(lengthOf(SubGpName[j+SubGpOffset])>1)
		{
			makeRectangle(18, j*GpSubHeight+2, GpHeight*4-20, GpSubHeight-4);
			run("Set...", "value=0 slice");
			run("Select None");
			if(SubGpShow[j+SubGpOffset]==1)setColor(255);
			else setColor(127);
			drawString(SubGpName[j+SubGpOffset], 20, (j+1)*GpSubHeight-2);
		}
	}
	selectImage(CurrentID);
}
function SortSubgp(mode)
{	
	if(mode == 0)ranks = Array.rankPositions(PointZ);
	if(mode == 1)ranks = Array.rankPositions(PointF);
	PointXbuf = Array.copy(PointX);
	PointYbuf = Array.copy(PointY);
	PointZbuf = Array.copy(PointZ);
	PointFbuf = Array.copy(PointF);
	PointSbuf = Array.copy(PointS);
	PointSxbuf = Array.copy(PointSx);
	for(i=0;i<lengthOf(PointX);i++)
	{
		PointX[i] = PointXbuf[ranks[i]];
		PointY[i] = PointYbuf[ranks[i]];
		PointZ[i] = PointZbuf[ranks[i]];
		PointF[i] = PointFbuf[ranks[i]];
		PointS[i] = PointSbuf[ranks[i]];
		PointSx[i] = PointSxbuf[ranks[i]];
	}
}
function makePoly(n, cx, cy, size, xyratio) 
{
    n2 = 3+(n-3)%4;
    if(n<7)p = 0;
    else p = PI/n2;
    
    center = size/2;
    r = size/2;
    twoPi = 2*PI;
    inc = twoPi/n2;
    xp = newArray(n2);
    yp = newArray(n2);
    for (i=0; i<n2; i++) 
    {
    	xp[i] = round(r*sin(p+inc*i)) + cx; 
        yp[i] = round((r*cos(p+inc*i))*xyratio) + cy;
    }
    makeSelection("polygon",xp,yp);
}
function Optimize(PosX,PosY,PosZ,optiSquare,optiDepth)
{
	Stack.getDimensions(wd, hg, ch, sl, fr);
	Stack.getPosition(cch, csl, cfr);
	medSquare = optiSquare/2;
	maxval = -1;
	maxind = -1;
	ofs = (cch-1)+(cfr-1)*ch*sl;
	for(k=maxOf(PosZ-optiDepth,0);k<minOf(PosZ+optiDepth,sl-1);k++)
	{
		setZCoordinate(k*ch+ofs);	
		sumval = 0;
		for(i=maxOf(PosX-medSquare,0);i<minOf(PosX+medSquare,wd-1);i++)
		{
			for(j=maxOf(PosY-medSquare,0);j<minOf(PosY+medSquare,hg-1);j++)
			{
				sumval += getPixel(i,j);
			}
		}
		if(sumval>maxval)
		{
			maxval = sumval;
			maxind = k;
		}	
	}
	return maxind+1;
}
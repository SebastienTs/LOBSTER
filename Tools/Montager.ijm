/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Name:	Montager
// Author: 	Sébastien Tosi (sebastien.tosi@irbbarcelona.org)
// Date:	24-01-2017
// Version:	1.0
//	
// Description: Montage localized objects identified by LOBSTER (see LOBSTER documentation for details).
//
// Usage:	Open image stack, load associated IRMA results ('Objs' or 'Spts'), "Run".
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Dialog box (parameters)
Dialog.create("Montager");
Dialog.addNumber("Box XY crop size (pix, odd)", 15);
Dialog.addNumber("Box Z crop depth (slice, odd)", 9);
Dialog.addNumber("Montage max number of column", 50);
Dialog.addNumber("First row to load from results", 1);
Dialog.addNumber("Last row to load (-1: all)", -1);
Dialog.show();
CropWidth = Dialog.getNumber();
CropZ = Dialog.getNumber();
MaxNCol = Dialog.getNumber();
StartAt = Dialog.getNumber();
EndAt = Dialog.getNumber();

// Initialization
ImageID = getImageID();
run("Select None");
getDimensions(width, height, channels, slices, frames);
if(channels>1)Stack.getActiveChannels(ActiveChans);
DispMin = newArray(channels);
DispMax = newArray(channels);
for(i=0;i<channels;i++)
{
	Stack.setChannel(i+1);
	getMinAndMax(DispMin[i], DispMax[i]);
}
run("Colors...", "foreground=white background=black selection=yellow");
if(!isOpen("Results"))exit("Load some results!");
if(EndAt==-1)EndAt = nResults;

// Build montage
setBatchMode(true);
newImage("Concat", "8-bit black", CropWidth, CropWidth, channels*(EndAt-StartAt+1));
selectImage("Concat");
Stack.setDimensions(channels, (EndAt-StartAt+1), 1);
cnt = 0;
for(i=StartAt;i<=EndAt;i++)
{
	selectImage(ImageID);
	XPos = floor(getResult("BoundingBox_1",i-1)+(getResult("BoundingBox_4",i-1)/2));
	YPos = floor(getResult("BoundingBox_2",i-1)+(getResult("BoundingBox_5",i-1)/2));
	ZPos = floor(getResult("BoundingBox_3",i-1)+(getResult("BoundingBox_6",i-1)/2));
	makeRectangle(XPos-floor(CropWidth/2),YPos-floor(CropWidth/2),CropWidth,CropWidth);
	if(channels>1)run("Duplicate...", "title=Mini duplicate channels=1-"+d2s(channels,0)+" slices="+d2s(ZPos-floor(CropZ/2),0)+"-"+d2s(ZPos+floor(CropZ/2),0));
	else run("Duplicate...", "title=Mini duplicate range="+d2s(ZPos-floor(CropZ/2),0)+"-"+d2s(ZPos+floor(CropZ/2),0));
	MiniID = getImageID();
	run("Z Project...", "projection=[Max Intensity]");
	if((getHeight()<CropWidth)||(getWidth()<(CropWidth)))run("Canvas Size...", "width="+d2s(CropWidth,0)+" height="+d2s(CropWidth,0)+" position=Center zero");
	rename("Proj");
	selectImage("Concat");
	Stack.setSlice(1+i-StartAt);
	for(c=1;c<=channels;c++)
	{
		selectImage("Proj");
		if(channels>1)Stack.setChannel(c);
		run("Copy");
		selectImage("Concat");
		Stack.setChannel(c);
		run("Paste");
	}
	selectImage(MiniID);
	close();
	selectImage("Proj");
	close();
	cnt++;
	if((cnt%100)==0)showProgress(cnt,EndAt-StartAt+1);
}
showProgress(0);
NCol = minOf(MaxNCol,cnt);
NRow = floor(cnt/MaxNCol-0.0001)+1;
selectImage("Concat");
run("Make Montage...", "columns="+d2s(NCol,0)+" rows="+d2s(NRow,0)+" scale=1 increment=1 border=0 font=12");
for(i=0;i<channels;i++)
{
	if(channels>1)Stack.setChannel(i+1);
	setMinAndMax(DispMin[i], DispMax[i]);
}
if(channels>1)Stack.setActiveChannels(ActiveChans);
selectImage("Concat");
close();
selectImage(ImageID);
run("Select None");
for(c=1;c<=channels;c++)
{
	selectImage(ImageID);
	Stack.setChannel(c);
	getLut(reds, greens, blues);
	selectImage("Montage");
	if(channels>1)Stack.setChannel(c);
	setLut(reds, greens, blues);
}
setBatchMode("exit & display");

// Main loop
while(isOpen("Montage"))
{
	getCursorLoc(x, y, z, mod);
	indx = -1;
	
	if(((mod&16)!=0)&&(getTitle=="Montage") )
	{
		indx = StartAt+floor(x/CropWidth)+floor(y/CropWidth)*NCol;
		if(indx>EndAt)
		{
			indx = -1;
			run("Restore Selection");
		}
		if((mod&1)==1)Remove = 1;
		else Remove = 0;
	}	
	while ( (mod&16)!=0 )
	{
		getCursorLoc(x, y, z, mod);
		wait(50);
	}
	if(indx > -1)
	{
		if(Remove == 0)
		{
			run("Select None");
			XPos = floor(getResult("BoundingBox_1",indx-1)+(getResult("BoundingBox_4",indx-1)/2));
			YPos = floor(getResult("BoundingBox_2",indx-1)+(getResult("BoundingBox_5",indx-1)/2));
			ZPos = floor(getResult("BoundingBox_3",indx-1)+(getResult("BoundingBox_6",indx-1)/2));
			ZPos = minOf(maxOf(ZPos,1),slices);
			selectImage(ImageID);
			if(channels > 1)Stack.setSlice(ZPos);
			else setSlice(ZPos);
			makeRectangle(XPos-floor(CropWidth/2),YPos-floor(CropWidth/2),CropWidth,CropWidth);
			run("Set... ", "zoom=400 x="+d2s(XPos,0)+" y="+d2s(YPos,0));
			selectImage("Montage");
			XPos = floor(x/CropWidth)*CropWidth;
			YPos = floor(y/CropWidth)*CropWidth;
			makeRectangle(XPos,YPos,CropWidth,CropWidth);
		}
		else
		{
			XPos = floor(x/CropWidth)*CropWidth;
			YPos = floor(y/CropWidth)*CropWidth;
			makeRectangle(XPos,YPos,CropWidth,CropWidth);
			run("Clear");
			run("Select None");
			setResult("Reject",indx,1);
			updateResults;
		}
	}
	wait(50);
}
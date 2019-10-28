///////////////////////////////////////////////////////////////////////////////////////////////////
//
// Name:	ImageStitcher_ZT_MemHyperStack
// Author: 	Sébastien Tosi (IRB/ADMCF)
// Version:	1.0
// Date:	06-10-2011	
//	
// Description: This macro builds a XY montage from an hyperstack (optionally multiple Z and T). 
// In this hyperstack, the positions (XY) of the images should be encoded as channels and the 
// ordering of these positions (Column/Row and Meander/Comb) has to be configured in the dialog 
// box: the images should appear in this order while browsing the hyperstack with the channel slider. 

// The positions of the image can be fixed (no overlap or known overlap) or fine stitching can be 
// performed based on image content. For this last feature, a sufficient overlap between the images
// should be provided. For multidimensional images, the stitching is only optimized for a single 
// user configurable (Z,T) position and applied to all other positions.
// 
// Note: for OME-TIFF filenaming the hyperstack can be easily obtained by importing all files as
// image sequence and transforming the stack to an hyperstack with xyzct convention (provided L and 
// T fields are fixed) or xyztc convention if L field is fixed. For this last case Column-Comb 
// configuration should be used regardless of the configuration of the scan. 
//
// Usage: Open the hyperstack to be processed, close all other images, run the macro.
//
///////////////////////////////////////////////////////////////////////////////////////////////////

// Check configuration
HyperstackID = getImageID();
Depth = bitDepth();
if(Depth==8)Format = "8-bit";
if(Depth==16)Format = "16-bit";
if(Depth==24)Format = "RGB";
if(Depth==32)Format = "32-bit";
Stack.getDimensions(Width, Height, channels, nSlice, nFrame); 

// Dialog Box
TilingArray = newArray("Column-Comb","Column-Meander","Row-Comb","Row-Meander");
FusionModes = newArray("None","Linear Blending","Average","Max. Intensity","Min. Intensity");
Dialog.create("3D montage");
Dialog.addMessage("Process an hyperstack with the positions coded as channels");
Dialog.addNumber("Number of rows", round(sqrt(channels)));
Dialog.addNumber("Number of columns", round(channels/round(sqrt(channels))));
Dialog.addChoice("Positions order", TilingArray, "Column-Comb");
Dialog.addNumber("Overlap (%)", 0);
Dialog.addNumber("Regression threshold", 0.3);
Dialog.addCheckbox("Stitch", false);
Dialog.addNumber("Reference slice for stitching", round(nSlice/2));
if(nFrame>1)Dialog.addNumber("Reference frame for stitching", round(nFrame/2));
Dialog.show();

// Recover parameters from dialog box
nRow = Dialog.getNumber();
nCol = Dialog.getNumber();
Tiling = Dialog.getChoice();
Overlap = Dialog.getNumber();
RegThr = Dialog.getNumber();
Stitch = Dialog.getCheckbox();
RefSlice = Dialog.getNumber();
if(nFrame>1)RefFrame = Dialog.getNumber();
else RefFrame = 1;

// Stiching of the selected slice: generate files before plugin call
setBatchMode(true);
Tmp = getDirectory("temp");
Cnt = 0;
for(i=0;i<nCol;i++)
{
	if(Tiling=="Row")ChanIndx=i+1;
	for(j=0;j<nRow;j++)
	{
		selectImage(HyperstackID);
		ChanIndx = IndexConv(Cnt,Tiling,nCol,nRow);
		print(ChanIndx,RefSlice);
		if(nFrame>1)run("Duplicate...", "title=Tmp duplicate channels="+ChanIndx+" slices="+d2s(RefSlice,0)+" frames="+d2s(RefFrame,0));
		else run("Duplicate...", "title=Tmp duplicate channels="+ChanIndx+" slices="+d2s(RefSlice,0));
		FilePath = Tmp+"\\X"+IJ.pad(d2s(i,0),4)+"_Y"+IJ.pad(d2s(j,0),4)+".tif";
		save(FilePath);
		selectImage("Tmp");
		close();
		Cnt++;
	}	
}

// Stitching and offsets check
if(Stitch==true)run("Stitch Grid of Images", "grid_size_x="+d2s(nCol,0)+" grid_size_y="+d2s(nRow,0)+" overlap="+d2s(Overlap,2)+" directory=["+Tmp+"] file_names=X{xxxx}_Y{yyyy}.tif rgb_order=rgb output_file_name=TileConfiguration.txt start_x=0 start_y=0 start_i=1 channels_for_registration=[Red, Green and Blue] fusion_method=[None] fusion_alpha=1.50 regression_threshold="+d2s(RegThr,2)+" max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 compute_overlap");
else run("Stitch Grid of Images", "grid_size_x="+d2s(nCol,0)+" grid_size_y="+d2s(nRow,0)+" overlap="+d2s(Overlap,2)+" directory=["+Tmp+"] file_names=X{xxxx}_Y{yyyy}.tif rgb_order=rgb output_file_name=TileConfiguration.txt start_x=0 start_y=0 start_i=1 channels_for_registration=[Red, Green and Blue] fusion_method=[None] fusion_alpha=1.50 regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50");

rename("Stitched");
resetMinAndMax();
MontageWidth = getWidth();
MontageHeight = getHeight();
Str = File.openAsString(Tmp+"\\TileConfiguration.txt.registered");
Fields = split(Str,"(,)");
if(lengthOf(Fields)==1+(3*nRow*nCol));
else exit("Stitching failed, try other reference slice or disable stitching!");
	
// Load images offset to arrays
OffsetX = newArray(nRow*nCol);
OffsetY = newArray(nRow*nCol);
Cnt = 1;
for(j=0;j<nRow;j++)
{
	for(i=0;i<nCol;i++)
	{
		OffsetX[i+j*nCol] = parseInt(Fields[Cnt]);
		Cnt++;
		OffsetY[i+j*nCol] = parseInt(Fields[Cnt]);	
		Cnt+=2;
	}
}

// 3D Montage (column by column)
for(t=1;t<=nFrame;t++)
{
CurrentFrameName = "3DMontage-"+IJ.pad(d2s(t,0),4);
newImage(CurrentFrameName, Format+" Black", MontageWidth, MontageHeight, nSlice);
Cnt = 0;
for(i=0;i<nCol;i++)
{
	if(Tiling=="Row")ChanIndx=i+1;
	for(j=0;j<nRow;j++)
	{
		ChanIndx = IndexConv(Cnt,Tiling,nCol,nRow);
		selectImage(HyperstackID);
		run("Duplicate...", "title=Tmp duplicate channels="+ChanIndx+" slices=1-"+d2s(nSlice,0)+" frames="+d2s(t,0));
		if(nSlices>1)run("Insert...", "source=Tmp destination="+CurrentFrameName+" x="+d2s(OffsetX[j*nCol+i],0)+" y="+d2s(OffsetY[j*nCol+i],0));
		else
		{
			run("Select All");
			run("Copy");
			selectImage(CurrentFrameName);
			run("Restore Selection");
			setSelectionLocation(OffsetX[j*nCol+i],OffsetY[j*nCol+i]);
			run("Paste");
			run("Select None");
		}
		selectImage("Tmp");
		close();
		Cnt++;
	}
}
}
setBatchMode("exit & display");
selectImage(HyperstackID);
close();
selectImage("Stitched");
close();
if(nFrame>1)
{
	run("Concatenate...", "all_open title=[Concatenated Stacks]");
	run("Stack to Hyperstack...", "order=xyczt(default) channels=1 slices="+d2s(nSlice,0)+" frames="+d2s(nFrame,0)+" display=Grayscale");
}
rename("Montage");
if(nSlice>1)Stack.setSlice(round(nSlice/2));
resetMinAndMax();

// Scan configuration index converter function
function IndexConv(Cnt,Tiling,nCol,nRow)
{
	col = floor(Cnt/nRow);
	row = (Cnt%nRow);
	if(Tiling=="Column-Comb")Index = col*nRow+row+1;
	if(Tiling=="Column-Meander")
	{
		if((col%2)==0)Index = col*nRow+row+1;
		else Index = (col+1)*nRow-row;
	}
	if(Tiling=="Row-Comb")Index = row*nCol+col+1;
	if(Tiling=="Row-Meander")
	{
		if((row%2)==0)Index = row*nCol+col+1;
		else Index = (row+1)*nCol-col;
	}
	return Index;
}
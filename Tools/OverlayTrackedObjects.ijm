/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Name:	OverlayTrackedObjects
// Author: 	Sébastien Tosi (sebastien.tosi@irbbarcelona.org)
// Date:	30-05-2019
// Version:	1.0
//	
// Description: 	Montage localized objects identified by LOBSTER (see LOBSTER documentation for details).
//
// Requirements:	Copy Random.lut to IJ luts folder
//
// Usage:		Run, select folder with original images, select folder with object label masks.
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

ImageFolder = getDirectory("Select input image folder");					// Folder with original images
MaskFolder = getDirectory("Select output label mask folder");				// Folder with object label masks
ImageFilter = ".tif";														// Original images filter
MaskFilter = ".tif";														// Object masks filter
Thickness = 3;																// Thickness of object contours (pixels)

run("Image Sequence...", "open="+ImageFolder+" file="+ImageFilter+" sort");
run("Grays");
run("Enhance Contrast", "saturated=0.35");
rename("Image");
run("16-bit");
run("Image Sequence...", "open="+MaskFolder+" file="+MaskFilter+" sort");
run("Random");
rename("Cells");
run("Duplicate...", "title=Max duplicate");
run("Maximum...", "radius="+Thickness+" stack");
imageCalculator("Subtract stack", "Max","Cells");
selectImage("Cells");
close();
run("Merge Channels...", "c1=Max c4=Image create");
setSlice(nSlices-1);
resetMinAndMax();
setSlice(1);
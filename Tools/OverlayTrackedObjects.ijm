/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Name:	OverlayTrackedObjects
// Author: 	Sébastien Tosi (sebastien.tosi@irbbarcelona.org)
// Date:	30-05-2019
// Version:	1.0
//	
// Description: Montage localized objects identified by LOBSTER (see LOBSTER documentation for details).
//
// Usage:	Configure path for images and object masks. "Run".
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////


ImageFolder = "E:\\LOBSTER\\Images\\HeLaMCF10AMovie\\Movie1";			// Folder with original images
MaskFolder = "E:\\LOBSTER\\Results\\Images\\HeLaMCF10AMovieOvlLbl\\Movie1";	// Folder with object masks
ImageFilter = ".tif";								// Original images filter (her all tif images)
MaskFilter = ".tif";								// Object masks filter (her all tif images)
Thickness = 3;									// Thickness of object contours (pixels)

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
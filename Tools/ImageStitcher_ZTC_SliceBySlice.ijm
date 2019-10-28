//////////////////////////////////////////////////////////////////////////////////////////////////
//
// Name:	ImageStitcher_ZTC_SliceBySlice
// Author: 	Sébastien Tosi (IRB/ADMCF)
// Date:	13-11-2013	
//
// This macro is designed to stitch the images from a multidimensional image (Z,T,C).
//	
// Image files must be 2D TIFF images stored in the same folder.
// File naming should ideally comply to OME-TIFF convention (--X, --Y, --Z, --T, --C, --L fields 
// with user fixed number of digits) but is configurable (fixed number of digits compulsory).  
// 
// The stitching is optimized for a reference Z,T position and applied to all other positions. 
// Stitching is performed slice by slice and the stitched images are exported to a single user 
// defined output folder. 
//
// The macro can also process a dataset with multiple channels, the stitching is then
// computed once on a reference channel and then applied to all other channels. To use this
// option tick "Additional channel" and configure L / C fields indices of additional channel.      
//////////////////////////////////////////////////////////////////////////////////////////////////

// Dialog box
FusionModes = newArray(5);
FusionModes[0] = "Linear Blending";
FusionModes[1] = "Max. Intensity";
FusionModes[2] = "Average";
FusionModes[3] = "Median";
FusionModes[4] = "Min. Intensity";
Dialog.create("ZTC_Stitcher");
Dialog.addNumber("Fields of view per column",3);
Dialog.addNumber("Fields of view per row",3);
Dialog.addNumber("Slice(s) to process",10);
Dialog.addNumber("Time frame(s) to process",1);
Dialog.addNumber("Overlap (%)",5);
Dialog.addNumber("Bit depth",8);
Dialog.addNumber("Regression threshold (0-1)",0.3);
Dialog.addChoice("Fusion mode",FusionModes);
Dialog.addString("Export root name","Stitched_");
Dialog.addMessage("Special Features");
Dialog.addCheckbox("Additional channel?",false);
Dialog.addNumber("C field to process",0);
Dialog.addNumber("L field to process",0);
Dialog.addCheckbox("Launch additional channel on complete?",false);
Dialog.addMessage("Additional parameters");
Dialog.addNumber("Column starting index",0);
Dialog.addNumber("Row starting index",0);
Dialog.addNumber("Slice starting index",300);
Dialog.addNumber("Time frame starting index",0);
Dialog.addMessage("File naming");
Dialog.addNumber("X/Y fields digits",2);
Dialog.addNumber("Z field digits",4);
Dialog.addNumber("T field digits",4);
Dialog.addNumber("C/L fields digits",2);
Dialog.show;
NX = Dialog.getNumber();
NY = Dialog.getNumber();
NZ = Dialog.getNumber();
NT = Dialog.getNumber();
Overlap = Dialog.getNumber();
BitDepth = Dialog.getNumber();
RegThr = Dialog.getNumber();
Fusion = Dialog.getChoice();
ExportRoot = Dialog.getString();
AddChan = Dialog.getCheckbox();
NewC = Dialog.getNumber();
NewL = Dialog.getNumber();
AutoLaunch = Dialog.getCheckbox();
StartX = Dialog.getNumber();
StartY = Dialog.getNumber();
StartZ = Dialog.getNumber();
StartT = Dialog.getNumber();
DigXY = Dialog.getNumber();
DigZ = Dialog.getNumber();
DigT = Dialog.getNumber();
DigCL = Dialog.getNumber();

//// Folders
OutputFolder  = getDirectory("Select the output image folder");
ImageFolder = getDirectory("Select the input image folder");

XStr = "";for(i=0;i<DigXY;i++)XStr = XStr+"x";
YStr = "";for(i=0;i<DigXY;i++)YStr = YStr+"y";

if(AutoLaunch == true)NitChan = 2;
else NitChan = 1;

for(itchan=0;itchan<NitChan;itchan++)
{

if(AutoLaunch == true)
{
	if(itchan == 0)AddChan = false;
	else AddChan = true;
}

FindRef = 1;
while(FindRef == 1)
{
	
// Reference file (slice and time frame)
if(AddChan == true)
{
	FindRef = 0;
	TemplateRegistrationFile = ImageFolder+"\\TileConfiguration.registered.txt";
	Content = File.openAsString(TemplateRegistrationFile);
	Lines = split(Content,"\n");
	Indx = indexOf(Lines[4],".tif");
	FileName = substring(Lines[4],0,Indx)+".tif";
}
else
{
	FilePath = File.openDialog("Select the reference file"); 
	FileName = File.getName(FilePath);
}
RefX = parseInt(substring(FileName,indexOf(FileName, "--X")+3,indexOf(FileName, "--X")+3+DigXY));
RefY = parseInt(substring(FileName,indexOf(FileName, "--Y")+3,indexOf(FileName, "--Y")+3+DigXY));
FileTemplate = replace(FileName, "--X"+IJ.pad(RefX,2), "--X{"+XStr+"}");
FileTemplate = replace(FileTemplate, "--Y"+IJ.pad(RefY,2), "--Y{"+YStr+"}");
RefZ = parseInt(substring(FileTemplate,indexOf(FileTemplate, "--Z")+3,indexOf(FileTemplate, "--Z")+3+DigZ));
if(indexOf(FileTemplate, "--T")>-1)RefT = parseInt(substring(FileTemplate,indexOf(FileTemplate, "--T")+3,indexOf(FileTemplate, "--T")+3+DigT));
else RefT = 0;
RefZString = "Z"+IJ.pad(RefZ,DigZ);
RefTString = "T"+IJ.pad(RefT,DigT);

if(AddChan == false)
{
//// Fine stitching in the reference slice and time frame
run("Grid/Collection stitching", "type=[Filename defined position] order=[Defined by filename         ] grid_size_x="+d2s(NX,0)+" grid_size_y="+d2s(NY,0)+" tile_overlap=0 first_file_index_x="+d2s(StartX,0)+" first_file_index_y="+d2s(StartY,0)+" directory=["+ImageFolder+"] file_names="+FileTemplate+" output_textfile_name=TileConfiguration.txt fusion_method=[Max. Intensity] regression_threshold="+d2s(RegThr,2)+" max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
rename("Tiled without overlap");
TotalWdth = getWidth();
TotalHght = getHeight();
run("Enhance Contrast", "saturated=0.35");
run("Grid/Collection stitching", "type=[Filename defined position] order=[Defined by filename         ] grid_size_x="+d2s(NX,0)+" grid_size_y="+d2s(NY,0)+" tile_overlap="+d2s(Overlap,2)+" first_file_index_x="+d2s(StartX,0)+" first_file_index_y="+d2s(StartY,0)+" directory=["+ImageFolder+"] file_names="+FileTemplate+" output_textfile_name=TileConfiguration.txt fusion_method=["+Fusion+"] regression_threshold="+d2s(RegThr,2)+" max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 compute_overlap computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
rename(Fusion+" fusion");
StitchedWdth = getWidth();
StitchedHght = getHeight();
run("Enhance Contrast", "saturated=0.35");
print("\\Clear");
print("Reference Z slice: "+RefZ);
print("Reference T frame: "+RefT);
print("Average estimated X overlap (%): "+d2s( 100*((TotalWdth-StitchedWdth)/(NX-1))/(TotalWdth/NX) ,2));
print("Average estimated Y overlap (%): "+d2s( 100*((TotalHght-StitchedHght)/(NY-1))/(TotalHght/NY) ,2));
waitForUser("Check stitching");
FindRef = getNumber("Select new reference? (0 --> no, 1 --> yes)?", 0);
selectImage("Tiled without overlap");
close();
selectImage(Fusion+" fusion");
close();
}
}

//// Apply computed displacements to all slices and time frames
TemplateRegistrationFile = ImageFolder+"\\TileConfiguration.registered.txt";
CurrentRegistrationFile = "TileConfiguration.current.txt";
Content = File.openAsString(TemplateRegistrationFile);

if(AddChan == true)
{
	RefC = parseInt(substring(FileName,indexOf(FileName, "--C")+3,indexOf(FileName, "--C")+3+DigXY));
	RefL = parseInt(substring(FileName,indexOf(FileName, "--L")+3,indexOf(FileName, "--L")+3+DigXY));
	RefCString = "C"+IJ.pad(RefC,DigCL);
	RefLString = "L"+IJ.pad(RefL,DigCL);
	Content = replace(Content, RefCString, "C"+IJ.pad(NewC,DigCL));
	Content = replace(Content, RefLString, "L"+IJ.pad(NewL,DigCL));
}

for(k=StartT;k<StartT+NT;k++)
{
for(i=StartZ;i<StartZ+NZ;i++)
{
	NewZString = "Z"+IJ.pad(i,DigZ);
	NewTString = "T"+IJ.pad(k,DigT);
	NewContent = replace(Content, RefZString, NewZString);
	NewContent = replace(NewContent, RefTString, NewTString);
	File.saveString(NewContent,ImageFolder+"\\"+CurrentRegistrationFile);
	run("Grid/Collection stitching", "type=[Positions from file] order=[Defined by TileConfiguration] directory=["+ImageFolder+"] layout_file="+CurrentRegistrationFile+" fusion_method=["+Fusion+"] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
	resetMinAndMax();
	saveAs("Tiff", OutputFolder +"\\"+"C"+d2s(itchan,0)+"_"+ExportRoot+d2s(NX,0)+"x"+d2s(NY,0)+"--"+NewZString+"--"+NewTString+".tif");
	rename("Computed");
	run("Copy");
	Wdth = getWidth();
	Hgth = getHeight();
	close();
	if(i == StartZ)
	{
		if(BitDepth==8) newImage("Current", "8-bit Black", Wdth, Hgth, 1);
		else newImage("Current", "16-bit Black", Wdth, Hgth, 1);
	}	
	else selectImage("Current");
	run("Paste");
	run("Tile");
	if(i == (StartZ+NZ-1))
	{
		selectImage("Current");
		close();
	}
}
}
}
///////////////////////////////////////////////////////////////////////////////////////////////
//// Name: 	ImageGroup_or_Project
//// Author:	Sébastien Tosi (IRB / Barcelona)
//// Version:	1.0
//// Date: 	30/11/2017
////
//// Usage:	
////		Mode 1:	No image opened
////		Process a folder of tif images, group/project images based on configurable 
////		numerical field (with known fixed number of digits), and save them to files. 
////
////		Mode 2: 1 hyperstack opened (possibly in virtual mode)
////		Extract each time frame, optionally Z-project, save images to files.
////
/////////////////////////////////////////////////////////////////////////////////////////////////

// Detect mode (folder of file / hyerstack)
if(nImages>0)HyperStackInput = Stack.isHyperstack;
else HyperStackInput = false;

//// Dialog box
Choices = newArray("Group","Max Intensity","Average Intensity");
Dialog.create("Group/Project by field");
if(HyperStackInput==false)
{
	Dialog.addString("Grouping field",  "_z");
	Dialog.addNumber("Grouping field digits", 3);
}
Dialog.addChoice("Grouping mode",Choices,"Group");
Dialog.show;
if(HyperStackInput==false)
{
	ZField = Dialog.getString();
	NDigits = Dialog.getNumber();
}
Group = Dialog.getChoice();

//// Folders
if(!HyperStackInput)ImageFolder = getDirectory("Select the input image folder");
OutputFolder  = getDirectory("Select the output image folder");

setBatchMode(true);
if(!HyperStackInput)
{
///// Initialization
BlankField = "";
for(i=0;i<NDigits+lengthOf(ZField);i++)BlankField = BlankField+".";

///// Processing
FileList = getFileList(ImageFolder);
NoZFileList = newArray(lengthOf(FileList));
cnt = -1;
for(i=0;i<lengthOf(FileList);i++)
{
	CurrentFile = FileList[i];
	if(endsWith(CurrentFile,".tif"))
	{
		cnt = cnt+1;
		indx = indexOf(CurrentFile,ZField);
		Part1 = substring(CurrentFile,0,indx);
		Part2 = substring(CurrentFile,indx+lengthOf(ZField)+NDigits,lengthOf(CurrentFile)-4);
		NoZFileList[cnt] = Part1+BlankField+Part2;
	}
}
NoZFileList = Array.trim(NoZFileList,cnt);
NoZFileList = Array.sort(NoZFileList);
LastName = "";
Nit = lengthOf(NoZFileList);
for(i=0;i<Nit;i++)
{
	showProgress((i+1)/Nit);
	if(NoZFileList[i] != LastName)
	{
		// Use regex with . wild characters
		run("Image Sequence...", "open=["+ImageFolder+"] file=[("+NoZFileList[i]+")] sort");
		LastName = NoZFileList[i];
		if(Group!="Group")
		{
			run("Z Project...", "projection=["+Group+"]");
			resetMinAndMax();
		}
		idx = indexOf(LastName,BlankField);
		FileWriteName = substring(LastName,0,idx)+substring(LastName,idx+NDigits+lengthOf(ZField),lengthOf(LastName))+".tif";
		save(OutputFolder+File.separator+FileWriteName);
		run("Close All");
	}
	
}
}
else
{
	OriginalID = getImageID();
	Stack.getDimensions(width, height, channels, slices, frames);
	for(i=1;i<=frames;i++)
	{
		showProgress(i/frames);
		selectImage(OriginalID);
		run("Duplicate...", "duplicate frames="+d2s(i,0));
		DupID = getImageID();
		if((Group!="Group")&&(slices>1))
		{
			run("Z Project...", "projection=["+Group+"]");
			resetMinAndMax();
			ZprojID = getImageID();
		}
		save(OutputFolder+File.separator+"T_"+IJ.pad(i,4)+"_"+getTitle());
		selectImage(DupID);
		close();
		if((Group!="Group")&&(slices>1))
		{
			selectImage(ZprojID);
			close();
		}
	}
}
setBatchMode("exit & display");
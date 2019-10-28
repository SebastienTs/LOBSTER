///////////////////////////////////////////////////////////////////////////////////////////////
//// Name: 	JOSE
//// Author:	Sébastien Tosi (IRB / Barcelona)
//// Version:	1.0
////
//// Description: Open a LOBSTER visualization scene created by JOSE.
////
//// Usage: Browse to LOBSTER_ROOT/Reports from file browser. All Scene files from subfolders
//// 	    are recursively listed. Open a scene by selecting its index from the list.
////
////	    Note: You can set LOBSTER_ROOT/Reports to a fixed path to avoid browsing. 	
////
//// Requirements: Only tested for Fiji lifeline June 2014, Win 7.
////
///////////////////////////////////////////////////////////////////////////////////////////////

// Options
//LOBSTER_ROOT_reports = "E:\\LOBSTER\\Results\\Reports\\";
LOBSTER_ROOT_reports = "";
VirtualMode = 0;

// Color lookup table
Colors = newArray("yellow","red","blue","magenta","orange","cyan","pink","white");
MinBB = 3;

// Initialization
run("Colors...", "foreground=white background=black selection=yellow");
roiManager("Associate", "true");
run("Close All");

// Scene file selector
print("\\Clear");
if(LOBSTER_ROOT_reports=="")dir = getDirectory("Select LOBSTER Reports folder");
else dir = LOBSTER_ROOT_reports;
count = 0;
listFiles(dir);
function listFiles(dir) 
{
	list = getFileList(dir);
	for (i=0; i<list.length; i++) 
	{
		if(endsWith(list[i], "/"))listFiles(""+dir+list[i]);
		else 
		{
			if(endsWith(list[i], ".sce"))
			{
				print(IJ.pad(count++,4) + ": " + dir + list[i]);
			}
		}
	}
}
str = getInfo("log");
str = split(str,"\n");
waitForUser("Adjust Log window\nClick OK to proceed");
idx = getNumber("Scene index", 0);
str = str[idx];
str = substring(str,6,lengthOf(str));
JobsceneFile = str;
	
// Open job scene as string
Jobscene = File.openAsString(JobsceneFile);
Jobscenelines = split(Jobscene,"\n");

// Configuration
ConfigNum = parseInt(Jobscenelines[1]);
Step = (floor(ConfigNum/100)%10);
FoldersIn = (floor(ConfigNum/10)%2);
Movie = (ConfigNum%2);

// Parse channel paths + filters and annotation paths
NChan = 0;NAnno = 0;Chan = 1;EnableColorCode = 0;
for(i=2;i<lengthOf(Jobscenelines);i++)
{
	if(Jobscenelines[i]=="ColorCode")
	{
		script = Jobscenelines[i+1];
		EnableColorCode = 1;
	}
	else
	{
		if(Jobscenelines[i]=="Annotations")Chan = 0;
		if((Jobscenelines[i]!="Channels")&&(Chan == 1))NChan = NChan+0.5;
		if((Jobscenelines[i]!="Annotations")&&(Chan == 0))NAnno = NAnno+0.5;
	}
}

ChanPath = newArray(NChan);
ChanFilter = newArray(NChan);
AnnoPath = newArray(NAnno);
//AnnoFilter = newArray(NChan);
NChan = 0;NAnno = 0;Chan = 1;cnt = 0;
for(i=2;i<lengthOf(Jobscenelines);i++)
{
	if(Jobscenelines[i]!="ColorCode")
	{
		if(Jobscenelines[i]=="Annotations")Chan = 0;
		if((Jobscenelines[i]!="Channels")&&(Chan == 1))
		{
			if((cnt%2)==0)ChanPath[NChan] = Jobscenelines[i];
			else 
			{
				ChanFilter[NChan] = Jobscenelines[i];
				NChan++;
			}
			cnt++;
		}
		if((Jobscenelines[i]!="Annotations")&&(Chan == 0))
		{	
			if((cnt%2)==0)AnnoPath[NAnno] = Jobscenelines[i];
			else NAnno++;
			cnt++;
		}
	}
	else i = lengthOf(Jobscenelines)-1;
}

// Open images and annotations
FileListi = getFileList(ChanPath[0]);
chancnt = 0;
imgcnt = 0;
Nfiles = lengthOf(FileListi);
if(Movie == 1)Nfiles = 1;
for(i=0;i<Nfiles;i++)
{	
	// Clear ROI Manager
	if(isOpen("ROI Manager"))
	{
		selectWindow("ROI Manager");
		run("Close");
	}
	for(c=0;c<NChan;c++)
	{
		Found = 0;
		FileListi = getFileList(ChanPath[c]);
		Filter = ChanFilter[c];
		
		if(indexOf(FileListi[i],Filter)>-1)
		{
			Found = 1;
			if(FoldersIn)
			{
				if(VirtualMode)run("Image Sequence...", "open=["+ChanPath[c]+FileListi[i]+"] sort use");
				else run("Image Sequence...", "open=["+ChanPath[c]+FileListi[i]+"] sort");
			}
			else
			{
				if(VirtualMode)run("TIFF Virtual Stack...", "open="+ChanPath[c]+FileListi[i]);
				else open(ChanPath[c]+FileListi[i]);
			}
			rename("Chan_"+d2s(chancnt,0));
			chancnt++;
		}
	
	}
	if(chancnt == NChan)
	{
		if(Movie==1)run("Random");
		
		// Composite
		if((NChan>1)||(Step>1))
		{
			if((Step == 1)&&(NChan>1))
			{
				if(nSlices == 1)
				{
					run("Images to Stack", "name=Stack title=[]");
					run("Stack to Hyperstack...", "order=xyczt(default) channels="+d2s(NChan,0)+" slices="+d2s(nSlices/NChan,0)+" frames=1 display=Composite");
				}
				else
				{
					if(chancnt == 4)run("Merge Channels...", "c1=Chan_1 c2=Chan_2 c3=Chan_3 c4=Chan_0");
					if(chancnt == 3)run("Merge Channels...", "c1=Chan_1 c2=Chan_2 c4=Chan_0");
					if(chancnt == 2)run("Merge Channels...", "c1=Chan_1 c4=Chan_0");
				}
			}
			if((Step>1)&&(NChan==1))run("Stack to Hyperstack...", "order=xyczt(default) channels="+d2s(Step,0)+" slices="+d2s(nSlices/Step,0)+" frames=1 display=Composite");
		}
		
		// Annotations
		getDimensions(width, height, channels, slices, frames);
		for(a=0;a<NAnno;a++)
		{
			FileListi = getFileList(AnnoPath[a]);
			open(AnnoPath[a]+FileListi[imgcnt]);
			if(slices==1)
			{
				for(n=0;n <nResults ;n++)
				{
					Sx = getResult("BoundingBox_1",n);
					Sy = getResult("BoundingBox_2",n);
					Wx = getResult("BoundingBox_3",n);
					Wy = getResult("BoundingBox_4",n);
					makeRectangle(Sx,Sy,maxOf(Wx,MinBB),maxOf(Wy,MinBB));
					roiManager("add");
					if(EnableColorCode == 1)
					{
						roiManager("select",roiManager("count")-1);
						color = eval(replace(script,"ObjIdx",n));
						roiManager("Set Color", Colors[color%8]);
					}
					else 
					{
						if(a>0)
						{
							roiManager("select",roiManager("count")-1);
							roiManager("Set Color", Colors[a%8]);
						}
					}
			
				}
			}
			else
			{
				for(n=0;n <nResults ;n++)
				{
					Sx = getResult("BoundingBox_1",n);
					Sy = getResult("BoundingBox_2",n);
					Sz = getResult("BoundingBox_3",n);
					Wx = getResult("BoundingBox_4",n);
					Wy = getResult("BoundingBox_5",n);
					Wz = getResult("BoundingBox_6",n);
					setSlice(1+floor(Sz)*Step);
					makeRectangle(Sx,Sy,maxOf(Wx,MinBB),maxOf(Wy,MinBB));
					roiManager("add");
					if(EnableColorCode == 1)
					{
						roiManager("select",roiManager("count")-1);
						roiManager("Set Color", Colors[ColorCode(n)%8]);
					}
				}
			}
			roiManager("Show All without labels");
		}
		setSlice(1);
		run("Channels Tool...");

		// Wait for user
		waitForUser;
		run("Close All");
		chancnt = 0;
		imgcnt++;
	}
}
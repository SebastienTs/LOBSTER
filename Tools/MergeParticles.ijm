macro "MergeParticles [F1]" 
{
	run("Enlarge...", "enlarge=1");
	run("Enlarge...", "enlarge=-1");
	run("Set...", "value=255");
}
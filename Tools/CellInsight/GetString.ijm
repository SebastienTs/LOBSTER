macro GetString
{
	OldName = getArgument();
	Dialog.create("Subgroup name");
	Dialog.addString("String =", OldName);
	Dialog.show();
	NewName = Dialog.getString();
	return NewName;
}
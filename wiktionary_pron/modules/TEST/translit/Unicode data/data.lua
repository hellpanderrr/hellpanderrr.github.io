-- General data used by [[Module:Unicode data]].
local export = {}

export.planes = {
	[ 0] = "Basic Multilingual Plane";
	[ 1] = "Supplementary Multilingual Plane";
	[ 2] = "Supplementary Ideographic Plane";
	[ 3] = "Tertiary Ideographic Plane";
	[14] = "Supplementary Special-purpose Plane";
	[15] = "Supplementary Private Use Area-A";
	[16] = "Supplementary Private Use Area-B";
}

export.unsupported_title = {
	[0x0020] = "Unsupported titles/Space";
	[0x0023] = "Unsupported titles/Number sign";
	[0x002E] = "Unsupported titles/Full stop";
	[0x003A] = "Unsupported titles/Colon";
	[0x003C] = "Unsupported titles/Less than";
	[0x003E] = "Unsupported titles/Greater than";
	[0x005B] = "Unsupported titles/Left square bracket";
	[0x005D] = "Unsupported titles/Right square bracket";
	[0x005F] = "Unsupported titles/Low line";
	[0x007B] = "Unsupported titles/Left curly bracket";
	[0x007C] = "Unsupported titles/Vertical line";
	[0x007D] = "Unsupported titles/Right curly bracket";
	[0x1680] = "Unsupported titles/Ogham space";
	[0xFFFD] = "Unsupported titles/Replacement character";
}

return export
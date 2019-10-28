uniform sampler3D texture_3d;
uniform sampler2D texture_depth;
uniform vec2 WindowSize;

void main()
{
	// Texture coordinate / start location of ray
	float x = gl_FragCoord.x/WindowSize[0];
	float y = gl_FragCoord.y/WindowSize[1];
	
	// Texture position start
	vec3 Pos = vec3(gl_TexCoord[0]);
	
	// Texture Position end, (from backface render output)
	vec3 Pos_end = texture2D(texture_depth, vec2(x,y)).rgb;
	
	// Calculate the update each step
	vec3 Pos_Update=(Pos_end-Pos);

	// Length in pixels
	float n=256.0*sqrt(Pos_Update.r*Pos_Update.r+Pos_Update.g*Pos_Update.g+Pos_Update.b*Pos_Update.b);
	
	// Update normalize
	Pos_Update=Pos_Update/n;
		
	// max intensity value found
	float maxval = 0.0;
	
	// boolean to float
    float hr;
	
	// Current intensity value
	float val;
	
	// Follow the ray, from start to end
	for (int i=0; i<int(n); i++) 
	{ 
		val = texture3D(texture_3d, Pos)[3];
		Pos = Pos+Pos_Update;
		hr = float(maxval>val);
    	maxval=maxval*hr+val*(1.0-hr);		
	}   
	
	if (maxval<LOWVAL)maxval = 0.0;
	maxval = maxval/HGHVAL;
	
	gl_FragColor = vec4(maxval,maxval,maxval,1.0);
}
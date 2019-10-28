uniform sampler3D texture;

void main()
{
	// Texture coordinate / start location of ray
	vec3 Pos = vec3(gl_TexCoord[0]);
    
    gl_FragColor = vec4(Pos.r,Pos.g,Pos.b,1.0);
}
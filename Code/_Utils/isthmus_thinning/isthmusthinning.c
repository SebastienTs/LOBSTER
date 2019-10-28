/* include files */
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include <math.h>
  #include <mex.h>
  #include "ibcenterline.h"
  #include "matrix.h"

/* global variables */
  long int           long_mask[26];
  unsigned char      char_mask[8];
  unsigned long int  neighbours;
  unsigned long int  direction;
  unsigned char      *lut_simple;
  unsigned char      *lut_isthmus;
  unsigned long int  size_x;
  unsigned long int  size_y;
  unsigned long int  size_z;
  unsigned long int  size_xy;
  unsigned long int  size_xyz;
  unsigned long int  z_size_xy, zm_size_xy, zp_size_xy;
  unsigned long int  y_size_x, ym_size_x, yp_size_x;
  analyze_hdr        hdr;
  unsigned char      *image;
  Bordercell *borderlist;
  List SurfaceVoxels;

 #include "readwrite_functions.c"
 #include "thinning_functions.c" 

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	int nDim = mxGetNumberOfDimensions(prhs[0]);
	const int *pDims = mxGetDimensions(prhs[0]);
	unsigned char *pD = mxGetPr(prhs[0]);
	unsigned long int i;
	
	//mexPrintf("NDim: %i\n",nDim);
	//mexPrintf("pDim: %i %i %i\n",pDims[0],pDims[1],pDims[2]);

    size_x = pDims[0];
    size_y = pDims[1];
    size_z = pDims[2];
      
	/* set slice- and image size */   
    size_xy  = size_x * size_y;
    size_xyz = size_xy * size_z;
	
	// Allocate mex output array: clean way
	mxArray *incopy = mxDuplicateArray(prhs[0]);
    image = (unsigned char *)mxGetPr(incopy);
	
	/****************/
	/* READING LUTs */
	/****************/
    init_lut_simple();
    init_lut_isthmus();
	
	/************/  
	/* THINNING */
	/************/
    sequential_thinning();
	
	/********/  
	/* FREE */
	/********/
    free(lut_simple);
    free(lut_isthmus);    
    
	// Clean way
	plhs[0] = incopy;
	
}
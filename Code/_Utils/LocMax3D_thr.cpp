#include <math.h>
#include "matrix.h"
#include "mex.h"
#include <cmath>
#include <omp.h>

void mexFunction( int nlhs, mxArray *plhs[], 
                  int nrhs, const mxArray*prhs[] )    
{ 
    // Check for proper number of arguments
    if (nrhs != 5)
    { 
        mexErrMsgTxt("Exactly 5 input arguments expected."); 
    } 
	float *im_in = (float *)mxGetPr(prhs[0]);
	const int nDim = mxGetNumberOfDimensions(prhs[0]);
    const int *pDims = mxGetDimensions(prhs[0]);
	float THR = (float)mxGetScalar(prhs[1]);
	int Ry = (int)mxGetScalar(prhs[2]);
	int Rx = (int)mxGetScalar(prhs[3]);
	int Rz = (int)mxGetScalar(prhs[4]);
	float val;
	bool valid;
	int ind, ind2, ind3;
	int size_y = pDims[0];
	int size_x = pDims[1];
	int size_z = pDims[2];
	int size_xy = size_x*size_y;

	// Allocate output array
	mxArray *im_out = mxCreateNumericArray(nDim, pDims, mxUINT8_CLASS, mxREAL);
    char *ptr_out = (char *)mxGetPr(im_out);

    // Main loop
    #pragma omp parallel for private(ind,val,ind2,ind3,valid)
    for(int i=Ry;i<size_y-Ry-1;i++)
    {
    	for(int j=Rx;j<size_x-Rx-1;j++)
    		{
    			for(int k=Rz;k<size_z-Rz-1;k++)
    			{
    				ind = i+j*size_y+k*size_xy;
    				val = im_in[ind];
    				if(val >= THR)
    				{
    					valid = true;
    					for(int ko=-Rz;ko<Rz+1;ko++)
    					{
    						ind2 = ind+ko*size_xy;
    						for(int jo=-Rx;jo<Rx+1;jo++)
    						{
    							ind3 = ind2+jo*size_y;
    							for(int io=-Ry;io<Ry+1;io++)
    							{	
									if(im_in[ind3+io] >= val)
									{
										if(!((ko == 0)&&(jo == 0)&&(io == 0)))
										{
											valid = false;
											io = Rx;jo=Ry;ko=Rz;
										}
									}
    							}
    						}
    					}
    					if(valid == true)ptr_out[ind] = 200;
    				}
    			}
			}    
    }
    plhs[0] = im_out;
    return;
}
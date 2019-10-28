// propagate.c 

// CellProfiler is distributed under the GNU General Public License.
// See the accompanying file LICENSE for details.                   
                                                                  
// Developed by the Whitehead Institute for Biomedical Research.    
// Copyright 2003,2004,2005.                                        

// call function with (labels, image, mask) as input.
// - labels are the seeds
// - image is the intensity to use to guide the segmentation
// - mask is the foreground region of the image

// Output is
// - labels
// - distances (optional)
                                                                  
// Authors:                                                         
//   Anne Carpenter <carpenter@wi.mit.edu>                          
//   Thouis Jones   <thouis@csail.mit.edu>                          
//   In Han Kang    <inthek@mit.edu>                                
//   Kyungnam Kim   <kkim@broad.mit.edu>
//   Sébastien Tosi, modified / simplified, 3D support 

#include <math.h>
#include <queue>
#include <vector>
#include <iostream>
using namespace std;
#include "mex.h"

// Input Arguments
#define LABELS_IN       prhs[0]
#define IM_IN           prhs[1]
#define MASK_IN         prhs[2]
#define NPLANES_IN		prhs[3]

// Output Arguments
#define LABELS_OUT        plhs[0]
#define DISTANCES_OUT     plhs[1]
#define DIFF_COUNT_OUT    plhs[2]

#define IJ(i,j) ((j)*m+(i))

class Pixel { 
public:
  float distance;
  unsigned int i, j;
  float label;
  Pixel (float ds, unsigned int ini, unsigned int inj, float l) : 
    distance(ds), i(ini), j(inj), label(l) {}
};

struct Pixel_compare { 
 bool operator() (const Pixel& a, const Pixel& b) const 
 { return a.distance > b.distance; }
};

typedef priority_queue<Pixel, vector<Pixel>, Pixel_compare> PixelQueue;

static void
push_neighbors_on_queue(PixelQueue &pq, float dist,
                        float *image,
                        unsigned int i, unsigned int j,
                        unsigned int m, unsigned int n, unsigned d,
                        float label,
                        float *labels_out)
{
  // TODO: Check if the neighbour is already labelled. If so, skip pushing.      
  // 6-connected
  if (i > 0) {
    if ( 0 == labels_out[IJ(i-1,j)] ) // if the neighbour was not labelled, do pushing
	  pq.push(Pixel(dist + fabs(image[IJ(i,j)] - image[IJ(i-1,j)]), i-1, j, label));
  }                                                                   
  if (j > 0) {                                                        
    if ( 0 == labels_out[IJ(i,j-1)] )   
	  pq.push(Pixel(dist + fabs(image[IJ(i,j)] - image[IJ(i,j-1)]), i, j-1, label));
  }                                                                   
  if (i < (m-1)) {
    if ( 0 == labels_out[IJ(i+1,j)] ) 
	  pq.push(Pixel(dist + fabs(image[IJ(i,j)] - image[IJ(i+1,j)]), i+1, j, label));
  }                                                                              
  if ((j%n)<(n-1)) { 
   if ( 0 == labels_out[IJ(i,j+1)] )   
	  pq.push(Pixel(dist + fabs(image[IJ(i,j)] - image[IJ(i,j+1)]), i, j+1, label));
  }
  if (j < d*n-n) {
    if ( 0 == labels_out[IJ(i,j+n)] ) 
	  pq.push(Pixel(dist + fabs(image[IJ(i,j)] - image[IJ(i,j+n)]), i, j+n, label));
  }
  if (j >= n) {              
    if ( 0 == labels_out[IJ(i,j-n)] )   
	  pq.push(Pixel(dist + fabs(image[IJ(i,j)] - image[IJ(i,j-n)]), i, j-n, label));
  }
}

static void propagate(float *labels_in, float *im_in,
                      mxLogical *mask_in, float *labels_out,
                      float *dists,
                      unsigned int m, unsigned int n, unsigned int d)
{
  // TODO: Initialization of nuclei labels can be simplified by labelling
  //       the nuclei region first, then make the queue prepared for 
  //       propagation
  //
  unsigned int i, j;
  PixelQueue pixel_queue;

  // Initialize dist to Inf, read labels_in and write out to labels_out
  for (j = 0; j < n*d; j++) {
    for (i = 0; i < m; i++) {
      dists[IJ(i,j)] = mxGetInf();            
      labels_out[IJ(i,j)] = labels_in[IJ(i,j)];
    }
  }
  
  // If the pixel is already labelled (i.e, labelled in labels_in) and within a mask, 
  // then set dist to 0 and push its neighbours for propagation */
  for (j = 0; j < n*d; j++) {
    for (i = 0; i < m; i++) {        
      float label = labels_in[IJ(i,j)];
      if ((label > 0) && (mask_in[IJ(i,j)])) {
        dists[IJ(i,j)] = 0.0;
        push_neighbors_on_queue(pixel_queue, 0.0, im_in, i, j, m, n, d, label, labels_out);
      }
    }
  }

  while (! pixel_queue.empty()) {
    Pixel p = pixel_queue.top();
    pixel_queue.pop();
    if (! mask_in[IJ(p.i, p.j)]) continue;
    if ((dists[IJ(p.i, p.j)] > p.distance) && (mask_in[IJ(p.i,p.j)])) {
      dists[IJ(p.i, p.j)] = p.distance;
      labels_out[IJ(p.i, p.j)] = p.label;
      push_neighbors_on_queue(pixel_queue, p.distance, im_in, p.i, p.j, m, n, d, p.label, labels_out);
    }
  }

}

void mexFunction( int nlhs, mxArray *plhs[], 
                  int nrhs, const mxArray*prhs[] )    
{ 
    float *labels_in, *im_in; 
    mxLogical *mask_in;
    float *labels_out, *dists;   
    unsigned int m, n, d; 
    
    // Check for proper number of arguments
    if (nrhs != 4) { 
        mexErrMsgTxt("Four input arguments required."); 
    } else if (nlhs !=1 && nlhs !=2 && nlhs !=3) {
        mexErrMsgTxt("The number of output arguments should be 1, 2, or 3."); 
    } 

    m = mxGetM(IM_IN); 
    n = mxGetN(IM_IN);

    if ((m != mxGetM(LABELS_IN)) || (n != mxGetN(LABELS_IN))) {
      mexErrMsgTxt("First and second arguments must have same size.");
    }

    if ((m != mxGetM(MASK_IN)) || (n != mxGetN(MASK_IN))) {
      mexErrMsgTxt("First and third arguments must have same size.");
    }

    if (! mxIsSingle(LABELS_IN)) {
      mexErrMsgTxt("First argument must be a single array.");
    }
    if (! mxIsSingle(IM_IN)) {
      mexErrMsgTxt("Second argument must be a single array.");
    }
    if (! mxIsLogical(MASK_IN)) {
      mexErrMsgTxt("Third argument must be a logical array.");
    }
    if (! mxIsSingle(NPLANES_IN)) {
      mexErrMsgTxt("Fourth argument must be a single.");
    }

    // Create matrices for the return arguments 
    //LABELS_OUT = mxCreateSingleMatrix(m, n, mxREAL);
    LABELS_OUT = mxCreateNumericMatrix(m, n, mxSINGLE_CLASS, mxREAL);
    //DISTANCES_OUT = mxCreateSingleMatrix(m, n, mxREAL);
    DISTANCES_OUT = mxCreateNumericMatrix(m, n, mxSINGLE_CLASS, mxREAL);

    // Assign pointers to the various parameters 
    labels_in = (float *)mxGetData(LABELS_IN);
    im_in = (float *)mxGetData(IM_IN);
    mask_in = mxGetLogicals(MASK_IN);
    d = (int)mxGetScalar(NPLANES_IN);
    n = n/d;
	  labels_out = (float *)mxGetData(LABELS_OUT);

    // Do the actual computations in a subroutine
    dists = (float *)mxGetData(DISTANCES_OUT);

	// Debug
	//mexPrintf("rows: %i\n", m);
	//mexPrintf("cols: %i\n", n);
	//mexPrintf("plns: %i\n", d);	
	
    propagate(labels_in, im_in, mask_in, labels_out, dists, m, n, d); 
    
    return;
}
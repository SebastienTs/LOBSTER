/*******************************************************************************
*
*       Name:                ibcenterline.c
*       Author:              K. Palagyi
*       Date:                14 November, 2013 
* 
*******************************************************************************/

/* include files */
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include <math.h>
  #include "ibcenterline.h"

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
  
/*===========================================================================
    function    m a i n
  ===========================================================================*/
int main(int argc, char *argv[])
  {

  /**********************/
  /* PARAMETER CHECKING */
  /**********************/
    if ( ! (argc==3) )
      {
        printf("\n USAGE:                                                   ");
        printf("\n   %s   inpname   outname ",argv[0]                        );
        printf("\n   where: - inpname  :   name of the input image          ");
        printf("\n                         containing the image data        ");
	printf("\n                         (without extension)              ");
        printf("\n          - outname  :   name of the output image         ");
        printf("\n                         storing the centerlines          ");
        printf("\n                         (without extension)              ");
        printf("\n\n");
        exit(0);
      } /* endif */


  /********************/
  /* READ INPUT IMAGE */
  /********************/
    read_image( argv[1] );

  /****************/
  /* READING LUTs */
  /****************/
    init_lut_simple();
    init_lut_isthmus();
    
  /************/  
  /* THINNING */
  /************/
    printf("\n Centerline extraction by sequential isthmus-based thinning ...");
    sequential_thinning();
    
  /********************/
  /* WRITE OUPUT IMAGE */
  /********************/
    write_image( argv[2] );
  
  /********/  
  /* FREE */
  /********/
    free(lut_simple);
    free(lut_isthmus);    
    free(image);

    printf("\n");	

    exit(0);
  };
/*===========================================================================
    end of function    m a i n
  ===========================================================================*/

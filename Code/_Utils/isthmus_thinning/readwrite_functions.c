/*******************************************************************************
*
*       Name:                readwrite_functions.c
*       Author:              K. Palagyi
*       Date:                14 November, 2013 
* 
*******************************************************************************/

/*========= function read_image =========*/
/* -------------
  considered global variables:
      NONE
  changed global variables:
      hdr
      size_x
      size_y
      size_z
      size_xy
      size_xyz
      image
----------------*/  
void read_image( char *inp_name )
{
  char file_name[300];
  FILE              *fp_inp_img;
  FILE              *fp_inp_hdr;
  short int          hdrshortint;
  unsigned long int  i, j, p, num;
  short int          perm;
  
  /* open IMG */
    strcpy(file_name, inp_name);
    strcat(file_name, ".img");
    if ( (fp_inp_img = fopen(file_name, "rb")) == NULL)
      {
        printf("ERROR: Can't open the input image data: %s!\n", file_name);
        exit(1);
      }
      
   /* open HDR */
    strcpy(file_name, inp_name);
    strcat(file_name, ".hdr" );
    if ( (fp_inp_hdr = fopen(file_name, "rb")) == NULL)
      {
        printf("ERROR: Can't open the input header %s!\n", file_name);
        exit(1);
      }
    
  /* read HDR */    
    if ( fread(&hdr, sizeof(analyze_hdr), 1, fp_inp_hdr) != 1 )
      {
        printf("ERROR: Couldn't read input header\n");
        exit(1);
      }
    fclose(fp_inp_hdr);
    
  /* set perm */  
    perm = 0;
    if ( hdr.sizeof_hdr != sizeof(analyze_hdr) )
      perm = 1;
      
  /* binary ? */    
    hdrshortint = hdr.bits;
    if ( perm ) 
      hdrshortint = ( hdrshortint<<8 ) | ( (hdrshortint>>8) & 0x00FF );
    if ( hdrshortint !=8 )
      {
        printf("ERROR: Cannot handle %d depth in image data \n", hdrshortint);
        exit(-1);
      }
      
  /* set dimensions */
    hdrshortint = hdr.x_dim;
    if ( perm ) 
      hdrshortint = ( hdrshortint<<8 ) | ( (hdrshortint>>8) & 0x00FF );
    size_x = (unsigned long int)hdrshortint;
    hdrshortint = hdr.y_dim;
    if ( perm ) 
      hdrshortint = ( hdrshortint<<8 ) | ( (hdrshortint>>8) & 0x00FF );
    size_y = (unsigned long int)hdrshortint;
    hdrshortint = hdr.z_dim;
    if ( perm ) 
      hdrshortint = ( hdrshortint<<8 ) | ( (hdrshortint>>8) & 0x00FF );
    size_z = (unsigned long int)hdrshortint;
    if ( size_z <= 1 )
      {
        printf("ERROR: The image data is not a real 3D one. Number of slices is %d \n", size_z);
        exit(-1);
      }  
     printf("\n Size of the input image: %d, %d, %d\n", size_x, size_y, size_z);
     
  /* add frame */
    size_x += 2;
    size_y += 2;
    size_z += 2;
      
  /* set slice- and image size */   
    size_xy  = size_x * size_y;
    size_xyz = size_xy * size_z;
    
  /* alloc image */
    image = (unsigned char *)malloc(size_xyz);
    if ( image == NULL )
      {
         printf("\n Alloc. error (image)");
         exit(0);
      }
      
  /* init image */
    for (i=0; i<size_xyz; i++)
      *(image +i) = 0;

  /* read image */ 
    p = size_xy + size_x + 1;
    for (i=1; i<size_z-1; i++)
      {
        for (j=1; j<size_y-1; j++)
          {
            if ( fread(image+p, 1, size_x-2, fp_inp_img) != (size_x-2) )
              {
                printf("ERROR: Couldn't read image data\n");
                exit(2);
              }
            p+=size_x;
          }
        p+=(2*size_x);
      }
    fclose(fp_inp_img);

  /* counting object points and set 1 */
    num = 0;
    for (i=0; i<size_xyz; i++)
      if ( *(image +i) )
        {
	  *(image +i) = 1;
          num++;
	}
    printf("\n Number of object points in the original image: %d\n", num);
    
}  
/*========= end of function read_image =========*/



/*========= function write_image =========*/
/* -------------
  considered global variables:
      hdr
      size_x
      size_y
      size_z
      size_xy
      size_xyz
  changed global variables:
      image 
----------------*/  
void write_image( char *out_name )
{
  char file_name[300];
  FILE              *fp_out_img;
  FILE              *fp_out_hdr;
  unsigned long int  i, j, p, num;
 
    
  /* open IMG */
    strcpy(file_name, out_name);
    strcat(file_name, ".img");
    if ( (fp_out_img = fopen(file_name, "wb")) == NULL)
      {
        printf("ERROR: Can't open the output image data: %s!\n", file_name);
        exit(1);
      }
      
  /* open HDR */
    strcpy(file_name, out_name);
    strcat(file_name, ".hdr" );
    if ( (fp_out_hdr = fopen(file_name, "wb")) == NULL)
      {
        printf("ERROR: Can't open the input header %s!\n", file_name);
        exit(1);
      }
    
  /* write HDR */    
    if ( fwrite(&hdr, sizeof(analyze_hdr), 1, fp_out_hdr) != 1 )
      {
        printf("ERROR: Couldn't read input header\n");
        exit(1);
      }
    fclose(fp_out_hdr);
    
  /* set non-zero to 255 */
    num=0;
    for (i=0; i<size_xyz; i++)
      if ( *(image +i) )
        {
          *(image +i) = 0xFF;
          num++;
        }
    printf("\n\n Number of object points in the skeleton: %d\n", num);
    
  /* write image */
    p = size_xy + size_x + 1;
    for (i=1; i<size_z-1; i++)
      {
        for (j=1; j<size_y-1; j++)
          {
            if ( fwrite(image+p, 1, size_x-2, fp_out_img) != (size_x-2) )
              {
                printf("ERROR: Couldn't write image data\n");
                exit(2);
              }
            p+=size_x;
          }
        p+=(2*size_x);
      }
    fclose(fp_out_img);
    
}  
/*========= end of function write_image =========*/


/*========= function set_long_mask =========*/
/* -------------
  considered global variables:
      NONE
  changed global variables:
      long_mask 
----------------*/  
void set_long_mask( void )
  {
    long_mask[ 0] = 0x00000001;
    long_mask[ 1] = 0x00000002;
    long_mask[ 2] = 0x00000004;
    long_mask[ 3] = 0x00000008;
    long_mask[ 4] = 0x00000010;
    long_mask[ 5] = 0x00000020;
    long_mask[ 6] = 0x00000040;
    long_mask[ 7] = 0x00000080;
    long_mask[ 8] = 0x00000100;
    long_mask[ 9] = 0x00000200;
    long_mask[10] = 0x00000400;
    long_mask[11] = 0x00000800;
    long_mask[12] = 0x00001000;
    long_mask[13] = 0x00002000;
    long_mask[14] = 0x00004000;
    long_mask[15] = 0x00008000;
    long_mask[16] = 0x00010000;
    long_mask[17] = 0x00020000;
    long_mask[18] = 0x00040000;
    long_mask[19] = 0x00080000;
    long_mask[20] = 0x00100000;
    long_mask[21] = 0x00200000;
    long_mask[22] = 0x00400000;
    long_mask[23] = 0x00800000;
    long_mask[24] = 0x01000000;
    long_mask[25] = 0x02000000;
  }
/*========= end of function set_char_mask =========*/


/*========= function set_char_mask =========*/
/* -------------
  considered global variables:
      NONE
  changed global variables:
      char_mask 
----------------*/  
void set_char_mask( void )
  {
    char_mask[0] = 0x01;
    char_mask[1] = 0x02;
    char_mask[2] = 0x04;
    char_mask[3] = 0x08;
    char_mask[4] = 0x10;
    char_mask[5] = 0x20;
    char_mask[6] = 0x40;
    char_mask[7] = 0x80;
  }
/*========= end of function set_long_mask =========*/


/*============= function init_lut_simple =============*/
/* -------------
  considered global variables:
      NONE
  changed global variables:
      lut_simple
      long_mask
      char_mask 
----------------*/  
void init_lut_simple( void )
{
  char  lutname [100];
  FILE  *lutfile;

  /* alloc lut_simple */
    lut_simple = (unsigned char *)malloc(0x00800000);
    if ( lut_simple == NULL)
      {
        printf("\n Alloc error!!!\n");
        exit(1);
      }  /* end if */ 

  /* open lutfile */
    strcpy( lutname, "lut_simple.dat");
    lutfile = fopen( lutname, "rb");
    if ( lutfile == NULL)
      {
        printf("\n\n file lut.dat is not found!!!\n");
        exit(1);
      }  /* end if */

  /* reading lutfile */
    fread( lut_simple, 1, 0x00800000, lutfile);
    fclose(lutfile);

  /* setting masks */
    set_long_mask();
    set_char_mask();

}
/*=========== end of function init_lut_simple ===========*/


/*============= function init_lut_isthmus =============*/
/* -------------
  considered global variables:
      NONE
  changed global variables:
      lut_isthmus
----------------*/  
void init_lut_isthmus( void )
{
  char  lutname [100];
  FILE  *lutfile;

  /* alloc lut_isthmus */
    lut_isthmus = (unsigned char *)malloc(0x00800000);
    if ( lut_isthmus == NULL)
      {
        printf("\n Alloc error!!!\n");
        exit(1);
      }  /* end if */ 

  /* open lutfile */
    strcpy( lutname, "lut_isthmus.dat");
    lutfile = fopen( lutname, "rb");
    if ( lutfile == NULL)
      {
        printf("\n\n file lut_isthmus.dat is not found!!!\n");
        exit(1);
      }  /* end if */

  /* reading lutfile */
    fread( lut_isthmus, 1, 0x00800000, lutfile);
    fclose(lutfile);

}
/*=========== end of function init_lut_isthmus ===========*/

/*******************************************************************************
*
*       Name:                thinning_functions.c
*       Author:              K. Palagyi
*       Date:                14 November, 2013 
*
*******************************************************************************/

/*==================================*/
/*========= list functions =========*/
/*==================================*/

void NewSurfaceVoxel(unsigned long int x,
                     unsigned long int y,
		     unsigned long int z) {
ListElement * LE;
	LE=(ListElement *)malloc(sizeof(ListElement));
	(*LE).x=x;
	(*LE).y=y;
	(*LE).z=z;
	(*LE).next=NULL;
	(*LE).prev=SurfaceVoxels.last;
	if (SurfaceVoxels.last!=NULL) (*((ListElement*)(SurfaceVoxels.last))).next=LE;
	SurfaceVoxels.last=LE;
	if (SurfaceVoxels.first==NULL) SurfaceVoxels.first=LE;
}

void RemoveSurfaceVoxel(ListElement * LE) {
ListElement * LE2;
	if (SurfaceVoxels.first==LE) SurfaceVoxels.first=(*LE).next;
	if (SurfaceVoxels.last==LE) SurfaceVoxels.last=(*LE).prev;
	if ((*LE).next!=NULL) {
		LE2=(ListElement*)((*LE).next);
		(*LE2).prev=(*LE).prev;
	}
	if ((*LE).prev!=NULL) {
		LE2=(ListElement*)((*LE).prev);
		(*LE2).next=(*LE).next;
	}
	free(LE);
}

void CreatePointList(PointList *s) {
	s->Head=NULL;
	s->Tail=NULL;
	s->Length=0;
}

void AddToList(PointList *s,Voxel e, ListElement * ptr) {
Cell * newcell;
	newcell=(Cell *)malloc(sizeof(Cell));
	newcell->v=e;
	newcell->ptr=ptr;
	newcell->next=NULL;
	if (s->Head==NULL) {
		s->Head=newcell;
		s->Tail=newcell;
		s->Length=1;
	}
	else {
		s->Tail->next=newcell;
		s->Tail=newcell;
		s->Length++;
	}
}

Voxel GetFromList(PointList *s, ListElement **ptr) {
Voxel R;    
Cell *tmp;
        R.i = -1;
        R.j = -1;
        R.k = -1;
	(*ptr)=NULL;
	if(s->Length==0) return R;
	else {
		R=s->Head->v;
		(*ptr)=s->Head->ptr;
		tmp=(Cell *)s->Head->next;
		free(s->Head);
		s->Head=tmp;
		s->Length--;
		if(s->Length==0) {
			s->Head=NULL;
			s->Tail=NULL;
		}
		return R;
	}
}

void DestroyPointList(PointList *s) {
ListElement * ptr;
	while(s->Length>0) GetFromList(s, &ptr);
}

void CollectSurfaceVoxels(void) {
unsigned long int x,y,z;

  SurfaceVoxels.first = NULL;
  SurfaceVoxels.last  = NULL;

  for( z=1, z_size_xy=size_xy;
       z<size_z-1;
       z++, z_size_xy+=size_xy )
    {
      zm_size_xy = z_size_xy - size_xy;
      zp_size_xy = z_size_xy + size_xy;
      for( y=1, y_size_x=size_x;
           y<size_y-1;
           y++, y_size_x+=size_x )
        {
          ym_size_x  = y_size_x - size_x;
          yp_size_x  = y_size_x + size_x;
          for(x=1; x<size_x-1; x++)
            if ( *(image + x + y_size_x + z_size_xy ) )
              {
                if (  ( *(image +   x + ym_size_x +  z_size_xy ) ==0 ) ||
                      ( *(image +   x + yp_size_x +  z_size_xy ) ==0 ) ||
                      ( *(image +   x +  y_size_x + zm_size_xy ) ==0 ) ||
                      ( *(image +   x +  y_size_x + zp_size_xy ) ==0 ) ||
                      ( *(image + x+1 +  y_size_x +  z_size_xy ) ==0 ) ||
                      ( *(image + x-1 +  y_size_x +  z_size_xy ) ==0 )    )
                   {
                      *(image + x + y_size_x + z_size_xy ) = 2;
                      NewSurfaceVoxel(x,y,z);
                   } /* endif */
              } /* endif */
        } /* endfor y */
    } /* endfor z */

}

/*===============================================================*/
/*========= functions concerning topological properties =========*/
/*===============================================================*/

/*========= function collect_26_neighbours =========*/
void collect_26_neighbours(unsigned long int x,
                           unsigned long int y,
                           unsigned long int z )
  {
    /*
      indices in "neighbours":
      0  1  2     9 10 11     17 18 19    y-1
      3  4  5    12    13     20 21 22     y
      6  7  8    14 15 16     23 24 25    y+1
     x-1 x x+1   x-1 x x+1    x-1 x x+1
        z-1          z           z+1 
    */

    z_size_xy  = z*size_xy;
    zm_size_xy = z_size_xy - size_xy;
    zp_size_xy = z_size_xy + size_xy;
    y_size_x   = y*size_x;
    ym_size_x  = y_size_x  - size_x;
    yp_size_x  = y_size_x  + size_x;

    neighbours = 0x00000000;

    if ( *(image + x-1 + ym_size_x + zm_size_xy ) )
        neighbours |= long_mask[ 0];
    if ( *(image +   x + ym_size_x + zm_size_xy ) )
        neighbours |= long_mask[ 1];
    if ( *(image + x+1 + ym_size_x + zm_size_xy ) )
        neighbours |= long_mask[ 2];
    if ( *(image + x-1 +  y_size_x + zm_size_xy ) )
        neighbours |= long_mask[ 3];
    if ( *(image +   x +  y_size_x + zm_size_xy ) )
        neighbours |= long_mask[ 4];
    if ( *(image + x+1 +  y_size_x + zm_size_xy ) )
        neighbours |= long_mask[ 5];
    if ( *(image + x-1 + yp_size_x + zm_size_xy ) )
        neighbours |= long_mask[ 6];
    if ( *(image +   x + yp_size_x + zm_size_xy ) )
        neighbours |= long_mask[ 7];
    if ( *(image + x+1 + yp_size_x + zm_size_xy ) )
        neighbours |= long_mask[ 8];

    if ( *(image + x-1 + ym_size_x +  z_size_xy ) )
        neighbours |= long_mask[ 9];
    if ( *(image +   x + ym_size_x +  z_size_xy ) )
        neighbours |= long_mask[10];
    if ( *(image + x+1 + ym_size_x +  z_size_xy ) )
        neighbours |= long_mask[11];
    if ( *(image + x-1 +  y_size_x +  z_size_xy ) )
        neighbours |= long_mask[12];
    if ( *(image + x+1 +  y_size_x +  z_size_xy ) )
        neighbours |= long_mask[13];
    if ( *(image + x-1 + yp_size_x +  z_size_xy ) )
        neighbours |= long_mask[14];
    if ( *(image +   x + yp_size_x +  z_size_xy ) )
        neighbours |= long_mask[15];
    if ( *(image + x+1 + yp_size_x +  z_size_xy ) )
        neighbours |= long_mask[16];

    if ( *(image + x-1 + ym_size_x + zp_size_xy ) )
        neighbours |= long_mask[17];
    if ( *(image +   x + ym_size_x + zp_size_xy ) )
        neighbours |= long_mask[18];
    if ( *(image + x+1 + ym_size_x + zp_size_xy ) )
        neighbours |= long_mask[19];
    if ( *(image + x-1 +  y_size_x + zp_size_xy ) )
        neighbours |= long_mask[20];
    if ( *(image +   x +  y_size_x + zp_size_xy ) )
        neighbours |= long_mask[21];
    if ( *(image + x+1 +  y_size_x + zp_size_xy ) )
        neighbours |= long_mask[22];
    if ( *(image + x-1 + yp_size_x + zp_size_xy ) )
        neighbours |= long_mask[23];
    if ( *(image +   x + yp_size_x + zp_size_xy ) )
        neighbours |= long_mask[24];
    if ( *(image + x+1 + yp_size_x + zp_size_xy ) )
        neighbours |= long_mask[25];

  }
/*========= end of function collect_26_neighbours =========*/


/*========= function simple_26_6 =========*/
int simple_26_6( void )
{
  return ( ( *(lut_simple + (neighbours>>3) ) ) & char_mask[neighbours%8]);
}
/*========= end of function simple_26_6 =========*/


/*========= function isthmus =========*/
int isthmus( void )	      
{
  return ( ( *(lut_isthmus + (neighbours>>3) ) ) & char_mask[neighbours%8]);
}
/*========= end of function isthmus =========*/


/*=========== function DetectSimpleBorderPoints ===========*/
void DetectSimpleBorderPoints(PointList *s) {
unsigned char value;
Voxel v;
ListElement * LE3;
unsigned long int x, y, z, num;

  LE3=(ListElement *)SurfaceVoxels.first;			
  while (LE3!=NULL)
    {
      x         = (*LE3).x;
      y         = (*LE3).y;
      z         = (*LE3).z;
      y_size_x  = y*size_x;
      z_size_xy = z*size_xy;           
      if ( *(image + x + y_size_x + z_size_xy) == 2 )   /* not an isthmus */
        {
          ym_size_x  = y_size_x  - size_x;
          yp_size_x  = y_size_x  + size_x;
          zm_size_xy = z_size_xy - size_xy;
          zp_size_xy = z_size_xy + size_xy;
          switch( direction )
            {
              case U: value = *(image + x   + ym_size_x + z_size_xy  );
                      break;
              case D: value = *(image + x   + yp_size_x + z_size_xy  );
                      break;
              case N: value = *(image + x   + y_size_x  + zm_size_xy );
                      break;
              case S: value = *(image + x   + y_size_x  + zp_size_xy );
                      break;
              case E: value = *(image + x+1 + y_size_x  + z_size_xy  );
                      break;
              case W: value = *(image + x-1 + y_size_x  + z_size_xy  );
                      break;
            } /* endswitch */
          if( value == 0 )
            {
	      collect_26_neighbours(x,y,z); 
              if ( simple_26_6() )
                {
                  v.i = x;
                  v.j = y;
                  v.k = z;
                  AddToList(s,v,LE3);
                } /* endif */
               else
	        {
	           if ( isthmus() )
	             {
		       *(image + x + y_size_x + z_size_xy) = 3;
        	     }  /* endif */
		}  /* endelse */
            } /* endif */    
        } /* endif */
      LE3=(ListElement *)(*LE3).next;
    } /* endwhile */

}
/*=========== end of function DetectSimpleBorderPoints ===========*/


/*========= function thinning_iteration_step =========*/
unsigned int thinning_iteration_step(void)
{
  unsigned long int changed;
  ListElement *ptr;
  PointList s;
  Voxel v;
 
  changed = 0;
  for ( direction=0; direction<6; direction++ )
    {
      CreatePointList(&s);
      DetectSimpleBorderPoints(&s);
      while ( s.Length > 0 )
        {
           v = GetFromList( &s, &ptr );	
	   collect_26_neighbours( v.i, v.j, v.k ); 	      
           if ( simple_26_6() )
             {
               z_size_xy = (v.k)*size_xy;
               y_size_x  = (v.j)*size_x;		 
               *(image + v.i + y_size_x + z_size_xy ) = 0; /* simple point is deleted */    
               changed ++;
               /* investigating v's 6-neighbours */
               if (*(image + v.i-1 + y_size_x + z_size_xy                )==1)
                 {
                   NewSurfaceVoxel( v.i-1, v.j  , v.k   );
                   *(image + v.i-1 + y_size_x + z_size_xy                ) = 2;
                 }
               if (*(image + v.i+1 + y_size_x        + z_size_xy         )==1)
                 {
                   NewSurfaceVoxel( v.i+1, v.j  , v.k   );
                   *(image + v.i+1 + y_size_x        + z_size_xy         ) = 2;
                 }
               if (*(image + v.i   + y_size_x-size_x + z_size_xy         )==1)
                 {
                   NewSurfaceVoxel( v.i  , v.j-1, v.k   );
                   *(image + v.i   + y_size_x-size_x + z_size_xy         ) = 2;
                 }
               if (*(image + v.i   + y_size_x+size_x + z_size_xy         )==1)
                 {
                   NewSurfaceVoxel( v.i  , v.j+1, v.k   );
                   *(image + v.i   + y_size_x+size_x + z_size_xy         ) = 2;
                 }
               if (*(image + v.i   + y_size_x        + z_size_xy-size_xy )==1)
                 {
                   NewSurfaceVoxel( v.i  , v.j  , v.k-1 );
                   *(image + v.i   + y_size_x        + z_size_xy-size_xy ) = 2;
                 }
               if (*(image + v.i   + y_size_x        + z_size_xy+size_xy )==1)
                 {
                   NewSurfaceVoxel( v.i  , v.j  , v.k+1 );
                   *(image + v.i   + y_size_x        + z_size_xy+size_xy ) = 2;
                 }
               RemoveSurfaceVoxel(ptr);
             } /* endif */
        } /* endwhile */
      DestroyPointList(&s);
    } /* endfor */

  return changed;
}
/*========= end of function thinning_iteration_step =========*/

/*========= function sequential_thinning =========*/
void sequential_thinning(void)
{
  unsigned int iter, changed;

  CollectSurfaceVoxels();

  iter = 0;
  changed = 1;
  while ( changed )
    {
      changed = thinning_iteration_step();
      iter++;
      //printf("\n  iteration step: %3d.    (deleted point(s): %6d)",
      //       iter, changed );     
    }

}
/*========= end of function sequential_thinning =========*/

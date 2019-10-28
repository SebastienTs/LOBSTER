/* ordering of deletion directions - DON'T MODIFY THEM */
  #define U                  0
  #define D                  1
  #define N                  2
  #define S                  3
  #define E                  4
  #define W                  5

/* types */
  typedef struct{
        int             sizeof_hdr;
        char            pad1[28];
        int             extents;
        char            pad2[2];
        char            regular;
        char            pad3;
        short int       dims;
        short int       x_dim;
        short int       y_dim;
        short int       z_dim;
        short int       t_dim;
        char            pad4[20];
        short int       datatype;
        short int       bits;
        char            pad5[6];
        float           x_size;
        float           y_size;
        float           z_size;
        char            pad6[48];
        int             glmax;
        int             glmin;
        char            descrip[80];
        char            pad7[120];
  } analyze_hdr;

  typedef struct {
        unsigned long int x,y,z;
        void *next;
        void *prev;
  } ListElement;

  typedef struct {
        void *first;
        void *last;
  } List;
 
  typedef struct {
        long i, j, k;
  } Voxel;

  typedef struct {
        Voxel v;
        ListElement * ptr;
        void *next;
  } Cell;

  typedef struct {
        Cell *Head;
        Cell *Tail;
        int Length;
  } PointList;

  typedef struct {
        ListElement *first;
        ListElement *last;
  } DoubleList;

  typedef struct {
        unsigned long int x, y, z;
        void             *next;
  } Bordercell; 

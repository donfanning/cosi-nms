
#include <stdio.h>
#include <stdlib.h>

void main( int argc, char *argv[] )
{
	int i;
	int	k;
	if( argc != 2 ) {
		printf("\nUsage: %s 100", argv[0] );
		exit(1);
	}
	k = atoi(argv[1]);
	for( i=0; i<1024*k; i++ )
		printf("W");
}

#include <stdio.h>
#include <stdlib.h>
//#include <iostream>
#include "flute.h"

//using namespace std;

int main()
{
    int d=0;
    int x[MAXD], y[MAXD];
    Tree flutetree;
    int flutewl;
    printf("FLUTE 3.1\n");
        
    while (!feof(stdin)) {
        scanf("%d %d\n", &x[d], &y[d]);
        d++;
    }
    readLUT();

    flutetree = flute(d, x, y, ACCURACY);
    printf("FLUTE wirelength = %d\n", flutetree.length);

    flutewl = flute_wl(d, x, y, ACCURACY);
    printf("FLUTE wirelength (without RSMT construction) = %d\n", flutewl);
}

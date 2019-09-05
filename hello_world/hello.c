#include <stdio.h>

int func(int);

int main(int argc, char *argv[])
{
    int r;
    
    printf("H ");
    printf("e ");
    printf("l ");
    printf("l ");
    printf("o     ");
    r = func(0);
    printf("Called func which returned %d", r);
}

int func(int x)
    {
        printf("W ");
        printf("o ");
        printf("r ");
        printf("l ");
        printf("d! \n");
        return 0;
    }

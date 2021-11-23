#include "io.h"
int x = 1;
int y = 1;
int main() {
    for (int i = 0; i < 2; i++)
    {
        outl(x+y*i);
    }
}
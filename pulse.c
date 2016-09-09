#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#define NPERIOD 3
#define Fs 44100
#define FUND 400
#define PERIOD (Fs / FUND)
#define NHARMONIC 6

void pulse(float width)
{
    FILE *f = fopen("/tmp/foo", "w");
    if (!f) {
        perror("/tmp/foo");
        exit(1);
    }

    float T = 1.0f / (float)FUND;
    float tau = width * T;
    for (int i = 0; i < NPERIOD * PERIOD; i++) {
        float t = (float)i / (float)Fs;
        float y = tau / T;
        for (int n = 1; n <= NHARMONIC; n++) {
            y += ((2 / (n * M_PI)) *
                  sinf(M_PI * n * tau / T) *
                  cosf((2 * M_PI * n) / T * t));
        }            
        // y = (1.5 + width) * y - 2 * width;
        fprintf(f, "%g\n", y);
    }

    fprintf(f, "end\n");
    fclose(f);
}

int main()
{
    pulse(0.10);
    return 0;
}

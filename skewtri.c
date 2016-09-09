#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define NPERIOD 3
#define Fs 44100
#define FUND 4
#define PERIOD (Fs / FUND)
#define NHARMONIC 4

// sum(n=1..+inf: 1/(1+2n)**2) - (pi**2 - 8) / 8

// sum from n=1 to infinity of 1/n**2 * sin(n*tau)*sin(n*tau/2)

FILE *f = NULL;

void begin(void)
{
    assert(!f);
    f = fopen("/tmp/foo", "w");
    if (!f) {
        perror("/tmp/foo");
        exit(1);
    }
}

void emit(float y)
{
    assert(f);
    fprintf(f, "%g\n", y);
}

void end(void)
{
    assert(f);
    fprintf(f, "end\n");
    fclose(f);
    f = NULL;
}

float skscale(float width, int h1, int hn)
{
    assert(1 <= h1);
    assert(h1 <= hn);
    float T = 1.0f / (float)FUND;
    float tau = width * T;
    float h = 0.0;
    float phase = fmaxf(tau/T/2, M_PI/2*T/hn);
    for (int n = h1; n <= hn; n++) {
        float c0 = 1.0 / n / n;
        float c1 = sinf((M_PI * n) * tau/T);
        float c2 = sinf((2 * M_PI * n) * phase);
        h += c0 * c1 * c2;
    }
    float scale = 1.0 / h;
    return scale;
}

void skewtri(float width)
{
    float T = 1.0f / (float)FUND;
    float tau = width * T;
    float scale = skscale(width, 1, NHARMONIC);
    for (int i = 0; i < NPERIOD * PERIOD; i++) {
        float t = (float)i / (float)Fs;
        float y = 0;
        for (int n = 1; n <= NHARMONIC; n++) {
            y += ( (1.0 / n / n) *
                  sinf(M_PI * n * tau / T) *
                  sinf((2 * M_PI * n) / T * t));
        }            
        y *= scale;
        emit(y);
    }
}

int main()
{
    // begin();
    // for (int i = 1; i < 50; i++) {
    //     float width = i * 0.01;
    //     float y = skscale(width, 1, 4) / skscale(width, 1, 1000);
    //     emit(y);
    // }
    // end();
    // printf("w=0.01, s6 = %g, s1000 = %g\n",
    //        skscale(0.01, 1, 1000), skscale(0.01, 1, 6));

    begin();
    skewtri(0.01);
    skewtri(0.12);
    skewtri(0.25);
    skewtri(0.50);
    end();

    assert(!f);
    return 0;
}

/*
 * sushi.c — a rotating torus rendered as ASCII/sushi glyphs,
 * in the spirit of Andy Sloane's donut.c.
 *
 * Build:  cc -O2 -o sushi_donut sushi_donut.c -lm
 * Run:    ./sushi_donut
 * Quit:   Ctrl-C
 *
 * How it works, in short:
 *   - A torus is defined parametrically by two angles: theta (around the
 *     tube) and phi (around the donut). Sweeping both gives every point
 *     on its surface.
 *   - Each point is rotated in 3D by angles A and B (spinning the donut),
 *     then projected onto a 2D screen using simple perspective divide
 *     (further points get squashed toward the center, closer points
 *     spread out — that's the `ooz` = "one over z" term).
 *   - A single fixed light source gives each point a brightness value
 *     via its surface normal (dot product with the light direction).
 *   - Brightness picks a character from a ramp; a z-buffer keeps only
 *     the nearest point per screen cell so the donut occludes itself.
 */

#include <math.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define COLS 80
#define ROWS 24

/* brightness ramp, darkest to brightest. swap this for plain ASCII if
 * your terminal font doesn't have the sushi glyph. */
static const char *ramp = " .:-=+*#%@";
/* static const char *ramp = " .,-~:;=!*#$@"; // classic donut.c ramp */

int main(void) {
    float A = 0, B = 0;
    char output[COLS * ROWS];
    float zbuffer[COLS * ROWS];

    /* K2: distance from the viewer to the torus center.
     * K1: screen-space scale, derived so the donut fills the terminal. */
    const float K2 = 5;
    const float K1 = COLS * K2 * 3 / (8 * (2 + 1));

    printf("\x1b[2J");              /* clear screen once */
    printf("\x1b[?25l");            /* hide cursor */

    for (;;) {
        memset(output, ' ', sizeof(output));
        memset(zbuffer, 0, sizeof(zbuffer));

        for (float theta = 0; theta < 2 * M_PI; theta += 0.07) {
            float costheta = cosf(theta), sintheta = sinf(theta);

            for (float phi = 0; phi < 2 * M_PI; phi += 0.02) {
                float cosphi = cosf(phi), sinphi = sinf(phi);

                float cA = cosf(A), sA = sinf(A);
                float cB = cosf(B), sB = sinf(B);

                /* point on the tube circle (radius 1), offset from the
                 * ring center (radius 2) */
                float circlex = 2 + costheta;
                float circley = sintheta;

                /* rotate by A around the x-axis, then by B around the
                 * z-axis, then push out to distance K2 from the viewer */
                float x = circlex * (cB * cosphi + sA * sB * sinphi) - circley * cA * sB;
                float y = circlex * (sB * cosphi - sA * cB * sinphi) + circley * cA * cB;
                float z = K2 + cA * circlex * sinphi + circley * sA;
                float ooz = 1 / z;

                int xp = (int)(COLS / 2 + K1 * ooz * x);
                int yp = (int)(ROWS / 2 - K1 * ooz * y * 0.5f); /* chars are ~2x taller than wide */

                /* surface normal, rotated the same way as the point,
                 * used to compute how much light this patch catches */
                float nx = costheta * cB * cosphi + sintheta * sA * sB * sinphi - sintheta * cA * sB;
                float ny = costheta * (sB * cosphi - sA * cB * sinphi) + sintheta * cA * cB;
                float nz = cA * costheta * sinphi + sintheta * sA;

                float L = nx * 0 + ny * 1 - nz * 0.7f; /* fixed light, roughly above-behind viewer */

                if (L > 0 && xp >= 0 && xp < COLS && yp >= 0 && yp < ROWS) {
                    int idx = xp + yp * COLS;
                    if (ooz > zbuffer[idx]) {
                        zbuffer[idx] = ooz;
                        int lum = (int)(L * (strlen(ramp) - 1));
                        if (lum < 0) lum = 0;
                        if (lum >= (int)strlen(ramp)) lum = strlen(ramp) - 1;
                        output[idx] = ramp[lum];
                    }
                }
            }
        }

        printf("\x1b[H");  /* cursor home, no clear — avoids flicker */
        for (int row = 0; row < ROWS; row++) {
            fwrite(&output[row * COLS], 1, COLS, stdout);
            putchar('\n');
        }
        printf("sushi linux  //  spinning torus  //  ^C to exit\n");
        fflush(stdout);

        A += 0.06f;
        B += 0.025f;
        usleep(25000); /* ~40fps */
    }

    return 0;
}

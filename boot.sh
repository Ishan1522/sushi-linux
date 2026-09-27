#!/bin/sh
# sushi linux — boot splash
#
#   curl -fsSL https://raw.githubusercontent.com/<you>/sushi-linux/main/boot.sh | sh
#
# Compiles sushi_donut.c on the fly (it's embedded below via heredoc) and
# runs it. Falls back to a plain printf banner if no C compiler is found,
# so the curl-and-pipe gag never just errors out on someone's machine.

set -e

BANNER='
   _____ __  _______  ____  ____
  / ___// / / / ___/ / __ \/ __ \
  \__ \/ /_/ /\__ \ / / / / /_/ /
 ___/ / __  /___/ // /_/ / _, _/
/____/_/ /_//____(_)____/_/ |_|

      L  I  N  U  X            booting...
'

printf '%s\n' "$BANNER"
sleep 0.4

CC="$(command -v cc || command -v gcc || command -v clang || true)"

if [ -z "$CC" ]; then
  echo "no C compiler found — printing a static plate instead:"
  echo ""
  echo "        .-\"\"\"\"\"-."
  echo "      .'  o  o    '."
  echo "     :   rice bed   :        sushi linux"
  echo "      '.  ~nori~  .'         (install gcc/clang for the real boot animation)"
  echo "        '-.....-'"
  exit 0
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

cat > "$WORKDIR/sushi_donut.c" <<'DONUT_C_EOF'
#include <math.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define COLS 80
#define ROWS 24

static const char *ramp = " .:-=+*#%@";

int main(void) {
    float A = 0, B = 0;
    char output[COLS * ROWS];
    float zbuffer[COLS * ROWS];
    const float K2 = 5;
    const float K1 = COLS * K2 * 3 / (8 * (2 + 1));
    int frames = 0;

    printf("\x1b[2J");
    printf("\x1b[?25l");

    for (;;) {
        memset(output, ' ', sizeof(output));
        memset(zbuffer, 0, sizeof(zbuffer));

        for (float theta = 0; theta < 2 * M_PI; theta += 0.07) {
            float costheta = cosf(theta), sintheta = sinf(theta);
            for (float phi = 0; phi < 2 * M_PI; phi += 0.02) {
                float cosphi = cosf(phi), sinphi = sinf(phi);
                float cA = cosf(A), sA = sinf(A);
                float cB = cosf(B), sB = sinf(B);

                float circlex = 2 + costheta;
                float circley = sintheta;

                float x = circlex * (cB * cosphi + sA * sB * sinphi) - circley * cA * sB;
                float y = circlex * (sB * cosphi - sA * cB * sinphi) + circley * cA * cB;
                float z = K2 + cA * circlex * sinphi + circley * sA;
                float ooz = 1 / z;

                int xp = (int)(COLS / 2 + K1 * ooz * x);
                int yp = (int)(ROWS / 2 - K1 * ooz * y * 0.5f);

                float nx = costheta * cB * cosphi + sintheta * sA * sB * sinphi - sintheta * cA * sB;
                float ny = costheta * (sB * cosphi - sA * cB * sinphi) + sintheta * cA * cB;
                float nz = cA * costheta * sinphi + sintheta * sA;

                float L = nx * 0 + ny * 1 - nz * 0.7f;

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

        printf("\x1b[H");
        for (int row = 0; row < ROWS; row++) {
            fwrite(&output[row * COLS], 1, COLS, stdout);
            putchar('\n');
        }
        printf("sushi linux  //  spinning torus  //  ^C to exit\n");
        fflush(stdout);

        A += 0.06f;
        B += 0.025f;
        frames++;
        if (frames > 600) break; /* auto-stop after ~15s when piped/curled */
        usleep(25000);
    }

    printf("\x1b[?25h");
    return 0;
}
DONUT_C_EOF

"$CC" -O2 -o "$WORKDIR/sushi_donut" "$WORKDIR/sushi_donut.c" -lm 2>/dev/null
exec "$WORKDIR/sushi_donut"

#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

int main(int argc, char *argv[]) {

    if (argc != 4) {
        printf("Se deben pasar 3 argumentos: ITER, N, y el nombre del fichero.\n");
        return 1;
    }

    int ITER = atoi(argv[1]);
    int N = atoi(argv[2]);

    FILE *fp;
    char filename[50];
    sprintf(filename, "plot/%s_data.txt", argv[3]); // construye el nombre del archivo
    fp = fopen(filename, "a");

    struct timeval start, end;
    gettimeofday(&start, NULL);

    int i, j;
    float a, b, c, d, e, t, u, v = 2, x, y, z;
    for (j = 0; j < ITER; j++) {
        for (i = 0; i < N; i++) {
            x = i + 1.1;
            y = j + x;
            b = 1 / (x * y);
            a = y * b;
            c = x * b;
            d = v * b;
            e = 2 * d;
        }
    }

    gettimeofday(&end, NULL);
    double elapsed_time = (end.tv_sec - start.tv_sec) + (end.tv_usec - start.tv_usec) / 1000000.0;

    printf("Tiempo total: %f segundos\n", elapsed_time);
    printf("Tiempo medio por iteración: %f segundos\n", elapsed_time / (ITER * N));
    printf("Tiempo medio por iteración del bucle N: %f segundos\n", elapsed_time / ITER);
    printf("Valor final de las variables:\n");
    printf("a: %f\n", a);
    printf("b: %f\n", b);
    printf("c: %f\n", c);
    printf("d: %f\n", d);
    printf("e: %f\n", e);
    printf("-----------------------------------------------------\n");

    fprintf(fp, "%d %d %f\n", j, i, elapsed_time);
    fclose(fp);

    return 0;
}

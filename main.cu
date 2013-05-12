#include <stdio.h>
#include <stdlib.h>
#include "squarematrix.h"
#include "elimination_gold.h"
#include "elimination_kernel.h"

// Matrix size
#define N 6

int main() {
	float a[] = {
			1.00, 0.00, 0.00, 0.00, 0.00, 0.00,
			1.00, 0.63, 0.39, 0.25, 0.16, 0.10,
			1.00, 1.26, 1.58, 1.98, 2.49, 3.13,
			1.00, 1.88, 3.55, 6.70, 6.62, 3,80,
			1.00, 2.51, 6.32, 5.88, 9.90, 0.28,
			1.00, 3.14, 9.87, 3.01, 9.41, 6.02
	};
	float b[] = {
			0.01, 0.61, 0.91, 0.99, 0.60, 0.02
	};
	float x[N];

	elimination_gold(a, b, x, N);

	for (unsigned int i = 0; i < N; i++)

	return 0;
}

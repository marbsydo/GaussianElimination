#include "elimination_kernel.h"

// Used by kernel 5
#define BLOCK_SIZE 16

// Used by kernels 13, 14 & 15
#define ELEMENTS_PER_THREAD 1

float elimination_kernel(float *a, float *b, int size, int kernel) {
	// Start timers
	check("Creating timers");
	cudaEvent_t timer1, timer2;
	cudaEventCreate(&timer1);
	cudaEventCreate(&timer2);
	cudaEventRecord(timer1, 0);

	// Copy data to GPU
	int sizeTotal = (size + 1) * size;
	float *g_a, *g_b;

	if (kernel < 8) {
		check("Allocating memory g_a");
		cudaMalloc((void**)&g_a, sizeTotal * sizeof(float));
		check("Allocating memory g_b");
		cudaMalloc((void**)&g_b, sizeTotal * sizeof(float));

		// Copy a to g_a which the device will use for reference
		check("Copying memory from host to device");
		cudaMemcpy(g_a, a, sizeTotal * sizeof(float), cudaMemcpyHostToDevice);
	} else {
		check("Allocating memory g_b");
		cudaMalloc((void**)&g_b, sizeTotal * sizeof(float));

		// Copy a to g_b which the device will modify in place
		check("Copying memory from host to device");
		cudaMemcpy(g_b, a, sizeTotal * sizeof(float), cudaMemcpyHostToDevice);
	}
	check("Copied memory from host to device");

	dim3 dimBlock(1,1,1);
	dim3 dimGrid(1,1,1);

	// Memory used for debugging
	float *c = (float*) malloc(sizeTotal * sizeof(float));

	// Execute kernel on GPU
	check("Executing kernel on GPU");
	switch (kernel) {
	case 0:
		elimination0<<<dimGrid, dimBlock>>>(g_a, g_b, size);
		break;
	case 1:
		dimBlock.x = size + 1;
		elimination1<<<dimGrid, dimBlock>>>(g_a, g_b, size);
		break;
	case 2:
		dimBlock.x = size + 1;
		dimBlock.y = size;
		elimination2<<<dimGrid, dimBlock>>>(g_a, g_b, size);
		break;
	case 3:
		dimBlock.x = size + 1;
		dimBlock.y = size;
		elimination3<<<dimGrid, dimBlock>>>(g_a, g_b, size);
		break;
	case 4:
		dimBlock.x = size + 1;
		dimBlock.y = size;
		elimination4<<<dimGrid, dimBlock>>>(g_a, g_b, size);
		break;
	case 5:
		dimBlock.x = BLOCK_SIZE;
		dimBlock.y = BLOCK_SIZE;
		dimGrid.x = 1;
		dimGrid.y = 1;
		//dimGrid.x = (size + 1 - 1) / BLOCK_SIZE + 1;
		//dimGrid.y = (size - 1) / BLOCK_SIZE + 1;
		elimination5<<<dimGrid, dimBlock>>>(g_a, g_b, size);
		break;
	case 6:
		dimBlock.x = size + 1;
		dimBlock.y = size;
		elimination6<<<dimGrid, dimBlock>>>(g_a, g_b, size, 0);
		for (unsigned int i = 1; i < size; i++) {
			cudaMemcpy(c, g_b, sizeTotal * sizeof(float), cudaMemcpyDeviceToHost);
			printf("Debug %d:\n", i);
			elimination_gold_print_matrix(c, size);
			elimination6<<<dimGrid, dimBlock>>>(g_b, g_b, size, i);
		}
		break;
	case 7:
		printf("Performing 7\n");
		// Each block represents one row
		// Blocks are tiled vertically
		dimBlock.x = size + 1; // Max of 512 threads per block
		dimGrid.x = size;

		elimination7<<<dimGrid, dimBlock>>>(g_a, g_b, size, 0);
		for (unsigned int i = 1; i < size; i++) {
			cudaMemcpy(c, g_b, sizeTotal * sizeof(float), cudaMemcpyDeviceToHost);
			printf("Debug %d:\n", i);
			elimination_gold_print_matrix(c, size);
			elimination7<<<dimGrid, dimBlock>>>(g_b, g_b, size, i);
		}
		break;
	case 8:
		dimBlock.x = size + 1;
		dimBlock.y = size;

		for (unsigned int i = 0; i < size; i++)
			elimination8_1<<<dimGrid, dimBlock>>>(g_b, size, i);
		elimination8_2<<<dimGrid, dimBlock>>>(g_b, size);
		break;
	case 9:
		dimBlock.x = size + 1;
		dimBlock.y = size;

		elimination9<<<dimGrid, dimBlock>>>(g_b, size);
		break;
	case 10:
		dimBlock.x = size + 1;
		dimBlock.y = size;

		elimination10<<<dimGrid, dimBlock>>>(g_b, size);
		break;
	case 11:

		// First stage requires 2 dimensions of tiles
		dimBlock.x = BLOCK_SIZE;
		dimBlock.y = BLOCK_SIZE;
		dimGrid.x = (size + 1 - 1) / BLOCK_SIZE + 1;
		dimGrid.y = (size - 1) / BLOCK_SIZE + 1;

		char buffer[50];

		for (int pivot = 0; pivot < size; pivot++) {
			elimination11_1<<<dimGrid, dimBlock>>>(g_b, size, pivot);
			//cudaDeviceSynchronize();

			sprintf(buffer, "Launched elimination11_1 kernel (pivot = %d)", pivot);
			check(buffer);
		}

		// Second stage requires only 1 dimension of tiles
		dimBlock.y = 1;
		dimGrid.y = 1;

		elimination11_2<<<dimGrid, dimBlock>>>(g_b, size);
		check("Launched elimination11_2 kernel");
		break;
	case 12:

		// Each block consists of a row of 512
		dimBlock.x = 512;
		dimBlock.y = 1;
		dimGrid.x = (size + 1 - 1) / dimBlock.x + 1;
		dimGrid.y = (size - 1) / dimBlock.y + 1;

		for (int pivot = 0; pivot < size; pivot++) {
			elimination12_1<<<dimGrid, dimBlock>>>(g_b, size, pivot);
			elimination12_2<<<dimGrid, dimBlock>>>(g_b, size, pivot);
		}

		break;
	case 13:

		// Each block consists of a row of 512
		dimBlock.x = 512;
		dimBlock.y = 1;
		dimGrid.x = (size + 1 - 1) / dimBlock.x + 1;
		dimGrid.y = (size - 1) / dimBlock.y + 1;

		for (int pivot = 0; pivot < size; pivot++) {
			elimination13_1<<<dimGrid, dimBlock>>>(g_b, size, pivot);
			elimination13_2<<<dimGrid, dimBlock>>>(g_b, size, pivot);
		}

		break;
	case 14:

		// Each block consists of a row of 512
		dimBlock.x = 512;
		dimBlock.y = 1;
		dimGrid.x = (size + 1 - 1) / dimBlock.x + 1;
		dimGrid.y = (size - 1) / dimBlock.y + 1;

		for (int pivot = 0; pivot < size; pivot++) {
			elimination14_1<<<dimGrid, dimBlock>>>(g_b, size, pivot);
			elimination14_2<<<dimGrid, dimBlock>>>(g_b, size, pivot);
		}

		break;
	case 15:

		// Each block consists of a row of 512
		dimBlock.x = 512;
		dimBlock.y = 1;
		dimGrid.x = (size + 1 - 1) / dimBlock.x + 1;
		dimGrid.y = (size - 1) / dimBlock.y + 1;

		for (int pivot = 0; pivot < size; pivot++) {
			elimination15_1<<<dimGrid, dimBlock>>>(g_b, size, pivot);
			elimination15_2<<<dimGrid, dimBlock>>>(g_b, size, pivot);
		}

		break;
	}

	check("Finished kernel execution");
	cudaDeviceSynchronize();
	check("Synchronized with device");

	// Copy data from GPU
	check("Copying data from device to host");
	cudaMemcpy(b, g_b, sizeTotal * sizeof(float), cudaMemcpyDeviceToHost);
	check("Copied data from device to host");

	// Tidy up
	check("Freeing memory");
	if (kernel < 8) {
		cudaFree(g_a);
		cudaFree(g_b);
	} else {
		cudaFree(g_b);
	}

	// Stop timers
	cudaEventRecord(timer2, 0);
	cudaEventSynchronize(timer1);
	cudaEventSynchronize(timer2);
	float elapsed;
	cudaEventElapsedTime(&elapsed, timer1, timer2);

	cudaDeviceReset();
	return elapsed;
}

// Very, very naive implementation, identical to CPU code
__global__ void elimination0(float *a, float *b, int size) {
#define element(_x, _y) (*(b + ((_y) * (size + 1) + (_x))))
	unsigned int xx, yy, rr;
	float c;

	// The matrix will be modified in place, so first make a copy of matrix a
	for (unsigned int i = 0; i < (size + 1) * size; i++)
		b[i] = a[i];

	for (yy = 0; yy < size; yy++) {
		float pivot = element(yy, yy);

		// Make the pivot be 1
		for (xx = 0; xx < size + 1; xx++)
			element(xx, yy) /= pivot;

		// Make all other values in the pivot column be zero
		for (rr = 0; rr < size; rr++) {
			if (rr != yy) {
				c = element(yy, rr);
				for (xx = 0; xx < size + 1; xx++)
					element(xx, rr) -= c * element(xx, yy);
			}
		}
	}
#undef element
}

// Inner xx loops are now parallel
// Uses one block, so limited to 512 threads
// Still uses only global memory
__global__ void elimination1(float *a, float *b, int size) {
#define element(_x, _y) (*(b + ((_y) * (size + 1) + (_x))))
	unsigned int xx, yy, rr;

	// The matrix will be modified in place, so first make a copy of matrix a
	for (unsigned int i = 0; i < (size + 1) * size; i++)
		b[i] = a[i];

	xx = threadIdx.x;

	for (yy = 0; yy < size; yy++) {
		float pivot = element(yy, yy);

		// Make the pivot be 1
		element(xx, yy) /= pivot;

		// Make all other values in the pivot column be zero
		for (rr = 0; rr < size; rr++) {
			if (rr != yy)
				element(xx, rr) -= element(yy, rr) * element(xx, yy);
		}
	}
#undef element
}

// Both xx and rr loops are now in parallel
__global__ void elimination2(float *a, float *b, int size) {
#define element(_x, _y) (*(b + ((_y) * (size + 1) + (_x))))
	unsigned int xx, yy, rr;

	// The matrix will be modified in place, so first make a copy of matrix a
	for (unsigned int i = 0; i < (size + 1) * size; i++)
		b[i] = a[i];

	__syncthreads();

	xx = threadIdx.x;
	rr = threadIdx.y;

	for (yy = 0; yy < size; yy++) {
		float pivot = element(yy, yy);

		// Make the pivot be 1
		element(xx, yy) /= pivot;

		// Make all other values in the pivot column be zero
		if (rr != yy)
			element(xx, rr) -= element(yy, rr) * element(xx, yy);

		__syncthreads();
	}
#undef element
}

// Data is copied in parallel
__global__ void elimination3(float *a, float *b, int size) {
#define element(_x, _y) (*(b + ((_y) * (size + 1) + (_x))))
	unsigned int xx, yy, rr;

	xx = threadIdx.x;
	rr = threadIdx.y;

	int tid = rr * (size + 1) + xx;

	// The matrix will be modified in place, so first make a copy of matrix a
	b[tid] = a[tid];

	__syncthreads();

	for (yy = 0; yy < size; yy++) {
		float pivot = element(yy, yy);

		// Make the pivot be 1
		element(xx, yy) /= pivot;

		// Make all other values in the pivot column be zero
		if (rr != yy)
			element(xx, rr) -= element(yy, rr) * element(xx, yy);

		__syncthreads();
	}
#undef element
}

// Shared memory is used
// However, still limited to matrices of size 22
__global__ void elimination4(float *a, float *b, int size) {
#define element(_x, _y) (*(sdata + ((_y) * (size + 1) + (_x))))
	unsigned int xx, yy, rr;

	// With a limit of 512 threads per block, and only one block, this results in a maximum
	// of a matrix size 22, which requires (22 + 1) x 22 values
	__shared__ float sdata[(22 + 1) * 22];

	xx = threadIdx.x;
	rr = threadIdx.y;

	int tid = rr * (size + 1) + xx;

	// The matrix will be modified in place, so first make a copy of matrix a
	sdata[tid] = a[tid];

	for (yy = 0; yy < size; yy++) {

		__syncthreads();

		// Make the pivot be 1
		element(xx, yy) /= element(yy, yy);

		__syncthreads();

		// Make all other values in the pivot column be zero
		if (rr != yy)
			element(xx, rr) -= element(yy, rr) * element(xx, yy);
	}

	b[tid] = sdata[tid];
#undef element
}

// Tries to use tiled implementation; does not work
__global__ void elimination5(float *a, float *b, int size) {
#define element(_x, _y) (*(sdata + ((_y) * (size + 1) + (_x))))
	unsigned int xx, yy, rr;

	__shared__ float sdata[BLOCK_SIZE * BLOCK_SIZE];

	xx = threadIdx.x;
	rr = threadIdx.y;

	int tid = rr * (size + 1) + xx;

	sdata[tid] = a[blockDim.y * BLOCK_SIZE + blockDim.x + tid];

	for (yy = 0; yy < size; yy++) {

		__syncthreads();

		// Make the pivot be 1
		element(xx, yy) /= element(yy, yy);

		__syncthreads();

		// Make all other values in the pivot column be zero
		if (rr != yy)
			element(xx, rr) -= element(yy, rr) * element(xx, yy);
	}

	b[blockDim.y * BLOCK_SIZE + blockDim.x + tid] = sdata[tid];
#undef element
}

// Kernel is invoked once per pivot
// One block, with thread dimensions equal to matrix dimensions
__global__ void elimination6(float *a, float *b, int size, int pivot) {
#define element(_x, _y) (*(b + ((_y) * (size + 1) + (_x))))
	int x = threadIdx.x;
	int y = threadIdx.y;

	int tid = y * (size + 1) + x;
	b[tid] = a[tid];

	if (y == pivot)
		element(x, y) /= element(pivot, pivot);

	__syncthreads();

	if (y != pivot)
		element(x, y) -= element(pivot, y) * element(x, pivot);

#undef element
}

// Kernel is invoked once per pivot
// Multiple blocks, with dimensions fixed
__global__ void elimination7(float *a, float *b, int size, int pivot) {
#define element(_x, _y) (*(b + ((_y) * (size + 1) + (_x))))
	element(threadIdx.x, blockDim.x) = 7;
	/*
	int x = threadIdx.x;
	int y = blockDim.x;

	if (x < size + 1 && y < size) {
		int tid = y * (size + 1) + x;

		b[tid] = a[tid];

		if (y == pivot)
			element(x, y) /= element(pivot, pivot);

		__syncthreads();

		if (y != pivot)
			element(x, y) -= element(pivot, y) * element(x, pivot);
	}
	*/
#undef element
}

__global__ void elimination8_1(float *a, int size, int pivot) {
#define element(_x, _y) (*(a + ((_y) * (size + 1) + (_x))))
	int x = threadIdx.x;
	int y = threadIdx.y;

	float cp = element(pivot, y) / element(pivot, pivot);

	if (y != pivot)
		element(x, y) -= cp * element(x, pivot);

#undef element
}

__global__ void elimination8_2(float *a, int size) {
#define element(_x, _y) (*(a + ((_y) * (size + 1) + (_x))))
	int yy = threadIdx.y * (size + 1) + threadIdx.x;
	element(size, yy) /= element(yy, yy);
#undef element
}

// A combination of both 8_1 and 8_2
// This opens up the possibility of using shared memory
__global__ void elimination9(float *a, int size) {
#define element(_x, _y) (*(a + ((_y) * (size + 1) + (_x))))
	int x = threadIdx.x;
	int y = threadIdx.y;

	float cp;

	for (int pivot = 0; pivot < size; pivot++) {

		cp = element(pivot, y) / element(pivot, pivot);

		if (y != pivot)
			element(x, y) -= cp * element(x, pivot);

		__syncthreads();
	}

	int yy = threadIdx.y * (size + 1) + threadIdx.x;
	element(size, yy) /= element(yy, yy);
#undef element
}

// Uses shared memory, but uses only one block
// Limited by amount of shared memory per block
__global__ void elimination10(float *a, int size) {
#define element(_x, _y) (*(sdata + ((_y) * (size + 1) + (_x))))

	int x = threadIdx.x;
	int y = threadIdx.y;
	int tid = y * (size + 1) + x;

	__shared__ float sdata[(22 + 1) * 22]; // Max size that will fit is 22
	sdata[tid] = a[tid];

	float cp;

	for (int pivot = 0; pivot < size; pivot++) {

		cp = element(pivot, y) / element(pivot, pivot);

		if (y != pivot)
			element(x, y) -= cp * element(x, pivot);

		__syncthreads();
	}

	element(size, tid) /= element(tid, tid);

	__syncthreads();

	a[tid] = sdata[tid];
#undef element
}

__global__ void elimination11_1(float *a, int size, int pivot) {
#define element(_x, _y) (*(a + ((_y) * (size + 1) + (_x))))

	int x = threadIdx.x + blockIdx.x * blockDim.x;
	int y = threadIdx.y + blockIdx.y * blockDim.y;

	if (x > size || y > size - 1)
		return;

	float cp = element(pivot, y) / element(pivot, pivot);

	if (y != pivot)
		element(x, y) -= cp * element(x, pivot);

#undef element
}

__global__ void elimination11_2(float *a, int size) {
#define element(_x, _y) (*(a + ((_y) * (size + 1) + (_x))))

	int tid = threadIdx.x + blockIdx.x * blockDim.x;

	if (tid > size)
		return;

	element(size, tid) /= element(tid, tid);

#undef element
}

// Divides the pivot row
__global__ void elimination12_1(float *a, int size, int pivot) {
#define element(_x, _y) (*(a + ((_y) * (size + 1) + (_x))))

	int x = threadIdx.x + blockIdx.x * blockDim.x;
	int y = threadIdx.y + blockIdx.y * blockDim.y;

	if (x <= size && y < size)
		if (y == pivot)
			element(x, y) /= element(pivot, pivot);

#undef element
}

// Subtracts the non-pivot row
__global__ void elimination12_2(float *a, int size, int pivot) {
#define element(_x, _y) (*(a + ((_y) * (size + 1) + (_x))))

	int x = threadIdx.x + blockIdx.x * blockDim.x;
	int y = threadIdx.y + blockIdx.y * blockDim.y;

	if (x <= size && y < size)
		if (y != pivot)
			element(x, y) -= element(pivot, y) * element(x, pivot);

#undef element
}

// Divides the pivot row
__global__ void elimination13_1(float *a, int size, int pivot) {
#define element(_x, _y) (*(a + ((_y) * (size + 1) + (_x))))

	int x = (threadIdx.x + blockIdx.x * blockDim.x) * ELEMENTS_PER_THREAD;
	int y = blockIdx.y;

	if (y < size)
		if (y == pivot) {
			float p = element(pivot, pivot);
			for (int xx = x; xx < x + ELEMENTS_PER_THREAD; xx++)
				if (xx <= size)
					element(xx, y) /= p;
		}

#undef element
}

// Subtracts the non-pivot row
__global__ void elimination13_2(float *a, int size, int pivot) {
#define element(_x, _y) (*(a + ((_y) * (size + 1) + (_x))))

	int x = (threadIdx.x + blockIdx.x * blockDim.x) * ELEMENTS_PER_THREAD;
	int y = blockIdx.y;

	if (y < size)
		if (y != pivot) {
			float c = element(pivot, y);
			for (int xx = x; xx < x + ELEMENTS_PER_THREAD; xx++)
				if (xx <= size)
					element(xx, y) -= c * element(xx, pivot);
		}

#undef element
}

// Divides the pivot row
__global__ void elimination14_1(float *a, int size, int pivot) {
#define element(_x, _y) (*(a + ((_y) * (size + 1) + (_x))))

	int y = blockIdx.y;

	if (y >= size || y != pivot)
		return;

	int x = (threadIdx.x + blockIdx.x * blockDim.x) * ELEMENTS_PER_THREAD;
	float p = element(pivot, pivot);
	int xx;

	#pragma unroll
	for (int i = 0; i < ELEMENTS_PER_THREAD; i++) {
		xx = i + x;
		if (xx <= size)
			element(xx, y) /= p;
	}

#undef element
}

// Subtracts the non-pivot row
__global__ void elimination14_2(float *a, int size, int pivot) {
#define element(_x, _y) (*(a + ((_y) * (size + 1) + (_x))))

	int y = blockIdx.y;

	if (y >= size || y == pivot)
		return;

	int x = (threadIdx.x + blockIdx.x * blockDim.x) * ELEMENTS_PER_THREAD;
	float c = element(pivot, y);
	int xx;

	#pragma unroll
	for (int i = 0; i < ELEMENTS_PER_THREAD; i++) {
		xx = i + x;
		if (xx <= size)
			element(xx, y) -= c * element(xx, pivot);
	}

#undef element
}

// Divides the pivot row
__global__ void elimination15_1(float *a, int size, int pivot) {

	int y = blockIdx.y;

	if (y >= size || y != pivot)
		return;

	int x = (threadIdx.x + blockIdx.x * blockDim.x) * ELEMENTS_PER_THREAD;
	int w = size + 1;
	float p = *(a + pivot * w + pivot);
	int xx;

	#pragma unroll
	for (int i = 0; i < ELEMENTS_PER_THREAD; i++) {
		xx = i + x;
		if (xx <= size)
			*(a + y * w + xx) /= p;
	}
}

// Subtracts the non-pivot row
__global__ void elimination15_2(float *a, int size, int pivot) {

	int y = blockIdx.y;

	if (y >= size || y == pivot)
		return;

	int x = (threadIdx.x + blockIdx.x * blockDim.x) * ELEMENTS_PER_THREAD;
	int w = size + 1;
	int pivotw = pivot * w;
	float *ayw = a + y * w;
	float c = *(ayw + pivot);
	int xx;

	#pragma unroll
	for (int i = 0; i < ELEMENTS_PER_THREAD; i++) {
		xx = i + x;
		if (xx <= size)
			*(ayw + xx) -= c * *(a + pivotw + xx);
	}
}

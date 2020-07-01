#include "cuda_runtime.h"
#include <stdlib.h>
#include <iostream>
#include<Windows.h>

using namespace std;
#pragma comment( lib,"winmm.lib" )
__global__ void Plus(float A[], float B[], float C[], int n)
{
    int i = blockDim.x * blockIdx.x + threadIdx.x;
    C[i] = A[i] + B[i];
}

//183ms
void test1()
{
    DWORD start, end;
    start = timeGetTime();

    float* A, * Ad, * B, * Bd, * C, * Cd;
    int n = 1024 * 1024;
    int size = n * sizeof(float);

    // CPU端分配内存
    A = (float*)malloc(size);
    B = (float*)malloc(size);
    C = (float*)malloc(size);

    // 初始化数组
    for (int i = 0; i < n; i++)
    {
        A[i] = 90.0;
        B[i] = 10.0;
    }

    // GPU端分配内存
    cudaMalloc((void**)&Ad, size);
    cudaMalloc((void**)&Bd, size);
    cudaMalloc((void**)&Cd, size);

    // CPU的数据拷贝到GPU端
    cudaMemcpy(Ad, A, size, cudaMemcpyHostToDevice);
    cudaMemcpy(Bd, B, size, cudaMemcpyHostToDevice);
    cudaMemcpy(Bd, B, size, cudaMemcpyHostToDevice);

    // 定义kernel执行配置，（1024*1024/512）个block，每个block里面有512个线程
    dim3 dimBlock(512);
    dim3 dimGrid(n / 512);

    // 执行kernel
    Plus << <dimGrid, dimBlock >> > (Ad, Bd, Cd, n);

    // 将在GPU端计算好的结果拷贝回CPU端
    cudaMemcpy(C, Cd, size, cudaMemcpyDeviceToHost);

    // 校验误差
    float max_error = 0.0;
    for (int i = 0; i < n; i++)
    {
        max_error += fabs(100.0 - C[i]);
    }

    cout << "max error is " << max_error << endl;

    // 释放CPU端、GPU端的内存
    free(A);
    free(B);
    free(C);
    cudaFree(Ad);
    cudaFree(Bd);
    cudaFree(Cd);
    end = timeGetTime();
    cout << "total time is " << (end - start) << "ms" << endl;
   
}
__global__ void addKernel(int** C, int** A, int** B)
{
    int idx = threadIdx.x + blockDim.x * blockIdx.x;
    int idy = threadIdx.y + blockDim.y * blockIdx.y;
    if (idx < 1024 && idy < 1024) {
        C[idy][idx] = A[idy][idx] + B[idy][idx];
    }
}
//14ms
void test2()
{
    DWORD start, end;
    int Row = 1024;
    int Col = 1024;
    start = timeGetTime();
    int** A = (int**)malloc(sizeof(int*) * Row);
    int** B = (int**)malloc(sizeof(int*) * Row);
    int** C = (int**)malloc(sizeof(int*) * Row);
    int* dataA = (int*)malloc(sizeof(int) * Row * Col);
    int* dataB = (int*)malloc(sizeof(int) * Row * Col);
    int* dataC = (int*)malloc(sizeof(int) * Row * Col);
    int** d_A;
    int** d_B;
    int** d_C;
    int* d_dataA;
    int* d_dataB;
    int* d_dataC;
    //malloc device memory
    cudaMalloc((void**)&d_A, sizeof(int**) * Row);
    cudaMalloc((void**)&d_B, sizeof(int**) * Row);
    cudaMalloc((void**)&d_C, sizeof(int**) * Row);
    cudaMalloc((void**)&d_dataA, sizeof(int) * Row * Col);
    cudaMalloc((void**)&d_dataB, sizeof(int) * Row * Col);
    cudaMalloc((void**)&d_dataC, sizeof(int) * Row * Col);
    //set value
    for (int i = 0; i < Row * Col; i++) {
        dataA[i] = 90;
        dataB[i] = 10;
    }
    //将主机指针A指向设备数据位置，目的是让设备二级指针能够指向设备数据一级指针
    //A 和  dataA 都传到了设备上，但是二者还没有建立对应关系
    for (int i = 0; i < Row; i++) {
        A[i] = d_dataA + Col * i;
        B[i] = d_dataB + Col * i;
        C[i] = d_dataC + Col * i;
    }

    cudaMemcpy(d_A, A, sizeof(int*) * Row, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, B, sizeof(int*) * Row, cudaMemcpyHostToDevice);
    cudaMemcpy(d_C, C, sizeof(int*) * Row, cudaMemcpyHostToDevice);
    cudaMemcpy(d_dataA, dataA, sizeof(int) * Row * Col, cudaMemcpyHostToDevice);
    cudaMemcpy(d_dataB, dataB, sizeof(int) * Row * Col, cudaMemcpyHostToDevice);
    dim3 threadPerBlock(16, 16);
    dim3 blockNumber((Col + threadPerBlock.x - 1) / threadPerBlock.x, (Row + threadPerBlock.y - 1) / threadPerBlock.y);
    printf("Block(%d,%d)   Grid(%d,%d).\n", threadPerBlock.x, threadPerBlock.y, blockNumber.x, blockNumber.y);
    addKernel << <blockNumber, threadPerBlock >> > (d_C, d_A, d_B);
    //拷贝计算数据-一级数据指针
    cudaMemcpy(dataC, d_dataC, sizeof(int) * Row * Col, cudaMemcpyDeviceToHost);

    int max_error = 0;
    for (int i = 0; i < Row * Col; i++)
    {
        //printf("%d\n", dataC[i]);
        max_error += abs(100 - dataC[i]);
    }

    //释放内存
    free(A);
    free(B);
    free(C);
    free(dataA);
    free(dataB);
    free(dataC);
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);
    cudaFree(d_dataA);
    cudaFree(d_dataB);
    cudaFree(d_dataC);

    printf("max_error is %d\n", max_error);
    end = timeGetTime();
    cout << "total time is " << (end - start) << "ms" << endl;

}
__global__ void matrix_mul_gpu(int* M, int* N, int* P, int width)
{
    int i = threadIdx.x + blockDim.x * blockIdx.x;
    int j = threadIdx.y + blockDim.y * blockIdx.y;

    int sum = 0;
    for (int k = 0; k < width; k++)
    {
        int a = M[j * width + k];
        int b = N[k * width + i];
        sum += a * b;
    }
    P[j * width + i] = sum;
}
//234ms
void test3()
{
    DWORD start, end;
    int Row = 1024;
    int Col = 1024;
    start = timeGetTime();

    int* A = (int*)malloc(sizeof(int) * Row * Col);
    int* B = (int*)malloc(sizeof(int) * Row * Col);
    int* C = (int*)malloc(sizeof(int) * Row * Col);
    //malloc device memory
    int* d_dataA, * d_dataB, * d_dataC;
    cudaMalloc((void**)&d_dataA, sizeof(int) * Row * Col);
    cudaMalloc((void**)&d_dataB, sizeof(int) * Row * Col);
    cudaMalloc((void**)&d_dataC, sizeof(int) * Row * Col);
    //set value
    for (int i = 0; i < Row * Col; i++) {
        A[i] = 90;
        B[i] = 10;
    }

    cudaMemcpy(d_dataA, A, sizeof(int) * Row * Col, cudaMemcpyHostToDevice);
    cudaMemcpy(d_dataB, B, sizeof(int) * Row * Col, cudaMemcpyHostToDevice);
    dim3 threadPerBlock(16, 16);
    dim3 blockNumber((Col + threadPerBlock.x - 1) / threadPerBlock.x, (Row + threadPerBlock.y - 1) / threadPerBlock.y);
    printf("Block(%d,%d)   Grid(%d,%d).\n", threadPerBlock.x, threadPerBlock.y, blockNumber.x, blockNumber.y);
    matrix_mul_gpu << <blockNumber, threadPerBlock >> > (d_dataA, d_dataB, d_dataC, Col);
    //拷贝计算数据-一级数据指针
    cudaMemcpy(C, d_dataC, sizeof(int) * Row * Col, cudaMemcpyDeviceToHost);

    //释放内存
    free(A);
    free(B);
    free(C);
    cudaFree(d_dataA);
    cudaFree(d_dataB);
    cudaFree(d_dataC);

    end = timeGetTime();
    cout << "total time is " << (end - start) << "ms" << endl;

}

int main()
{
    test1();
    test2();
    test3();
    return 0;
}
#include <iostream>
#include <stdlib.h>
#include<Windows.h>
#include <math.h>

using namespace std;
#pragma comment( lib,"winmm.lib" )

//15ms
void test1() 
{
    DWORD start, end;
    start = timeGetTime();
    float* A, * B, * C;
    int n = 1024 * 1024;
    int size = n * sizeof(float);
    A = (float*)malloc(size);
    B = (float*)malloc(size);
    C = (float*)malloc(size);

    for (int i = 0; i < n; i++)
    {
        A[i] = 90.0;
        B[i] = 10.0;
    }

    for (int i = 0; i < n; i++)
    {
        C[i] = A[i] + B[i];
    }

    float max_error = 0.0;
    for (int i = 0; i < n; i++)
    {
        max_error += fabs(100.0 - C[i]);
    }
    cout << "max_error is " << max_error << endl;
    end = timeGetTime();
    cout << "total time is " << (end - start) << "ms" << endl;
}

//10ms
void test2()
{
    int ROWS = 1024;
    int COLS = 1024;
    DWORD start, end;
    start = timeGetTime();
    int* A, ** A_ptr, * B, ** B_ptr, * C, ** C_ptr;
    int total_size = ROWS * COLS * sizeof(int);
    A = (int*)malloc(total_size);
    B = (int*)malloc(total_size);
    C = (int*)malloc(total_size);
    A_ptr = (int**)malloc(ROWS * sizeof(int*));
    B_ptr = (int**)malloc(ROWS * sizeof(int*));
    C_ptr = (int**)malloc(ROWS * sizeof(int*));

    //CPU一维数组初始化
    for (int i = 0; i < ROWS * COLS; i++)
    {
        A[i] = 80;
        B[i] = 20;
    }

    for (int i = 0; i < ROWS; i++)
    {
        A_ptr[i] = A + COLS * i;
        B_ptr[i] = B + COLS * i;
        C_ptr[i] = C + COLS * i;
    }

    for (int i = 0; i < ROWS; i++)
        for (int j = 0; j < COLS; j++)
        {
            C_ptr[i][j] = A_ptr[i][j] + B_ptr[i][j];
        }

    //检查结果
    int max_error = 0;
    for (int i = 0; i < ROWS * COLS; i++)
    {
        //cout << C[i] << endl;
        max_error += abs(100 - C[i]);
    }

    cout << "max_error is " << max_error << endl;
    end = timeGetTime();
    cout << "total time is " << (end - start) << "ms" << endl;
   
}
void matrix_mul_cpu(float* M, float* N, float* P, int width)
{
    for (int i = 0; i < width; i++)
        for (int j = 0; j < width; j++)
        {
            float sum = 0.0;
            for (int k = 0; k < width; k++)
            {
                float a = M[i * width + k];
                float b = N[k * width + j];
                sum += a * b;
            }
            P[i * width + j] = sum;
        }
}
//5547ms
void test3()
{
    int ROWS = 1024;
    int COLS = 1024;
    DWORD start, end;
    start = timeGetTime();
    float* A, * B, * C;
    int total_size = ROWS * COLS * sizeof(float);
    A = (float*)malloc(total_size);
    B = (float*)malloc(total_size);
    C = (float*)malloc(total_size);

    //CPU一维数组初始化
    for (int i = 0; i < ROWS * COLS; i++)
    {
        A[i] = 80.0;
        B[i] = 20.0;
    }

    matrix_mul_cpu(A, B, C, COLS);

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
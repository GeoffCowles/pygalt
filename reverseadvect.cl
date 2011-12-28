__kernel void reverseadvect( __global float* x, __global float* y, __global float* u, __global float* v)
{
    unsigned int i = get_global_id(0);

    x[i] = x[i] - .01*u[i];
    y[i] = y[i] - .01*v[i];
}


__kernel void advect( __global float* x, __global float* y, __global float* u, __global float* v, float deltat)
{
    unsigned int i = get_global_id(0);
    x[i] = x[i] +  deltat*u[i];
    y[i] = y[i] +  deltat*v[i];
}

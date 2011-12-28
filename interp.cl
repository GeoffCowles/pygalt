__kernel void interp( __global int* incell, __global int* stat, __global float* u, __global float* v, __global float* uf1, __global float* vf1, __global float *uf2, __global float *vf2, float frac)
{
    unsigned int i = get_global_id(0);
    unsigned int cell;

    cell = incell[i];
    u[i] = 0.0;
    v[i] = 0.0;
	if(stat[i] == 1)
	{
    u[i] = frac*uf1[cell] + (1-frac)*uf2[cell];
    v[i] = frac*vf1[cell] + (1-frac)*vf2[cell];
	}
}


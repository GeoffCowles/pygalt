__kernel void interp( __global float* u1, __global float* v1, __global float* u2, __global float* v2, __global float* uf1, __global float* vf1, __global float *uf2, __global float *vf2, float frac, int behind)
{
    unsigned int i = get_global_id(0);

    u1[i] = u2[i];
    v1[i] = v2[i];
    
    if(behind==0) {
        u2[i] = frac*uf1[i] + (1-frac)*uf2[i];
        v2[i] = frac*vf1[i] + (1-frac)*vf2[i];
    }
    else {
    
        u2[i] = frac*uf2[i] + (1-frac)*uf1[i];
        v2[i] = frac*vf2[i] + (1-frac)*vf1[i];
    }
}


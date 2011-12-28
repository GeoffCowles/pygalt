// update particle state 
__kernel void setstate( __global int* incell, __global int* incell2, __global float* x, __global float* x2,  __global float* y, __global float* y2, __global float* tini, __global float* tlag, __global int* stat, __global int* mark, float mtime)
{
    unsigned int i = get_global_id(0);

	//particle left domain, reset
	if(incell[i]==-1){
		x[i] = x2[i];
		y[i] = y2[i];
		incell[i] = incell2[i];
	}
	//particle still in domain, update last vals
	else{
		x2[i] = x[i];
		y2[i] = y[i];
		incell2[i] = incell[i];
	}
	//if particle is in domain of interest, update time
	if(mark[incell[i]]==1){
		tlag[i] = mtime;
	}
	//set status of particel 
	stat[i] = 1;
	if(mark[incell[i]]==-1 | mtime < tini[i]){
		stat[i] = 0;
	}
}


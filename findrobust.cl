// find cell containing particle
__kernel void findrobust( __global int* incell, __global int* stat, __global float* x, __global float* y,  __global float* xt, __global float* yt, int nelem)
{
    unsigned int i = get_global_id(0);
    float xtri[3];
    float ytri[3];
    float xp = x[i];
    float yp = y[i];
    int cell;
    
    if(stat[i]==0){return;}


    if(incell[i]==-1){
      for (int cell=0; cell <nelem-1; ++cell){
        xtri[0] = xt[cell*3  ];
        xtri[1] = xt[cell*3+1];
        xtri[2] = xt[cell*3+2];
   	    ytri[0] = yt[cell*3  ];
        ytri[1] = yt[cell*3+1];
        ytri[2] = yt[cell*3+2];

  	    float f1 = (yp-ytri[0])*(xtri[1]- xtri[0]) - (xp-xtri[0])*(ytri[1]-ytri[0]);  
	    float f2 = (yp-ytri[2])*(xtri[0]- xtri[2]) - (xp-xtri[2])*(ytri[0]-ytri[2]);  
	    float f3 = (yp-ytri[1])*(xtri[2]- xtri[1]) - (xp-xtri[1])*(ytri[2]-ytri[1]);  

	    if(f1*f3 >= 0.0 & f3*f2 >= 0.0)
	    {
	    incell[i] = cell;
	    break;
	    }
	  }
	}
}


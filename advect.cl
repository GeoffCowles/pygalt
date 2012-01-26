__kernel void advect( __global int* incell, __global int* stat, __global int* nbe, __global float* a1u, __global float* a2u, __global float* xc, __global float* yc, __global float* x, __global float* y, __global float* u1, __global float* v1, __global float* u2, __global float* v2, float deltat)
{
    unsigned int i = get_global_id(0);
//     x[i] = x[i] +  deltat*u2[incell[i]];
//     y[i] = y[i] +  deltat*v2[incell[i]];

    const float a_rk[4] = {0.0, 0.5, 0.5, 1.0};
    const float b_rk[4] = {1.0/6.0, 1.0/3.0, 1.0/3.0, 1.0/6.0};
    const float c_rk[4] = {0.0, 0.5, 0.5, 1.0};
    
    float chix[4];
    float chiy[4];
    
    float pdx,pdy,u,v,up1,up2,vp1,vp2,xoc,yoc, dvdx, dvdy;
    int ns, icell,e1,e2,e3;
    
    icell = incell[i];
    
	e1 = nbe[icell*3+0];
	e2 = nbe[icell*3+1];
	e3 = nbe[icell*3+2];
	
	pdx = x[i];
	pdy = y[i];

//    Loop over RK Stages
    for(ns=0; ns<4; ns++)
    {
        if(ns>0)
        {
			pdx = x[i]  + a_rk[ns]*deltat*chix[ns-1];
			pdy = y[i]  + a_rk[ns]*deltat*chiy[ns-1];
        }
		
		xoc = pdx - xc[icell];
		yoc = pdy - yc[icell];
    
		dvdx = a1u[icell*4+0]*u1[icell]+a1u[icell*4+1]*u1[e1]+a1u[icell*4+2]*u1[e2]+a1u[icell*4+3]*u1[e3];
		dvdy = a2u[icell*4+0]*u1[icell]+a2u[icell*4+1]*u1[e1]+a2u[icell*4+2]*u1[e2]+a2u[icell*4+3]*u1[e3];
		up1 = u1[icell] + dvdx*xoc +dvdy*yoc;

	
		dvdx = a1u[icell*4+0]*u2[icell]+a1u[icell*4+1]*u2[e1]+a1u[icell*4+2]*u2[e2]+a1u[icell*4+3]*u2[e3];
		dvdy = a2u[icell*4+0]*u2[icell]+a2u[icell*4+1]*u2[e1]+a2u[icell*4+2]*u2[e2]+a2u[icell*4+3]*u2[e3];
		up2 = u2[icell] + dvdx*xoc +dvdy*yoc;
		
		dvdx = a1u[icell*4+0]*v1[icell]+a1u[icell*4+1]*v1[e1]+a1u[icell*4+2]*v1[e2]+a1u[icell*4+3]*v1[e3];
		dvdy = a2u[icell*4+0]*v1[icell]+a2u[icell*4+1]*v1[e1]+a2u[icell*4+2]*v1[e2]+a2u[icell*4+3]*v1[e3];
		vp1 = v1[icell] + dvdx*xoc +dvdy*yoc;
	

		dvdx = a1u[icell*4+0]*v2[icell]+a1u[icell*4+1]*v2[e1]+a1u[icell*4+2]*v2[e2]+a1u[icell*4+3]*v2[e3];
		dvdy = a2u[icell*4+0]*v2[icell]+a2u[icell*4+1]*v2[e1]+a2u[icell*4+2]*v2[e2]+a2u[icell*4+3]*v2[e3];
		vp2 = v2[icell] + dvdx*xoc +dvdy*yoc;
			
        u  = (1.0-c_rk[ns])*up1 + c_rk[ns]*up2;
	    v  = (1.0-c_rk[ns])*vp1 + c_rk[ns]*vp2;
	    chix[ns]  = u;
	    chiy[ns]  = v;
	    	    
	    
    
	    
    }
//--Sum Stage Contributions to get Updated Particle Positions--------

    for(ns=0; ns<4; ns++)
    {
    	x[i] = x[i] + deltat*chix[ns]*b_rk[ns];
    	y[i] = y[i] + deltat*chiy[ns]*b_rk[ns];    	
    }
    	



}


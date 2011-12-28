// see mat_mult_mini in /usr/local/ati-stream-sdk-v2.2-lnx64/samples/opencl/cl/app/MatrixMulImage/MatrixMulImage_Kernels.cl
// determine if a point (x,y) is contained within a triangle defined by vertices [xt(3),yt(3)]
// = 0 => not contained
// = 1 => is contained
// note if point lies on a line exactly coinciding with a triangle edge it may find the point 
// to be in the triangle.  This is an issue if seeding particles from locations on a semi-structured grid
// otherwise not an issue

__kernel void isintriangle( float3 xt , float3 yt, float x, float y, uint res)
{
float f1 = (y-yt.x)*(xt.y - xt.x) - (x-xt.x)*(yt.y-yt.x);  
float f2 = (y-yt.z)*(xt.x - xt.z) - (x-xt.z)*(yt.x-yt.z);  
float f3 = (y-yt.y)*(xt.z - xt.y) - (x-xt.y)*(yt.z-yt.y);  
res = (f1*f3 >= 0.0 & f3*f2 >= 0.0)? 1:0;

}

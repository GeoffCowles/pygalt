// find nearest cell center to each particle
// see: http://stackoverflow.com/questions/5381397/openclnearest-neighbour-using-euclidean-distance

__kernel void 
nearest_neighbour(__global float2 *model,
__global float2 *dataset,
__global unsigned int *nearest,
const unsigned int model_size)
{
    int g_dataset_id = get_global_id(0);

    float dmin = MAXFLOAT;
    float d;

    float2 local_xyz = dataset[g_dataset_id];
    float2 d_xyz;
    int imin;

    for (int i=0; i<model_size; ++i) {
        d_xyz = model[i] - local_xyz;

        d_xyz *= d_xyz;

        d = d_xyz.x + d_xyz.y + d_xyz.z;

        if(d < dmin)
        {
            imin = i;
            dmin = d;
        }
    }

    nearest[g_dataset_id] = imin; // Write only once in global memory
}
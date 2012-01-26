# simple test
import pyopencl as cl
import numpy
from pycdf import *
from numpy import *
from utils import *
from time  import time

# numpy types 
dtype_flt = numpy.float32
dtype_int = numpy.int32

#-----------------------------------------------------
# set runtime control vars
outname = "./testing/solidbody/output.nc"    # output file
gridfile = "./testing/solidbody/solidbody.nc"
lagfile = "./testing/solidbody/preprocessing/solidbody_test.nc" 
#forcefile = "semass_4x11_dply3_C_vertavge_only_3daytest.nc" 
#forcefile = "semass_4x31_dply3_D_vertavge.nc" 
forcefile = "./testing/solidbody/solidbody.nc"

select_GPU = "ATI Radeon HD 6970M"  # GPU to use
select_PLATFORM = "Apple"

#select_GPU = "Intel"  # GPU to use
#select_PLATFORM = "ATI"

#select_GPU = "Cypress"  # GPU to use
#select_PLATFORM = "ATI"

deltat_py = 240.  #time step in seconds
deltat    = 240.*numpy.ones(1,dtype=numpy.float32) #time step
deltat_py_days = deltat_py/(3600*24.);
deltat_days = deltat/(3600*24.);
freq   = 2          # output frequency in time steps
#-----------------------------------------------------

# set kernel build options
if "NVIDIA" in select_PLATFORM:
	buildopts = "-cl-mad-enable -cl-fast-relaxed-math"
else:
	buildopts = ""


# get the device ID for the desired device
print "====== available platforms/devices =========="
for platform in cl.get_platforms():
	for devices in platform.get_devices():
		print platform.name," / ", devices.name
print ""
print "======= selected platforms/devices =========="
for platform in cl.get_platforms():
	for devices in platform.get_devices():
#		if select_PLATFORM in platform.name:
		if select_GPU in devices.name:
			device = devices
			print "Using Platform: ",platform.name 
			print "Using Device: ",devices
print ""

# read the mesh, connectivity, and active cell list
fin = CDF(gridfile)
xv  = fin.var('x')[:]
yv  = fin.var('y')[:]
xc  = fin.var('xc')[:]
yc  = fin.var('yc')[:]
#ac  = fin.var('active_cells')[:]
nv  = fin.var('nv')[:,:]; #[3,nelems]
nv  = nv-1; # shift indices of connectivity to C-style
nbe = fin.var('nbe')[:,:]; #[3,nelems]
nbe = numpy.transpose(nbe);
nbe = nbe -1;
nbe = nbe.flatten();
a1u  = fin.var('a1u')[:,:]; #[4,nelems]
a1u = numpy.transpose(a1u);
a1u = a1u.flatten();
a2u  = fin.var('a2u')[:,:]; #[4,nelems]
a2u = numpy.transpose(a2u);
a2u = a2u.flatten();
neney = fin.var('neney')[:];
eney = fin.var('eney')[:,:];
eney = numpy.transpose(eney);
eney = eney-1; # shift indices of connectivity to C-style
eney = eney.flatten();
fin.close();


# get and report dimensions
nverts = xv.size
nelems = xc.size
print "\n\n\n"
print "number of elements: ", nelems
print "number of vertices: ", nverts


# create an array containing vertices by element
xt  = numpy.zeros(nelems*3,dtype=numpy.float32)
yt  = numpy.zeros(nelems*3,dtype=numpy.float32)
ii  = 0;
for i in range(0,nelems*3,3):
	xt[i]   = xv[nv[0,ii]] 
	xt[i+1] = xv[nv[1,ii]]
	xt[i+2] = xv[nv[2,ii]]
	yt[i]   = yv[nv[0,ii]] 
	yt[i+1] = yv[nv[1,ii]]
	yt[i+2] = yv[nv[2,ii]]
	ii = ii + 1

# read initial particle position, cell, spawning time 
fin = CDF(lagfile)
x  = fin.var('x')[:]
x2 = x #last x position
y  = fin.var('y')[:]
y2 = y #last y position
cell = fin.var('cell')[:]
cell = cell -1 # convert to C-style counting
cell2 = cell
tini = fin.var('tspawn')[:]
fin.close()
nlag = len(x) 
print "# of particles: ",nlag

tlag = numpy.zeros(nlag,dtype=dtype_flt)
stat = numpy.zeros(nlag,dtype=dtype_int)

mark  = numpy.zeros(nelems,dtype=numpy.int32)
mark[cell] = 1 

# open forcing file and read time range and number of forcing frames
fin = CDF(forcefile)
ftime = fin.var('time')[:];
ntimes = ftime.size
ftime = ftime-ftime[0];
nits = int((ftime[-1]-ftime[0])/(deltat_days)) 
print "begin time: ",ftime[0]
print "end time: ",ftime[-1]
print "# timesteps: ",nits
print "# of forcing frames: ",ntimes
uf1  = numpy.zeros(nelems,dtype=dtype_flt)   
vf1  = numpy.zeros(nelems,dtype=dtype_flt)   
uf2  = numpy.zeros(nelems,dtype=dtype_flt)   
vf2  = numpy.zeros(nelems,dtype=dtype_flt)   

u1 = numpy.zeros(nelems,dtype=dtype_flt)
v1 = numpy.zeros(nelems,dtype=dtype_flt)
u2 = numpy.zeros(nelems,dtype=dtype_flt)
v2 = numpy.zeros(nelems,dtype=dtype_flt)

# create context and command queue 
a_ctx = cl.Context([device])
a_queue = cl.CommandQueue(a_ctx,
        properties=cl.command_queue_properties.PROFILING_ENABLE)

# create kernel for advection
prog = open('advect.cl','r')
fstr = "".join(prog.readlines())
prg = cl.Program(a_ctx,fstr).build(options=buildopts)
advect_knl = prg.advect

# create kernel for reverse advection 
prog = open('reverseadvect.cl','r')
fstr = "".join(prog.readlines())
prg = cl.Program(a_ctx,fstr).build(options=buildopts)
revadvect_knl = prg.reverseadvect

# create kernel for interpolating velocities 
prog = open('interp.cl','r')
fstr = "".join(prog.readlines())
prg = cl.Program(a_ctx,fstr).build(options=buildopts)
interp_knl = prg.interp

# create kernel for locating nearest cell 
prog = open('findcell.cl','r')
fstr = "".join(prog.readlines())
prg = cl.Program(a_ctx,fstr).build(options=buildopts)
findcell_knl = prg.findcell

# create kernel for locating nearest cell 
prog = open('findrobust.cl','r')
fstr = "".join(prog.readlines())
prg = cl.Program(a_ctx,fstr).build(options=buildopts)
findrobust_knl = prg.findrobust

# create kernel for updating state 
prog = open('setstate.cl','r')
fstr = "".join(prog.readlines())
prg = cl.Program(a_ctx,fstr).build(options=buildopts)
setstate_knl = prg.setstate

# create memory buffers
mf   = cl.mem_flags
frame_frac = numpy.ones(1,dtype=dtype_flt)
num_elems  = numpy.ones(1,dtype=dtype_int)
num_elems[0] = nelems 
cell_buf = cl.Buffer(a_ctx,mf.READ_WRITE | mf.COPY_HOST_PTR, hostbuf = cell)
cell2_buf = cl.Buffer(a_ctx,mf.READ_ONLY  | mf.COPY_HOST_PTR, hostbuf = cell2)
tlag_buf = cl.Buffer(a_ctx,mf.READ_WRITE | mf.COPY_HOST_PTR, hostbuf = tlag)
tini_buf = cl.Buffer(a_ctx,mf.READ_WRITE | mf.COPY_HOST_PTR, hostbuf = tini)
stat_buf = cl.Buffer(a_ctx,mf.READ_ONLY  | mf.COPY_HOST_PTR, hostbuf = stat)
mark_buf = cl.Buffer(a_ctx,mf.READ_ONLY  | mf.COPY_HOST_PTR, hostbuf = mark)
x_buf    = cl.Buffer(a_ctx,mf.READ_WRITE | mf.COPY_HOST_PTR, hostbuf = x)
y_buf    = cl.Buffer(a_ctx,mf.READ_WRITE | mf.COPY_HOST_PTR, hostbuf = y)
x2_buf   = cl.Buffer(a_ctx,mf.READ_WRITE | mf.COPY_HOST_PTR, hostbuf = x2)
y2_buf   = cl.Buffer(a_ctx,mf.READ_WRITE | mf.COPY_HOST_PTR, hostbuf = y2)
u1_buf    = cl.Buffer(a_ctx,mf.READ_WRITE | mf.COPY_HOST_PTR, hostbuf = u1)
v1_buf    = cl.Buffer(a_ctx,mf.READ_WRITE | mf.COPY_HOST_PTR, hostbuf = v1)
u2_buf    = cl.Buffer(a_ctx,mf.READ_WRITE | mf.COPY_HOST_PTR, hostbuf = u2)
v2_buf    = cl.Buffer(a_ctx,mf.READ_WRITE | mf.COPY_HOST_PTR, hostbuf = v2)
xc_buf   = cl.Buffer(a_ctx,mf.READ_ONLY  | mf.COPY_HOST_PTR, hostbuf = xc)
yc_buf   = cl.Buffer(a_ctx,mf.READ_ONLY  | mf.COPY_HOST_PTR, hostbuf = yc)
xt_buf   = cl.Buffer(a_ctx,mf.READ_ONLY  | mf.COPY_HOST_PTR, hostbuf = xt)
yt_buf   = cl.Buffer(a_ctx,mf.READ_ONLY  | mf.COPY_HOST_PTR, hostbuf = yt)
uf1_buf  = cl.Buffer(a_ctx,mf.READ_ONLY | mf.COPY_HOST_PTR, hostbuf = uf1)
vf1_buf  = cl.Buffer(a_ctx,mf.READ_ONLY  | mf.COPY_HOST_PTR, hostbuf = vf1)
uf2_buf  = cl.Buffer(a_ctx,mf.READ_ONLY  | mf.COPY_HOST_PTR, hostbuf = uf2)
vf2_buf  = cl.Buffer(a_ctx,mf.READ_ONLY  | mf.COPY_HOST_PTR, hostbuf = vf2)
cell_buf = cl.Buffer(a_ctx,mf.READ_WRITE | mf.COPY_HOST_PTR, hostbuf = cell)
nbe_buf = cl.Buffer(a_ctx,mf.READ_ONLY  | mf.COPY_HOST_PTR, hostbuf = nbe)
a1u_buf = cl.Buffer(a_ctx,mf.READ_ONLY  | mf.COPY_HOST_PTR, hostbuf = a1u)
a2u_buf = cl.Buffer(a_ctx,mf.READ_ONLY  | mf.COPY_HOST_PTR, hostbuf = a2u)
neney_buf = cl.Buffer(a_ctx,mf.READ_ONLY  | mf.COPY_HOST_PTR, hostbuf = neney)
eney_buf = cl.Buffer(a_ctx,mf.READ_ONLY  | mf.COPY_HOST_PTR, hostbuf = eney)
#crap_buf = cl.Buffer(a_ctx,mf.READ_ONLY  | mf.COPY_HOST_PTR, hostbuf = frame_frac)
#time_buf = cl.Buffer(a_ctx,mf.READ_ONLY  | mf.COPY_HOST_PTR, hostbuf = deltat)


# setup output file and dump initial positions
write_output_header(outname,'testing',nlag,nelems)
icnt = 0
fout = CDF(outname, NC.WRITE)
print "writing initial positions"
t_var  = fout.var('time')
x_var  = fout.var('x')
y_var  = fout.var('y')
c_var  = fout.var('cell')
m_var  = fout.var('mark')
tlag_var = fout.var('tlag')
tini_var = fout.var('tinit')
t_var[icnt] = 0.0 
x_var[icnt] = x
y_var[icnt] = y
c_var[icnt] = cell
m_var[icnt] = mark
tlag_var[icnt] = tlag
tini_var[icnt] = tini

u2 = fin.var('ua')[0,:]
v2 = fin.var('va')[0,:]
cl.enqueue_write_buffer(a_queue, u2_buf, u2).wait()
cl.enqueue_write_buffer(a_queue, v2_buf, v2).wait()

#===========================================================================
# loop over time
#===========================================================================
#mtime = 0.0 # initialize model time
mtime    = numpy.zeros(1,dtype=numpy.float32) #model time 
mtime_py = 0.0
t1 = time() # initialize timer
flast = -1
print x
for its in range(nits):
	print "iteration ",its+1," of ",nits
#for its in range(1,4):
    #---------------------------------------------------------------------------
	# update forcing 
    # ua is size [ntimes,nelems]
    #---------------------------------------------------------------------------
	close = int(abs(ftime-mtime).argmin())
	if ftime[close] < mtime:
		f1 = close
		f2 = min(ntimes-1,f1+1)
	else:
		f1 = max(close-1,0)
		f2 = f1 + 1 
	#print close
	#print (mtime-ftime[f1])/(ftime[f2]-ftime[f1]), (ftime[f2]-mtime)/(ftime[f2]-ftime[f1])
	frame_frac[0] =  (ftime[f2]-mtime)/(ftime[f2]-ftime[f1]) #*numpy.ones(1,dtype=numpy.float32)
	#print f1
	#print f2
	#print ftime[f1]
	#print ftime[f2]

	# read new frames and push to kernel
 	# note since the data in f2 becomes f1 we do not need to push two frames 
 	# every time we go to a new interval.  By using an additional flag we can 
	# set the linear interpolation in the kernel to be correct whether or not 
	# f1 is behind or in front of f2
	if(f1 != flast):
		flast = f1
		uf1 = fin.var('ua')[f1,:]
		vf1 = fin.var('va')[f1,:]
		uf2 = fin.var('ua')[f2,:]
		vf2 = fin.var('va')[f2,:]
		cl.enqueue_write_buffer(a_queue, uf1_buf, uf1).wait()
		cl.enqueue_write_buffer(a_queue, vf1_buf, vf1).wait()
		cl.enqueue_write_buffer(a_queue, uf2_buf, uf2).wait()
		cl.enqueue_write_buffer(a_queue, vf2_buf, vf2).wait()

    #---------------------------------------------------------------------------
	# find cell containing particle and update state
    #---------------------------------------------------------------------------
	event = findcell_knl(a_queue,x.shape,None,cell_buf,neney_buf,eney_buf,x_buf,
		y_buf,xt_buf,yt_buf)

	#cl.enqueue_read_buffer(a_queue, cell_buf, cell).wait()

	event = findrobust_knl(a_queue,x.shape,None,cell_buf,x_buf,
		y_buf,xt_buf,yt_buf,num_elems)

	#cl.enqueue_read_buffer(a_queue, cell_buf, cell).wait()
	#print "cells",cell,f1,f2

    #---------------------------------------------------------------------------
	# update particle state and reset particles on land 
    #---------------------------------------------------------------------------
	event = setstate_knl(a_queue,x.shape,None,cell_buf,cell2_buf,x_buf,x2_buf,
		y_buf,y2_buf,tini_buf,tlag_buf,stat_buf,mark_buf,mtime)
	#cl.enqueue_read_buffer(a_queue, tlag_buf, tlag).wait()
	#print "tlag",cell[200],mark[cell[200]],tlag[200]

    #---------------------------------------------------------------------------
	# update forcing
    #---------------------------------------------------------------------------
	event = interp_knl(a_queue,u1.shape,None,u1_buf,v1_buf,u2_buf,v2_buf,uf1_buf,vf1_buf,
		uf2_buf,vf2_buf,frame_frac)

	#cl.enqueue_read_buffer(a_queue, u_buf, u).wait()
	#cl.enqueue_read_buffer(a_queue, v_buf, v).wait()
	#print "uval",u

    #---------------------------------------------------------------------------
	# advect with opencl
    #---------------------------------------------------------------------------
	event = advect_knl(a_queue,x.shape,None,cell_buf,stat_buf,nbe_buf,a1u_buf,a2u_buf,xc_buf,yc_buf,x_buf,y_buf,u1_buf,v1_buf,u2_buf,v2_buf,deltat) 
	#event = revadvect_knl(a_queue,x.shape,None,x_buf,y_buf,u_buf,v_buf)

    #---------------------------------------------------------------------------
	# dump particle positions to file
    #---------------------------------------------------------------------------
	 
	if (its+1)%freq == 0:
	#if (its==nits-1):
		# transfer data back into host
		cl.enqueue_read_buffer(a_queue, x_buf, x).wait()
		cl.enqueue_read_buffer(a_queue, y_buf, y).wait()
		cl.enqueue_read_buffer(a_queue, cell_buf, cell).wait()
		cl.enqueue_read_buffer(a_queue, tlag_buf, tlag).wait()
		cl.enqueue_read_buffer(a_queue, tini_buf, tini).wait()

    	# write to netcdf file
		icnt = icnt + 1
		print "writing iteration: ",icnt
		t_var[icnt] = mtime_py 
		x_var[icnt] = x
		print "x = ",x
		y_var[icnt] = y
		c_var[icnt] = cell +1
		tini_var[icnt] = tini  
		tlag_var[icnt] = tlag

    #---------------------------------------------------------------------------
	# update model time, timer, and report 
    #---------------------------------------------------------------------------

	# update model time
	mtime = mtime + deltat_py_days
	mtime_py = mtime_py + deltat_py_days
	 
	# update timer
	timer = time()-t1
	temp  = timer/(its+1)
    #print 'time per iteration %5.3f: ' %  temp 

    
print "simulation finished"
print "total gpu time: ", timer
print 
#print x



# close the output file
fin.close()
fout.close()

# finish up

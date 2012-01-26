def horzbareq():
	print "======================================================="

def horzbardash():
	print "-------------------------------------------------------"

def write_output_header(fname,casetitle,nlag,nelems):
	from numpy import *
	from pycdf import *
	try:
		f = CDF(fname, NC.WRITE|NC.CREATE|NC.TRUNC)
		f.automode()
	except CDFError:
		f = CDF(fname, NC.WRITE|NC.CREATE|NC.TRUNC)
		f.automode()

	# global attributes
	f.title = casetitle
	f.source = "pygalt"

	# dimensions
	nlag_dim = f.def_dim('nlag',nlag)
	nele_dim = f.def_dim('nele',nelems)
	time_dim = f.def_dim('time',NC.UNLIMITED)

	# variables
	t_var = f.def_var('time',NC.FLOAT,(time_dim))
	t_var.units = 's'
	x_var = f.def_var('x',NC.FLOAT,(time_dim,nlag_dim))
	x_var.units = 'm'
	y_var = f.def_var('y',NC.FLOAT,(time_dim,nlag_dim))
	y_var.units = 'm'
	c_var = f.def_var('cell',NC.INT,(time_dim,nlag_dim))
	c_var.units = '-'
	m_var = f.def_var('mark',NC.INT,(time_dim,nele_dim))
	m_var.units = '-'
	tlag_var = f.def_var('tlag',NC.FLOAT,(time_dim,nlag_dim))
	tlag_var.units = 'days'
	tini_var = f.def_var('tinit',NC.FLOAT,(time_dim,nlag_dim))
	tini_var.units = 'days'
	
	f.close()


# make sure pycdf is working
from pycdf import *
d = CDF('example.nc',NC.WRITE|NC.CREATE)  # create dataset
d.definemode()
d.title = 'this is an example'      # set attribute type and value
d.close()

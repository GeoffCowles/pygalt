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
freq   = 2          # output frequency in time steps
#-----------------------------------------------------


##-----------------------------------------------------
## set runtime control vars
#outname = "/Users/cliu/Desktop/output.nc"    # output file
#gridfile = "./preprocessing/scp4.1_grid.nc"
#lagfile = "./preprocessing/example_initfile.nc" 
##forcefile = "semass_4x11_dply3_C_vertavge_only_3daytest.nc" 
##forcefile = "semass_4x31_dply3_D_vertavge.nc" 
#forcefile = "/scratch/cmlab/BUZZBAY/HINDCASTS/local/output/scp4.1_ss2010_hind_v3.nc"

#select_GPU = "ATI Radeon HD 6970M"  # GPU to use
#select_PLATFORM = "Apple"

##select_GPU = "Intel"  # GPU to use
##select_PLATFORM = "ATI"

##select_GPU = "Cypress"  # GPU to use
##select_PLATFORM = "ATI"

#deltat_py = 240.  #time step in seconds
#freq   = 500          # output frequency in time steps
#-----------------------------------------------------
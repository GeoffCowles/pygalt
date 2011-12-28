close all; clear all;
gridfile = 'semass_41_mesh.nc';
lagfile = 'slm_out_41_10frame_dply3_surfU_smallDT.nc'; 
slmfile = 'slm.nc';

nc = netcdf(gridfile) ;
xv = nc{'x'}(:);
yv = nc{'y'}(:);
xc = nc{'xc'}(:);
yc = nc{'yc'}(:);
h = nc{'h'}(:);
nv = nc{'nv'}(:,:)';
[nelems,jnk] = size(nv);
nverts = numel(xv);
close(nc);

nc = netcdf(lagfile);
mark = nc{'mark'}(1,:);
cell = find(mark==1);
tlag = nc{'tlag'}(end,:);
tini = nc{'tinit'}(1,:);
close(nc);
%plot(xc(cell),yc(cell),'r+')

nlag = numel(find(tini==0));
ntimes = numel(tini)/nlag;

% compute slm
slm = 1000*ones(nelems,ntimes,1);
tlag = reshape(tlag,nlag,ntimes);
tini = reshape(tini,nlag,ntimes);
for i=1:ntimes
  slm(cell,i) = tlag(:,i)-tini(:,i); 
end;

nc = netcdf(slmfile,'clobber');
% variables
nc('node') = nverts;
nc('elem') = nelems;
nc('time') = ntimes;
nc('three') = 3; 
nc{'x'} = ncfloat('node');
nc{'y'} = ncfloat('node');
nc{'nv'} = ncfloat('three','elem');
nc{'slm'} = ncfloat('time','elem');

nc{'x'}(:) = xv;
nc{'y'}(:) = yv;
nc{'nv'}(:,:) = nv';
nc{'slm'}(:,:) = slm'; 
close(nc);




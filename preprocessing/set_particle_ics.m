% compute the volume of a subregion using a user-clicked bounding box
close all; clear all;

fname = 'semass_41_mesh.nc'; 
fout  = 'slm_init_41_10frame.nc';
nc = netcdf(fname);


% load the mesh and bathymetry
x = nc{'x'}(:);
y = nc{'y'}(:);
h = nc{'h'}(:);
t = nc{'nv'}(:,:);

[jnk,nelems] = size(t);
nverts = prod(size(x));

% compute xc,yc,hc
xc = zeros(nelems,1);
yc = zeros(nelems,1);
hc = zeros(nelems,1);
for i=1:nelems
  xc(i) = sum(x(t(1:3,i)))/3;
  yc(i) = sum(y(t(1:3,i)))/3;
  hc(i) = sum(h(t(1:3,i)))/3;
end;

figure
patch('Vertices',[x,y],'Faces',t',...
       'Cdata',h,'edgecolor','interp','facecolor','interp');
hold on;

axis([8.2e5,8.7e5,-1.6e5,-1.1e5]);

%[xp,yp] = ginput(4);
load bb_bndry;

%xp = [8e5,8.5e5,8.5e5,8e5];
%yp = [-2.5e5,-2.5e5,-2e5,-2e5];
%xp = [6.5e5,7e5,7e5,6.5e5];
%yp = [-1e5,-1e5,0,0];
%xp = [8e5,9e5,9e5,8e5];
%yp = [-2e5,-2e5,0,0];

t1 = [1,2,4];
t2 = [2,3,4];

mark = zeros(nelems,1);
for i=1:nelems
  if(isintriangle(xp(t1),yp(t1),xc(i),yc(i))); 
    mark(i) = 1; 
  end;
  if(isintriangle(xp(t2),yp(t2),xc(i),yc(i))); 
    mark(i) = 1; 
  end;
end;

fprintf('%d of %d elements in subregion\n',sum(mark),nelems);

nlag     = sum(mark);
indomain = find(mark==1);
plot(xc(indomain),yc(indomain),'ro');
close(nc);

% dump header
nc = netcdf(fout,'clobber');
nc.type = 'PYMALT Initial Particle Position File' ;
nc.history = 'FILE CREATED using set_particle_ics'; 

ntimes = 10; 
xinit = zeros(nlag,ntimes);
yinit = zeros(nlag,ntimes);
tinit = zeros(nlag,ntimes);
cinit = zeros(nlag,ntimes);

for i=1:ntimes
   xinit(:,i) = xc(indomain);
   yinit(:,i) = yc(indomain);
   cinit(:,i) = indomain;
   tinit(:,i) = real(i-1); 
end;
  
  

% dimensions
nlag = prod(size(xinit));
nc('nlag') = nlag;



% variables
nc{'x'} = ncfloat('nlag');
nc{'x'}.long_name = 'initial x particle position';
nc{'y'} = ncfloat('nlag');
nc{'y'}.long_name = 'initial y particle position';
nc{'cell'} = ncint('nlag');
nc{'cell'}.long_name = 'initial cell containing particle';
nc{'tspawn'} = ncfloat('nlag');
nc{'tspawn'}.long_name = 'spawn time in days'; 

nc{'x'}(1:nlag) = reshape(xinit,[nlag,1]); 
nc{'y'}(1:nlag) = reshape(yinit,[nlag,1]); 
nc{'cell'}(1:nlag) = reshape(cinit,[nlag,1]); 
nc{'tspawn'}(1:nlag) = reshape(tinit,[nlag,1]); 
close(nc);

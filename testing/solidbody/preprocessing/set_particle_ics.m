% compute the volume of a subregion using a user-clicked bounding box
close all; clear all;

fname = '../solidbody.nc'; 
fout  = 'solidbody_test.nc';
nc = netcdf(fname);


% load the mesh and bathymetry
x = nc{'x'}(:);
y = nc{'y'}(:);
h = nc{'h'}(:);
t = nc{'nv'}(:,:)';

[nelems,jnk] = size(t);
nverts = numel(x);

% compute xc,yc,hc
xc =mean(x(t),2);
yc =mean(y(t),2);
hc =mean(h(t),2);

figure
patch('Vertices',[x,y],'Faces',t,...
       'Cdata',h,'edgecolor','interp','facecolor','interp');
hold on;


% %[xp,yp] = ginput(4);
% load bb_bndry;
% 
% %xp = [8e5,8.5e5,8.5e5,8e5];
% %yp = [-2.5e5,-2.5e5,-2e5,-2e5];
% %xp = [6.5e5,7e5,7e5,6.5e5];
% %yp = [-1e5,-1e5,0,0];
% %xp = [8e5,9e5,9e5,8e5];
% %yp = [-2e5,-2e5,0,0];
% 
% t1 = [1,2,4];
% t2 = [2,3,4];
% 
% mark = zeros(nelems,1);
% for i=1:nelems
%   if(isintriangle(xp(t1),yp(t1),xc(i),yc(i))); 
%     mark(i) = 1; 
%   end;
%   if(isintriangle(xp(t2),yp(t2),xc(i),yc(i))); 
%     mark(i) = 1; 
%   end;
% end;
% 
% fprintf('%d of %d elements in subregion\n',sum(mark),nelems);
% 
% nlag     = sum(mark);
% indomain = find(mark==1);
% plot(xc(indomain),yc(indomain),'ro');
% close(nc);



ntimes = 1; 
% xinit = zeros(nlag,ntimes);
% yinit = zeros(nlag,ntimes);
% tinit = zeros(nlag,ntimes);
% cinit = zeros(nlag,ntimes);

% for i=1:ntimes
%    xinit(:,i) = xc(indomain);
%    yinit(:,i) = yc(indomain);
%    cinit(:,i) = indomain;
%    tinit(:,i) = real(i-1); 
% end;
  
xinit = 250.05:100:750.05; nlag = numel(xinit);
yinit = 500*ones(nlag,1);
tinit = zeros(nlag,1);
cinit = zeros(nlag,1);

for i=1:nlag
    for j=1:nelems
        if(isintriangle(x(t(j,:)),y(t(j,:)),xinit(i),yinit(i)))
            cinit(i)=j;
        end
    end
end



% dump header
nc = netcdf(fout,'clobber');
nc.type = 'PYMALT Initial Particle Position File' ;
nc.history = 'FILE CREATED using set_particle_ics'; 

% dimensions
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

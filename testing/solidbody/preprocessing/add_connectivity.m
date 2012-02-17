%function add_connectivity(fname);
fname = '../solidbody.nc';
nc = netcdf(fname,'w');
x = nc{'x'}(:);
y = nc{'y'}(:);
xc = nc{'xc'}(:);
yc = nc{'yc'}(:);
h = nc{'h'}(:);
nv = nc{'nv'}(:,:)';
ntve = nc{'ntve'}(:);
nbve = nc{'nbve'}(:,:)';
nbe = nc{'nbe'}(:,:)';
patch('Vertices',[x,y],'Faces',nv,...
       'Cdata',h,'edgecolor','k','facecolor','w');
[nelems,jnk] = size(nv);
hold on;

% analyze the ntve/nbve situation
maxney = 16;
eney = zeros(nelems,maxney);
neney = maxney*ones(nelems,1);
% for i=1:nelems
%     radlist = sqrt( (xc - xc(i)).^2 + (yc - yc(i)).^2 );
%     [~,rad_ind] = sort(radlist,'ascend');
%     eney(i,:) = rad_ind(1:maxney);
% 
%     
% end

eney = zeros(nelems,maxney);
neney = zeros(nelems,1);
for i=1:nelems
  cnt = 1;  
  neney(i) = cnt;
  eney(i,cnt) = i;
  for j=1:3
    cell = nbe(i,j);
    if(cell > 0);
      cnt = cnt + 1;
      neney(i) = cnt; 
      eney(i,cnt) = cell;
    end;
  end;
  for node = 1:3
    i1 = nv(i,node);
    for j=1:ntve(i1);
      cell = nbve(i1,j);
      if(numel(find(eney(i,1:cnt)==cell))==0);
  	cnt = cnt + 1;
        neney(i) = cnt;
        eney(i,cnt) = cell;
      end;
    end;
  end;
end;

check = 50;
hold on;
plot(xc(eney(check,1)),yc(eney(check,1)),'g+')
plot(xc(eney(check,2:4)),yc(eney(check,2:4)),'b+')
plot(xc(eney(check,5:neney(check))),yc(eney(check,5:neney(check))),'r+')

check = ceil(nelems/2);
hold on;
plot(xc(eney(check,1)),yc(eney(check,1)),'g+')
plot(xc(eney(check,2:4)),yc(eney(check,2:4)),'b+')
plot(xc(eney(check,5:neney(check))),yc(eney(check,5:neney(check))),'r+')

% dump the new vars
nc('maxney') = maxney;
nc{'eney'} = ncint('maxney','nele');
nc{'eney'}.long_name = 'element neighbors'; 
nc{'neney'} = ncint('nele');
nc{'neney'}.long_name = 'number of element neighbors';

nc{'eney'}(1:maxney,1:nelems) = eney';
nc{'neney'}(1:nelems) = neney(1:nelems);
close(nc);


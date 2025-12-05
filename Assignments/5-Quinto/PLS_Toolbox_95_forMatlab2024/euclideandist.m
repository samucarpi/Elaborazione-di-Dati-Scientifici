function dist = euclideandist(x,basis,options)
%EUCLIDEANDIST Calculate Euclidean Distance betweem rows of a matrix.
% Calculates the Euclidean Distance (sum of the squared differences) from
% each row to every other row in the supplied matrix or, optionally, all
% rows of (x) to all rows in a second matrix (basis). 
%
% If input (x) is a dataset, then any excluded columns (variables) will be
% ignored in the calculation and any excluded rows (samples) will only be
% returned as ROWS in the output distance matrix. That is, distance TO
% excluded samples will not be included as columns. For example, if there
% are 10 samples but only samples 1-5 are included, the output distance
% matrix will be 10 rows (one for each sample) and 5 columns (designating
% the distance to each of the 5 included samples)
%
% Optional input (options) is a structure with one or more of the following
% fields:
%   waitbar : [ 'off' | 'on' | {'auto'}] Governs display of a waitbar
%             during the calculation. If 'auto' then a waitbar will be
%             displayed only if the total calculation time is likely to
%             exceed 3 seconds.
%   diag    : {0} Defines what value should be used when comparing a sample
%             to itself. Technically, this distance is zero, but in some
%             instances, using an alternative value (e.g. "inf") is useful
%             for flagging these self-calculated distances.
%
%I/O: dist = euclideandist(x,options)
%I/O: dist = euclideandist(x,basis,options)

%Copyright © Eigenvector Research, Inc. 1993
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%JMS extracted from cluster.m and refactored for excluded samples 2014
if nargin<1
  x = 'io';
end

if ischar(x);
  options = [];
  options.waitbar = 'auto';  %'auto' 'on' 'off'
  options.diag    = 0;  %what should the diagonal (self sample distance) be
  
  if nargout==0; evriio(mfilename,x,options); else dist = evriio(mfilename,x,options); end
  return;
end

switch nargin
  case 1
    basis   = [];
    options = [];
  case 2
    if isstruct(basis)
      options = basis;
      basis = [];
    else
      options = [];
    end
  case 3
end
options = reconopts(options,mfilename);

[m,n]   = size(x);
[bm,bn] = size(basis);
if ~isdataset(x)
  x = dataset(x);
end  
incl  = x.include;
mincl = length(incl{1});
if ~isempty(basis)
  if isdataset(basis)
    incl{2} = basis.include{2};
    basis = basis.data(basis.include{1},incl{2});
  else
    basis = basis(:,incl{2});
  end
end  
hasexcluded = (m~=length(incl{1}));
x = x.data(:,incl{2});

[m,n]   = size(x);
[bm,bn] = size(basis);

%initialize calcs for waitbar
waitbarhandle = [];
startat = now;
switch options.waitbar
  case 'auto'
    trigger = 3;
  case 'off'
    trigger = inf;
  case 'on'
    trigger = 0;
end

if isempty(basis)
  %normal x samples to x samples
  if n>m
    if ~hasexcluded
      usemode = 1;
      ivect = 2:m;
    else
      usemode = 11;
      ivect = 1:m;
      subrange = intersect(ivect,incl{1});
    end
  else
    usemode = 2;
    ivect = incl{1};
  end
  dist = ones(m,mincl).*options.diag;
else
  %calculate distance from x samples to a basis samples
  dist    = zeros(m,bm);
  usemode = 3;  %always when we have a basis
  ivect   = 1:m;
end

for ii = 1:length(ivect)
  
  i = ivect(ii);
  
  switch usemode
    case 1
      %element-by-element calculation (faster if vars>samps)
      for j = 1:i-1;
        dist(i,j) = single(sqrt(sum((x(i,:)-x(j,:)).^2)));
        dist(j,i) = dist(i,j);
      end
      dist(i,i) = options.diag;

    case 11
      %element-by-element calculation with Excluded (faster if vars>samps)
      for jj = 1:length(subrange)
        switch subrange(jj)
          case i
            continue
        end
        dist(i,jj) = single(sqrt(sum((x(i,:)-x(subrange(jj),:)).^2)));
      end
      
    case 2
      %sum of subtracted variables (faster if vars<samps)
      colsum = 0;
      for v = 1:n
        colsum = colsum + (x(:,v)-x(i,v)).^2;
      end
      dist(:,ii) = single(sqrt(colsum));
      dist(i,ii) = options.diag;
      
    case 3
      %compare x to a basis
      for j = 1:bm
        dist(i,j) = single(sqrt(sum((x(i,:)-basis(j,:)).^2)));
      end
      
  end
  
  %do waitbar
  if isfinite(trigger) & (now-startat)*24*60*60>3 & mod(i,min(100,fix(m/20)))==0;
    switch usemode
      case 1
        comb_done = (((i*(i+1))/2)-1);
        im   = length(ivect);
        pct  = comb_done/(((im*(im+1))/2)-1);
        
      case {11, 2,3}
        pct = i/m;
        
    end
    est = (1-pct)*((now-startat)*24*60*60)/pct;
    if ~isempty(waitbarhandle)
      if ishandle(waitbarhandle)
        waitbar(pct);
        set(waitbarhandle,'name',['Est. Time Remaining: ' besttime(est)])
      else
        error('User cancelled distance calculation');
      end
    elseif est > trigger
      waitbarhandle = waitbar(pct,'Calculating Distances');
      set(waitbarhandle,'name',['Est. Time Remaining: ' besttime(est)])
    end
  end
  
  
end
if ~isempty(waitbarhandle);
  delete(waitbarhandle);
  drawnow;
end

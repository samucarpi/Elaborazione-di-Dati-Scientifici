function out = std(x,flag,dim,missing,maxbytes)
%STD Memory friendly standard deviation calculation.
% The I/O for this function is identical to the Mathworks STD function.

% Copyright © Eigenvector Research, Inc. 2009
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

persistent is65 is84
if isempty(is65)
  is65 = checkmlversion('<','7.0');
end
if isempty(is84)
  is84 = checkmlversion('<','8.5');
end

%defaults for unsupplied inputs
if nargin<3
  dim = 1;
  while size(x,dim)==1 & dim<ndims(x)
    dim = dim+1;
  end
end
if nargin<2 | isempty(flag)
  flag = 0;
end
if nargin<4 | isempty(missing)
  % matlab 8.5 added new 4th argument to std 'missing'
  missing = 'includenan';
end
if nargin<5 | isempty(maxbytes);
  %determine maximum window size allowabl
  maxbytes = 5e6;
end

%get some constants
sz = size(x);
nrm = sz(dim)-1+flag;   %normalization factor (flag = 0 is n-1; flag = 1 is n)

switch is65
  case 1
    %6.5 ALWAYS does simple method
    out = sqrt(var(x));
    return;
end

if prod(sz)*8*2<maxbytes
  %total size of x is safe for standard call to var? use that
  % (note: safe is number of bytes required by x * duplicate variables used within var)
  if is84
    out = sqrt(var(x,flag, dim));
  else
    out = sqrt(var(x,flag, dim, missing));
  end
  return
end

%We have to use windows, figure out how big a window we can use
usevar = 1;  %flag saying if we should use the "var" function for sub-matrix calcs (faster individual calcs, but smaller windows required)
winsize = (maxbytes./8./sz(dim)).^(1/(length(sz)-1));  %calculate window size needed to keep memory under that limit
if usevar; winsize = winsize/2; end  %correct for additional memory useage by std function
winsize = max(1,floor(winsize));   %get rounded window size

%define which indices we're indexing through
indexon = setdiff(1:length(sz),dim);

%create subsref array to do indexing
[subs{1:length(sz)}] = deal(':');
[subs{indexon}] = deal(1:winsize);
for j=indexon
  subs{j}(subs{j}>sz(j)) = [];
end
S = substruct('()',subs);
R = S;
R.subs{dim} = 1;

%create output matrix
sz_out = sz;
sz_out(dim) = 1;
out = zeros(sz_out)*nan;

%loop over all indexes. Loop is terminated when we sense our counters
%(stored in subs) have all rolled over back to {1 1 ... 1}
done = false;
while ~done

  %create indexing and assignment substructs
  S.subs = subs;
  R.subs(indexon) = S.subs(indexon);

  %get vector, calculate std and store in output
  vect = subsref(x,S);
  
  switch winsize
    case 1
      vect = vect-mean(vect);
      val  = sqrt(sum(vect.^2)/nrm);
      
    otherwise
      switch usevar
        case 1
          val = sqrt(var(vect,flag,dim));
          
        otherwise
          %windowsize > 1
          % use matrix-friendly std
          vect  = permute(vect,[dim indexon]);
          vectr = vect(:,:);
          mn    = mean(vectr);
          for j=1:size(vectr,2)
            vectr(:,j) = vectr(:,j)-mn(j);
          end
          val  = sqrt(sum(vectr.^2)/nrm);
          szv  = size(vect);
          val  = reshape(val,[1 szv(2:end)]);
          val  = reshape(val,cellfun('length',S.subs));
      end
      
  end
  
  out  = subsasgn(out,R,val);
  
  %increment to next element
  for j=indexon
    %increment this element
    subs{j} = subs{j}+winsize;
    subs{j}(subs{j}>sz(j)) = [];  %drop invalid indices
    if isempty(subs{j})
      %if it rolled over, allow increment of next element after resetting this one
      subs{j} = 1:winsize;
      if j==indexon(end)
        %last element rolled over? we're done exit now
        done = true;
      end
    else
      %this did not roll over, don't increment any others
      break;
    end
  end  %increment indexed elements loop
  
end  %end while

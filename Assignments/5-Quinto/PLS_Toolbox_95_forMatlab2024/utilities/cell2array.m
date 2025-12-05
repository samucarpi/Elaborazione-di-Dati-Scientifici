function xx = cell2array(x,xsize);
%CELL2ARRAY Converts a cell of batch data to a zero-padded array.
%
%I/O: xnew = cell2array(x);
%
%See also: CELL2HTML

%Copyright Eigenvector Research 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if isstr(x)
  xx = x;
  return
end

% Define xsize
if nargin==1 
  if isa(x,'dataset')% Then it's a SDO
    if iscell(x.data)
      order = length(size(x.data{1}))+1;
      xsize = NaN; % first mode variable-length
      for k = 2:order-1
        xsize(k) = length(x.includ{k});
      end
      xsize(order) = length(find(x.includ{1}));
    else
      order = length(size(x.data));
      inc = x.includ;
      for k = 1:order
        xsize(k) = length(find(x.includ{k}));
      end
    end
  else
    % Determine size of x
    if ~iscell(x)&~isstr(x) 
      order = length(size(x));
      xsize = size(x);
    elseif ~isstr(x)
      order = length(size(x{1}))+1;
      xsize = [size(x{1}) length(x)];  
      % Make last-1 mode dimension NaN to indicate that it may vary
      xsize(1) = NaN;
    else
      order = 3;
    end
  end
end
order = length(xsize);
if ~isa(x,'dataset')% Then it's a SDO
  includ = 1:xsize(end);
else
  includ = x.includ{1};
end


% Make X a an array (zero-padded) if it's a cell
if isa(x,'dataset')
  xx = x.data;
else
  xx = x;
end
if iscell(xx)
  J = 1; % Find max size of varying mode 
  for k = 1:length(xx)
      KK = size(xx{k},1);
      J = max(J,KK(1));
  end
  X = zeros([J xsize(2:end)]);
  X = permute(X,[order 1:order-1]);
  
  count = 0;
  for k = 1:length(xx);
    if any(includ==k)
      if isa(x,'dataset')
        % Make include fields for each cell at a time
        inc = x.includ;
        xxk = xx{k};
        inc{1} = 1:size(xxk,1);
        xxk = xx{k}(inc{:});
        xs = size(xxk);
      else
        xs = size(xx{k});
        xxk = xx{k};
      end
      K = xs(1);
      X(k-count,1:xs(1),:)=reshape(xxk,xs(1),prod(xs)/xs(1));
    else
      count = count+1;
    end
  end
  X = ipermute(X,[order 1:order-1]);
  X = reshape(X,[J xsize(2:end)]);
  xx = X;
  xsize(1) = J;
else
  if isa(x,'dataset')% Then it's a SDO
    inc=x.includ;
    xx = xx(inc{:});
  end
end

function R2 = r2calc(x,y,old)
%R2CALC Calculate R^2 for a given pair of vectors or matricies.
% R2CALC is used to calculate the correlation coefficient (R-squared) for
% pairs of vectors, such as a predicted and measured values from a
% regression model (y-predicted and y-measured). The inputs are the two
% vectors (x) and (y) and the output is the R^2 value for those vectors.
% Non-finite values in either (x) or (y) are automatically ignored in this
% calculation.
%
% If input (x) or (y) is a matrix, the output (R2) will contain the paired
% R^2 values for each pair of column-wise vectors in the matricies. Columns
% of (x) are columns of (R2). Columns of (y) are rows of (R2). For example,
% if (x) contains 5 columns and (y) is a single column, (R2) will be a 1 by
% 5 vector of R^2 values.
%
%I/O: R2 = r2calc(x,y)

%Copyright Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% JMS 12/2008 split out from plotscoreslimits for use other places

if ndims(x)>2 | ndims(y)>2
  error('R2 is not currently defined for multiway matricies')
end

%extract from DSOs
if isdataset(x) & isdataset(y)
  %use intersection of include in first mode (if both are DSOs)
  incl = intersect(x.include{1},y.include{1});
  x.include{1} = incl;
  y.include{1} = incl;
end
if isdataset(x)
  include = x.include;
  if ~isdataset(y) & size(y,1)==size(x,1)
    %same # of rows in y as in x and y isn't DSO? apply include here too
    y = y(include{1},:);
  end
  x = x.data(include{:});
end
if isdataset(y)
  include = y.include;
  if size(y,1)==size(x,1)
    %same # of rows in y as in x? apply include here too (note: x will
    %never be DSO here because code above will extract it. But if the
    %include field of X is empty, this will use the y include field on x)
    x = x(include{1},:);
  end
  y = y.data(include{:});
end

%transpose if row vectors 
if size(x,1)==1 & size(x,2)>1
  x = x';
end
if size(y,1)==1 & size(y,2)>1
  y = y';
end
% transpose if mismatched sizes (but not 2 equal size square matrices case)
if size(x,1)==size(y,2) & size(x,1)~=size(y,1)
  y = y';
elseif size(x,2)==size(y,1) & size(x,2)~=size(y,2)
  x = x';
end

% %OLD CODE: The following is the OLD way of calculating R2. Much slower.
% for j=1:size(y,2);
%   usey = isfinite(y(:,j));
%   for k=1:size(x,2);
%     use = isfinite(x(:,k)) & usey;
%     R2m = corrcoef(x(use,k),y(use,j)).^2;
%     R2(j,k) = R2m(1,2);
%   end
% end

R2 = [];
usex = isfinite(x);
usey = isfinite(y);

%check for special cases:
if all(all(usex,2)==any(usex,2)) & all(all(usey,2)==any(usey,2))
  %if same elements are missing in all columns or none are missing
  if ~all(usex(:)) | ~all(usey(:))
    %same elements missing in all columns, drop the affected rows
    use = all(usex,2) & all(usey,2);
    x = x(use,:);
    y = y(use,:);
  end
  
  %everything is finite now, easy case
  x = mncn(x);
  y = mncn(y);
  if isempty(x) | isempty(y)
    R2 = [];
  else
    R2 = mycorrcoef(y,x).^2;
  end
   
else
  %difficult case - mismatched missing  
  x(~usex) = 0;
  y(~usey) = 0;
  R2 = zeros(size(y,2),size(x,2));
  for j=1:size(y,2);
    for k=1:size(x,2);
      use = usex(:,k) & usey(:,j);
      y1 = y(use,j);
      x1 = x(use,k);
      y1 = y1-mean(y1);
      x1 = x1-mean(x1);
      R2(j,k) = mycorrcoef(x1,y1).^2;
    end
  end
  
end

%----------------------------------------------------
function cc = mycorrcoef(x,y)

cc = (x'*y)./sqrt(sum(x.^2)'*sum(y.^2));

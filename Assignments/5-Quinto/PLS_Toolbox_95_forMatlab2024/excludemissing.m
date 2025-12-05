function [newx,bad] = excludemissing(x,threshold)
%EXCLUDEMISSING Automatically exclude too-much missing data in a matrix.
% Excludes rows, columns, or n-dim elements of input (x) which have too
% much missing based on the input (threshold) which is a fraction of
% allowed missing data. If omitted, threshold will be equal to the default
% max_missing value of the function MDCHECK (typically 0.40).
% Note, excludemissing soft-excludes rows or columns with too much missing
% data. It then repeat checks to see if the remaining included rows or
% columns might now have any bad rows/columns. The repeat check cycle 
% continues until now new bad rows or columns are found.
%
% Outputs are a dataset object with excluded elements (newx) and a cell
% holding the indices of the bad elements for each mode of data (bad).
%
%I/O: [newx,bad] = excludemissing(x,threshold);
%
%See also: MDCHECK, REPLACE

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0; x = 'io'; end
if isstr(x)
  options = [];
  if nargout==0; evriio(mfilename,x,options); else; newx = evriio(mfilename,x,options); end
  return;
end

if nargin<2;
  options = mdcheck('options');
  threshold = options.max_missing;
end

if ~isa(x,'dataset');
  x = dataset(x);
end

nd = ndims(x);
includeschanged = true;
badacc = cell(1,nd);
while includeschanged
  includeschanged = false;
  %get missing map for included data
  incl = x.include;
  [flag,immap] = mdcheck(x.data(incl{:}));
  if isempty(immap)
    immap = zeros(size(x.data(incl{:})));
  end
  
  %insert missing map into full-sized map of all data
  immap = single(immap);
  
  %locate "bad" elements for each mode
  for mode = 1:nd;
    nmissing = immap;
    for othermodes = setdiff(1:nd,mode);
      %average of mssing data in all other modes
      nmissing = mean(nmissing,othermodes);
    end
    %locate elements with more missing than allowed
    bad{mode} = find(nmissing>threshold);
    bad{mode} = bad{mode}(:)';  %row-vectorize
  
      includeall = x.include{mode};
      b2 = badacc{mode};
      b22 = bad{mode};
      if numel(b22)>0 
        includeschanged = true;
      end
      btmp = setdiff(includeall,b2);
      % update accumulation of bad row/cols
      badacc{mode} = union(b2,btmp(b22));
      badacc{mode} = badacc{mode}(:)';
      x.include{mode} = setdiff(includeall, badacc{mode});    
  end
end   % while
newx = x;
bad  = badacc;

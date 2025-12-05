function [x,y] = matchrows(x,y,options)
%MATCHROWS Matches up rows from two DataSet objects using labels or sizes.
% Given two input DataSet objects (x) and (y), MATCHROWS locates rows of
% (y) which match rows of (x) based on the labels in both objects and
% re-orders (y) to match (x). If (y) contains additional rows which match
% no rows of (x), they are dropped from (y). If some rows of (x) do not
% have matching (y) rows, the corresponding rows of (y) are filled in with
% NaN.
%
% If no matching row labels are found, MATCHROWS searches other modes
% of x and y for matching labels. If no matching labels are found in any
% mode, sizes of the inputs are used to attempt a match. If no sizes match,
% an error is thrown.
%
% Output DSOs are aligned (and possibly transposed or permuted) DataSets.
%
% The order of tests is:
%   All label sets on mode 1 of both x and y
%   All label sets on modes 2-k of y vs. mode 1 of x (transpose y)
%   All label sets on modes 2-k of y vs. modes 2-k of x (transpose x and y)
%   Number of y rows vs. number of x rows (no change)
%   Number of y columns vs. number of x rows (transpose y)
%   Number of y columns vs. number of x columns (transpose x and y)
% (where k is the number of modes of x or y) Multi-dimensional x and y are
% supported by all tests.
% 
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%           unique_labels: [ 'off' | {'on'} ] Require labels to be unique in x before matching.
%
%I/O: [x,y] = matchrows(x,y)
%
%See also: ALIGNMAT, EDITDS, MATCHVARS, SHUFFLE

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0; x = 'io'; end
if ischar(x);
  options = [];
  options.unique_labels = 'on';
  if nargout==0; evriio(mfilename,x,options); clear x; else;  x     = evriio(mfilename,x,options);  end
  return;
end

if nargin<3
  options = matchrows('options');
end

options = reconopts(options,mfilename);

if ~isdataset(x); x = dataset(x); end
if ~isdataset(y); y = dataset(y); end

%look for matching labels
ylbls = y.label;
xlbls = x.label;
match = false;
for xmode = 1:ndims(x);  %loop over all modes of x
  for ymode = 1:ndims(y);  %loop over all modes of y
    for yset = 1:size(ylbls,2)  %loop over all label sets
      if isempty(ylbls{ymode,yset}); continue; end   %no labels in this set
      ylbl = str2cell(ylbls{ymode,yset});
      if strcmpi(options.unique_labels,'on') & length(ylbl)~=length(unique(ylbl))     %labels are not unique
        continue
      end
      for xset = 1:size(xlbls,2) %loop over all label sets
        if isempty(xlbls{xmode,xset}); continue; end   %no labels in this set
        %see if these two sets match at all
        xlbl = str2cell(xlbls{xmode,xset});
        if strcmpi(options.unique_labels,'on') & length(xlbl)~=length(unique(xlbl))
          %labels are not unique
          continue
        end
        [commonlabels,yindex,xindex] = intersect(ylbl,xlbl);
        if ~isempty(commonlabels)  %something in common?
          match = true;
          break;
        end
      end
      if match; break; end  %got a match, skip other sets
    end
    if match; break; end  %got a match, skip other sets
  end
  if match; break; end  %got a match, skip other sets
end

if ~match
  %no matches by labels? check sizes
  usedlabels = false;  %indicate that we did NOT find labels
  szx = size(x);
  szy = size(y);
  for xmode = 1:ndims(x);
    for ymode = 1:ndims(y);
      if szx(xmode)==szy(ymode)
        xindex = 1:szx(xmode);
        yindex = xindex;
        match = 1;
        break;
      end
    end
    if match; break; end  %got a match, skip other sets
  end
else
  usedlabels = true;  %indicate that we DID find labels
end

if match
  %got a matching pair of sets
  %first check for transposed x or y block
  if xmode>1;
    x = permute(x,[xmode setdiff(1:ndims(x),xmode)]);  %switch mathing dim to first mode
  end
  if ymode>1;
    y = permute(y,[ymode setdiff(1:ndims(y),ymode)]);  %switch mathing dim to first mode
  end
  if length(yindex)~=size(x,1) | ~all(yindex==xindex)
    %if we need to reorder and/or insert missing values...
    temp = nan(1,size(x,1));
    temp(xindex) = yindex;
    missing = isnan(temp);   %identify missing y rows
    if any(missing)
      %create fake row of y to replicate for missing values. This makes
      %sure we don't have any classes, axisscales, etc for these missing
      %items.
      ysz = size(y);
      y = [y;dataset(nan([1 ysz(2:end)]))];
      temp(missing) = size(y,1);
    end
    %reorder rows of y including adding "missing" for rows which didn't
    %appear in y (only in x)
    y = nindex(y,temp,1);
    if usedlabels
      %if we used labels to align, copy the labels we used from x to y
      y.label{1,yset} = x.label{1,xset};
    end
  end
else
  error('Could not find corresponding labels or matching sizes.')
end

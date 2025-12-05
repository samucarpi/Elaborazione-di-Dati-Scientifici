function adata = augmentdata(mode,varargin)
%AUGMENTDATA Augment one or more datasets regardless of size.
% With two datasets of differing sizes 'augmentdata' will infill (at the
% ends) with NaN to achieve correct sizing for concatenation along 'mode'.
%
%
%I/O: adata = augmentdata(mode,x,y)
%I/O: adata = augmentdata(mode,x,y,z,...)
%
%See also: MATCHROWS, MATCHVARS, REPLACE

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%Get size info.
allsz = size(varargin{1});%All sizes.
for i = 2:length(varargin)
  thissize = size(varargin{i});
  sz_ts = size(thissize);%This size.
  sz_as = size(allsz);%All size.
  if sz_ts(2) > sz_as(2)
    %Add ones to all sizes.
    allsz = [allsz ones(sz_as(1),sz_ts(2) - sz_as(2))];
  elseif sz_ts(2) < sz_as(2)
    %Add ones to this size.
    thissize = [thissize ones(1,sz_as(2) - sz_ts(2))];
  end
  allsz = [allsz;thissize];
end

maxsz = max(allsz);

adata = [];
%Loop through incoming data, upsize and augment.
for i = 1:length(varargin)
  thisdata = varargin{i};%Get single dataset.
  padsz = allsz(i,:);
  %Loop through all modes.
  for j = 1:length(maxsz)
    if j == mode
      %Skip the aug mode.
      continue
    end
    %Pad all other dims to max size.
    if maxsz(j)>padsz(j);
      padsz(j) = maxsz(j)-padsz(j);
    else
      continue
    end
    thisdata = cat(j,thisdata,nan(padsz));
    padsz(j) = maxsz(j);%Account for new size.
  end
  adata = cat(mode,adata,thisdata);
end
  
%-----------------------
%TEST: adata = augmentdata(1,ones(3),rand(2))
%TEST: adata = augmentdata(2,ones(3),rand(2))
%TEST: adata = augmentdata(3,ones(3),rand(2))
%TEST: adata = augmentdata(2,ones(3),rand(2),zeros(4,4))
%TEST: adata = augmentdata(2,dataset(ones(3)),rand(2))
%TEST: adata = augmentdata(1,rand(3,2,2),ones(2,3,3))
%TEST: adata = augmentdata(2,rand(3,2,2),ones(2,3,3))
%TEST: adata = augmentdata(3,rand(3,2,2),ones(2,3,3))
%TEST: adata = augmentdata(3,rand(3,2,2),ones(2,3),ones(1,1,2,2))

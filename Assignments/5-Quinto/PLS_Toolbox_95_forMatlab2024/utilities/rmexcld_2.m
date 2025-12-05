function [iinc,jinc] = rmexcld_2(m,i1,w)
%RMEXCLD_2 Remove edges excluded before running spatial derivative operator
%  For a DataSet object (x) of type 'image' [x.type=='image'], RMEXCLD_3
%  returns indices with edges and excluded pixels accounted for so that
%  the spatial derivatiaves are not influenced by edge effects and excluded
%  pixels (see RMEXCLD_2DEMO for additional information).
%
%  For a M by N image DataSet object can be reshaped to a Mx by My by N
%  matrix y = reshape(x.data,[x.imagesize N]); where x.imagesize = [Mx My]
%  and M = prod(x.imagesize) = Mx*My;.
%  For zc = the derivative down the spatial columns then
%    covv = zv(iinc,:)'*zv(iinc,:)/length(iinc); and
%  for zh = the derivative across the spatial rows then
%    covh = zh(jinc,:)'*zh(jinc,:)/length(jinc);.
%  The spatial covariance matrices that are not influenced by excluded
%  pixels.
%    
%  INPUTS:
%      m = [Mx My] two element vector of image size: x.imagesize.
%     i1 = x.include{1} DataSet include field for x.type=='image'.
%
%  OPTIONAL INPUT:
%      w = {3} scalar window width (odd member of [1:2:odd scalar]).
%
%  OUTPUTS:
%   iinc = indices for down the columns.
%   jinc = indices for across the rows.
%
%Example:
%   [iinc,jinc] = rmexcld_2(x.imagesize,x.include{1},5);
% 
%I/O: [iinc,jinc] = rmexcld_2(m,i1,w);
%
%See Also: SAVGOL_2

% Copyright © Eigenvector Research, Inc. 2021
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Note: minimal error checking in the interest of speed

if nargin<3
  w       = 3; %window for derivative operator
end
if w==1
  p2      = 1;
  p       = [-1 0];
else
  p2      = floor(w/2);
  p       = -p2:p2;
end

%Remove indices next to the edges
[ii,jj]   = ind2sub(m,i1);

iinc      = i1;
jinc      = i1;
for k=1:p2
  iinc    = setdiff(iinc,sub2ind(m,ii(ii==k),     jj(ii==k)));
  jinc    = setdiff(jinc,sub2ind(m,ii(jj==k),     jj(jj==k)));
end
if w~=1
  for k=0:p2-1
    iinc  = setdiff(iinc,sub2ind(m,ii(ii==m(1)-k),jj(ii==m(1)-k)));
    jinc  = setdiff(jinc,sub2ind(m,ii(jj==m(2)-k),jj(jj==m(2)-k)));
  end
end

%Remove due to excluded indices (excluded internal pixels)
inu       = setdiff(1:prod(m),i1); %,iinc);%excluded pixels
if ~isempty(inu)
  [ii,jj] = ind2sub(m,inu); %excluded pixels
  jj      = jj(ii>p2 & ii<=m(1)-p2);
  ii      = ii(ii>p2 & ii<=m(1)-p2);
  if ~isempty(ii)
    for k=1:length(p)
      iinc  = setdiff(iinc,sub2ind(m,ii+p(k),jj));
    end
  end
  [ii,jj] = ind2sub(m,inu); %excluded pixels
  ii      = ii(jj>p2 & jj<=m(2)-p2);
  jj      = jj(jj>p2 & jj<=m(2)-p2);
  if ~isempty(ii)
    for k=1:length(p)
      jinc  = setdiff(jinc,sub2ind(m,ii,jj+p(k)));
    end
  end
end

end %RMEXCLD_2
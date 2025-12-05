function s = percentile(x,y)
%PERCENTILE Finds percentile point (similar to MEDIAN).
%  Input (x) is a M by N data array, (y) is a percentile where 0<y<1.
%  The output is a 1 by N vector (s) of percentile points [PERCENTILE 
%  works on the columns of (x)].
%
%Example: If y=0.5 then s is the median.
%Example: for (x) M by 1 then
%    hist(x,200)
%    vline(percentile(x,0.9))
%  draws the 90% percentile on the histogram.
%
%I/O: s = percentile(x,y);
%
%See also: MEDIAN

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
%jms 7/03 evriio enabled

%Should add dim so that s = percentile(x,y,dim);

if nargin == 0; x = 'io'; end
if ischar(x);
  options = [];
  if nargout==0; clear s; evriio(mfilename,x,options); else; s = evriio(mfilename,x,options); end
  return; 
end

m      = size(x,1);
x      = sort(x);
if y<0|y>1
  error('Input (y) must be betweeen 0 and 1')
end

my     = m*y;
mlo    = floor(my);
if (my-mlo)~=0
  s    = x(ceil(my),:);
else
  s    = (x(mlo,:)+x(mlo+1,:))/2;
end

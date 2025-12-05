function i0 = localmaxima(x,w)
%LOCALMAXIMA Automated identification of local maxima
%  Finds maxima in windows of width (w). Wider windowing
%  is used to avoid local maxima that might be due to
%  noise - the default window width =3.
%  This function is called by PEAKFIND.
%
%  INPUT:
%    x      = MxN matrix of measured traces containing peaks
%             each 1xN row of (x) is an individual trace.
%
%  OPTIONAL INPUT:
%    w      = odd scalar window width for determining local maxima.
%             {default: w = 3}.
%
%  OUTPUT:
%    i0     = Mx1 cell w/ indices of the location of the major peaks
%             for each of the M traces.
%
%  EXAMPLES:
%    load nir_data
%    plot(spec1.axisscale{2},spec1.data(1,:))
%    i0 = localmaxima(spec1.data(1,:));
%    vline(spec1.axisscale{2}(i0{1}))
% 
%    i0 = localmaxima(spec1.data(1,:),5);
%    vline(spec1.axisscale{2}(i0{1}),'r')
%
%I/O: i0 = localmaxima(x,w);
%
%See also: PEAKFIND

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%NBG 8/05

[m,n] = size(x);
i0    = cell(m,1);
if nargin<2
  w   = 3;
end
if mod(w,2)~=1
  error('Input (w) must be odd.')
end
p     = (w-1)/2;
for j1=1:m  %Finds major peaks
  tmp = zeros(w-1,n);
  for j2=1:p
    tmp(j2,p+1:end-p)   = sign(x(j1,p+1:end-p)-x(j1,j2:end-2*p+j2-1));
    tmp(p+j2,p+1:end-p) = sign(x(j1,p+1:end-p)-x(j1,p+j2+1:end-p+j2));
  end
  i0{j1} = find(sum(tmp)==2*p);
end

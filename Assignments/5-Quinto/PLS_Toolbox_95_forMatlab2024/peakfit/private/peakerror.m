function [y1,y2,y3] = peakerror(x,peakdef,y,ax,opts,nx,nparm,nparm1);
%PEAKERROR Objective function for FITPEAKS.
%  This function is called by FITPEAKS and is not for
%  general use.
% 
%  INPUTS:
%    x       = NXx1 vector, peak parameters.
%    peakdef = NPx1 structure, peak definitions.
%    y       = 1xN vector, measured signal to fit peaks to.
%    ax      = 1xN vector, peak axis.
%    opts    = options structure from FITPEAKS.
%    nx      = scalar, number of peak parameters.
%    nparm   = NPx1 vector, elements are number of peak parameters.
%    nparm1  = NP+1x1 vector, cumsum number of peak parameters.
%
%  OUTPUTS:
%    y1      = scalar, squared fit error.
%    y2      = NXx1 vector, Jacobian
%    y3      = NXxNX matrix, Hessian
%
%I/O: [y1,y2,y3] = peakerror(x,peakdef,y,ax,opts,nx,nparm,nparm1);
%
%See also: FITPEAKS

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%nbg 4/04

n           = length(ax);      %number of channels in ax
np          = length(peakdef); %number of peaks
r           = zeros(1,n);      %y - sum of the peaks
ym          = y*y';

for i1=1:np
  if ~isempty(lower(peakdef(i1).fun))
    j1    = [nparm1(i1)+1:nparm1(i1+1)];
    switch lower(peakdef(i1).fun)
    case 'gaussian'
      r   = r + peakgaussian(x(j1),ax);
    case 'lorentzian'
      r   = r + peaklorentzian(x(j1),ax);
    case 'pvoigt1'
      r   = r + peakpvoigt1(x(j1),ax);
    case 'pvoigt2'
      r   = r + peakpvoigt2(x(j1),ax);
    case 'gaussianskew'
      r   = r + peakgaussianskew(x(j1),ax);
    end
  end
end
r         = (y - r).*opts.wts;
y1        = r*r'/ym;            %fval w/o the penalty functions

if nargout>1
  y2      = zeros(nx,1);     %Jacobian
  y3      = zeros(nx,nx);    %Hessian
  
  for i1=1:np
    if ~isempty(lower(peakdef(i1).fun))
      j1           = [nparm1(i1)+1:nparm1(i1+1)];
      switch lower(peakdef(i1).fun)
      case 'gaussian'
        [s1,s2,s3] = peakgaussian(x(j1),ax);
      case 'lorentzian'
        [s1,s2,s3] = peaklorentzian(x(j1),ax);
      case 'pvoigt1'
        [s1,s2,s3] = peakpvoigt1(x(j1),ax);
      case 'pvoigt2'
        [s1,s2,s3] = peakpvoigt2(x(j1),ax);
      case 'gaussianskew'
        [s1,s2,s3] = peakgaussianskew(x(j1),ax);
      end
      y2(j1,1)     = -2*s2*r'/ym;
      y3(j1,j1)    = 2*s2*s2'/ym;
%       for i2=1:nparm(i1)
%         y3(j1(i2),j1(i2)) = y3(j1(i2),j1(i2))-2*r*squeeze(s3(i2,i2,:));
%         for i3=i2+1:nparm(i1)
%           y3(j1(i2),j1(i3)) = y3(j1(i2),j1(i3))-2*r*squeeze(s3(i2,i3,:));
%           y3(j1(i3),j1(i2)) = y3(j1(i2),j1(i3));
%         end
%       end
    end
  end
end

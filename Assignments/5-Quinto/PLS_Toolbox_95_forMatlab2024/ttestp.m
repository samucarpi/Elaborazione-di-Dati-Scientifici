function y = ttestp(x,a,z) 
%TTESTP Evaluates t-distribution and its inverse.
%  For input flag (z) = 1 {default}, TTESTP estimates the
%  the probability point (y) for given t-statistic (x)
%  with (a) degrees of freedom.
%
%  For input flag (z) = 2 the output (y) is the t-statistic
%  for given probability (x) with (a) degrees of freedom.
%
%Example:
%  y = ttestp(1.9606,5000,1)
%    y = 0.025
%  y = ttestp(0.005,5000,2)
%    y = 2.577
% 
%I/O: y = ttestp(x,a,z)
%I/O: ttestp demo
%
%See also: FTEST, STATDEMO

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%The original was based on a public domain stats toolbox
%Modified 12/94 BMW, 10/96 NBG
%modified nbg 3/02: error trapping, switch/case, added tol, change to golden section
% numbers are better behaved, changed help
%jms 6/23/03 -modified for multiple tests simultaneously
%nbg 12/22/06 increased itmax, decreased xtol and ftol

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  if nargout==0; clear y; evriio(mfilename,varargin{1},options); else; y = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin<3, z = 1; end           %nbg 3/02
if prod(size(a))>1
  error('Input a must be scalar.')
end
if prod(size(z))>1
  error('Input z must be scalar.')
end

if a==0;
  y=inf;
  return
end

y = [];
for x = x;
  aa    = a*0.5;
  switch z
    case 1
      bb      = 0.50;
      y(end+1)= betainc(a/(a + x.^2),aa,bb)*0.5;
    case 2
      ic   = 1;         itmax = 1000;  %increased itmax = 100; 12/22/06
      xtol = 1e-10;     ftol  = 1e-10; %decreased xtol=1e-8; ftol=1e-6; 12/22/06
      xl   = 0.0;       xr    = 1.0;
      fxl = -x*2;       fxr   = 1.0 - (x*2);
      if fxl*fxr > 0
        error('Probability not in the range(0,1).')
      else
        %     while ic < 30
        % 	  xx = (xl + xr) * 0.5;
        %    	  p1 = betainc(xx,aa,0.5);
        % 	  fcs = p1 - (x*2);
        % 	  if fcs * fxl > 0
        % 	    xl = xx;
        % 	    fxl = fcs;
        % 	  else
        % 	    xr = xx;
        % 	    fxr = fcs;
        % 	  end
        % 	  xrmxl = xr - xl;
        % 	  if xrmxl <= 0.0001 | abs(fcs) <= 1E-4
        % 	    break
        % 	  else
        % 	    ic = ic + 1;
        %    	  end
        %     end
        %   end
        %   if ic == 30
        %     error(' failed to converge ')
        %   end
        %   tmp = xx;
        %   y = sqrt((a - a * tmp) / tmp);
        while ic<itmax
          xx   = xl+(xr-xl)*0.382;   %change to golden section, might use Newton-Raphson
          p1   = betainc(xx,aa,0.5);
          fcs  = p1 - (x*2);
          if fcs*fxl>0
            xl   = xx;
            fxl  = fcs;
          else
            xr   = xx;
            fxr  = fcs;
          end
          xrmxl  = xr-xl;
          if any([xrmxl<=xtol abs(fcs)<=ftol])
            break
          else
            ic   = ic + 1;
          end
        end
      end
      if ic>=itmax
        warning('EVRI:TtestpConvergence',['TTESTP failed to converge. Number of iterations at maximum ',int2str(itmax)])
      end
      y(end+1) = sqrt((a-a*xx)/xx);
    otherwise
      error('Input z must be 1 or 2.')
  end
end

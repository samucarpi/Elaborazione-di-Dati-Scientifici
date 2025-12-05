function [sx,logscl] = logdecay(x,tau)
%LOGDECAY Scales a matrix using the inverse log decay of the variable axis.
% Inputs are data to be scaled (x), and the decay rate (tau). Outputs are
% the variance scaled matrix (sx) and the log decay based variance scaling
% parameters (logscl).
%
% For an m x n matrix x the variance scaling used for variable i is
% exp(-(i-1)/((n-1)*tau)). This gives a scaling of 1 on the first
% variable (i.e. no scaling), and a scaling of 1/exp(-1/tau) on the
% last variable. The following table gives example values of tau and
% the scaling on the last variable
%  tau    scaling
%    1      2.7183
%   1/2     7.3891
%   1/3    20.0855
%   1/4    54.5982
%   1/5   148.4132
%
%  The default value for tau is .3
% I/O: [sx,logscl] = logdecay(x,tau);
%
%See also: GLOG, SCALE

%Copyright Eigenvector Research 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%bmw 10/19/05
%rsk 10/19/05 add evriio, dataset, and preprocess.
%jms 10/19/05 use scale call.
%jms 4/29/06 no longer mean-centers, don't return mn
%lwl 10/16/19 bmw code to copy dataset info over
%lwl 10/16/19 lwl input checks

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; sx = evriio(mfilename,varargin{1},options); end
  return;
end

switch nargin
  case 1 % only x passed
    if ~isdataset(x) & ~isnumeric(x)
      error('X must be a Dataset Object or numeric array');
    end
    
  case 2 % x and tau passed
    if ~isdataset(x) & ~isnumeric(x)
      error('X must be a Dataset Object or numeric array');
    end
    if ~isscalar(tau)
      error('Tau must be a scalar value');
    end
end

isdso = false;

mass = [];
if nargin == 1
  %Create default for tau.
  tau = .3;  
end

if isa(x,'dataset')
  isdso = true;
  inc   = x.include{2};
  mass  = x.axisscale{2};
  xdata = x.data;
else
  xdata = x;
end

[m,n] = size(xdata);
varscl = 1:n;
if ~isempty(mass);
  %If we have the actual mass value, use that to sort the data into
  %increasing mass order, then use THAT order to scale the masses (takes
  %care of the posibility that we don't have the massess in order in the
  %DSO)
  [mass,order] = sort(mass);
  varscl = order(:)';  %get order of masses
end

logscl = exp(-(varscl-1)/((n-1)*tau));
temp =  scale(xdata,logscl.*0,logscl);
if isdso
  sx = dataset(temp);
  sx = copydsfields(x,sx);
%   sx.data = temp;
else
  sx = temp;
end

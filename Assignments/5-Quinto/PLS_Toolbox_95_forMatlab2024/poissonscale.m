function [xs,sc] = poissonscale(x,sc,options)
%POISSONSCALE Perform Poisson scaling with scaling offset.
% Scales each variable by its square root mean value. When no scale values
% are passed, a calibration is performed in which the square root mean
% values are calculated for each variable and then these are applied to the
% input data. If previously calculated scales are passed, these are simply
% applied to the data. An optional options structure allows setting of the
% offset which is added to each mean to avoid over-scaling when a variable
% has a near-zero mean.
%
% INPUTS:
%    x       = Data to be scaled (double or DataSet object).
% OPTIONAL INPUTS:
%    sc      = Vector of previously-calculated scales. Must be equal in
%              length to the number of included x-block variables.
%    options = Options structure with one or more of the following fields:
%          offset: [ 3 ] percent of the maximum mean value to be used as an
%                   offset on all scales. Avoids division by near-zero
%                   means.
%            mode: [ 1 ] dimension of data on which to calculate the mean
%                  value for the scaling. 1 = mean over rows (to scale
%                  variables); 2 = mean over columns (to scale samples).
% OUTPUTS:
%    xs = Scaled data.
%    sc = Vector of scales calculated for given data.
%
%I/O: [xs,sc] = poissonscale(x,options);     %calibrate scaling
%I/O: xs = poissonscale(x,sc);               %apply previous scaling

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0; x = 'io'; end
if ischar(x) %Help, Demo, Options
  options = [];
  options.offset = 3;
  options.mode   = 1;
  if nargout==0; evriio(mfilename,x,options); else; xs = evriio(mfilename,x,options); end
  return;
end

switch nargin
case 1
  % (x)
  sc = [];
  options = [];
case 2
  % (x,sc)
  % (x,options)
  if isstruct(sc)
    % (x,options)
    options = sc;
    sc = [];
  else
    % (x,sc)
    options = [];
  end
case 3
  % (x,sc,options)
end
options = reconopts(options,mfilename);

switch options.mode
case 1

case 2
  x = x';
end
    

%handle calibration calls (no sc passed) vs. apply calls (sc passed)
if isempty(sc)
  %calibration - calculate scales
  [junk,mn] = mncn(x);   %calculate means of all vars (missing-data friendly)
  mn   = abs(mn);
  mn   = mn+options.offset*max(mn)/100;  %add x% of maximum means of all vars
  sc   = sqrt(abs(mn));
else  %apply previously calculated scales
  %nothing - done below...
end

%apply scaling
xs = scale(x,sc*0,sc);

switch options.mode
case 1

case 2
  xs = xs';
end

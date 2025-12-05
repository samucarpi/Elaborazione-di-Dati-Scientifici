function [specsub,specnos] = stdsslct(spec,nosamps,rinv)
%STDSSLCT Selects data subsets (often for use in standardization).
%  Selects a subset of the given spectra based on leverage for
%  use in developing instrument standardization transforms.
%
%  Inputs are the spectra (spec) and the number samples to be
%  selected (nosamps). STDSSLCT selects the sample furthest
%  from the mean, orthogonalizes the data to that sample, then
%  selects the next sample, ...
%
%  Optional input (rinv) is the model inverse used for the
%  calibration model to be used with the data. If supplied,
%  samples will be selected based on their leverage on the
%  calibration model. Otherwise, they will be selected based
%  on their distance from the multivariate mean.
%
%  The outputs are the matrix of spectra selected (specsub) and a
%  vector of sample (row) numbers of the selected spectra (specnos).
%
%I/O: [specsub,specnos] = stdsslct(spec,nosamps,rinv);
%I/O: stdsslct demo
%
%See also: DISTSLCT, DOPTIMAL, FACTDES, FFACDES1, RINVERSE, STDGEN, STDIZE

%Copyright Eigenvector Research, Inc. 1994
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%bmw
%Modified bmw 5/96, 3/97
%nbg 8/02 removed the disp, changed help, added nosamp error trap
%nbg 10/02 modified hat = r1*r1';

if nargin == 0; spec = 'io'; end
varargin{1} = spec;
if ischar(varargin{1});
  options = [];
  if nargout==0; clear specsub; evriio(mfilename,varargin{1},options); else; specsub = evriio(mfilename,varargin{1},options); end
  return; 
end

[ms,ns] = size(spec);
if nosamps>ns
  disp(' Warning: Number of samples (nosamps) can''t be larger than size(spec,2).')
  disp(' Resetting (nosamps).')
end
nosamps = min([ns,nosamps]);
r1      = mncn(spec);
subset  = zeros(1,nosamps);
for i=1:nosamps
  if nargin < 3
    %hat = r1*r1';                    %nbg commented 10/11/02
    hat = sum(r1.*r1,2);               %nbg added 10/11/02
  else
    %hat = r1*rinv;                   %nbg commented 10/11/02
    hat = diag(r1*rinv);              %nbg added 10/11/02
  end
  %[x subset(1,i)] = max(diag(hat));  %nbg commented 10/11/02
  [x subset(1,i)] = max(hat);         %nbg added 10/11/02
  r0 = r1(subset(1,i),:);
  r1(subset(1,i),:) = zeros(1,ns);
  for j = 1:ms
    r1(j,:) = r1(j,:) - ((r0*r1(j,:)')/(r0*r0'))*r0;
  end
end
% disp('The subset selected consists of the following samples:')
% disp('  ')
% disp(subset)
specnos = subset;
specsub = spec(subset,:);

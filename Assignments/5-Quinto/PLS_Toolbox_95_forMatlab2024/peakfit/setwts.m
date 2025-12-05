function wts = setwts(peakdef,ax,wf)
%SETWTS Sets weights outside the anticipated peak windows to zero.
%  INPUTS:
%    peakdef = standard peak structure.
%         ax = 1xN axis scale corresponding to the peak structure.
%
%  OPTIONAL INPUT:
%         wf = window width of each peak {default wf = 2}.
%
%  OUTPUT:
%        wts = 1xN vector of wts used for weighted least-squares when
%              fitting peaks. Channels outside
%                peakdef(i).param(2)+-wf*peakdef(i).ub(3)
%              for all peaks in (peakdef) are set to ~0.
%              Weights are set based on a Gaussian distribution (see
%              PEAKGAUSSIAN).
%
%I/O: wts = setwts(peakdef,ax);
%
%See also: FITPEAKS, PEAKFUNCTION, PEAKSTRUCT

% Copyright © Eigenvector Research, Inc. 2005
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%NBG 2005
%NBG 10/08 modified the help.

if nargin<3
  wf   = 2;
end

k      = length(peakdef);
wts    = zeros(k,length(ax));
for i1=1:k
  i2   = find(ax>peakdef(i1).param(2)-wf*peakdef(i1).ub(3) & ...
              ax<peakdef(i1).param(2)+wf*peakdef(i1).ub(3));
  wts(i1,i2) = peakgaussian([1 peakdef(i1).param(2:3)],ax(i2));
end
if k>1
  wts  = max(wts);
end

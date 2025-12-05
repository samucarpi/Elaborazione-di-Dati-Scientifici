function [y,peakdef] = peakfunction(peakdef,ax)
%PEAKFUNCTION Outputs the estimated peaks from parameters in PEAKDEF
%  Given the multi-record standard peak structure (peakdef)
%  and the corresponding wavelength/frequency axis (ax), the
%  peak parameters in the field (peakdef.param) are used to
%  generate peaks. This function is called by PEAKFITS and the
%  result is the output (fit). See FITPEAKS for more information.
%
%  INPUTS:
%    peakdef = standard peak structure (see PEAKSTRUCT)
%              output by FITPEAKS.
%         ax = corresponding wavelength/frequency axis.
%              This is also input to the function FITPEAKS.
%              Peak positions are based on this axis.
%
%  OUTPUTS:
%          y = estimated peaks based on the parameters in
%              the input (peakdef).
%    peakdef = the original input (peakdef) with the area
%              field estimated.
%
%Example:
%     [y,peakdef] = peakfunction(peakdef,ax); %generate peak fit result
%     plot(ax,y)   %plot the peak fit
%
%I/O: [y,peakdef] = peakfunction(peakdef,ax);
%
%See also: FITPEAKS, PEAKSTRUCT

% Copyright © Eigenvector Research, Inc. 2005
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%nbg 6/05
%nbg 8/05 modified help, added peakdef as an output
%nbg 12/05 added voigt

%need to check the area calculations!

y = zeros(1,length(ax));
for i1=1:length(peakdef)
  if ~isempty(lower(peakdef(i1).fun))
    switch lower(peakdef(i1).fun)
    case 'gaussian'
      y  = y + peakgaussian(peakdef(i1).param,ax);
      peakdef(i1).area = sqrt(2*pi)*peakdef(i1).param(1)*peakdef(i1).param(3);
    case 'lorentzian'
      y  = y + peaklorentzian(peakdef(i1).param,ax);
      peakdef(i1).area = pi*peakdef(i1).param(1)*peakdef(i1).param(3);
    case 'pvoigt1'
      y  = y + peakpvoigt1(peakdef(i1).param,ax);
      peakdef(i1).area = prod(peakdef(i1).param([1 3]))* ...
        (peakdef(i1).param(4)*sqrt(pi)/2/sqrt(log(2))+(1-peakdef(i1).param(4))*pi);
    case 'pvoigt2'
      y  = y + peakpvoigt2(peakdef(i1).param,ax);
      peakdef(i1).area = prod(peakdef(i1).param([1 3 4]))*sqrt(2*pi) + ...
        prod(peakdef(i1).param([1 3]))*(1-peakdef(i1).param(4))*pi;
    case 'gaussianskew'  
      y  = y + peakgaussianskew(peakdef(i1).param,ax);
      peakdef(i1).area = pi*peakdef(i1).param(1)*peakdef(i1).param(3);
    end
  end
end

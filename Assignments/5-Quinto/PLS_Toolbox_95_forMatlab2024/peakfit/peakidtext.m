function h = peakidtext(peakdef)
%PEAKIDTEXT Writes peak ID information on present graph.
%  If (ax) is the wavelength/frequency/time axis and (y)
%  is a specfic vector corresponding to a set of peaks
%  that have been fit and stored in a standard peak
%  structure (peakdef), then
%
%    y   = peakfunction(peakdef,ax); %estimates the peak fit
%    plot(ax,y)                      %plots the peak fit
%    peakidtext(peakdef)             %puts the peak id on each peak
%
%  puts a vertical line at the peak center and puts a
%  text label (peakdef.id) on the graph based.
%
%  The output (h) is a vector of handles corresponding
%  to the individual text labels.
%
%I/O: h = peakidtext(peakdef);

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
%nbg 10/08 modified the help.

h       = zeros(length(peakdef),1); %handles
va      = axis;
for i1=1:length(peakdef)
  if ~isempty(lower(peakdef(i1).fun))
    g     = vline(peakdef(i1).param(2));
    set(g,'color',[0.8 0.8 0.8])
    switch class(peakdef(i1).id)
    case 'double'
      s   = [' ',num2str(peakdef(i1).id)];
    case 'char'
      s   = [' ',peakdef(i1).id];
    end
    h(i1) = text(peakdef(i1).param(2), va(3)+0.9*(va(4)-va(3)),s);
  end
end
  
if nargout==0;
  clear h
end

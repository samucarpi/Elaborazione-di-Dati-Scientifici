function scrn = getscreensize(units,sizepref)
%GETSCREENSIZE Screen size which is dynamically updated.
% Returns the actual size of the user's screen. Unlike the
% get(0,'screensize') property, this one is correctly updated for changes
% to the screen after Matlab has been started. The first input is
% the 'units' in which the screen size is desired. Valid settings are:
%  [ inches | centimeters | normalized | points | pixels | characters ]
%
% The second input is 'sizepref' and will override the size logic to return
% the size based on setting:
%   'default' - Use java.
%   'smaller' - Use smaller of Java or get(0,'screensize')
%   'larger' - Use larger of Java or get(0,'screensize')
%   'matlab' - Use get(0,'screensize')
%
%I/O: scrn = getscreensize(units)

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1
  units = get(0,'units');
end

if nargin<2
  sizepref = 'matlab';
end

%get size in pixels
pos = java.awt.Toolkit.getDefaultToolkit.getScreenSize;
scrn = [1 1 pos.getWidth pos.getHeight];
jscrn = scrn;%Keep java screen size for ratio if needed.

if ~strcmpi(sizepref,'default')
  oldunits = get(0,'units');
  set(0,'units','pixels')
  mlsize = get(0,'screensize');
  set(0,'units',oldunits)
  switch sizepref
    case 'smaller'
      if prod(mlsize(3:4))<prod(scrn(3:4))
        %Make scrn the smaller Matlab screen size.
        scrn = mlsize;
      end
    case 'larger'
      if prod(mlsize(3:4))>prod(scrn(3:4))
        %Make scrn the larger Matlab screen size.
        scrn = mlsize;
      end
    case 'matlab'
      scrn = mlsize;
  end
end

switch units
  case 'normalized'
    scrn = [0 0 1 1];
    
  case 'pixels'
    %already as pixels...
    
  case {'inches','centimeters','points','characters'}
    %these conversions are dependent on various system settings
    %grab the "wrong" (bad) screen size in both the desired units and
    %pixels and calculate the conversion between them. Then apply that
    %conversion to the "right" (good) screen size we got from Java (in
    %pixels)
    oldunits = get(0,'units');
    set(0,'units',units)
    badunsz = get(0,'screensize');  %not updated for changes after start of Matlab
    set(0,'units','pixels')
    badpxsz = get(0,'screensize');
    set(0,'units',oldunits);
    conv = badunsz(3:4)./badpxsz(3:4);  %calculate how to convert
    
    scrn(3:4) = scrn(3:4).*conv;  %apply conversion
  case 'ratio'
    %NOT USED YET
    
    %Get the ratio of the two sizes. One will be actual pixel size and one
    %will be adjusted pixel size. MATLAB reports are based on a pixel size
    %of 1/96th while Java is actual. 
    %
    %The ratio value is a way to scale pixel size. 
    %
    %NOTE: This may be different between systems so use carefully. 
    
    scrn = jscrn(3)/mlsize(3); 
  otherwise
    %just return pixels... no error
    
end

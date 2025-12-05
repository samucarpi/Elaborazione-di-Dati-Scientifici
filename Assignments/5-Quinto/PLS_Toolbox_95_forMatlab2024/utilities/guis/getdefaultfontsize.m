function mysize = getdefaultfontsize(style,options)
%GETDEFAULTFONTSIZE - Get default font size for a platform.
% Input 'style' is for kind of font to get. 
%   style :
%     normal  - Used for normal text and label controls.
%     heading - Larger style used for titles.
%     notes   - Smaller than normal.
%     all     - return structure.
%
%I/O: mysize = getdefaultfontsize(style,options)
%
%See also: 

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1; style = 'normal'; end

if ismember(style,evriio([],'validtopics'));
  options = getdefaults;
  if nargout==0; clear myfont; evriio(mfilename,style,options); else; mysize = evriio(mfilename,style,options); end
  return; 
end

if nargin<2
  options = getdefaultfontsize('options');
end

options = reconopts(options,'getdefaultfontsize');

if strcmpi(style,'all')
  mysize = options;
else
  mysize = options.(style).*options.multiplier;
end


function opts = getdefaults
%Get system defaults.

if ~ispc
  opts.normal  = 12;
  opts.heading = 18;
  opts.notes   = 10;
else
  opts.normal  = 10;
  opts.heading = 16;
  opts.notes   = 8;
end

opts.multiplier = 1.0;

function varargout = preprouser(fig);
%PREPROUSER User-defined preprocessing methods.
%  Called by PREPROCESS when initializing the preprocessing%  methods catalog. User-defined preprocessing methods
%  can be put into this file to be automatically loaded
%  into the PREPROCESS GUI.
%
%  Type "helpwin preprouser" for help on this function.
% 
%I/O: called by PREPROCESS - not user accessable
%
%See also: PREPROCATALOG, PREPROCESS

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0; fig = 'io'; end
varargin{1} = fig;
if ischar(varargin{1});
  options = [];
  if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return; 
end

if exist('preprouser2')==2; preprouser2(fig); end

%---------------------------------------
pp = [];
pp.description   = 'Absolute Value';
pp.calibrate     = {'out{2} = sign(data); data = abs(data);' };
pp.apply         = {'out{2} = sign(data); data = abs(data);' };
pp.undo          = {'data = data.*out{2};' };
pp.out           = {};
pp.settingsgui   = '';
pp.settingsonadd = 0;
pp.usesdataset   = 0;
pp.caloutputs    = 0;
pp.keyword       = 'Abs';
pp.tooltip       = 'Remove +/- sign from data (absolute value)';
pp.category      = 'Transformations';
pp.userdata      = [ ];

preprocess('addtocatalog',fig,pp);

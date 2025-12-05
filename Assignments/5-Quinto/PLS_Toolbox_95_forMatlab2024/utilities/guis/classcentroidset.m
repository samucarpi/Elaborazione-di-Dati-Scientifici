function varargout = classcentroidset(varargin)
%CLASSCENTROIDSET GUI used to modfiy settings of of CLASSCENTROID.
% Both input (p) and output (p) are preprocessing structures
% If no input is supplied, GUI with default settings is provided
% if p is 'default', default structure is returned without GUI.
%
%I/O:   p = classcentroidset(p)
%I/O:   p = classcentroidset('default')
%I/O:   p = classcentroidset('defaultscale')
%
%See also: PREPROCESS, CLASSCENTROID

%Copyright Eigenvector Research 2016
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0 || (nargin == 1 && isa(varargin{1},'struct'))

  if nargin==0
    p = default;
  else
    p = default(varargin{1});
  end
  
  new = optionsgui(p.userdata);
  if ~isempty(new)
    p.userdata = new;
  end
  varargout = {p};
  
elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK

  if ismember(varargin{1},evriio([],'validtopics'))
    options = [];
    if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
    return; 
  end
  
	try
    if nargout == 0;
      feval(varargin{:});
    else
      [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
    end
	catch
		disp(lasterr);
	end

end

if nargout == 0
  varargout = {};
end

% --------------------------------------------------------------------
function pp = default(pp)
%generate default preprocessing structure for this method

if nargin<1 || isempty(pp)
  pp = preprocess('validate');    %get a blank structure
end

pp = [];
pp.description = 'Class Centroid Centering';
pp.calibrate = { '[data,out{1}] = classcentroid(data,userdata);' };
pp.apply     = { 'data = classcentroid(data,out{1});'   };
pp.undo      = { 'data = rescale(data,out{1});'  };
pp.out       = {};
pp.settingsgui   = 'classcentroidset';
pp.settingsonadd = 0;
pp.usesdataset   = 1;
pp.caloutputs    = 1;
pp.keyword  = 'classcentroid';
pp.tooltip  = 'Remove class centroid from each variable';
pp.category = 'Scaling and Centering';

pp = preprocess('validate',pp);

if isempty(pp.userdata) || ~isfield(pp.userdata,'definitions')
  opts = classcentroid('options');
  opts.definitions = feval(opts.definitions);
  pp.userdata = opts;
end

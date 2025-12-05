function varargout = classcenterset(varargin)
%CLASSCENTERSET GUI used to modfiy settings of of CLASSCENTER.
% Both input (p) and output (p) are preprocessing structures
% If no input is supplied, GUI with default settings is provided
% if p is 'default', default structure is returned without GUI.
%
%I/O:   p = classcenterset(p)
% (or)  p = classcenterset('default')
%
%See also: PREPROCESS, CLASSCENTER

%Copyright Eigenvector Research 2016
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0  | (nargin == 1 & isa(varargin{1},'struct'))

  if nargin==0;
    p = default;
  else
    p = default(varargin{1});
  end
  
  new = optionsgui(p.userdata);
  if ~isempty(new);
    p.userdata = new;
  end
  varargout = {p};
  
elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK

  if ismember(varargin{1},evriio([],'validtopics'));
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
function p = default(p)
%  pass back the default structure for this preprocessing method
% if "p" is passed in, only the userdata from that structure is kept

if nargin<1 || isempty(p)
  p = preprocess('validate');    %get a blank structure
end
         
p.description = 'Class Center';
p.calibrate = { '[data,out{1},out{2}] = classcenter(data,userdata.classset);' };
p.apply     = { 'data = classcenter(data,userdata.classset,out{1},out{2});'   };
p.undo      = { 'data = classcenter(data,userdata.classset,-out{1},out{2});'  };
p.out       = {};
p.settingsgui   = 'classcenterset';
p.settingsonadd = 0;
p.usesdataset   = 1;
p.caloutputs    = 2;
p.keyword  = 'classcenter';
p.tooltip  = 'Remove mean response from each class';
p.category = 'Scaling and Centering';


if isempty(p.userdata) | ~isfield(p.userdata,'definitions')
  addopts = {
    'classset' 'Settings' 'double' [] 'novice' 'Class set (from rows) which should be used to center data. Default is class set 1.'
    };
  opts.definitions = [makesubops(addopts)];
  opts.classset = 1;  %classset is only thing that shows in window with default of 1. 
  p.userdata = opts;
end

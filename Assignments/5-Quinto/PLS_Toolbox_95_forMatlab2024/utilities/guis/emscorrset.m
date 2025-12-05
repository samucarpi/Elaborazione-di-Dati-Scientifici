function varargout = emscorrset(varargin)
%EMSCORRSET GUI used to modfiy settings of of EMSCORR.
% Both input (p) and output (p) are preprocessing structures
% If no input is supplied, GUI with default settings is provided
% if p is 'default', default structure is returned without GUI.
%
%I/O:   p = emscorrset(p)
% (or)  p = emscorrset('default')
%
%See also: PREPROCESS, EMSCORR

%Copyright Eigenvector Research 2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% JMS 1/5/07
%4/24/08 NBG %p.usesdataset  changed from 0 to 1 

if nargin == 0  | (nargin == 1 & isa(varargin{1},'struct'))

  if nargin==0;
    p = default;
  else
    p = default(varargin{1});
  end
  
  newopts = optionsgui(p.userdata);
  if ~isempty(newopts);
    p.userdata = newopts;
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
elseif nargout == 1 & exist('newopts', 'var') & isempty(newopts)
  [varargout{1:nargout}] = {};
end

% --------------------------------------------------------------------
function p = default(p)
%  pass back the default structure for this preprocessing method
% if "p" is passed in, only the userdata from that structure is kept

if nargin<1 | isempty(p);
  p = preprocess('validate');    %get a blank structure
end
         
p = preprocess('validate',p);  %validate what was passed in
  
p.description   = 'EMSC (Extended Scatter Correction)';
p.calibrate     = {'[data,junk,out{1}] = emscorr(data,userdata.xref,userdata);'};
p.apply         = {'data = emscorr(data,out{1},userdata);'};
p.undo          = {};
p.out           = {};
p.settingsgui   = 'emscorrset';
p.settingsonadd = 1;
p.usesdataset   = 1; %4/24/08 NBG changed from 0 to 1
p.caloutputs    = 1;
p.keyword       = 'emsc';
p.category      = 'Filtering';
p.tooltip       = 'Extended Multiplicative Scatter/Signal Correction.';

if isempty(p.userdata) | ~isfield(p.userdata,'definitions')
  opts = emscorr('options');
  addopts = {
    'xref' 'Settings' 'vector' [] 'novice' 'Reference spectrum for correction (empty = use mean of data).'
    };
  opts.definitions = [makesubops(addopts);feval(opts.definitions)];
  opts.definitions(ismember({opts.definitions.name},'display')) = [];  %do NOT show display as an option
  opts.xref = [];  %xref to show in opts gui
  opts.display = 'off';  %ALWAYS have display be none
  p.userdata = opts;
end

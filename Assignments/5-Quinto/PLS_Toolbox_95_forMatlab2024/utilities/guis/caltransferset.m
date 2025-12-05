function varargout = caltransferset(varargin)
%CALTRANSFERSET GUI used to modfiy settings of Calibration Transfer preprocessing.
% Both input (p) and output (p) are preprocessing structures
% If no input is supplied, GUI with default settings is provided
% if p is 'default', default structure is returned without GUI
%
%I/O:   p = caltransferset(p)
% (or)  p = caltransferset('default')
%
%See also: CALTRANSFER, GLSWSET, PREPROCESS

%Copyright Eigenvector Research, Inc. 2016
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


if nargin == 0  | (nargin == 1 & isa(varargin{1},'struct'))% LAUNCH GUI

	fig = openfig(mfilename,'reuse');
  set(fig,'WindowStyle','modal');
  centerfigure(fig,gcbf);
  set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));

	% Generate a structure of handles to pass to callbacks, and store it. 
	handles = guihandles(fig);
	guidata(fig, handles);
  if nargin > 0;
    setup(handles, varargin{1})
  else
    setup(handles, []);
  end

	% Wait for callbacks to run and window to be dismissed:
	uiwait(fig);

	if nargout > 0
    if ishandle(fig);  %still exists?
      varargout{1} = encode(handles);
      close(fig);
    else
      varargout{1} = varargin{1};   %return 
    end
  end

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

% --------------------------------------------------------------------
function p = default(p)
%  pass back the default structure for this preprocessing method
% if "p" is passed in, only the userdata from that structure is kept

% NOTES:
%  Need 'otherdata' for additional data (e.g., yblock).
%  Calibrate is just adding model to pp struct.
%  Apply 

%I/O: [transfermodel,x1t,x2t] = caltransfer(x1,x2,method,options);
%I/O: x2t = caltransfer(x2,transfermodel,options);


if nargin<1 | isempty(p)
  p = preprocess('validate');    %get a blank structure
end
         
p = preprocess('validate',p);  %validate what was passed in
  
p.description   = 'Calibration Transfer (Preprocessing)';
p.calibrate     = {'if isempty(userdata.calt_model); error([''Caltransfer preprocessing requires a model in userdata.calt_model.'']); end; data = caltransfer(data,userdata.calt_model);'};
p.apply         = {'data = caltransfer(data,userdata.calt_model);'};
p.undo          = {};   %cannot undo
p.out           = {};
p.settingsgui   = '';
p.settingsonadd = 0;
p.usesdataset   = 1;
p.caloutputs    = 0;
p.keyword       = 'caltransfer';
p.tooltip       = 'Calibration and instrument transfer models for preprocessing.';
p.category      = 'Transformations';

if isempty(p.userdata)
  p.userdata    = struct('calt_model',[]);  %defaults
end

function varargout = npls_guifcn(varargin)
%NPLS_GUIFCN NPLS Analysis-specific methods for Analysis GUI.
% This is a set of utility functions used by the Analysis GUI only.
%See also: ANALYSIS

%Copyright © Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin>0;
  try
    switch lower(varargin{1})
      case evriio([],'validtopics')
        options = analysis('options');
        %add guifcn specific options here
        if nargout==0
          evriio(mfilename,varargin{1},options)
        else
          varargout{1} = evriio(mfilename,varargin{1},options);
        end
        return;
      otherwise
        if nargout == 0;
          feval(varargin{:}); % FEVAL switchyard
        else
          [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
        end
    end
  catch
    erdlgpls(lasterr,[upper(mfilename) ' Error']);
  end
end

%----------------------------------------------------
function gui_init(varargin);
reg_guifcn('gui_init',varargin{:});

%----------------------------------------------------
function gui_deselect(varargin)
reg_guifcn('gui_deselect',varargin{:});

%----------------------------------------------------
function gui_updatetoolbar(varargin)
reg_guifcn('gui_updatetoolbar',varargin{:});

%----------------------------------------------------
function out = isdatavalid(xprofile,yprofile,fig)
%two-way x
% out = xprofile.data & xprofile.ndims==2;

%multi-way x
% out = xprofile.data & xprofile.ndims>2;

%discrim: two-way x with classes OR y
%out = xprofile.data & xprofile.ndims==2 & (xprofile.class | (yprofile.data & yprofile.ndims==2) );

%multiway x
out = xprofile.data & xprofile.ndims>=2 & yprofile.data & yprofile.ndims==2;
    
%     %two-way x and y
%     out = xprofile.data & xprofile.ndims==2 & yprofile.data & yprofile.ndims==2;

%multi-way x and y
% out = xprofile.data & xprofile.ndims>2 & yprofile.data;

%--------------------------------------------------------------------
function out = isyused(handles)

out = true;


%----------------------------------------------------
function calcmodel_Callback(varargin);
% Callback of the uicontrol handles.calcmodel.
reg_guifcn('calcmodel_Callback',varargin{:});

% --------------------------------------------------------------------
function plotyloads_Callback(varargin)
% Callback of the uicontrol handles.plotyloads.
reg_guifcn('plotyloads_Callback',varargin{:});

%----------------------------------------------------
function ssqtable_Callback(varargin)
% Callback of the uicontrol handles.ssqtable.
% Selects number of PCs from the ssq table list box.
reg_guifcn('ssqtable_Callback',varargin{:});

%----------------------------------------------------
function pcsedit_Callback(varargin)
reg_guifcn('pcsedit_Callback',varargin{:});

%--------------------------------------------------------------------
function updatefigures(h)
reg_guifcn('updatefigures',h);

%----------------------------------------
function closefigures(handles)
reg_guifcn('closefigures',handles);

% --------------------------------------------------------------------
function updatessqtable(varargin)
reg_guifcn('updatessqtable',varargin{:});

% --------------------------------------------------------------------
function threshold_Callback()

% --------------------------------------------------------------------
function storedopts = getoptions(atype, handles)
%Returns options strucutre for specified (atype) analysis.
%Called from plsda_guifcn as well.
storedopts  = getappdata(handles.analysis,'analysisoptions');
curanalysis = getappdata(handles.analysis,'curanal');

if isempty(storedopts) | ~strcmp(storedopts.functionname, curanalysis)
  storedopts = npls('options');
end

storedopts.display       = 'off';
storedopts.plots         = 'none';

% --------------------------------------------------------------------
function modl = model_in_cache(handles)
reg_guifcn('model_in_cache',handles);

% --------------------------------------------------------------------
function modl = add_model_to_cache(varargin)
reg_guifcn('add_model_to_cache',varargin{:});

%----------------------------------------------------
function  optionschange(h)

function varargout = choosencomp(varargin)
%CHOOSENCOMP GUI to select number of components from a PCA SSQ table.
% CHOOSENCOMP creates a GUI that displays the sum-squares captured (SSQ)
% table and allows the user to select the number of principal components
% (ncomp) from the list.

%  Presents user with a GUI SSQ table from which a desired number of
%  components can be selected. Input (model) . Output (ncomp) 
%
%INPUT:
%  model = is a standard PCA model structure or SSQ table.
%
%OUTPUT:
%  ncomp = is the selected number of components. It is empty [] if user
%          selects "Cancel" in the GUI.
%
%I/O: ncomp = choosencomp(model);
%
%See also: SSQTABLE

% Copyright © Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 1 & ~ischar(varargin{1});
  
  ssq = varargin{1};
  if isa(ssq,'struct')
    if ~isfield(ssq,'modeltype');
      error('Input must be a valid model or a sum of squares captured table');
    end
    if ~strcmp(lower(ssq.modeltype),'pca')
      error('This function currently works with PCA models only')
    end
    ssq     = ssq.detail.ssq;
  end
  
  %open figure and initialize
  fig = openfig('choosencomp','new');
  handles = guihandles(fig);
  guidata(fig,handles);
  
  set(handles.tableheader,'string',...
    { '          Percent Variance Captured by PCA Model           ',...
      '  Principal      Eigenvalue      % Variance    % Variance  ',...
      'Component     of Cov(X)           This  PC      Cumulative ' } )
  
  tableformat       = '%3.0f       %4.2e   %6.2f    %6.2f';
  
  s = cell(0);
  for jj=1:size(ssq,1);
    s{jj}   = [sprintf(tableformat,ssq(jj,:))];
  end
  set(handles.ssqtable,'max',2,'min',0);
  set(handles.ssqtable,'String',s,'Value',[],'Enable','on')
  set(handles.pcsedit,'enable','on');

  try
    uiwait(fig);
  catch
  end
  
  if ishandle(fig);  %still exist?
    varargout = {get(handles.ssqtable,'value')};
    close(fig);
  else
    varargout = {[]};
  end
  
else

  if nargin == 0; varargin{1} = 'io'; end
  if ischar(varargin{1}) & ismember(varargin{1},evriio([],'validtopics'));
    options = [];
    if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
    return; 
  end

  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  
end





% --------------------------------------------------------------------
function  pcsedit_Callback(h, eventdata, handles, varargin)

val = str2num(get(handles.pcsedit,'string'));
if prod(size(val))>1; val = val(1); end     %vector? take first element
if ~isempty(val) & (val < 1 | val > length(get(handles.ssqtable,'string')));
  val = get(handles.ssqtable,'value');    %outside of valid range? revert to what's selected in ssqtable
end
if ~isempty(val) & ( val < 1 | val > length(get(handles.ssqtable,'string')) );
  val = [];     %STILL outside valid range? revert to nothing
end
if isempty(val)
  %nothing selected
  set(handles.ssqtable,'max',2,'min',0);      
  set(handles.OK,'enable','off');
else
  %one item selected
  set(handles.ssqtable,'max',1,'min',1);
  set(handles.OK,'enable','on');
end
set(handles.ssqtable,'value',val)
set(handles.pcsedit,'string',num2str(val))

% --------------------------------------------------------------------
function  ssqtable_Callback(h, eventdata, handles, varargin)

set(handles.pcsedit,'string',num2str(get(handles.ssqtable,'value')))
pcsedit_Callback(handles.pcsedit,[],handles);

% --------------------------------------------------------------------
function  OK_Callback(h, eventdata, handles, varargin)

uiresume(handles.choosencomp);



% --------------------------------------------------------------------
function  cancel_Callback(h, eventdata, handles, varargin)

close(handles.choosencomp);

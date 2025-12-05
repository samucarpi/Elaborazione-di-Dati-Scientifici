function varargout = anndlgui(varargin)
% ANNDLGUI MATLAB code for anndlgui.fig
%      ANNDLGUI, by itself, creates a new ANNDLGUI or raises the existing
%      singleton*.
%
%      H = ANNDLGUI returns the handle to a new ANNDLGUI or the handle to
%      the existing singleton*.
%
%      ANNDLGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ANNDLGUI.M with the given input arguments.
%
%      ANNDLGUI('Property','Value',...) creates a new ANNDLGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before anndlgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to anndlgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help anndlgui

% Last Modified by GUIDE v2.5 27-Jul-2021 15:01:58

if ~isempty(varargin) && ischar(varargin{1})
  if ismember(varargin{1},evriio([],'validtopics'));
    options = [];
    options.selectvars_lvs = 10;
    options.showalloptions = 'no';%Show all options or not.
    if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
    return;
  end
  
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
else
  fig = openfig(mfilename,'new');
  
  if nargout > 0;
    varargout = {fig};
  end
end






% --------------------------------------------------------------------
function panelinitialize_Callback(figh, frameh, varargin)
%Initialize panel objects.

myctrls = findobj(figh,'userdata','anndlgui');
drawnow
handles = guihandles(figh);
%scalePosition(handles)
set(findall(myctrls,'-property','Fontsize'),'Fontsize',getdefaultfontsize)

guioptions = anndlgui('options');

%Gather needed inputs.
xblk = analysis('getobjdata','xblock',handles);
yblk = analysis('getobjdata','yblock',handles);
modl = analysis('getobjdata','model',handles);


panelresize_Callback(figh, frameh, varargin)
panelupdate_Callback(figh, frameh, varargin)

%Set algorithm.
curanal = getappdata(handles.analysis,'curanal');

opts = getappdata(handles.analysis, 'analysisoptions');
if isempty(opts)
  %Options were cleared so add them again.
  anndl_guifcn('setoptions',handles);
  opts = getappdata(handles.analysis, 'analysisoptions');
end

switch opts.algorithm
  case 'sklearn'
    set(handles.popupmenu_framework,'value',1);
  case 'tensorflow'
    set(handles.popupmenu_framework,'value',2);
  otherwise
    error('Unknown algorithm for ANNDL.')
end

%Update all controls based on framework choice.
popupmenu_framework_Callback(handles.popupmenu_framework, [], handles);

% --------------------------------------------------------------------
function panelresize_Callback(figh, frameh, varargin)
% Resize specific to panel manager. figh is parent figure, frameh is frame
% handle.

handles = guihandles(figh);

ssqpos = get(handles.ssqframe,'position');

%Let layer panel expand.
panel_L = 10;
panel_W = 480;
new_B = ssqpos(4)-30;

%Set panel positions.
set(handles.uipanel_method,'position',ssqpos)

%Move framework controls to top.
set(handles.text_framework,'position',[20 new_B 144 20])
set(handles.popupmenu_framework,'position',[150 new_B 220 20])

new_B = new_B - 150;

%Move parameter panel next.
set(handles.uipanel_params,'position',[panel_L new_B panel_W 144]);

%Allow layer table to expand.
%150 is min height of layer table.
%92 is height needed for compresison panel.
layer_height = max(150,new_B - 102);
new_B = new_B - (layer_height+10);

set(handles.uipanel_layer,'position',[panel_L new_B panel_W layer_height]);

new_B = new_B - 82;

set(handles.uipanel_compression,'position',[panel_L new_B panel_W 72]);


% --------------------------------------------------------------------
function  panelupdate_Callback(figh, frameh, varargin)
%Update panel controls.
% This is done via popupmenu_framework_Callback
handles = guihandles(figh);
popupmenu_framework_Callback(handles.popupmenu_framework, [], handles,false);


%----------------------------------------------------
function anndlgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to anndlgui (see VARARGIN)

% Choose default command line output for anndlgui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes anndlgui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


%----------------------------------------------------
function pushbutton_addlayer_Callback(hObject, eventdata, handles)
% Add hidden layer. 

%Enable for SK now. Need to work out TF.
opts = getappdata(handles.analysis, 'analysisoptions');
switch opts.algorithm
  case 'sklearn'
    opts.sk.hidden_layer_sizes = {opts.sk.hidden_layer_sizes{:} 100};
  
  case 'tensorflow'
    thislayer.type = 'Dense';
    thislayer.units = 100;
    thislayer.size = [];
    opts.tf.hidden_layer{end+1}= thislayer;
end

setoptions(handles,opts);
popupmenu_framework_Callback(handles.popupmenu_framework, [], handles);

%----------------------------------------------------
function popupmenu_compression_Callback(hObject, eventdata, handles)
% Compression callback.

myval = get(hObject,'value');
opts = getappdata(handles.analysis, 'analysisoptions');

switch myval
  case 1
    opts.compression = 'none';
    set(handles.edit_ncomp,'enable','off','String','')
  case 2
    opts.compression = 'pca';
    set(handles.edit_ncomp,'enable','on','string',num2str(opts.compressncomp));
  case 3
    opts.compression = 'pls';
    set(handles.edit_ncomp,'enable','on','string',num2str(opts.compressncomp));
end

setoptions(handles,opts)

%----------------------------------------------------
function edit_ncomp_Callback(hObject, eventdata, handles)
% Ncomp callback.

myval = str2num(get(hObject,'String'));

if ~isint(myval) || isempty(myval) || myval<1
  evrierrordlg('Ncomp must be integer greater than 0.')
  %Reset value.
  popupmenu_framework_Callback(handles.popupmenu_framework, eventdata, handles)
  return
end

opts = getappdata(handles.analysis, 'analysisoptions');
opts.compressncomp = myval;
setoptions(handles,opts);

%----------------------------------------------------
function popupmenu_solver_Callback(hObject, eventdata, handles)
% Solver/Optimizer callback.

mysolverstr = get(handles.popupmenu_solver,'string');
mysolverval = get(handles.popupmenu_solver,'value');
opts = getappdata(handles.analysis, 'analysisoptions');

switch opts.algorithm
  case 'sklearn'
    opts.sk.solver = mysolverstr{mysolverval};
  case 'tensorflow'
    opts.tf.optimizer = mysolverstr{mysolverval};
end

setoptions(handles,opts)

%----------------------------------------------------
function edit_maxiter_Callback(hObject, eventdata, handles)
% Max iteration callback.

maxiterval = str2num(get(handles.edit_maxiter,'string'));
if ~isint(maxiterval) || isempty(maxiterval)
  evrierrordlg('Max_iter/Epochs must be integer.')
  %Reset value.
  popupmenu_framework_Callback(handles.popupmenu_framework, eventdata, handles)
  return
end

if maxiterval<1
  evrierrordlg('Max_iter/Epochs must be greater than 0.')
  %Reset value.
  popupmenu_framework_Callback(handles.popupmenu_framework, eventdata, handles)
  return
end

opts = getappdata(handles.analysis, 'analysisoptions');

switch opts.algorithm
  case 'sklearn'
    opts.sk.max_iter = maxiterval;
  case 'tensorflow'
    opts.tf.epochs = maxiterval;
end

setoptions(handles,opts)

%----------------------------------------------------
function edit_batchsize_Callback(hObject, eventdata, handles)
% Batch size callback.

batchsizeval = str2num(get(handles.edit_batchsize,'string'));
if ~isint(batchsizeval) || isempty(batchsizeval)
  evrierrordlg('Batch size must be integer.')
  %Reset value.
  popupmenu_framework_Callback(handles.popupmenu_framework, eventdata, handles)
  return
end

if batchsizeval<1
  evrierrordlg('Batch size must be greater than 0.')
  %Reset value.
  popupmenu_framework_Callback(handles.popupmenu_framework, eventdata, handles)
  return
end

opts = getappdata(handles.analysis, 'analysisoptions');

switch opts.algorithm
  case 'sklearn'
    opts.sk.batch_size = batchsizeval;
  case 'tensorflow'
    opts.tf.batch_size = batchsizeval;
end

setoptions(handles,opts)

%----------------------------------------------------
function popupmenu_activation_Callback(hObject, eventdata, handles)
% Activation callback.

myactivstr = get(handles.popupmenu_activation,'string');
myactivval = get(handles.popupmenu_activation,'value');
opts = getappdata(handles.analysis, 'analysisoptions');

switch opts.algorithm
  case 'sklearn'
    opts.sk.activation = myactivstr{myactivval};
  case 'tensorflow'
    opts.tf.activation = myactivstr{myactivval};
end

setoptions(handles,opts)


%----------------------------------------------------
function popupmenu_loss_Callback(hObject, eventdata, handles)
% Loss selection on for tensorflow.

mylossstr = get(handles.popupmenu_loss,'string');
mylossval = get(handles.popupmenu_loss,'value');
opts = getappdata(handles.analysis, 'analysisoptions');

opts.tf.loss = mylossstr{mylossval};

setoptions(handles,opts)

%----------------------------------------------------
function popupmenu_framework_Callback(hObject, eventdata, handles, updateopts)
% Changing framework (algorithm). Boolean 'updateopts' input will save
% options if true. If false it will just update the interface. Prevents
% recursive call from anndl_guifcn. 


if nargin<4
  updateopts = true;
end

myval = get(hObject,'value');
opts = getappdata(handles.analysis, 'analysisoptions');
mytbl = handles.uitable_layer;
oldalgorithm = opts.algorithm;

switch myval
  case 1 %sklearn
    opts.algorithm = 'sklearn';
    solvertxt = {'adam' 'lbfgs' 'sgd'};
    solverval = find(ismember(solvertxt,opts.sk.solver));
    solvelabel = 'Solver:';
    opts.sk.solver = solvertxt{solverval};
    
    activationtxt = {'relu' 'identity' 'tanh' 'logistic'};
    activationval = find(ismember(activationtxt,opts.sk.activation));
    opts.sk.activation = activationtxt{activationval};
    lossenable = false;
    
    maxiterstr = 'Max Iter:';
    maxiterval = num2str(opts.sk.max_iter);
    
    batchsizeval = num2str(opts.sk.batch_size);
    
    tblcols = {'Layer' 'Units' 'Remove'};
    tbldata = getLayerTable(opts);
    set(mytbl,'Data',tbldata,'ColumnName',tblcols,'ColumnFormat',{'numeric' 'numeric' 'logical'},...
      'ColumnEditable',[false true true],'CellEditCallback',@uitable_layer_CellEditCallback);
    
  case 2 %tensorflow
    opts.algorithm = 'tensorflow';
    solvertxt = {'adam' 'adamax' 'rmsprop' 'sgd'};
    solverval = find(ismember(solvertxt,opts.tf.optimizer));
    solvelabel = 'Optimizer:';
    opts.tf.optimizer = solvertxt{solverval};
    
    activationtxt = {'relu' 'linear' 'tanh' 'sigmoid'};
    activationval = find(ismember(activationtxt,opts.tf.activation));
    opts.tf.activation = activationtxt{activationval};
    
    
    if strcmpi(opts.functionname,'anndl')
      losstxt = {'mean_squared_error' 'mean_absolute_error' 'log_cosh'};
    elseif strcmpi(opts.functionname,'anndlda')
      losstxt = {'binary_crossentropy' 'categorical_crossentropy' 'poisson'};
    end
    lossval = find(ismember(losstxt,opts.tf.loss));
    lossenable = true;
    
    maxiterstr = 'Epochs:';
    maxiterval = num2str(opts.tf.epochs);
    
    batchsizeval = num2str(opts.tf.batch_size);

    tblcols = {'Layer' 'Layer Type' 'Units' 'Pool/Kernel Size' 'Remove'};
    tbldata = getLayerTable(opts);
    layertypes = anndl('getlayerdefaults');
    layertypes = layertypes(:,1)';
    
    set(mytbl,'Data',tbldata,'ColumnName',tblcols,'ColumnFormat',...
      {'numeric' layertypes 'char' 'char' 'logical'},...
      'ColumnEditable',[false true true true true],'CellEditCallback',@uitable_layer_CellEditCallback);
    
  otherwise
    error('Unknown algorithm for ANNDL.')
end

set(handles.popupmenu_solver,'string',solvertxt','value',solverval)
set(handles.text_solver,'String',solvelabel);

set(handles.popupmenu_activation,'string',activationtxt','value',activationval);

set(handles.text_maxiter,'string',maxiterstr);
set(handles.edit_maxiter,'string',maxiterval);

set(handles.edit_batchsize,'string',batchsizeval);

if lossenable
  set(handles.popupmenu_loss,'string',losstxt,'value',lossval,'enable','on')
else
  set(handles.popupmenu_loss,'string',' ','value',1,'enable','off')
end

set(handles.popupmenu_compression,'String',{'None' 'PCA' 'PLS'});

switch opts.compression
  case 'none'
    set(handles.popupmenu_compression,'value',1);
    set(handles.edit_ncomp,'enable','off','String','')
  case 'pca'
    set(handles.popupmenu_compression,'value',2);
    set(handles.edit_ncomp,'enable','on','string',num2str(opts.compressncomp));
  case 'pls'
    set(handles.popupmenu_compression,'value',3);
    set(handles.edit_ncomp,'enable','on','string',num2str(opts.compressncomp));
end

if updateopts
  % only clear the model if algorithm option is changed.
  samealgorithm = strcmp(oldalgorithm, opts.algorithm);
  if samealgorithm
    setoptions(handles,opts, false); % do not clear the model
  else
    setoptions(handles,opts);        % do clear the model
  end
end

%--------------------------------------------------------------------
function setoptions(handles,newoptions,clearmodel)
%Set options in analysis gui and call change callback.

if nargin<3
  clearmodel = 1;
end

curanal = getappdata(handles.analysis,'curanal');
analysis('setopts',handles,curanal,newoptions);

if clearmodel
  analysis('clearmodel',handles.analysis, [], handles, []);
end

fn  = analysistypes(curanal,3);
if ~isempty(fn);
  feval(fn,'optionschange',handles.analysis);
end


%--------------------------------------------------------------------
function uitable_layer_CellEditCallback(hObject, eventdata,varargin)
% hObject    handle to uitable_layer (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)

%TF Conv1D table map: 
%  Layer  Units   LayerType       PoolSize 
%  1      100     Conv1D             3
%  2      -gray-  AveragePooling1D   5
%  3      -gray-  Flatten          -gray-
%  4      16      Dense            -gray-
%  5      0.25    Dropout          -gray-
%  opts.tf.layer_types = {'Conv1D' 'AveragePooling1D' 'Flatten' 'Dense' 'Dropout'} 
%  opts.tf.hidden_layer_sizes = {{100,{3}}, {5}, 16, 0.25};
%TF Conv2D table map: 
%  Layer  Units   LayerType     PoolSize 
%  1      100     Conv2D          3,3
%  2      -gray-  MaxPooling2D    5,5
%  3      -gray-  Flatten        -gray-
%  4      16      Dense          -gray-
%  5      0.25    Dropout        -gray-
%  opts.tf.layer_types = {'Conv2D' 'MaxPooling2D' 'Flatten' 'Dense' 'Dropout'} 
%  opts.tf.hidden_layer_sizes = {{100,{3,3}}, {5,5}, 16, 0.25}
%
%TF Conv3D table map: 
%  Layer  Units   LayerType     PoolSize 
%  1      100     Conv3D          3,3,3
%  2      -gray-  MaxPooling3D    5,5,5
%  3      -gray-  Flatten        -gray-
%  4      16      Dense          -gray-
%  5      0.25    Dropout        -gray-
%  opts.tf.layer_types = {'Conv3D' 'MaxPooling3D' 'Flatten' 'Dense' 'Dropout'} 
%  opts.tf.hidden_layer_sizes = {{100,{3,3,3}}, {5,5,5}, 16, 0.25}

handles = guihandles(ancestor(hObject,'figure'));
mytbl = handles.uitable_layer;
opts = getappdata(handles.analysis, 'analysisoptions');

doupdate = false;

switch opts.algorithm
  case 'sklearn'
    
    if eventdata.Indices(2)==3
      %If only one row then you can remove. 
      if size(mytbl.Data,1)==1
        %Warning message and reset to zero.
        evriwarndlg('There must be at least one layer.','Layer Warning')
        eventdata.Source.Data{eventdata.Indices(1),eventdata.Indices(2)} = false;
        return
      else
        %Remove this row.
        opts.sk.hidden_layer_sizes(eventdata.Indices(1)) = [];
        doupdate = true;
      end
    else
      %Update options with new value for layer size.
      if eventdata.NewData>0
        opts.sk.hidden_layer_sizes{eventdata.Indices(1)} = eventdata.NewData;
      else
        evriwarndlg('Value must be positive.','Layer Warning')
        eventdata.Source.Data{eventdata.Indices(1),eventdata.Indices(2)} = eventdata.PreviousData;
      end
    end
      
  case 'tensorflow'
    myrow = eventdata.Indices(1);
    mycol = eventdata.Indices(2);
    tbldata = mytbl.Data;
    currentlayer = opts.tf.hidden_layer{myrow};
    
    %Get default for this layer type (tbldata will have updated value if
    %change occured in layer column).
    layerdefault = anndl('getlayerdefaults',tbldata{myrow,2});
    
    %Most of the transactions from the table for TF are complicated so just
    %force an update of the table for everything.
    doupdate = true;
    
    switch mycol
      case 2
        %Type change, reset units and size based on defaults for now. 
        currentlayer.type = tbldata{myrow,2};
        currentlayer.units = layerdefault{2};
        currentlayer.size = layerdefault{3};
        opts.tf.hidden_layer{myrow} = currentlayer;
      case 3
        %Units change, check against default.
        if isempty(layerdefault{2})
          evriwarndlg(['Layer type: ' tbldata{myrow,1} ' does not use units. Resetting to empty.'],'Layer Warning');
          myval = [];
        else
          myval = str2num(tbldata{myrow,3});
          if isnan(myval)
            myval = [];
          end
          if any(myval<0) || isempty(myval)
             evriwarndlg(['Layer size must have positive number. Resetting to default.'],'Layer Warning')
             myval = layerdefault{2};
          end
        end
        currentlayer.units = myval; 
        
      case 4
        %Size change, check against default. 
        if isempty(layerdefault{3})
          evriwarndlg(['Layer type: ' upper(tbldata{myrow,2}) ' does not use size. Resetting to empty.'],'Layer Warning');
          myval = [];
        else
          myval = str2num(tbldata{myrow,4});
          if isnan(myval)
            %Bad character, probably letter.
            myval = [];
          end
          
          %Check number of elements.
          if numel(myval)<numel(layerdefault{3})
            evriwarndlg(['Layer size must have ' num2str(numel(layerdefault{3})) ' elements. Adding defaults.'],'Layer Warning')
            myval = [myval layerdefault{3}(numel(myval)+1:end)];
          end
          
          if numel(myval)>numel(layerdefault{3})
            evriwarndlg(['Layer size must have ' num2str(numel(layerdefault{3})) ' elements. Removing elements.'],'Layer Warning')
            myval = myval(1:numel(layerdefault{3}));
          end
          
          if any(myval<0) || ~isint(myval)
             evriwarndlg(['Layer size must have positive integers. Resetting to defaults.'],'Layer Warning')
             myval = layerdefault{3};
          end

        end
        currentlayer.size = myval; 
      case 5
        %Remove layer.
        opts.tf.hidden_layer(myrow) = [];
        if isempty(opts.tf.hidden_layer)
          %Add default back.
          evriwarndlg(['At least one layer is needed. Adding default.'],'Layer Warning')
          opts.tf.hidden_layer(1) = {struct('type','Dense','units',100,'size',[])}
        end
    end
    
    if mycol~=5
      opts.tf.hidden_layer{myrow} = currentlayer;
    end
end

setoptions(handles,opts)
if doupdate
  popupmenu_framework_Callback(handles.popupmenu_framework, [], handles);
end

%--------------------------------------------------------------------
function mytbl = getLayerTable(opts)
%Create layer table.

%TF Conv1D table map: 
%  Layer  Units   LayerType       PoolSize 
%  1      100     Conv1D             3
%  2      -gray-  AveragePooling1D   5
%  3      -gray-  Flatten          -gray-
%  4      16      Dense            -gray-
%  5      0.25    Dropout          -gray-
%  opts.tf.layer_types = {'Conv1D' 'AveragePooling1D' 'Flatten' 'Dense' 'Dropout'} 
%  opts.tf.hidden_layer_sizes = {{100,{3}}, {5}, 16, 0.25};
%TF Conv2D table map: 
%  Layer  Units   LayerType     PoolSize 
%  1      100     Conv2D          3,3
%  2      -gray-  MaxPooling2D    5,5
%  3      -gray-  Flatten        -gray-
%  4      16      Dense          -gray-
%  5      0.25    Dropout        -gray-
%  opts.tf.layer_types = {'Conv2D' 'MaxPooling2D' 'Flatten' 'Dense' 'Dropout'} 
%  opts.tf.hidden_layer_sizes = {{100,{3,3}}, {5,5}, 16, 0.25}
%
%TF Conv3D table map: 
%  Layer  Units   LayerType     PoolSize 
%  1      100     Conv3D          3,3,3
%  2      -gray-  MaxPooling3D    5,5,5
%  3      -gray-  Flatten        -gray-
%  4      16      Dense          -gray-
%  5      0.25    Dropout        -gray-
%  opts.tf.layer_types = {'Conv3D' 'MaxPooling3D' 'Flatten' 'Dense' 'Dropout'} 
%  opts.tf.hidden_layer_sizes = {{100,{3,3,3}}, {5,5,5}, 16, 0.25}
%
%SK Layer table map: 
%  Layer   Units 
%  1         200
%  2         500
% 
%  opts.sk.hidden_layer_sizes = {200 500};

% Layer types: {'Dense' 'Dropout' 'Flatten' 'Conv1D' 'Conv2D' 'Conv3D'...
% 'MaxPooling1D' 'MaxPooling2D' 'MaxPooling3D' 'AveragePooling1D' 'AveragePooling2D' 'AveragePooling3D'}
    

switch opts.algorithm
  case 'sklearn'
    myunits = opts.sk.hidden_layer_sizes';
    layernum = num2cell(1:length(myunits))';
    layerremove = num2cell(false(length(myunits),1));
    mytbl = [layernum myunits layerremove];
    
  case 'tensorflow'
    
    mylayers = opts.tf.hidden_layer;
    for i = 1:length(mylayers)
      mytbl{i,1} = i;%Layer number.
      %Layer type
      mytbl{i,2} = mylayers{i}.type;
      %Units
      mytbl{i,3} = '---';
      if isfield(mylayers{i},'units') && ~isempty(mylayers{i}.units)
        mytbl{i,3} = num2str(mylayers{i}.units);
      end
      %Size
      mytbl{i,4} = '---';
      if isfield(mylayers{i},'size') && ~isempty(mylayers{i}.size)
        mytbl{i,4} = num2str(mylayers{i}.size);
      end
    end
    
end


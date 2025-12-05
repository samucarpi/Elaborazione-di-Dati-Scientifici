function varargout = iplsgui(varargin)
% IPLSGUI Panel gui for ipls in analysis.
%
%

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if ~isempty(varargin) && ischar(varargin{1})
  if ismember(varargin{1},evriio([],'validtopics'));
    options = [];
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


% --- Executes just before iplsgui is made visible.
function iplsgui_OpeningFcn(hObject, eventdata, handles, varargin)

handles.output = hObject;

% Update handles structure
guidata(hObject, handles);


function varargout = iplsgui_OutputFcn(hObject, eventdata, handles)

varargout{1} = handles.output;

function iplsclear_Callback(hObject, eventdata, handles)
%Return to orginal include field.

crossval_figure = getappdata(handles.analysis);
cvv = getappdata(crossval_figure.crossvalgui);
crossval_settings = cvv.cvsettings;          
  
xblk = analysis('getobjdata','xblock',handles);
xincld = getappdata(handles.analysis,'ipls_originalInclude_x');
if ~isempty(xincld) && ~isempty(xblk)
  xblk.include{2} = xincld;
  analysis('setobjdata','xblock',handles,xblk);
  evrihelpdlg('Included Variables have been reset to original ranges.','Included Variables Reset');
end

  %Insure that the CV settings have not been reset when clicking 'use'
setappdata(crossval_figure.crossvalgui,'cvsettings',crossval_settings);
if strcmpi(crossval_settings.cv,'custom')
%Set the cvsets appdata for custom.
  setappdata(crossval_figure.crossvalgui,'cvsets',crossval_settings.split);
end
crossvalgui('resetfigure',crossval_figure.crossvalgui);

panelupdate_Callback(handles.analysis, [], []);

% --- Executes on button press in iplsok.
function iplsok_Callback(hObject, eventdata, handles)
%Stick ipls results into include field.

%Gather needed inputs.
xblk = analysis('getobjdata','xblock',handles);
yblk = analysis('getobjdata','yblock',handles);

iuse = getappdata(handles.analysis,'ipls_use');

%Get include info.
xincld = getappdata(handles.analysis,'ipls_originalInclude_x');
oinclude = xblk.include{2};

try
  xblk.include{2} = iuse;
  crossval_figure = getappdata(handles.analysis);
  cvv = getappdata(crossval_figure.crossvalgui);
  crossval_settings = cvv.cvsettings;          
  analysis('setobjdata','xblock',handles,xblk);
  
  %Insure that the CV settings have not been reset when clicking 'use'
  setappdata(crossval_figure.crossvalgui,'cvsettings',crossval_settings);
  if strcmpi(crossval_settings.cv,'custom')
  %Set the cvsets appdata for custom.
    setappdata(crossval_figure.crossvalgui,'cvsets',crossval_settings.split);
  end
  crossvalgui('resetfigure',crossval_figure.crossvalgui);

  %Set orginal include here otherwise it gets cleared in update callback above.
  if isempty(xincld)
    setappdata(handles.analysis,'ipls_originalInclude_x',oinclude);
  end
  
  %Set flag for mod date on both blocks.
  setappdata(handles.analysis,'ipls_xmoddate',xblk.moddate);
  if ~isempty(yblk)
    setappdata(handles.analysis,'ipls_ymoddate',yblk.moddate);
  end
  evrihelpdlg('Current variables set to those selected.','Use Selected Variables');

  panelupdate_Callback(handles.analysis, [], []);
catch
  error('Unable to asign selection results to current xblock.');
end

% --- Executes on button press in iplsexecute.
function iplsexecute_Callback(hObject, eventdata, handles)
% Execute ipls with current settings.

handles = guihandles(handles.analysis);

%Gather needed inputs.
xblk = analysis('getobjdata','xblock',handles);
yblk = analysis('getobjdata','yblock',handles);

int_width = str2num(get(handles.iplssize,'String'));
maxlv = str2num(get(handles.iplsmaxlv,'String'));

myopts = ipls('options');

myopts.preprocessing = {getappdata(handles.preprocessmain,'preprocessing') getappdata(handles.preproyblkmain,'preprocessing')};

modeval = get(handles.iplsmode,'value');
modestr = get(handles.iplsmode,'string');
myopts.mode = modestr{modeval};

algval = get(handles.iplsalgorithm,'value');
algstr = get(handles.iplsalgorithm,'string');
myopts.algorithm = algstr{algval};

stepstr = get(handles.iplsstepsize,'string');
if strcmpi(stepstr,'auto')
  stepstr = '';
end
myopts.stepsize = str2num(stepstr);

% If it is iplsda but yblock is not logical then convert it to be so.
if strcmpi(getappdata(handles.analysis,'curanal'),'plsda') & ~isempty(yblk) & ~islogical(yblk.data)
    yblk = class2logical(yblk.data);
end
  
if strcmpi(getappdata(handles.analysis,'curanal'),'plsda') & isempty(yblk)
  model = analysis('getobjdata','model',handles);
  if isempty(model);
    try
      analysis('calcmodel_Callback',handles.analysis,[],handles);
      model = analysis('getobjdata','model',handles);
    catch
      %do nothing - model will still be empty so error below will be thrown
    end
  end
  if isempty(model);
    %probably had a problem calculating the model or trapped above
    erdlgpls('A PLSDA model must first be calculated with this data but something went wrong when calculating the model. Click the model icon to solve the problem and build a model, then re-execute.','No Model Present');
    return
  end
  yblk = model.detail.data{2};
end

ipls_use = getappdata(handles.analysis,'ipls_use');
if ~isempty(ipls_use)
  switch myopts.mode
    case 'forward'
      switch evriquestdlg('Should current selections add to the previously selected intervals or start a new selection?','Previous Selection Found','Add To Previous','Start New','Cancel','Add To Previous');
        case 'Cancel'
          return;
        case 'Add To Previous'
          myopts.mustuse = ipls_use;  %force ipls to use these windows
        otherwise
          %start with nothing
      end
    case 'reverse'
      switch evriquestdlg('Should previouly selected intervals be removed or start a new selection?','Previous Selection Found','Remove From Previous','Start New','Cancel','Remove From Previous');
        case 'Cancel'
          return;
        case 'Remove From Previous'
          xblk.include{2} = intersect(xblk.include{2},ipls_use);   %pre-exclude the ones already thrown away
        otherwise
          %start with only whatever is included in xblock
      end
  end
end

myopts.numintervals = str2num(get(handles.iplsintervals,'string'));
if isempty(myopts.numintervals);
  myopts.numintervals = inf;
end

%Get current crosssvalidation.
[cvmode,cvlv,cvsplit,cviter] = crossvalgui('getsettings',getappdata(handles.analysis,'crossvalgui'));
if ~strcmp(cvmode,'none')
  myopts.cvi = {cvmode cvsplit cviter};
end

try
  opt=mdcheck('options');
  opt.max_pcs=maxlv;
  [flag,missmap,xblk] = mdcheck(xblk,opt);
  iplsout = ipls(xblk,yblk,int_width,maxlv,myopts);
  if isempty(iplsout)
    %User cancel.
    return
  end
  analysis('adopt',handles,iplsout.figh,'modelspecific');
  setappdata(handles.analysis,'ipls_use',iplsout.use);
  
  %create a description of the selected variables
  list = iplsout.use;
  if ~isempty(xblk.axisscale{2});
    list = xblk.axisscale{2}(list);
  end
  list = encode(list,'');
  list = textwrap({list},45);
  set(handles.intervallist,'string',list);

  %Turn the "OK" button on so user can add use to include field.
  set(handles.iplsok,'enable','on');
catch
  myerr = lasterr;
  try
    %Try to delete waitbar if it's out there.
    delete(findobj(0,'tag','iplswaitbar'));
  end
  erdlgpls(['Error occured while trying to execute ipls:      ' myerr],'iPLS Error');
end

% --------------------------------------------------------------------
function iplsreset_Callback(hObject, eventdata, handles)

panelinitialize_Callback(handles.analysis,[], []);

% --------------------------------------------------------------------
function iplssize_Callback(hObject, eventdata, handles)


% --------------------------------------------------------------------
function iplsmode_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function iplsalgorithm_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function iplsintervals_auto_Callback(hObject, eventdata, handles)

handles = guihandles(handles.analysis);
if get(handles.iplsintervals_auto,'value')==1
  set(handles.iplsintervals,'String','auto');
  set(handles.iplsintervals,'enable','off');
else
  if isempty(str2num(get(handles.iplsintervals,'String')))
    set(handles.iplsintervals,'String','1');
  end
  set(handles.iplsintervals,'enable','on');
end

% --------------------------------------------------------------------
function iplsintervals_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function iplsstepsize_auto_Callback(hObject, eventdata, handles)

handles = guihandles(handles.analysis);
if get(handles.iplsstepsize_auto,'value')==1
  set(handles.iplsstepsize,'String','auto');
  set(handles.iplsstepsize,'enable','off');
else
  if isempty(str2num(get(handles.iplsstepsize,'String')))
    set(handles.iplsstepsize,'String','1');
  end
  set(handles.iplsstepsize,'enable','on');
end

% --------------------------------------------------------------------
function iplsstepsize_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function iplsmaxlv_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function panelinitialize_Callback(figh, frameh, varargin)
%Initialize panel objects.

handles = guihandles(figh);

%Gather needed inputs.
xblk = analysis('getobjdata','xblock',handles);
modl = analysis('getobjdata','model',handles);

%Clear old ipls status data.
setappdata(handles.analysis,'ipls_use',[]);
set(handles.intervallist,'string','');
setappdata(handles.analysis,'ipls_xmoddate',[]);
setappdata(handles.analysis,'ipls_ymoddate',[]);
setappdata(figh,'ipls_originalInclude_x',[]);

myopts = ipls('options');
myopts.numintervals = inf; %NOTE: Hard-code to force on automatic interval selection

%Set mode.
if strcmp(myopts.mode,'forward')
  set(handles.iplsmode,'value',1);
else
  set(handles.iplsmode,'value',2);
end

%Set num intervals. iplsintervals
if isinf(myopts.numintervals)
  switch 0
    case 0
      set(handles.iplsintervals,'String','1');
      set(handles.iplsintervals_auto,'value',0);
      set(handles.iplsintervals,'enable','on');
    case 1
      set(handles.iplsintervals,'String','auto');
      set(handles.iplsintervals_auto,'value',1);
      set(handles.iplsintervals,'enable','off');
  end
else
  set(handles.iplsintervals_auto,'value',0);
  set(handles.iplsintervals,'enable','on');
  set(handles.iplsintervals,'String',num2str(myopts.numintervals));
end

%Set step size.
if isempty(myopts.stepsize)
  %Auto select.
  switch 1
    case 0
      %automatic OFF
      set(handles.iplsstepsize,'String','1');
      set(handles.iplsstepsize_auto,'value',0);
      set(handles.iplsstepsize,'enable','on');
    case 1
      %automatic ON
      set(handles.iplsstepsize,'String','auto');
      set(handles.iplsstepsize_auto,'value',1);
      set(handles.iplsstepsize,'enable','off');
  end
else
  set(handles.iplsstepsize,'String',num2str(myopts.stepsize));
end

%Vars per interval, start with 1.
set(handles.iplssize,'String','1');

%Set algorithm.
curanal = getappdata(handles.analysis,'curanal');
switch curanal
  case {'pls','plsda'}
    sval = 1;
  case 'pcr'
    sval = 2;
  case 'mlr'
    sval = 3;
end
set(handles.iplsalgorithm,'value',sval);

%Set max LVs initial value to editpc value.
if strcmp(curanal,'mlr')
  %Not used for mlr.
  set(handles.iplsmaxlv,'enable','off');
  set(handles.iplsmaxlv,'String','1');
else
  set(handles.iplsmaxlv,'enable','on');
  %Set max lv to min of model|row|col|20
  minval = 20;
  if ~isempty(modl)
    minval = [minval size(modl.loads{1},2)];
  end
  
  if ~isempty(xblk)
    minval = [minval size(xblk.data,1)];
    minval = [minval size(xblk.data,2)];
  end

  set(handles.iplsmaxlv,'String',min(minval));
end

%Set rPLS defaults.
rplsopts = rpls('options');
switch rplsopts.mode
  case 'specified'
    set(handles.rplsmode,'value',1)
  case 'suggested'
    set(handles.rplsmode,'value',2)
  case 'surveyed'
    set(handles.rplsmode,'value',3)
end

set(handles.rplsiter,'String',num2str(rplsopts.maxiter));
set(handles.rplslvs,'String',num2str(rplsopts.maxlv));


%Mac fonts are bigger so size smaller to look better.
if ismac
  set([handles.iplsstepsize_auto handles.iplsintervals_auto handles.iplsadvanced],'Fontsize',9);
end

% --------------------------------------------------------------------
function  panelupdate_Callback(figh, frameh, varargin)

%Update panel objects.
handles = guihandles(figh);

%Gather needed inputs.
xblk = analysis('getobjdata','xblock',handles);
yblk = analysis('getobjdata','yblock',handles);
myctrls = findobj(figh,'userdata','iplsgui');

%Get ipls status data.
xmod = getappdata(handles.analysis,'ipls_xmoddate');
ymod = getappdata(handles.analysis,'ipls_ymoddate');

%Check for changes to data and clear ipls_use if changes were made.
if ~isempty(xblk) && ~isempty(xmod) && (datenum(xblk.moddate) ~= datenum(xmod))
  setappdata(handles.analysis,'ipls_use',[]);
  set(handles.intervallist,'string','');
  setappdata(figh,'ipls_originalInclude_x',[]);
elseif ~isempty(yblk) &&  ~isempty(ymod) && (datenum(yblk.moddate) ~= datenum(ymod))
  setappdata(handles.analysis,'ipls_use',[]);
  set(handles.intervallist,'string','');
end

%Enable all controls.
if ~isempty(xblk) & (~isempty(yblk) | strcmpi(getappdata(handles.analysis,'curanal'),'plsda'))
  set(myctrls,'enable','on');
  iplsintervals_auto_Callback([], [], handles);
  iplsstepsize_auto_Callback([], [], handles);
else
  %Disable.
  set(myctrls,'enable','off');
end

%Disable based on method dropdown.
mymethod = get(handles.varselectionmethod,'value');
switch mymethod
  case 1
    %Disable rpls and ga
    set([getControlHandles(handles,'rpls') getControlHandles(handles,'ga')],'enable','off')
  case 2
    set([getControlHandles(handles,'ipls') getControlHandles(handles,'ga')],'enable','off')
  case 3
    set([getControlHandles(handles,'rpls') getControlHandles(handles,'ipls')],'enable','off')
end


%Enable "Use" button. 
if ~isempty(getappdata(handles.analysis,'ipls_use'))
  set(handles.iplsok,'enable','on');
else
  set(handles.iplsok,'enable','off');
end

%Enable "Discard" button. 
if ~isempty(getappdata(handles.analysis,'ipls_originalInclude_x'))
  set(handles.iplsclear,'enable','on');
else
  set(handles.iplsclear,'enable','off');
end
  

%Save original include field so user can "reset".
%setappdata(figh,'ipls_originalInclude_x',xblk.include{2});
if ~get(handles.iplsadvanced,'value')
  tohide = [handles.text7 handles.iplsstepsize ...
    handles.iplsstepsize_auto ...
    handles.text4 handles.iplsmode ];
  set(tohide,'visible','off');
end

%HARD-CODED hide of algorithm
set([handles.text5 handles.iplsalgorithm],'visible','off');

% --------------------------------------------------------------------
function myctrls = getControlHandles(hh,method)
%Get list of disable/enable control handles for given method.

myctrls = [];

switch method
  case 'ipls'
    myctrls = [hh.iplsmode hh.iplsintervals hh.iplsintervals_auto hh.iplssize ...
      hh.iplsstepsize hh.iplsstepsize_auto hh.iplsmaxlv hh.iplsalgorithm ...
      hh.iplsadvanced hh.iplsexecute hh.iplsreset];
  case 'rpls'    
    myctrls = [hh.rplsmode hh.rplslvs hh.rplsiter hh.rplsexecute hh.rplsreset];    
  case 'ga'
    myctrls = hh.openinga;
end

% --------------------------------------------------------------------
function panelresize_Callback(figh, frameh, varargin)
% Resize specific to panel manager. figh is parent figure, frameh is frame
% handle.

handles = guidata(figh);
if ~isfield(handles,'text4')
  handles = guihandles(figh);
  guidata(figh,handles);
end
myctrls = findobj(figh,'userdata','iplsgui');
set(myctrls,'units','pixels');

%Move rest of controls to upper left of frame.
frmpos = get(frameh,'position');%[left bottom width height]

%Column widths.
c1pad = 6;
c2pad = 5;
c3pad = 5;
allpad = c1pad+c2pad+c3pad;
usewidth = (frmpos(3)-allpad-15-frmpos(1));
w1 = max(usewidth*.48,136);
w2 = max(usewidth*.28,80);
w3 = max(usewidth*.24,70);

txtpos = get(handles.text4,'position');
newbottom = (frmpos(2)+frmpos(4)-(txtpos(4)+8));
newleft1 = (frmpos(1)+c1pad);
newleft2 = (newleft1+w1+c2pad);
newleft3 = (newleft2+w2+c3pad);

fs = getdefaultfontsize('normal');
sc = fs/10;

%Height
ht = 20;
ht2 = 20;

%Division size.
smdiv = 2;
lgdiv = 10;

%Var selection method.
set(handles.text13,'position',[newleft1 newbottom w1 ht]);
set(handles.varselectionmethod,'position',[newleft2 newbottom w2 ht]);

%iPLS Controls
newbottom = newbottom-(ht+smdiv)-10;

set(handles.text4,'position',[newleft1 newbottom w1 ht]);
set(handles.iplsmode,'position',[newleft2 newbottom w2 ht]);

newbottom = newbottom-(ht+smdiv);

set(handles.text6,'position',[newleft1 newbottom w1 ht]);
set(handles.iplsintervals,'position',[newleft2 newbottom w2 ht]);
set(handles.iplsintervals_auto,'position',[newleft3 newbottom w3+10 ht]);

newbottom = newbottom-(ht+lgdiv);

set(handles.text2,'position',[newleft1 newbottom w1 ht]);
set(handles.iplssize,'position',[newleft2 newbottom w2 ht]);

newbottom = newbottom-(ht+smdiv);

set(handles.text7,'position',[newleft1 newbottom w1 ht]);
set(handles.iplsstepsize,'position',[newleft2 newbottom w2 ht]);
set(handles.iplsstepsize_auto,'position',[newleft3 newbottom w3+10 ht]);

if ~get(handles.iplsadvanced,'value')
  set(handles.text3,'position',[newleft1 newbottom w1 ht]);
  set(handles.iplsmaxlv,'position',[newleft2 newbottom w2 ht]);
end

newbottom = newbottom-(ht+lgdiv);

set(handles.text3,'position',[newleft1 newbottom w1 ht]);
set(handles.iplsmaxlv,'position',[newleft2 newbottom w2 ht]);

newbottom = newbottom-(ht+lgdiv);

% set(handles.text5,'position',[newleft1 newbottom w1 ht]);
% set(handles.iplsalgorithm,'position',[newleft2 newbottom w2 ht]);
% 
% newbottom = newbottom-(ht+smdiv);

wbtn = usewidth/4-8;
set(handles.iplsadvanced,'position',[newleft1 newbottom wbtn ht2]);
set(handles.iplsexecute,'position',[newleft1+(wbtn+8)*1 newbottom wbtn ht2]);
set(handles.iplsreset,'position',[newleft1+(wbtn+8)*2 newbottom wbtn ht2]);
set(handles.helpbtn,'position',[newleft1+(wbtn+8)*3 newbottom wbtn ht2]);

newbottom = newbottom-(smdiv+2);

myfrmpos = get(handles.frame3,'position');
myfrmpos(1) = frmpos(1)+4;
myfrmpos(2) = newbottom;
myfrmpos(3) = frmpos(3)-8;
myfrmpos(4) = (frmpos(2)+frmpos(4)-(txtpos(4)+8))-newbottom-6;
set(handles.frame3,'position',myfrmpos);

newtop    = newbottom-smdiv;

%rPLS Controls.
myfrmpos = get(handles.frame5,'position');
myfrmpos(1) = frmpos(1)+4;
myfrmpos(2) = newtop-myfrmpos(4);
myfrmpos(3) = frmpos(3)-8;
set(handles.frame5,'position',myfrmpos);

newbottom = newbottom-(ht+smdiv)-10;

set(handles.text10,'position',[newleft1 newbottom w1 ht]);
set(handles.rplsmode,'position',[newleft2 newbottom w2 ht]);

newbottom = newbottom-(ht+smdiv)-10;

set(handles.text11,'position',[newleft1 newbottom w1 ht]);
set(handles.rplslvs,'position',[newleft2 newbottom w2 ht]);

newbottom = newbottom-(ht+smdiv)-10;

set(handles.text9,'position',[newleft1 newbottom w1 ht]);
set(handles.rplsiter,'position',[newleft2 newbottom w2 ht]);

newbottom = newbottom-(ht+smdiv)-10;

set(handles.rplsexecute,'position',[newleft1+(wbtn+8)*1 newbottom wbtn ht2]);
set(handles.rplsreset,'position',[newleft1+(wbtn+8)*2 newbottom wbtn ht2]);
set(handles.rplshelp,'position',[newleft1+(wbtn+8)*3 newbottom wbtn ht2]);


%Selected Intervals
newtop    = newbottom-smdiv-14;

myfrmpos = get(handles.frame2,'position');
myfrmpos(1) = frmpos(1)+4;
myfrmpos(2) = newtop-myfrmpos(4);
myfrmpos(3) = frmpos(3)-8;
set(handles.frame2,'position',myfrmpos);

newtop    = newtop-smdiv*2;

set(handles.text1,'position',[newleft1 newtop-ht2 w1+10 ht2]);
set(handles.iplsok,'position',[newleft2+10 newtop-ht2 w3 ht2]);
set(handles.iplsclear,'position',[newleft3 newtop-ht2 w3 ht2]);

mypos = get(handles.intervallist,'position');
mypos(3) = frmpos(3)-12;
set(handles.intervallist,'position',[newleft1 newtop-ht2-2-mypos(4) mypos(3:4)]);

%GA Frame

newtop = myfrmpos(2)-smdiv;
myfrmpos  = get(handles.gaframe,'position');
myfrmpos(1) = frmpos(1)+4;
myfrmpos(2) = newtop-myfrmpos(4);
myfrmpos(3) = frmpos(3)-8;
set(handles.gaframe,'position',myfrmpos);

halfwidth = (myfrmpos(3)-20)/2;
mypos = get(handles.openinga,'position');
mypos(1) = myfrmpos(1)+halfwidth+5;
mypos(2) = myfrmpos(2)+5;
mypos(3) = halfwidth;
mypos(4) = myfrmpos(4)-10;
set(handles.openinga,'position',mypos);

mypos = get(handles.gatext,'position');
mypos(1) = myfrmpos(1)+5;
mypos(2) = myfrmpos(2)+5;
mypos(3) = halfwidth;
mypos(4) = myfrmpos(4)-10;
set(handles.gatext,'position',mypos);


% --- Executes during object creation, after setting all properties.
function intervallist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to intervallist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on selection change in intervallist.
function intervallist_Callback(hObject, eventdata, handles)
% hObject    handle to intervallist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns intervallist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from intervallist




% --- Executes on button press in helpbtn.
function helpbtn_Callback(hObject, eventdata, handles)
% hObject    handle to helpbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

evrihelp('ipls_variable_selection_interface')



% --- Executes on button press in iplsadvanced.
function iplsadvanced_Callback(hObject, eventdata, handles)
% hObject    handle to iplsadvanced (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of iplsadvanced

analysis('panelviewselect_Callback',gcbf, [], guidata(gcbf))


% --- Executes on button press in openinga.
function openinga_Callback(hObject, eventdata, handles)
% hObject    handle to openinga (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

xblk = analysis('getobjdata','xblock',handles);
yblk = analysis('getobjdata','yblock',handles);

if strcmpi(getappdata(handles.analysis,'curanal'),'plsda') & ~isempty(yblk) & ~islogical(yblk.data)
    yblk = class2logical(yblk.data);
end
  
if strcmpi(getappdata(handles.analysis,'curanal'),'plsda') & isempty(yblk)
  model = analysis('getobjdata','model',handles);
  if isempty(model);
    try
      analysis('calcmodel_Callback',handles.analysis,[],handles);
      model = analysis('getobjdata','model',handles);
    catch
      %do nothing - model will still be empty so error below will be thrown
    end
  end
  if isempty(model);
    %probably had a problem calculating the model or trapped above
    erdlgpls('A PLSDA model must first be calculated with this data but something went wrong when calculating the model. Click the model icon to solve the problem and build a model, then re-execute.','No Model Present');
    return
  end
  yblk = model.detail.data{2};
end


h = genalg(xblk,yblk);

%push current settings into genalg
obj = evrigui(handles.analysis);
switch obj.getMethod
  case 'mlr'
    genalg('mlr',h);
  otherwise
    genalg('pls',h);
end
genalg('preproxblk',h,obj.getXPreprocessing);
genalg('preproyblk',h,obj.getYPreprocessing);

cvi = obj.getCrossvalidation;
if ~isempty(cvi) & ~strcmpi(cvi{1},'none');
  genalg('actsubsets',h,cvi{2});
  switch cvi{1}
    case 'rnd'
      genalg('random',h);
    otherwise
      genalg('contiguous',h);
  end
end




function rplsiter_Callback(hObject, eventdata, handles)
% hObject    handle to rplsiter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rplsiter as text
%        str2double(get(hObject,'String')) returns contents of rplsiter as a double



% --- Executes on selection change in rplsmode.
function rplsmode_Callback(hObject, eventdata, handles)
% hObject    handle to rplsmode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns rplsmode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from rplsmode



function rplslvs_Callback(hObject, eventdata, handles)
% hObject    handle to rplslvs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rplslvs as text
%        str2double(get(hObject,'String')) returns contents of rplslvs as a double


% --- Executes on selection change in varselectionmethod.
function varselectionmethod_Callback(hObject, eventdata, handles)
% Change variable selection method.

%Clear intervals.
setappdata(handles.analysis,'ipls_use',[]);
set(handles.intervallist,'string','');

panelupdate_Callback(handles.analysis, [], [])


% --- Executes on button press in rplsexecute.
function rplsexecute_Callback(hObject, eventdata, handles)
% hObject    handle to rplsexecute (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
  set(handles.analysis,'pointer','watch')
  pause(.01);drawnow%Make sure pointer updated.
  handles = guihandles(handles.analysis);
  
  %Gather needed inputs.
  xblk = analysis('getobjdata','xblock',handles);
  yblk = analysis('getobjdata','yblock',handles);
  
  rplsmodestr = get(handles.rplsmode,'string');
  rplsmodeval = get(handles.rplsmode,'value');
  rplsmode = rplsmodestr{rplsmodeval};
  
  rpsmaxiter = str2num(get(handles.rplsiter,'String'));
  rplsmaxlv = str2num(get(handles.rplslvs,'String'));
  
  myopts = rpls('options');
  myopts.display = 'off';
  myopts.mode = rplsmode;
  myopts.maxlv = rplsmaxlv;
  myopts.maxiter = rpsmaxiter;
  
  myopts.preprocessing = {getappdata(handles.preprocessmain,'preprocessing') getappdata(handles.preproyblkmain,'preprocessing')};
  
  % If it is iplsda but yblock is not logical then convert it to be so.
  if strcmpi(getappdata(handles.analysis,'curanal'),'plsda') & ~isempty(yblk) & ~islogical(yblk.data)
    yblk = class2logical(yblk.data);
  end
  
  if strcmpi(getappdata(handles.analysis,'curanal'),'plsda') & isempty(yblk)
    model = analysis('getobjdata','model',handles);
    if isempty(model);
      try
        analysis('calcmodel_Callback',handles.analysis,[],handles);
        model = analysis('getobjdata','model',handles);
      catch
        %do nothing - model will still be empty so error below will be thrown
      end
    end
    if isempty(model);
      %probably had a problem calculating the model or trapped above
      erdlgpls('A PLSDA model must first be calculated with this data but something went wrong when calculating the model. Click the model icon to solve the problem and build a model, then re-execute.','No Model Present');
      return
    end
    yblk = model.detail.data{2};
  end
  
  %Get current crosssvalidation.
  [cvmode,cvlv,cvsplit,cviter] = crossvalgui('getsettings',getappdata(handles.analysis,'crossvalgui'));
  if ~strcmp(cvmode,'none')
    myopts.cvi = {cvmode cvsplit cviter};
  end
catch
  myerr = lasterr;
  if ishandle(handles.analysis)
    set(handles.analysis,'pointer','arrow');
  end
  erdlgpls(['Error occured while trying to execute rpls:      ' myerr],'rPLS Error');
  return
end

try
  opt=mdcheck('options');
  opt.max_pcs=rplsmaxlv;
  [flag,missmap,xblk] = mdcheck(xblk,opt);
  rplsout = rpls(xblk,yblk,rplsmaxlv,myopts);
  if isempty(rplsout)
    %User cancel.
    return
  end
  analysis('adopt',handles,rplsout.figh,'modelspecific');
  
  list = rplsout.selectedIdxs{rplsout.selected};
  
  setappdata(handles.analysis,'ipls_use',list);
  
  %create a description of the selected variables
  if ~isempty(xblk.axisscale{2});
    list = xblk.axisscale{2}(list);
  end
  list = encode(list,'');
  list = textwrap({list},45);
  set(handles.intervallist,'string',list);

  %Turn the "OK" button on so user can add use to include field.
  set(handles.iplsok,'enable','on');
catch
  myerr = lasterr;
  if ishandle(handles.analysis)
    set(handles.analysis,'pointer','arrow');
  end
  erdlgpls(['Error occured while trying to execute rpls:      ' myerr],'rPLS Error');
end
set(handles.analysis,'pointer','arrow');

% --- Executes on button press in rplsreset.
function rplsreset_Callback(hObject, eventdata, handles)
% hObject    handle to rplsreset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
panelinitialize_Callback(handles.analysis,[], []);

% --- Executes on button press in rplshelp.
function rplshelp_Callback(hObject, eventdata, handles)
% hObject    handle to rplshelp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

evrihelp('rpls_variable_selection_interface')

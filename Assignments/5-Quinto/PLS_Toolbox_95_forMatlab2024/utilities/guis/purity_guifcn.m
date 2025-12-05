function varargout = purity_guifcn(varargin)
%PURITY_GUIFCN - Analysis-specific methods for Analysis GUI
% This is a set of utility functions used by the VarAnalysis GUI only.
%See also: VARANALYSIS

%Copyright © Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargout == 0;
  feval(varargin{:}); % FEVAL switchyard
else
  [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
end

%----------------------------------------------------
function gui_init(h,eventdata,handles,varargin);
%create toolbar
[atb abtns] = toolbar(handles.analysis, 'purity','');
handles  = guidata(handles.analysis);
analysis('toolbarupdate',handles);

%change pc edit label.
set(handles.pcseditlabel,'string','Number Components:','Enable','on')

mytbl = getappdata(handles.analysis,'ssqtable');
mytbl = ssqsetup(mytbl,{'Fit<br>(%Model)' 'Fit<br>(%X)' 'Fit<br>Cumulative (%X)' ' '},...
  '<b>&nbsp;&nbsp;&nbsp;PC',{'%6.2f' '%6.2f' '%6.2f' ''},0);

set(handles.tableheader,'string','Percent Variance Captured by Purity Model','HorizontalAlignment','center')

%turn off valid crossvalidation
%enable_crossvalgui must be set before crossvalgui('disable',cvgui); call.
setappdata(handles.analysis,'enable_crossvalgui','off');

%Add panel.
panelinfo.name = 'SSQ Table';
panelinfo.file = 'ssqtable';
panelmanager('add',panelinfo,handles.ssqframe)

%Turn off preprocessing
setappdata(handles.preprocessmain,'preprocessing',preprocess('none'));
%set(handles.preprocess,'enable','off');

%general updating
updatessqtable(handles)
updatefigures(handles.analysis)

%----------------------------------------------------
function calcmodel_Callback(h,eventdata,handles,varargin);

statmodltest = lower(getappdata(handles.analysis,'statmodl'));

if ismember(statmodltest,{'none' 'calnew'})
  
  data = analysis('getobjdata','xblock',handles);
  
  %INITIALIZE OPTIONS
  options = getappdata(handles.analysis,'analysisoptions');
  if isempty(options)
    options = purity('options');
  end
  options.interactive='on';
  options.select=[1:size(data.data,3)];
  options.resolve='off';
  options.display='off';
  options.offset=[3 10];
  options.returnfig = 'on';
  
  chf = getappdata(handles.calcmodel,'children');
  if ~isempty(chf)
    options.fighandle = chf;
  end
  
  %CALL PURITY
  
  [model fighandle] = purity(data,0,options);
  model.detail.window_der=1;
  
  %SAVE RESULTS ETC AS USERDATA
  
  userdata.data=data;
  userdata.model=model;
  userdata.datasource=model.datasource;  %store ORIGINAL datasource info
  
  %SET VISIBILITY TO CALLBACK
  
  hh=fighandle;
  setappdata(hh,'parent',double(handles.analysis));
  setappdata(hh,'userdata',userdata); %Put dataset and model in main purity figure.
  setappdata(handles.calcmodel,'children',hh)
  [atb abtns] = toolbar(hh, 'puritymainfig','');
  toolbar(hh, 'enable','')
  set(findobj(abtns,'tag','winderdecrease'),'enable','off')
  set(findobj(abtns,'tag','tbaccept'),'enable','off')
  handlespur = guidata(fighandle);
  
  %If there is an existing figure, don't place additional purity menu on.
  if isempty(findobj(fighandle,'tag','puritymenu'))
    createpuritymenu(hh)
  end
  
  %always clear prediction (the user is building the model
  analysis('setobjdata','prediction',handles,[]);
  
elseif analysis('isloaded','validation_xblock',handles)
  %Apply purity model
  data = analysis('getobjdata','validation_xblock',handles);
  modl = analysis('getobjdata','model',handles);
  
  try
    test = purity(data,modl);
  catch
    erdlgpls({'Error applying model to validation data.',lasterr,'Model not applied.'},'Apply Model Error');
    test = [];
  end
  
  analysis('setobjdata','prediction',handles,test);
  
end

analysis('updatestatusboxes',handles);
updatefigures(handles.analysis);


% --------------------------------------------------------------------
function plotloads_Callback(h, eventdata, handles, varargin)
pca_guifcn('plotloads_Callback',h, eventdata, handles, varargin)

%Check to see if user was using stick plot and set plotgui to stick if so.
pm = analysis('getobjdata','model',handles);
%Use try/catch here becuase not sure if all purity models will have
%axistype field in same place.
if strcmp(pm.detail.options.axistype{2},'bar')
  plotgui('update','plottype','stick')
end

%----------------------------------------------------
function out = isdatavalid(xprofile,yprofile,fig)

%two-way x
out = xprofile.data & xprofile.ndims==2;

%multi-way x
% out = xprofile.data & xprofile.ndims>2;

%discrim: two-way x with classes OR y
% out = xprofile.data & xprofile.ndims==2 & (xprofile.class | (yprofile.data & yprofile.ndims==2) );

%two-way x and y
% out = xprofile.data & xprofile.ndims==2 & yprofile.data & yprofile.ndims==2;

%multi-way x and y
% out = xprofile.data & xprofile.ndims>2 & yprofile.data;

%--------------------------------------------------------------------
function out = isyused(handles)

out = false;

%----------------------------------------------------
function gui_deselect(h,eventdata,handles,varargin)
%Set gui back to defualt settings.
set([handles.tableheader handles.pcseditlabel handles.ssqtable handles.pcsedit],'visible','on')
set(handles.tableheader,'string', { '' },'horizontalalignment','left')
set(handles.preprocess,'enable','on');
closefigures(handles);

%Set crossval gui to default.
setappdata(handles.analysis,'enable_crossvalgui','on');
%Update cvgui.
analysis('updatecrossvallimits',handles)
%Clear table.
mytbl = getappdata(handles.analysis,'ssqtable');
clear(mytbl,'all');

%Get rid of panel objects.
panelmanager('delete',panelmanager('getpanels',handles.ssqframe),handles.ssqframe)

%----------------------------------------------------
function gui_updatetoolbar(h,eventdata,handles,varargin)


%----------------------------------------------------
function gui_prepromenu(h,eventdata,handles,varargin)
%Turn off preprocessing
set(handles.preprocessmain,'enable','off')

%--------------------------------------------------------------------
function updatefigures(h)

pca_guifcn('updatefigures',h);

%-------------------------------------------------
function updatessqtable(handles,pc)
%Purity SSQ table is modified from standard form. Purity is currently a
%single direction method where a user can't interact with the SSQ table to
%select the number of components.

modl = analysis('getobjdata','model',handles);
mytbl = getappdata(handles.analysis,'ssqtable');

if isempty(modl)
  clear(mytbl);%Clear data.
  return
else
  %PCs not given? assume max from model
  if nargin<2
    pc = size(modl.loads{2});
    pc = pc(end);
  end
  
  [ssq_table,column_headers,column_format] = getssqtable(modl,pc,'raw',5,true);
  
  %Update table data.
  mytbl.data = ssq_table;
  %Make selection the current PC.
  setselection(mytbl,'rows',pc)
  
  %Use min and max to allow 'value' to be set to [] and not display
  %selection.
  set(handles.pcsedit,'String',int2str(pc),'Enable','inactive')
end


%----------------------------------------
function closefigures(handles)
%close the analysis specific figures
for parent = [handles.calcmodel];
  children = getappdata(parent,'children');
  children = children(ishandle(children));
  for j=findobj(children)';   %find children in ANY sub-object
    children=[children getappdata(j,'children')];
  end
  children = children(ishandle(children));
  children = children(ismember(char(get(children,'type')),{'figure'}));
  if ~isempty(children)
    delete(children)
  end
  setappdata(parent,'children',[]);
end

pca_guifcn('closefigures',handles);
%----------------------------------------
function [userdata, npurvar] = purity_enter(handles)

userdata=getappdata(handles.purity_main_fig,'userdata');

dim3=size(userdata.data.data,3);

if strcmpi(userdata.model.detail.options.mode,'cols')
  %doing standard mode
  npurvar=length(userdata.model.detail.purvarindex);
else
  %doing transpose
  npurvar=length(userdata.model.detail.purspecindex);
  userdata.model.detail.purvarindex=userdata.model.detail.purspecindex;
end;

%----------------------------------------
function purity_return(userdata, npurvar, handles)
%THIS ACTION IS NEEDED FOR ALL OPTIONS AND ALSO TAKES CARE OF OPTION 'MAX'

%TAKE CARE THAT WHEN WINDOW FOR DERIVATIVE CHANGES THE BASE WITH THE
%DERIVATIVE VALUES SHOULD BE CHANGED TOO

test=userdata.model.detail.window_der(userdata.model.detail.window_der~=1);%
if ~isempty(test);
  test2=(std(test)>.001);
else;
  test2=0;
end;
if test2;
  temp=userdata.model.detail;
  index_derivatives=find(temp.slab==2);
  base_derivative=userdata.data.data(:,temp.purvarindex(index_derivatives),2);
  remember_base=temp.base;
  userdata.model.detail.base(:,index_derivatives)=base_derivative;
end;

%NEWNEWNEW
%Have to call with fighandle becuase options set to options.returnfig =
%'on'.
[userdata.model fighandle]=purity(userdata.data,0,userdata.model);

%enable toolbar after cursor maybe?
if test2;
  userdata.model.detail.base=remember_base;
end;

userdata.model.detail.options.resolve='off';%only needed after resolve
if strcmp(userdata.model.detail.options.mode,'row2col');
  userdata.model.detail.options.mode='rows';
end;

%Store userdasta
%hh = guidata(getappdata(handles.purity_main_fig,'parent'));
if ishandle(handles.purity_main_fig)
  setappdata(handles.purity_main_fig,'userdata',userdata);
end

%----------------------------------------
function transpose_Callback(h,eventdata,handles,varargin)
[userdata npurvar] = purity_enter(handles);
if isempty(userdata.model.detail.purvarindex);
  userdata.model.detail.inactivate=[];
  userdata.model.detail.options.mode='rows';
  userdata.model.detail.base=[];
end;
purity_return(userdata, npurvar, handles)

%Transpose is only a "one-way" operation, can't transpose back to variables,
%so disable menu item.
setappdata(handles.purity_main_fig,'transpose',1)

%----------------------------------------
function winderincrease_Callback(h,eventdata,handles,varargin)
[userdata npurvar] = purity_enter(handles);

%Let application know we've created derivative. Won't allow transpose if
%type = image.
setappdata(handles.purity_main_fig,'derset',1);

f=+1;
userdata.model.detail.window_der(npurvar+1)=...
  max(userdata.model.detail.window_der(npurvar+1)+f*2,3);
if size(userdata.data,3)==1;
  userdata.data=cat(3,userdata.data,userdata.data);
  userdata.model.detail.options.select=[1 2];
  t=double(handles.purity_main_fig);
  t=max(t);
  figure(t);
  %Add second toolbar for derivative plots.
  dertoolbar(handles)
  %User should press der increase before der decrease becomes relevant
  set(handles.winderdecrease, 'enable','on')
end;
a=-savgol(userdata.data.data(:,:,1),userdata.model.detail.window_der(end),2,2);
a(a<0)=0;
userdata.data.data(:,:,2)=a;
purity_return(userdata, npurvar, handles)

%----------------------------------------
function winderdecrease_Callback(h,eventdata,handles,varargin)
[userdata npurvar] = purity_enter(handles);
f=-1;
userdata.model.detail.window_der(npurvar+1)=...
  max(userdata.model.detail.window_der(npurvar+1)+f*2,3);
if size(userdata.data,3)==1;
  userdata.data=cat(3,userdata.data,userdata.data);
  userdata.model.detail.options.select=[1 2];
  t=handles.purity_main_fig;
  t=max(t);
  figure(t);
  if ~isempty(findobj(handles.purity_main_fig, 'tag', 'dertoolbar'))
    %Old code, can be refactored later.
    set(handles.settwo, 'visible', 'on')
    set(handles.offsettwoincrease, 'visible', 'on')
    set(handles.offsettwodecrease, 'visible', 'on')
  end
end;
a=-savgol(userdata.data.data(:,:,1),userdata.model.detail.window_der(end),2,2);
a(a<0)=0;
userdata.data.data(:,:,2)=a;

purity_return(userdata, npurvar, handles)

%----------------------------------------
function cursor_Callback(h,eventdata,handles,varargin)
[userdata npurvar] = purity_enter(handles);
userdata.model.detail.options.interactive='cursor';
%Disable toolbar maybe?
userdata.model.detail.options.plot='replot';
purity_return(userdata, npurvar, handles)
%----------------------------------------
function inactivate_Callback(h,eventdata,handles,varargin)
[userdata npurvar] = purity_enter(handles);
userdata.model.detail.options.interactive='inactivate';
userdata.model.detail.options.plot='replot';
purity_return(userdata, npurvar, handles)
max_Callback(h,eventdata,handles,varargin)
%----------------------------------------
function reactivate_Callback(h,eventdata,handles,varargin)
[userdata npurvar] = purity_enter(handles);
userdata.model.detail.options.interactive='reactivate';
userdata.model.detail.options.plot='replot';
purity_return(userdata, npurvar, handles)
max_Callback(h,eventdata,handles,varargin)
%----------------------------------------
function max_Callback(h,eventdata,handles,varargin)
[userdata npurvar] = purity_enter(handles);
userdata.model.detail.options.plot='replot';
purity_return(userdata, npurvar, handles)
%----------------------------------------
function setone_Callback(h,eventdata,handles,varargin)
[userdata npurvar] = purity_enter(handles);
if ~isfield(userdata.model.detail,'base');
  userdata.model.detail.base=[];
end;


if isempty(userdata.model.detail.base)
  if evriio('mia');setappdata(handles.purity_main_fig,'image_old',[]);end;
end;

if evriio('mia')
  a=get(handles.purity_main_fig,'children');
  b=get(a,'type');
  index=find(strcmp(b,'axes'));
  c=get(a(index),'children');
  try;%in case no image display is needed
    d=get(c,'type');
    index=find(strcmp(d,'image'));
    im=get(c(index),'Cdata');
  catch;
    im=[];
  end;
  setappdata(handles.purity_main_fig,'image_old',im);
end;


%Tell app var/s have been set.
setappdata(handles.purity_main_fig,'varset',1)

index=1; %First set of plots, non derivative.
userdata.model.detail.purvarindex=[userdata.model.detail.purvarindex...
  userdata.model.detail.cursor_index(index)];
userdata.model.detail.slab=[userdata.model.detail.slab index];

userdata.model.detail.window_der(npurvar+2)=userdata.model.detail.window_der(npurvar+1);
if strcmp(userdata.model.detail.options.mode,'cols');
  userdata.model.detail.base=...
    [userdata.model.detail.base...
    userdata.data.data(:,userdata.model.detail.purvarindex(end),index)];
else;
  userdata.model.detail.base=...
    [userdata.model.detail.base...
    userdata.data.data(userdata.model.detail.purvarindex(end),:,index)'];
end;

purity_return(userdata, npurvar, handles)
max_Callback(h,eventdata,handles,varargin)
%----------------------------------------
function settwo_Callback(h,eventdata,handles,varargin)
[userdata npurvar] = purity_enter(handles);
if ~isfield(userdata.model.detail,'base');
  userdata.model.detail.base=[];
end;

%Tell app var/s have been set.
setappdata(handles.purity_main_fig,'varset',1)

index=2; %First set of plots, non derivative.
userdata.model.detail.purvarindex=[userdata.model.detail.purvarindex...
  userdata.model.detail.cursor_index(index)];
userdata.model.detail.slab=[userdata.model.detail.slab index];

userdata.model.detail.window_der(npurvar+2)=userdata.model.detail.window_der(npurvar+1);
if strcmp(userdata.model.detail.options.mode,'cols');
  userdata.model.detail.base=...
    [userdata.model.detail.base...
    userdata.data.data(:,userdata.model.detail.purvarindex(end),index)];
else;
  userdata.model.detail.base=...
    [userdata.model.detail.base...
    userdata.data.data(userdata.model.detail.purvarindex(end),:,index)'];
end;

purity_return(userdata, npurvar, handles)
max_Callback(h,eventdata,handles,varargin)
%----------------------------------------
function offsetoneincrease_Callback(h,eventdata,handles,varargin)
[userdata npurvar] = purity_enter(handles);
userdata = offset(userdata,1,1);
purity_return(userdata, npurvar, handles)
%----------------------------------------
function offsetonedecrease_Callback(h,eventdata,handles,varargin)
[userdata npurvar] = purity_enter(handles);
userdata = offset(userdata,1,-1);
purity_return(userdata, npurvar, handles)
%----------------------------------------
function offsettwoincrease_Callback(h,eventdata,handles,varargin)
[userdata npurvar] = purity_enter(handles);
userdata = offset(userdata,2,1);
purity_return(userdata, npurvar, handles)
%----------------------------------------
function offsettwodecrease_Callback(h,eventdata,handles,varargin)
[userdata npurvar] = purity_enter(handles);
userdata = offset(userdata,2,-1);
purity_return(userdata, npurvar, handles)
%----------------------------------------
function reset_Callback(h,eventdata,handles,varargin)
[userdata npurvar] = purity_enter(handles);

setappdata(handles.purity_main_fig,'image_old',[]);

if npurvar == 1 | npurvar == 0
  %Reset from 1 to zero, no pure vars set.
  setappdata(handles.purity_main_fig,'varset',0)
end
if isempty(userdata.model.detail.purvarindex)
  purity_return(userdata, npurvar, handles)
  return
end
userdata.model.detail.purvarindex(end)=[];
userdata.model.detail.slab(end)=[];
userdata.model.detail.window_der(end)=[];
userdata.model.detail.base(:,end)=[];
userdata.model.detail.diag(end-1:end,:)=[];
purity_return(userdata, npurvar, handles)
max_Callback(h,eventdata,handles,varargin)
%----------------------------------------
function plotcursor_Callback(h,eventdata,handles,varargin)
[userdata npurvar] = purity_enter(handles);
varplotetc(userdata.data,userdata.model,handles);
return
purity_return(userdata, npurvar, handles)
%----------------------------------------
function resolve_Callback(h,eventdata,handles,varargin)
[userdata npurvar] = purity_enter(handles);
if npurvar==0;
  evrihelpdlg('You must set one or more pure variables before attempting to resolve components','No Pure Variables');
  return
end

userdata.model.detail.options.resolve='on';%first resolve
if strcmp(userdata.model.detail.options.mode,'rows');
  answer=[];
  while isempty(answer);
    answer=evriquestdlg(str2mat('Calculate pure variable solution?',...
      ['Reminder: offset (' num2str(userdata.model.detail.options.offset_row2col) ') change for pure variable'],...
      'calculations may be desirable'),'Pure Variable Solution','Yes','Yes + Change Offset','No','Yes');
  end;
  if strcmp(answer,'Cancel')
    return
  end
  if strcmp(answer,'Yes');
    userdata.model.detail.options.mode='row2col';
  end;
  if strcmp(answer,'Yes + Change Offset');
    userdata.model.detail.options.mode='row2col';
    answer = inputdlg(['New offset for pure variable solution (Default = ' num2str(userdata.model.detail.options.offset_row2col) ').'],'Offset for Pure Varaible');
    if isempty(answer{1})
      answer = userdata.model.detail.options.offset_row2col;
    else
      try
        %Try/catch in case of typo.
        answer = str2num(answer{1});
      catch
        answer = userdata.model.detail.options.offset_row2col;
      end
    end
    userdata.model.detail.options.offset_row2col = answer;
  end;
end;
drawnow
purity_return(userdata, npurvar, handles)

%check if scores were created and, if so, enable the "accept"
userdata = getappdata(handles.purity_main_fig,'userdata');
mod = userdata.model;
if isempty(mod.loads{1})
  enb = 'off';
else
  enb = 'on';
end
set(findobj(handles.purity_main_fig,'tag','tbaccept'), 'Enable',enb)

%----------------------------------------
function specplot_Callback(h,eventdata,handles,varargin)
[userdata npurvar] = purity_enter(handles);
specplot(userdata.data,userdata.model,handles);
return
purity_return(userdata, npurvar, handles)
%----------------------------------------
function varplotetc(data,model,handles);

%plots current variable, reconstructed TSI and TSI.

%INITIALIZATIONS

[nrows,ncols,nslabs]=size(data.data);

if isempty(data.axisscale{1});data.axisscale{1}=[1:nrows];end;
if isempty(data.axisscale{2});data.axisscale{2}=[1:ncols];end;

if strcmp(model.detail.options.mode,'cols');
  n=1;
else;
  n=2;
end;
[x2plot,x2plot_lim,index_exclude]=x2plot_incl(data,n);


%%%

limits_axis1=sort(data.axisscale{1}([1 end]));
limits_axis2=sort(data.axisscale{2}([1 end]));

[nrows,ncols]=size(data);

f1=handles.purity_main_fig;f1=f1(1);

%Find figure or create new one.
chld = getappdata(f1,'children');
chld = chld(find(ishandle(chld)));
plotcursorfig = findobj(chld,'tag','plotcursorfig');
if isempty(plotcursorfig) | ~ishandle(plotcursorfig)
  plotcursorfig = figure('tag', 'plotcursorfig', 'integerhandl',...
    'off', 'NumberTitle','off','name','Plot At Cursor');
  pctb = uitoolbar(plotcursorfig);
  icons = gettbicons;
  uipushtool(pctb,'TooltipString','Return','ClickedCallback','close','cdata',icons.close);
  curchild = getappdata(f1,'children');
  curchild = unique([curchild plotcursorfig]);
  setappdata(f1,'children',plotcursorfig)
else
  figure(plotcursorfig)
end

oldcursorindex=model.detail.cursor_index;
oldpurvarindex=model.detail.purvarindex;

%PLOT CONVENTIONAL VARIABLE AT CURSOR POSITION

if strcmp(model.detail.options.mode,'cols');
  plotxdata=data.data(:,oldcursorindex(1),1);
  tsi=sum(data.data(:,:,1),2);
  x4string=data.axisscale{2};
  stringmatrix=sprintf('  pure variable     coefficient\n');
else;
  plotxdata=data.data(oldcursorindex(1),:,1);
  tsi=sum(data.data(:,:,1),1)';
  x4string=data.axisscale{1};
  stringmatrix=sprintf('  pure spectrum     coefficient\n');
end;

im_old=getappdata(handles.purity_main_fig,'image_old');
if evriio('mia') & strcmp(data.type,'image') & strcmp(model.detail.options.mode,'rows') & ...
    ~isempty(im_old);
  a=get(handles.purity_main_fig,'children');
  b=get(a,'type');
  index=find(strcmp(b,'axes'));
  c=get(a(index),'children');
  d=get(c,'type');
  index=find(strcmp(d,'image'));
  im_new=get(c(index),'Cdata');
  
  %take care of NaN
  im_old_array=im_old(:);
  im_new_array=im_new(:);
  array=isnan(im_old_array);
  im_old_array(array)=[];
  im_new_array(array)=[];
  
  r=im_old_array\im_new_array;
  d=r*im_old-im_new;
  d(d<0)=0;
  subplot(236);imagesc(d);axis image ;colormap(hot);
  title('difference image');
end;

h=subplot(221);
if evriio('mia') & strcmp(data.type,'image') & strcmp(model.detail.options.mode,'cols')
  delete(h);
  subplot(231);
  im2plot=data.imagedata(:,:,oldcursorindex(1));
  a=NaN(data.imagesize);
  a(data.include{1})=0;
  a=reshape(a,data.imagesize);
  im2plot=im2plot+a;
  imagesc(im2plot);
  axis image;
  colormap hot;
elseif strcmp(model.detail.options.axistype{1},'continuous');
  plot(x2plot,plotxdata,'k-');
elseif strcmp(model.detail.options.axistype{1},'bar');
  plotms(x2plot,plotxdata');
else;
  plot(x2plot,plotxdata,'ko')
end;

if ~strcmp(data.type,'image') | (strcmp(data.type,'image') & ~strcmp(model.detail.options.mode,'cols'))
  %Don't plot negative values.
  axis([x2plot_lim,0,max(1.1*tsi)]);
  
  %Add 10% to top of plot so looks nicer.
  %Remove neg values for plotting.
  a3=0;a4=1.1*max(plotxdata);
  if a4<=0;v=axis;a3=v(3);a4=v(4);end;
  axis([x2plot_lim,a3,a4]);
end

if strcmp(model.detail.options.mode,'rows');
  title (textstring([data.name, '   spectrum: ',...
    num2str(data.axisscale{1}(oldcursorindex(1)))]));
else;
  title (textstring([data.name, '   variable: ',...
    num2str(data.axisscale{2}(oldcursorindex(1)))]));
end;


%PLOT 2ND DERIVATIVE DATA AT CURSOR POSITION

if nslabs==2;
  plotxdata=data.data(:,oldcursorindex(2),2);
  h=subplot(223);
  if evriio('mia') & strcmp(data.type,'image');
    delete (h);
    subplot(234);
    im2plot=data.imagedata(:,:,oldcursorindex(2),end);
    a=NaN(data.imagesize);
    a(data.include{1})=0;
    a=reshape(a,data.imagesize);
    im2plot=im2plot+a;
    imagesc(im2plot);
    
    axis image
  elseif strcmp(model.detail.options.axistype{1},'continuous');
    plot(x2plot,plotxdata,'k-');
  elseif strcmp(model.detail.options.axistype{1},'bar');
    plotms(x2plot,plotxdata');
    
  else;
    plot(x2plot,plotxdata,'ko')
    
  end;
  
  if ~(evriio('mia') & strcmp(data.type,'image'));
    a3=0;a4=1.1*max(plotxdata);
    if a4<=0;v=axis;a3=v(3);a4=v(4);end;
    axis ([sort(data.axisscale{1}([1 end])),a3,a4]);
  end;
  title(['2nd derivative variable: ',...
    num2str(data.axisscale{2}(oldcursorindex(2)))]);
end;

%CREATE MATRIX WITH PURE VARIABLE INTENSITIES

matrix=model.detail.base;

%PLOT TSI AND LSQ APPROXIMATION OF TSI

if isempty(model.detail.purvarindex);
  h=subplot(222);
  if evriio('mia') & strcmp(data.type,'image') & strcmp(model.detail.options.mode,'cols')
    delete(h);
    subplot(233);
    im2plot=reshape(tsi,data.imagesize);
    a=NaN(data.imagesize);
    a(data.include{1})=0;
    a=reshape(a,data.imagesize);
    im2plot=im2plot+a;
    imagesc(im2plot);
    axis image;
    colormap hot;
    title('Total Signal');
  elseif strcmp(model.detail.options.axistype{1},'continuous');
    plot(x2plot,tsi,'k--');
    axis([x2plot_lim,0,max(1.1*tsi)]);
    title('--tsi');
  elseif strcmp(model.detail.options.axistype{1},'bar');
    plotms(x2plot,tsi')
    axis([x2plot_lim,0,max(1.1*tsi)]);
    title('tsi');
  else;
    plot(x2plot,tsi,'ko')
    axis([x2plot_lim,0,max(1.1*tsi)]);
    title('o tsi');
  end;
else;
  matrix2=matrix(data.include{n},:)\tsi(data.include{n});
  lsqpure=matrix*matrix2;
  maxy=1.1*max(max(tsi),max(lsqpure));
  h=subplot(2,2,2);
  if evriio('mia') & strcmp(data.type,'image') & strcmp(model.detail.options.mode,'cols')
    delete(h);
    subplot(233);
    %Add two image plots on left side.
    
    im2plot=reshape(tsi,data.imagesize);
    a=NaN(data.imagesize);
    a(data.include{1})=0;
    a=reshape(a,data.imagesize);
    im2plot=im2plot+a;
    imagesc(im2plot);
    
    title('Total Signal')
    axis image;
    colormap hot;
    cax = caxis;%Save caxis so can scale the summed pur vars plot below
    subplot(2,3,6);
    
    im2plot=reshape(lsqpure,data.imagesize);
    a=NaN(data.imagesize);
    a(data.include{1})=0;
    a=reshape(a,data.imagesize);
    im2plot=im2plot+a;
    imagesc(im2plot);
    
    title('Scaled Sum of Pure Variables')
    axis image;
    caxis(cax);%Use caxis from Total Signal.
    colormap hot;
  elseif strcmp(model.detail.options.axistype{1},'continuous');
    plot(x2plot,tsi,'r--' );hold on;plot(x2plot,lsqpure,'-k');
    axis([x2plot_lim,0,maxy]);
    title ('- lsq, -- tsi');
    hx=xlabel('');
    
  elseif strcmp(model.detail.options.axistype{2},'bar');
    plotms(x2plot,tsi');hold on;
    plot(x2plot,lsqpure,'r*');
    axis([x2plot_lim,0,maxy]);
    title ('* lsq, - tsi');
    hx=xlabel('');
    
  else;
    plot(x2plot,tsi,'ko');hold on;plot(x2plot,lsqpure,'*k');
    axis([x2plot_lim,0,maxy]);
    title('* lsq, o tsi');
    hx=xlabel('');
    hold off;
  end;
  
  %PRINT LSQ INFORMATION
  [m,n]=size(matrix2);
  for i=1:m;a=x4string(oldpurvarindex(i));
    if model.detail.slab(i)==1;
      stringmatrix=[stringmatrix sprintf('  %5.0f            %8.4f\n',a,matrix2(i))];
    else;
      stringmatrix=[stringmatrix sprintf('  %5.0f*            %8.4f\n',a,matrix2(i))];
    end;
  end;
  
  rsqd=sqrt(sum((tsi(:)-lsqpure(:)).^2)/sum(tsi(:).*tsi(:)));
  
  stringmatrix=[stringmatrix sprintf('\n relative rssq: %6.4f\n  ',rsqd)];
  stringmatrix=[stringmatrix,sprintf('* indicates 2nd derivative')];
  %set(hx,'string',stringmatrix,'Fontname','courier');
  if ~(evriio('mia') & strcmp(data.type,'image'));
    subplot(224);
  else;
    subplot(235);
  end;
  
  ht=text(0,1,stringmatrix);
  set(ht,'VerticalAlignment','top','Fontsize',8);
  
  c=get(gcf,'color');set(gca,'color',c,'xcolor',c,'ycolor',c);
end;


%----------------------------------------
function y=textstring(string);
%creates strings that take appropriate actions for _ (underbar), etc.

%SUBSTITUTE A NON ASCII CHARACTER FOR BLANKS IN ORIGINAL STRING

dummy=char(128);
index=find(string==' ');
string(index)=dummy;

%PUT IN \ CHARACTERS

a=blanks(length(string));
index=find(string=='_');
a(index)='\';
string=[a;string];
string=string(:);
a=string==' ';
y=string(~a)';

%SUBSTITUTE NON ASCII CHARACTERS WITH BLANKS

index=(y==dummy);
y(index)=' ';

%----------------------------------------
function userdata = offset(userdata,index,change);
userdata.model.detail.options.offset(index)=...
  max((userdata.model.detail.options.offset(index)+change),0);%prevents negative values
userdata.model.detail.options.offset_row2col=...
  max((userdata.model.detail.options.offset_row2col+change),0);

%----------------------------------------
function specplot(data,model,handles);
%TODO: Plot average for Mass Spec data. Plots all on top of each other
%currently.

%plots current variable, reconstructed TSI and TSI.

%INITIALIZATIONS

[nrows,ncols,nslabs]=size(data.data);
npurvar=length(model.detail.purvarindex);
c=model.detail.cursor_index;
if isempty(data.axisscale{2});data.axisscale{2}=[1:ncols];end;
[x2plot,x2plot_lim,index_exclude]=x2plot_incl(data,2);

f1=handles.purity_main_fig;f1=f1(1);
%Find figure or create new one.
chld = getappdata(f1,'children');
chld = chld(find(ishandle(chld)));
%Find figure or create new one.
specplotfig = findobj(chld,'tag','specplotfig');
if isempty(specplotfig) | ~ishandle(specplotfig)
  specplotfig = figure('tag', 'specplotfig', 'integerhandl',...
    'off', 'NumberTitle','off','name','Plot At Cursor');
  pctb = uitoolbar(specplotfig);
  icons = gettbicons;
  uipushtool(pctb,'TooltipString','Return','ClickedCallback','close','cdata',icons.close);
  curchild = getappdata(f1,'children');
  curchild = unique([curchild specplotfig]);
  setappdata(f1,'children',specplotfig)
else
  figure(specplotfig)
end

%PLOT CONVENTIONAL VARIABLE AT CURSOR POSITION


if strcmp(model.detail.options.axistype{2},'continuous');
  y=data.data(:,:,1);linetype='-';
elseif strcmp(model.detail.options.axistype{2},'discrete');
  y=(data.data(:,:,1));linetype='*';
elseif strcmp(model.detail.options.axistype{2},'bar');
  y=mean(data.data(:,:,1));linetype='|';
end;

subplot(311);
if strcmp(model.detail.options.axistype{2},'bar');
  plotms(x2plot,y(data.include{1}));
  hold on
  plot(x2plot_lim,[0 0],'k');
  hold off
else;
  plot(x2plot,y(data.include{1},:),linetype,x2plot_lim,[0 0],'k')
end;
setxdir(x2plot(data.include{2}));
title('original data');
mx=max(max(y));
a3=0;a4=1.1*mx;
if a4<=0;v=axis;a3=v(3);a4=v(4);end;
if strcmp(model.detail.options.mode,'cols')
  %Can plot cursor if haven't transposed.
  h=line(data.axisscale{2}([c(1) c(1)]),[0 a4]);
  set(h,'color',[0 0 0]);
end

if length(c)>1;
  h=line(data.axisscale{2}([c(2) c(2)]),[0 a4]);
  set(h,'LineStyle',':','color',[0 0 0]);
end;
axis ([x2plot_lim,a3,a4]);

%PLOT RECONSTRUCTED DATA, IF RESOLVED DATA ARE THERE

if ~isempty(model.loads{1});
  datarec=model.loads{1}*model.loads{2}';
  datarec=datarec(data.include{1},:);
  %fill in zeros
  datadif=data.data(data.include{1},data.include{2},1)-datarec;
  if strcmp(model.detail.options.axistype{2},'bar');
    y1=mean(datarec);linetype='|';
    y2=mean(datadif);
  elseif strcmp(model.detail.options.axistype{2},'continuous');;
    y1=datarec;linetype='-';
    y2=datadif;
  elseif strcmp(model.detail.options.axistype{2},'discrete');;
    y1=datarec;linetype='*';
    y2=datadif;
    
  end;
  
  set(gca,'xTicklabel',[]);
  subplot(312);
  
  if strcmp(model.detail.options.axistype{2},'bar');
    plotms(x2plot(data.include{2}),y1);
    hold on
    plot(x2plot_lim,[0 0],'k');
    hold off
  else;
    y1b=zeros(size(y1));y1b(:,data.include{2})=y1;
    plot(x2plot,y1b,linetype,x2plot_lim,[0 0],'k')
    
  end;
  
  setxdir(x2plot(data.include{2}));
  title('reconstructed data');
  mx=max(y(:));
  a3=0;a4=1.1*mx;
  if a4<=0;v=axis;a3=v(3);a4=v(4);end;
  axis ([x2plot_lim,a3,a4]);
  set(gca,'xTicklabel',[]);
  
  subplot(313);
  rsqd=sqrt(sum((datadif(:)).^2)/sum(sum(data.data(data.include{1},data.include{2},1).^2)));%calculate rel. diff.
  
  if strcmp(model.detail.options.axistype{2},'bar');
    plotms(x2plot(data.include{2}),y2);
    hold on
    plot(x2plot_lim,[0 0],'k');
    hold off
  else;
    y2b=zeros(size(y2));y2b(:,data.include{2})=y2;
    plot(x2plot,y2b,linetype,x2plot_lim,[0 0],'k');
    
  end;
  
  
  %plot(data.axisscale{2},datadif,data.axisscale{2}([1 end]),[0 0],'k');
  %setxdir;
  setxdir(x2plot(data.include{2}));
  title(['original - reconstructed, rrssq: ',num2str(rsqd)]);
  if strcmp(model.detail.options.axistype{2},'bar');
    s=sort([max(mean(datadif)),-min(mean(datadif))]);
  else;
    s=sort([max(datadif(:)),-min(datadif(:))]);
  end;
  s=1.1*s(2);
  axis ([x2plot_lim,-s,s]);
  
end;

%----------------------------------------
function setxdir(x)
%SETXDIR sets correct Xdir
%argument x determined direction. For simple plot, no arguments needed.

if nargin;
  if x(1)<x(2);set(gca,'Xdir','Normal');else;set(gca,'Xdir','Reverse');end;
  return;
end;

h=get(gca,'Children');
for i=1:length(h);
  if strcmp(get(h(i),'Type'),'line');
    x=get(h(i),'Xdata');
    if length(x)>1;
      if x(1)<x(2);set(gca,'Xdir','Normal');else;set(gca,'Xdir','Reverse');end;
      break;
    end;
    
  end;
end;

%----------------------------------------
function continuous_Callback(h,eventdata,handles,varargin)
[userdata npurvar] = purity_enter(handles);

%DISCR/CONT
a{1,1}='continuous';a{1,2}='continuous';
a{2,1}='continuous';a{2,2}='discrete';
a{3,1}='continuous';a{3,2}='bar';
a{4,1}='discrete';a{4,2}='continuous';
a{5,1}='discrete';a{5,2}='discrete';
a{6,1}='discrete';a{6,2}='bar';
a{7,1}='bar';a{7,2}='continuous';
a{8,1}='bar';a{8,2}='discrete';
a{9,1}='bar';a{9,2}='bar';

index1=strmatch(userdata.model.detail.options.axistype{1},str2mat(a{:,1}));
index2=strmatch(userdata.model.detail.options.axistype{2},str2mat(a{:,2}));
for i=1:3;
  for j=1:3;
    if index1(i)==index2(j);
      index=index1(i);
    end;
  end;
end;

index=index+1;if index==10;index=1;end;
userdata.model.detail.options.axistype{1}=a{index,1};
userdata.model.detail.options.axistype{2}=a{index,2};
setappdata(handles.purity_main_fig,'userdata',userdata);

%keyboard
userdata.model.detail.options.plot='replot';
purity_return(userdata, npurvar, handles)
%----------------------------------------
function accept_Callback(h,eventdata,handles,varargin)
%Load model back into analysis.
userdata = getappdata(handles.purity_main_fig,'userdata');
mod = userdata.model;
if isempty(mod.loads{1})
  resolve_Callback(h,[],handles)
  userdata = getappdata(handles.purity_main_fig,'userdata');
  mod = userdata.model;
  if isempty(mod.loads{1})
    %still no loads? prob. no components selected.
    return;
  end
end


mod.datasource = userdata.datasource;  %replace ORIGINAL datasource
ph = getappdata(handles.purity_main_fig,'parent');
handles = guidata(ph);
feval('analysis','loadmodel',h, [], handles, mod)
%Need to clear timestamp after loading becuase this is not a saved model.
handles = guidata(ph);
setappdata(handles.savemodel,'timestamp',[]);

%Set statmodl/data
setappdata(handles.analysis, 'statmodl', 'calold')

closefigures(handles)

%Add model to cache.
analysis('cachecurrent',handles);


%----------------------------------------
function puritymenu_Callback(h,eventdata,handles,varargin)
%Disable 'accept' button if model hasn't been 'resolved'
userdata = getappdata(handles.purity_main_fig,'userdata');
mod = userdata.model;

if isempty(mod.loads{1})
  set(findobj(handles.purity_main_fig,'tag','accept'), 'Enable','off')
else
  set(findobj(handles.purity_main_fig,'tag','accept'), 'Enable','on')
end

transpose = getappdata(handles.purity_main_fig,'transpose');
if isempty(transpose)
  %No gui_init of appdata fields for purity main fig so need to check for
  %empty.
  transpose = 0;
end

varset = getappdata(handles.purity_main_fig,'varset');
if isempty(varset)
  varset = 0;
end

derset = getappdata(handles.purity_main_fig,'derset');
if isempty(derset)
  derset = 0;
end

if varset
  %If var is set then can't transpose. Assumes program will run through
  %code below disabling transpose.
  set(findobj(handles.purity_main_fig,'tag','transposemenu'),'enable','off')
else
  set(findobj(handles.purity_main_fig,'tag','transposemenu'),'enable','on')
end

if transpose
  %Transpose is only a "one-way" operation, can't transpose back to variables,
  %so disable menu item.
  set(findobj(handles.purity_main_fig,'tag','transposemenu'),'enable','off')
end

if strcmp(userdata.data.type,'image') & transpose
  %If using image dataset and transpose then plot types don't make sense.
  set(findobj(handles.purity_main_fig,'tag','continuosmenu'),'enable','off')
  %Can't use derivative either.
  set(findobj(handles.purity_main_fig,'tag','winderincrease'),'enable','off')
end

if strcmp(userdata.data.type,'image') & derset
  %If derivative has been set and type = image then error will occur on
  %transpose. One-way.
  set(findobj(handles.purity_main_fig,'tag','transposemenu'),'enable','off');
end

%----------------------------------------
function createpuritymenu(h)

pm = uimenu(h,'Label','Purity','Tag','puritymenu','CallBack','purity_guifcn(''puritymenu_Callback'',gcbo,[],guidata(gcbo))');

uimenu(pm,'Label','&Transpose','Tag','transposemenu','Accelerator','t',...
  'Callback','purity_guifcn(''transpose_Callback'',gcbo,[],guidata(gcbo))');
uimenu(pm,'Label','&Inactivate','Tag','inactivatemenu','Accelerator','i',...
  'Callback','purity_guifcn(''inactivate_Callback'',gcbo,[],guidata(gcbo))');
uimenu(pm,'Label','&Reactivate','Tag','reactivatemenu','Accelerator','r',...
  'Callback','purity_guifcn(''reactivate_Callback'',gcbo,[],guidata(gcbo))');
uimenu(pm,'Label','&Max','Tag','maxmenu','Accelerator','m',...
  'Callback','purity_guifcn(''max_Callback'',gcbo,[],guidata(gcbo))');
uimenu(pm,'Label','&Plot Spectrum','Tag','specplotmenu','Accelerator','l',...
  'Callback','purity_guifcn(''specplot_Callback'',gcbo,[],guidata(gcbo))');
uimenu(pm,'Label','&Resolve','Tag','resolvemenu','Accelerator','e',...
  'Callback','purity_guifcn(''resolve_Callback'',gcbo,[],guidata(gcbo))');
uimenu(pm,'Label','&Continuous/Discrete','Tag','continuousmenu','Accelerator','d',...
  'Callback','purity_guifcn(''continuous_Callback'',gcbo,[],guidata(gcbo))');
uimenu(pm,'Label','&Accept','Tag','accept','Accelerator','f',...
  'Callback','purity_guifcn(''accept_Callback'',gcbo,[],guidata(gcbo))');

%----------------------------------------
function plotms (varlist,spec,c);

%function plotms (varlist,spec);

%plots a mass spectrum.
if nargin==2;c='b';end;
lengthspec=length(spec);
y0=zeros(1,lengthspec);
plot(reshape([varlist;varlist;varlist],1,3*lengthspec),...
  reshape([y0;spec;y0],1,3*lengthspec),c);
%----------------------------------------
function dertoolbar(handles);
%Check to see if dertoolbar already exists.
if isempty(findobj(handles.purity_main_fig, 'tag', 'dertoolbar'))
  iconscust = gettbicons;
  htoolbar = uitoolbar(handles.purity_main_fig, 'tag', 'dertoolbar');
  for i = 1 : 7
    if i == 2
      hbtnscust(i)=uipushtool(htoolbar, ...
        'tag', 'settwo', ...
        'ClickedCallback', 'purity_guifcn(''settwo_Callback'',gcbo,[],guidata(gcbo))',...
        'Enable', 'On', ...
        'TooltipString', 'Set Derivative Pure Variable', ...
        'Separator', 'on',...
        'CData', getfield(iconscust, 'SetPureVarTwo'));
    elseif i == 6
      hbtnscust(i)=uipushtool(htoolbar, ...
        'tag', 'offsettwoincrease', ...
        'ClickedCallback', 'purity_guifcn(''offsettwoincrease_Callback'',gcbo,[],guidata(gcbo))',...
        'Enable', 'On', ...
        'TooltipString', 'Increase Offset Derivative', ...
        'Separator', 'on',...
        'CData', getfield(iconscust, 'IncreaseOffsetTwo'));
    elseif i == 7
      hbtnscust(i)=uipushtool(htoolbar, ...
        'tag', 'offsettwodecrease', ...
        'ClickedCallback', 'purity_guifcn(''offsettwodecrease_Callback'',gcbo,[],guidata(gcbo))',...
        'Enable', 'On', ...
        'TooltipString', 'Decrease Offset Derivative', ...
        'Separator', 'off',...
        'CData', getfield(iconscust, 'DecreaseOffsetTwo'));
    else
      hbtnscust(i)=uipushtool(htoolbar, 'tag', ['space' num2str(i)],'enable', 'off');
      if i == 4
        set(hbtnscust(i), 'Separator', 'on')
      end
      
    end
  end
end
%%%%%%%%
function [x2plot,x2plot_lim,index_exclude]=x2plot_incl(data,dim);

n=length(data.axisscale{dim});

index_exclude=setdiff([1:n],data.include{dim});
x2plot=data.axisscale{dim};
x2plot(index_exclude)=NaN;

ax=find(~isnan(x2plot));
x2plot_lim=sort(x2plot(ax([1 end])));


%----------------------------------------------------
function  optionschange(h)





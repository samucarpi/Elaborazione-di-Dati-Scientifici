function varargout = reg_guifcn(varargin)
%REG_GUIFCN Regression Analysis-specific methods for Analysis GUI.
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
        options.usenewvarselect = 1;
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
function gui_init(h,eventdata,handles,varargin);
%create toolbar

[atb abtns] = toolbar(handles.analysis,getappdata(handles.analysis,'curanal'),'');
handles  = guidata(handles.analysis);

%Enable correct buttons.
analysis('toolbarupdate',handles)  %set buttons

%change pc edit box to text box.
set(handles.pcsedit,'style','text')

mytbl = getappdata(handles.analysis,'ssqtable');

%Temporary use of reg_guifcn options for panel version.
roptions = reg_guifcn('options');

%change pc edit label.
switch getappdata(handles.analysis,'curanal')
  case {'pls' 'npls'}
    set(handles.pcseditlabel,'string','Number LVs:')
    
    mytbl = ssqsetup(mytbl,{'X-Block<br>LV' 'X-BLock<br>Cumulative' 'Y-Block<br>LV' 'y-Block<br>Cumulative' ' '},...
  '<b>&nbsp;&nbsp;&nbsp;LV',{'%6.2f' '%6.2f' '%6.2f' '%6.2f' ''},1);
    
    %Add panel.
    panelinfo.name = 'SSQ Table';
    panelinfo.file = 'ssqtable';
    if strcmpi(getappdata(handles.analysis,'curanal'),'pls')
      if roptions.usenewvarselect
        panelinfo(2).name = 'Variable Selection';
        panelinfo(2).file = 'variableselectiongui';
      else
        panelinfo(2).name = 'Variable Selection';
        panelinfo(2).file = 'iplsgui';
      end
    end
    panelmanager('add',panelinfo,handles.ssqframe)
  case 'mlr'
    %Turn off ssqtable.
    analysis('ssqvisible',handles,'off')
    
    panelinfo.name = 'Function Settings';
    panelinfo.file = '';
    
    if roptions.usenewvarselect
      panelinfo(2).name = 'Variable Selection';
      panelinfo(2).file = 'variableselectiongui';
    else
      panelinfo(2).name = 'Stepwise Variable Selection';
      panelinfo(2).file = 'iplsgui';
    end
    
    panelmanager('add',panelinfo,handles.ssqframe)
    
  otherwise
    set(handles.pcseditlabel,'string','Number PCs:')

    mytbl = ssqsetup(mytbl,{'X-Block<br>PC' 'X-BLock<br>Cumulative' 'Y-Block<br>PC' 'y-Block<br>Cumulative' ' '},...
  '<b>&nbsp;&nbsp;&nbsp;PC',{'%6.2f' '%6.2f' '%6.2f' '%6.2f' ''},1);
    
    %Add view selections to dropdown.
    panelinfo.name = 'SSQ Table';
    panelinfo.file = 'ssqtable';
    if roptions.usenewvarselect
      panelinfo(2).name = 'Variable Selection';
      panelinfo(2).file = 'variableselectiongui';
    else
      panelinfo(2).name = 'IPCR Variable Selection';
      panelinfo(2).file = 'iplsgui';
    end
    panelmanager('add',panelinfo,handles.ssqframe)

    handles = guihandles(handles.analysis);
    guidata(handles.analysis,handles);
end

tableheader = 'Percent Variance Captured by Model (* = suggested)';

%change the name of the "factors" in the crossvalidate GUI
crossvalgui('namefactors',getappdata(handles.analysis,'crossvalgui'),'LVs')
set(handles.tableheader,'string',tableheader,'HorizontalAlignment','center');

%turn on valid crossvalidation
%enable_crossvalgui must be set before crossvalgui('disable',cvgui); call.
setappdata(handles.analysis,'enable_crossvalgui','on');
%setappdata(handles.analysis,'tableformat',format);
setappdata(handles.analysis,'tableheader',tableheader);

%Check for option enabled objects.
options = pca_guifcn('options');

%Auto select button visibility.
if exist('choosecomp.m','file')==2 && strcmp(options.autoselectcomp,'on') ...
    && ismember(getappdata(handles.analysis,'curanal'),{'pls','pcr'})
  setappdata(handles.analysis,'autoselect_visible',1)
else
  setappdata(handles.analysis,'autoselect_visible',0)
end


%general updating
analysis('updatestatusboxes',handles)
updatefigures(handles.analysis)
updatessqtable(handles)

%----------------------------------------------------
function gui_deselect(h,eventdata,handles,varargin)

%Get rid of panel objects.
panelmanager('delete',panelmanager('getpanels',handles.ssqframe),handles.ssqframe)

%Change pcsedit back to defualt style.
set(handles.pcsedit,'style','edit')
set([handles.tableheader handles.pcseditlabel handles.ssqtable handles.pcsedit],'visible','on')
set(handles.tableheader,'string', { '' },'horizontalalignment','left')
setappdata(handles.analysis,'autoselect_visible',0)
%Clear table.
mytbl = getappdata(handles.analysis,'ssqtable');
clear(mytbl,'all');

setappdata(handles.analysis,'enable_crossvalgui','on');


closefigures(handles);
%----------------------------------------------------
function gui_updatetoolbar(h,eventdata,handles,varargin)

fn  = analysistypes(getappdata(handles.analysis,'curanal'),1);
if strcmp(fn,'mlr')
  doe_guifcn('gui_updatetoolbar',h,eventdata,handles,varargin{:});
end

pca_guifcn('gui_updatetoolbar',h,eventdata,handles,varargin);
%----------------------------------------------------
function out = isdatavalid(xprofile,yprofile,fig)
%two-way x
% out = xprofile.data & xprofile.ndims==2;

%multi-way x
% out = xprofile.data & xprofile.ndims>2;

%discrim: two-way x with classes OR y
%out = xprofile.data & xprofile.ndims==2 & (xprofile.class | (yprofile.data & yprofile.ndims==2) );

%two-way x and y
out = xprofile.data & xprofile.ndims==2 & yprofile.data & yprofile.ndims==2;

%multi-way x and y
% out = xprofile.data & xprofile.ndims>2 & yprofile.data;

%--------------------------------------------------------------------
function out = isyused(handles)

out = true;


%----------------------------------------------------
function calcmodel_Callback(h,eventdata,handles,varargin);
% Callback of the uicontrol handles.calcmodel.

handles = guihandles(handles.analysis);%Update handles.

statmodl = lower(getappdata(handles.analysis,'statmodl'));
if strcmp(statmodl,'calnew') & ~analysis('isloaded','rawmodel',handles)
  statmodl = 'none';
end

switch statmodl
  case {'none'}
    regmode = getappdata(handles.analysis,'curanal');

    x = analysis('getobjdata','xblock',handles);
    
    if isempty(x.includ{1});
      erdlgpls('All samples excluded. Can not calibrate','Calibrate Error');
      return
    end
    if isempty(x.includ{2});
      erdlgpls('All x-block variables excluded. Can not calibrate','Calibrate Error');
      return
    end

    if mdcheck(x);
      ans = evriquestdlg({'Missing Data Found in X-block - Replacing with "best guess"','Results may be affected by this action.'},'Warning: Replacing Missing Data','OK','Cancel','OK');
      if ~strcmp(ans,'OK'); return; end
      drawnow;
      try
        if strcmpi(getfield(modelcache('options'),'cache'),'on')
          modelcache([],x);
          evritip('missingdatacache','Original data (with missing values) has been stored in the model cache.',1)
        end
      catch
      end
      [flag,missmap,x] = mdcheck(x,struct('toomuch','ask'));
      analysis('setobjdata','xblock',handles,x)
    end

    y = analysis('getobjdata','yblock',handles);
    if isempty(y);
      erdlgpls('No y-block information is loaded. Can not calibrate','Calibrate Error');
      return
    end
    %check for missing data in y-block
    nans = any(isnan(y.data(y.include{1},y.include{2})),2);
    if all(nans)
      erdlgpls('All y-block rows contained missing data. Can not calibrate','Calibrate Error');
      return;
    end
    if any(nans);
      evrimsgbox({'Missing Data Found in Y-block - Excluding all samples with missing y-block values.'},'Warning: Excluding Missing Data Samples','warn','modal');
      y.include{1} = intersect(y.include{1},y.include{1}(find(~nans)));
      analysis('setobjdata','yblock',handles,y);    %and save back to object
    end
    if isempty(y.includ{1});
      erdlgpls('All y-block rows excluded. Can not calibrate','Calibrate Error');
      return
    end
    if isempty(y.includ{2});
      erdlgpls('All y-block columns excluded. Can not calibrate','Calibrate Error');
      return
    end
    if strcmpi(regmode,'lwr') & length(y.includ{2})>1
      erdlgpls('LWR cannot operate on multivariate y. Choose a single column to operate on.','Calibrate Error')
      analysis('editselectycols',handles.analysis,[],handles);
      return
    end
    isect = intersect(y.include{1},x.include{1}); %intersect samples includ from x- and y-blocks
    if length(x.include{1})~=length(isect) | length(y.include{1})~=length(isect);  %did either change?
      y.include{1} = isect;
      analysis('setobjdata','yblock',handles,y);   %and save back to object
      x.include{1} = isect;
      analysis('setobjdata','xblock',handles,x);    %and save back to object
    end

    preprocessing = {getappdata(handles.preprocessmain,'preprocessing') getappdata(handles.preproyblkmain,'preprocessing')};

    options = reg_guifcn('options');
    [cvmode,cvlv,cvsplit,cviter] = crossvalgui('getsettings',getappdata(handles.analysis,'crossvalgui'));

    if ~strcmp(cvmode,'none')
      maxlv   = min([length(x.includ{1}) length(x.includ{2}) options.maximumfactors cvlv]);
    else  %no cross-val method? Don't let the slider limit the # of LVs
      maxlv   = min([length(x.includ{1}) length(x.includ{2}) options.maximumfactors]);
    end
    minlv   = max(1,getappdata(handles.pcsedit,'default'));
    if isempty(minlv); minlv = 1; end;                    %default model
    if minlv>maxlv;    minlv = 1; end;                    %don't allow > # of evs (in fact, consider this a reset of default)

    if all(all(y.data(y.includ{1},:) == y.data(y.includ{1}(1),1)));
      erdlgpls('All y values are identical - can not do regression analysis','Calibrate Error');
      return
    end

    try
      switch regmode
        case {'pls'}
          opts = getoptions(regmode,handles);
          opts.preprocessing = preprocessing;
          
          if strcmp(opts.algorithm , 'robustpls')
            modl = pls(x,y,minlv,opts);
            rawmodl = modl;
          else
            opts.rawmodel      = 1;
            rawmodl   = pls(x,y,maxlv,opts);
            modl      = pls(x,y,minlv,rawmodl,opts);
            modl.detail.ssq(minlv+1:size(rawmodl.detail.ssq,1),:) = rawmodl.detail.ssq(minlv+1:end,:);   %copy complete SSQ table
          end

        case 'pcr'
          opts = getoptions(regmode,handles);
          opts.preprocessing = preprocessing;

          if ismember(opts.algorithm, {'frpcr' 'robustpcr'})
            modl = pcr(x,y,minlv,opts);
            rawmodl = modl;
          else
            opts.rawmodel      = 1;
            rawmodl = pcr(x,y,maxlv,opts);
            modl = pcr(x,y,minlv,rawmodl,opts);            
            modl.detail.ssq = rawmodl.detail.ssq;   %copy complete SSQ table
          end

        case 'mlr'
          opts = getoptions(regmode,handles);
          opts.preprocessing = preprocessing;
          modl = mlr(x,y,opts);
          rawmodl = modl;         
        case 'lwr'
          %Check inputs.
          if ~lwr_guifcn('pre_calc_check',handles);
            return
          end
          npts = str2num(get(handles.lwr_npts,'string'));
          opts = getoptions(regmode,handles);
          opts.preprocessing = preprocessing;
          
          if strcmpi('none',getappdata(handles.analysis,'statmodl'))
            %Clear cache, calculate, and add to new cache.
            analysis('setobjdata','modelcache',handles,[]);
            modl = lwr(x,y,minlv,npts,opts);
          else
            %Check to see if calculated and add/load.
            modl = model_in_cache(handles);
            if isempty(modl)
              modl = lwr(x,y,minlv,npts,opts);
            end
          end
          
          %The function will handle duplicates.
          add_model_to_cache(handles,modl);
          
          rawmodl = [];%Can't do raw model trick. 

        otherwise

          %is regmode a valid m-file?
          if ~exist(regmode,'file');
            erdlgpls('Unrecognized / Invalid regression method','Calibrate Error');
            return
          end

          %see if we can do a standard regression!
          try
            opts = getoptions(regmode,handles);
            opts.preprocessing = preprocessing;

            rawmodl   = feval(regmode,x,y,maxlv,opts);
            modl      = feval(regmode,x,y,minlv,opts);
            modl.detail.ssq = rawmodl.detail.ssq;   %copy complete SSQ table

          catch
            erdlgpls({'Error using ' regmode ' regression method',lasterr},'Calibrate Error');
            return
          end

      end
    catch
      erdlgpls({'Error using ' regmode ' regression method',lasterr},'Calibrate Error');
      return
    end

    %Do cross-validation
    cvinfo = [];
    if ~strcmp(cvmode,'none') || (strcmpi(modl.modeltype,'mlr') && ~ismember(modl.detail.options.algorithm,{'leastsquares' 'ridge' 'ridge_hkb'}))
      [modl,success] = crossvalidate(handles.analysis,modl);

      if success
        cvinfo = copycvfields(modl);
        if ~isempty(rawmodl);
          rawmodl = copycvfields(modl,rawmodl);
        end
      end
    else % just calculate RMSEC
      %vld_mdls = {'PLS','PCR','MLR','NPLS','PLSDA'};
      vld_mdls = {'PLS','PCR','NPLS','PLSDA'};
      if ismember(modl.modeltype,vld_mdls)
        getsetcalstats(modl,handles,maxlv);
        if ~(strcmpi(modl.modeltype,'MLR')) % Update local variable (only if it's not an MLR model, - if the line below executes for an MLR model, serious issues will occur)
          modl=analysis('getobjdata','model',handles); 
        end
      end
    end

    %UPDATE GUI STATUS
    %set status windows
    setappdata(handles.analysis,'statmodl','calold');
    analysis('setobjdata','model',handles,modl);
    
    %Using cache with LWR so update modelcache here so updatessqtable can
    %access it. The cachecurrent function will get called again but
    %modelcache will not add duplicates.
    analysis('cachecurrent',handles)
    %Need slight pause to allow model to be cached. If this is not done
    %there seems to be an error with cache tree.
    evripause(.3)
    
    %%% IF ROBUST, DON'T SAVE RAWMODL
    if isfield(opts,'algorithm') & (~isempty(findstr(opts.algorithm , 'robust')) | strcmp(opts.algorithm,'frpcr'))
      analysis('setobjdata','rawmodel',handles,[]);
    else
      analysis('setobjdata','rawmodel',handles,rawmodl);
    end

    if ~strcmp(regmode,'mlr') && ~strcmp(regmode,'lwr') && isempty(getappdata(handles.pcsedit,'default')) && exist('choosecomp.m','file')==2 && strcmp(options.autoselectcomp,'on')
      %Make auto selection of components.
      selectpc = choosecomp(modl);
      if ~isempty(selectpc) && minlv~=selectpc
        %Recalculate model
        minlv = selectpc;

        switch regmode
          case {'pls'}
            if strcmp(opts.algorithm , 'robustpls')
              modl = pls(x,y,minlv,opts);
            else
              opts.rawmodel      = 1;
              modl      = pls(x,y,minlv,rawmodl,opts);
              modl.detail.ssq(minlv+1:size(rawmodl.detail.ssq,1),:) = rawmodl.detail.ssq(minlv+1:end,:);   %copy complete SSQ table
            end

          case 'pcr'
            if ismember(opts.algorithm, {'frpcr' 'robustpcr'})
              modl = pcr(x,y,minlv,opts);
            else
              opts.rawmodel      = 1;
              modl = pcr(x,y,minlv,rawmodl,opts);
              modl.detail.ssq = rawmodl.detail.ssq;   %copy complete SSQ table
            end

          otherwise
            %see if we can do a standard regression!
            try
              modl      = feval(regmode,x,y,minlv,opts);
              modl.detail.ssq = rawmodl.detail.ssq;   %copy complete SSQ table

            catch
              erdlgpls({'Error using ' regmode ' regression method',lasterr},'Calibrate Error');
              return
            end
        end

        if ~isempty(cvinfo)
          for fyld = fieldnames(cvinfo)';
            modl.detail.(fyld{:}) = cvinfo.(fyld{:});
          end
        end
        analysis('setobjdata','model',handles,modl);
      end
    end

    
    handles = guidata(handles.analysis);
    updatessqtable(handles,minlv)
    
    %set buttons
    analysis('toolbarupdate',handles)  %set buttons

  case {'calnew'}
    %apply model to new data (or change of # of components only)
    rawmodl = analysis('getobjdata','rawmodel',handles);
    x = analysis('getobjdata','xblock',handles);
    y = analysis('getobjdata','yblock',handles);
    mytbl = getappdata(handles.analysis,'ssqtable');

    %minlv   = get(handles.ssqtable,'Value'); %number of PCs
    minlv   = getselection(mytbl,'rows');

    if isempty(y);
      erdlgpls('No y-block information. Can not calibrate','Calibrate Error');
      return
    end
    if isempty(y.includ{2});
      erdlgpls('All y-block columns excluded. Can not calibrate','Calibrate Error');
      return
    end

    regmode = getappdata(handles.analysis,'curanal');
    try
      opts = rawmodl.detail.options;
      opts.rawmodel = 1;
      switch regmode
        case {'pls' 'pcr'}
          modl      = feval(regmode,x,y,minlv,rawmodl,opts);
          modl.detail.ssq(minlv+1:size(rawmodl.detail.ssq,1),:) = rawmodl.detail.ssq(minlv+1:end,:);   %copy complete SSQ table
        case 'npls'
          modl      = feval(regmode,x,y,minlv,opts);
          modl.detail.ssq(minlv+1:size(rawmodl.detail.ssq,1),:) = rawmodl.detail.ssq(minlv+1:end,:);   %copy complete SSQ table
        otherwise
          modl      = feval(regmode,x,y,minlv,opts);
      end
    catch
      erdlgpls({'Error using ' regmode ' regression method',lasterr},'Calibrate Error');
      return
    end

    [cvmode,cvlv,cvsplit,cviter] = crossvalgui('getsettings',getappdata(handles.analysis,'crossvalgui'));
    if ~strcmp(cvmode,'none')
      %copy cross-val info into modl
      modl = copycvfields(rawmodl,modl);
    else
      % copy rmsec, r2c, & bias from oiginal model
      omodl = analysis('getobjdata','model',handles);
      if ~isempty(omodl)
        modl.detail.rmsec = omodl.detail.rmsec;
        modl.detail.bias = omodl.detail.bias;
        modl.detail.r2c = omodl.detail.r2c;
      end
    end
    
    setappdata(handles.analysis,'statmodl','calold');
    analysis('setobjdata','model',handles,modl);
    updatessqtable(handles,minlv)
    
end

if analysis('isloaded','validation_xblock',handles)
  %apply model to test data
  [x,y,modl] = analysis('getreconciledvalidation',handles);
  if isempty(x); return; end  %some cancel action
  
  regmode = getappdata(handles.analysis,'curanal');
  try
    switch regmode
      case {'pls'}
        opts = getoptions(regmode,handles);
        opts.rawmodel      = 0;

        test = pls(x,y,modl,opts);

      case 'pcr'
        opts = getoptions(regmode,handles);
        opts.rawmodel      = 0;

        test = pcr(x,y,modl,opts);
        
      case 'lwr'
        opts = getoptions(regmode,handles);
        test = lwr(x,y,modl,opts);

      otherwise

        opts               = feval(regmode,'options');
        opts.display       = 'off';
        opts.plots         = 'none';

        test = feval(regmode,x,y,modl,opts);

    end
  catch
    erdlgpls({'Error using ' regmode ' regression method',lasterr,'Model not applied to validation data.'},'Apply Model Error');
    test = [];
  end
  
  analysis('setobjdata','prediction',handles,test)

else
  %no test data? clear prediction
  analysis('setobjdata','prediction',handles,[]);  
end

guidata(h,handles)

analysis('updatestatusboxes',handles);
analysis('toolbarupdate',handles)  %set buttons

%delete model-specific plots we might have had open
temp = getappdata(handles.analysis,'modelspecific');
close(temp(ishandle(temp)));
setappdata(handles.analysis,'modelspecific',[]);

updatefigures(handles.analysis);     %update any open figures
figure(handles.analysis)

% --------------------------------------------------------------------
function plotyloads_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.plotyloads.

ldopts.plots = 'none';
ldopts.block = 2;
a = plotloads(handles.analysis,ldopts);

figname = ['Y-block Variables/Loadings' getappdata(handles.analysis,'figname_info')];

%all other loadings use these settings
plotbymode = 2;
linkmap_data = [1 2];
linkmap_loads = [2 1];
myname = 'yloads';

%- - - - - - - - - - - - - - - - - - - - - - - - 
%add name and callback fns
myprops = [];
myprops.figurename = figname;
myprops.includechangecallback = ['pca_guifcn(''loadsincludchange'',h,myobj,''y'')'];
myprops.sourcemode = 2;

%set object data (or update)
myid = analysis('setobjdata',myname,handles,a,myprops);

%link to y-block (if there)
dataid = analysis('getobj','yblock',handles);
if ~isempty(dataid)
  linkshareddata(dataid,'add',myid,'analysis',struct('linkmap',linkmap_data));
  linkshareddata(myid,'add',dataid,'analysis',struct('linkmap',linkmap_loads));
end

%See if there is a valid plotgui subscriber.
fighandle = analysis('findpg',myid,handles,'*');
if isempty(fighandle);
  plotsettings = {'name',figname,'plotby',plotbymode,'userdata',double(handles.analysis), ...
    'plotcommand', '',...
    'viewlabels',0,'controlby',getappdata(handles.analysis,'plotgui'),'axismenuvalues',{0 1},'viewaxislines',[1 1 1],...
    'validplotby',plotbymode};
  myid.properties.plotsettings = plotsettings;
  plotgui('new',myid,plotsettings{:});
else
  figure(min(double(fighandle)));
end


%----------------------------------------------------
function ssqtable_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.ssqtable.
% Selects number of PCs from the ssq table list box.

pca_guifcn('ssqtable_Callback',h,eventdata,handles,varargin{:});

%----------------------------------------------------
function pcsedit_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.pcsedit.
% Selects number of PCs in the editable text box.

pca_guifcn('pcsedit_Callback',h,eventdata,handles,varargin{:});


% --------------------------------------------------------------------
function [modl,success] = crossvalidate(h,modl,perm)
%CrossValidationGUI CrossValidateButton CallBack
handles  = guidata(h);

if nargin<3
  perm = 0;
end

success  = 0;  %indicates failure

x        = analysis('getobjdata','xblock',handles);
y        = analysis('getobjdata','yblock',handles);
mc       = modl.detail.preprocessing;

[cv,lv,split,iter,cvi] = crossvalgui('getsettings',getappdata(h,'crossvalgui'));

askrobuststyle = 0;
switch lower(modl.modeltype)
  case 'pls'
    modeltype = lower(modl.detail.options.algorithm);
    if strcmp(modeltype,'robustpls')
      modeltype = 'sim';
      askrobuststyle = 1;

    end
  case 'pcr'
    modeltype = lower(modl.modeltype);
    if strcmp(modl.detail.options.algorithm,'robustpcr')
      askrobuststyle = 1;
    end
    if strcmp(modl.detail.options.algorithm,'correlationpcr')
      modeltype = 'correlationpcr';
    end

  otherwise
    modeltype = lower(modl.modeltype);
end

if askrobuststyle
  %ask how to handle unsupported robust cross-val
  default = getappdata(0,'robust_crossval_default');
  if isempty(default); default = 'All Data'; end
  ans = evriquestdlg('Robust cross-validation is not fully supported. Do you want to perform cross-validation using all data, exclude the currently flagged outliers, or abort cross-validation?','Robust Cross-Validation','All Data','Exclude Outliers','Abort',default);
  switch ans
    case 'Exclude Outliers'
      x.include{1} = modl.detail.includ{1};
    case 'Abort'
      return
  end
  setappdata(0,'robust_crossval_default',ans);
end

m  = length(x.includ{1});
n  = length(x.includ{2});
lv = min([lv m n]);

methodopts = getoptions(lower(modl.modeltype),handles);

opts = [];
opts.preprocessing = mc;
opts.display = 'off';
opts.plots = 'none';
if isfield(methodopts,'weights')
  opts.weights = methodopts.weights;
  opts.weightsvect = methodopts.weightsvect;
end

if strcmpi(modeltype,'lwr')
  %LWR needs setup for cv.
  opts.lwr = methodopts;
  opts.lwr.ptsperterm = 0;    %ALWAYS zero (means use minimumpts always)
  opts.lwr.minimumpts = getappdata(handles.analysis,'lwr_npts');   %number of points to use
  opts.lwr.preprocessing = 0;%PP is passed in cv opts.
  lv = min(opts.lwr.minimumpts, lv);
end

if strcmpi(modeltype,'mlr')
  %MLR needs setup for cv.
  lv = 1;
  opts.rmoptions.algorithm = modl.detail.options.algorithm;
  opts.rmoptions.optimized_ridge = modl.detail.mlr.best_params.optimized_ridge;
  opts.rmoptions.optimized_lasso = modl.detail.mlr.best_params.optimized_lasso;
  if strcmp(cv,'none')
    cvi = {'vet' 10};
  end
end

opts.testx = analysis('getobjdata','validation_xblock',handles);
opts.testy = analysis('getobjdata','validation_yblock',handles);
if isempty(opts.testx) | isempty(opts.testy)
  opts.testx = [];
  opts.testy = [];
end

if perm>0
  opts.permutation = 'yes';
  opts.npermutation = perm;
  if isfield(modl,'loads');
    lv = size(modl.loads{1},2);
  else
    lv = 1;
  end
end

try
  modl = crossval(x,y,modl,cvi,lv,opts);
catch
  erdlgpls({'Unable to perform cross-valiation - Aborted';lasterr},'Cross-Validation Error');
  return
end

if perm>0
  success = lv;
else
  success  = 1;  %Got here, everything was OK
end
%----------------------------------------------------
function  optionschange(h)

%--------------------------------------------------------------------
function updatefigures(h)
%update any open figures

handles = guidata(h);
if ~strcmp(getappdata(handles.analysis,'statmodl'),'none');
  if ~isempty(analysis('findpg','yloads',handles,'*'))
    plotyloads_Callback(handles.analysis, [], handles);
  end
end

pca_guifcn('updatefigures',h);

%----------------------------------------
function closefigures(handles)
%close the analysis specific figures

for id = {'yloads'};
  mylink = analysis('getobj',id{:},handles);
  if ~isempty(mylink)
    removeshareddata(mylink);
  end
end

pca_guifcn('closefigures',handles);


% --------------------------------------------------------------------
function updatessqtable(handles,pc)

if strcmpi(getappdata(handles.analysis,'curanal'),'lwr')
  lwr_guifcn('updatessqtable',handles,pc);
  return
end

options = reg_guifcn('options');
modl = analysis('getobjdata','model',handles);
mytbl = getappdata(handles.analysis,'ssqtable');

if isempty(modl)
  %set(handles.ssqtable,'String',{},'Value',1,'Enable','off')
  clear(mytbl);%Clear data.
  set(handles.pcsedit,'String','','Enable','off')
  return
end
rawmodl = modl;

if strcmpi(modl.modeltype,'mlr')
  %SSQ table is not visisble.
  return
end

%PCs not given? assume max from model
if nargin<2
  if isfield(modl,'loads')
    pc = size(modl.loads{2});
    pc = pc(end);
  else
    pc = 0;
  end
end

%set listbox
maxpc = options.maximumfactors;
maxcalcpc  = min([size(rawmodl.detail.ssq,1); maxpc]);

if exist('choosecomp.m','file')==2 && strcmp(options.autoselectcomp,'on')
  suggestedpc = choosecomp(modl);
else
  suggestedpc = [];
end

[ssq_table,column_headers,column_format] = getssqtable(rawmodl,maxcalcpc,'raw',11,true);
ssq_table = [ssq_table repmat({' '},size(ssq_table,1),1)];
column_headers{end+1} = '<html>Status</html>';
column_format{end+1} = '';

%Fill out rest of SSQ table.
statmodl = getappdata(handles.analysis,'statmodl');
opts = getoptions(getappdata(handles.analysis,'curanal'),handles);
if (isfieldcheck(modl,'model.detail.plsfn') & strcmpi(modl.detail.plsfn,'npls')) ...
    | (isfield(opts,'algorithm') & (~isempty(findstr(opts.algorithm , 'robust')) | strcmp(opts.algorithm,'frpcr') )) ...
    & ~strcmpi(statmodl,'loaded')
  for jj=maxcalcpc+1: maxpc
    ssq_table{jj,end} = 'not calculated';
  end
end

if ~isempty(suggestedpc)
  ssq_table{suggestedpc,end} = 'suggested';
end

%don't allow > # of evs
if pc > maxpc;
  pc = 1;
end

if ~isempty(suggestedpc) && suggestedpc==pc
  ssq_table{pc,end} = 'current*';
else
  ssq_table{pc,end} = 'current';
end

%Update table data.
mytbl.data = ssq_table;
mytbl.column_labels = column_headers;
mytbl.column_format = column_format;

%Make selection the current PC.
setselection(mytbl,'rows',pc)

%set(handles.ssqtable,'String',s,'Value',pc,'Enable','on')
set(handles.pcsedit,'String',int2str(pc),'Enable','on','style','text')

if ~isempty(getappdata(handles.pcsedit,'default'))
  setappdata(handles.pcsedit,'default',pc);
end

% --------------------------------------------------------------------
function threshold_Callback()

% --------------------------------------------------------------------
function storedopts = getoptions(atype, handles)
%Returns options strucutre for specified (atype) analysis.
%Called from plsda_guifcn as well.
storedopts  = getappdata(handles.analysis,'analysisoptions');
curanalysis = getappdata(handles.analysis,'curanal');

if isempty(storedopts) | ~strcmp(storedopts.functionname, curanalysis)
  switch atype
    case 'pcr'
      storedopts = pcr('options');
    case 'pls'
      storedopts = pls('options');
    case 'plsda'
      storedopts = plsda('options');
    case 'lwr'
      storedopts = lwr('options');
    otherwise
      storedopts = feval(atype,'options');
  end  
end

storedopts.display       = 'off';
storedopts.plots         = 'none';

% --------------------------------------------------------------------
function modl = model_in_cache(handles)

%List of model names.
curcachemodls = analysis('getobjdata','modelcache',handles);
pc = getappdata(handles.pcsedit,'default');

modl = [];

if ~isempty(curcachemodls)
  %Search for num PCs match.
  for ii = 1:length(curcachemodls)
    tempcachemodl = modelcache('get',curcachemodls{ii});
    if ~isempty(tempcachemodl)
      tempcachemodlpcs = size(tempcachemodl.loads{2});
      if tempcachemodlpcs(end)==pc
        %Found model
        modl = tempcachemodl;
      end
    end
  end
end

% --------------------------------------------------------------------
function modl = add_model_to_cache(handles,modl)
%Add model name to cache if not already there.

curcachemodls = analysis('getobjdata','modelcache',handles);
thisname = modelcache('save_uniquename','model',modl);
if ~ismember(thisname,curcachemodls)
  curcachemodls{end+1} = thisname;
end

analysis('setobjdata','modelcache',handles,curcachemodls);




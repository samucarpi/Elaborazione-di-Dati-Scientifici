function varargout = mpca_guifcn(varargin);
%MPCA_GUIFCN Analysis-specific methods for Analysis GUI.
% This is a set of utility functions used by the Analysis GUI only.
%See also: ANALYSIS

%Copyright © Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%rsk 06/02/04 Change pcsedit to text box, deselct changes back to edit.
%     -Users must make changes via ssq table.

if nargin>0;
  try
    switch lower(varargin{1})
      case evriio([],'validtopics')
        options = analysis('options');
        %add guifcn specific options
        if nargout==0
          evriio(mfilename,varargin{1},options)
        else
          varargout{1} = evriio(mfilename,varargin{1},options);
        end
        return;
      otherwise
        myfile = lower(which(mfilename));
        target = lower(which(varargin{1}));
        if strcmp(myfile(1:end-2),target(1:end-2))
          if nargout == 0;
            feval(varargin{:}); % FEVAL switchyard
          else
            [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
          end
        else
          if nargout == 0;
            pca_guifcn(varargin{:}); % FEVAL switchyard
          else
            [varargout{1:nargout}] = pca_guifcn(varargin{:}); % FEVAL switchyard
          end
        end
    end
  catch
    erdlgpls(lasterr,[upper(mfilename) ' Error']);
  end
end

%----------------------------------------------------
function gui_init(h,eventdata,handles,varargin);

feval('pca_guifcn','gui_init',handles.analysis,[],handles);

%hide autoselect components button
set(handles.findcomp,'visible','off')

%create toolbar
%set appdata
%change ssq table labels
%turn on valid crossvalidation
%general updating

handles = guidata(handles.analysis);
pre = getappdata(handles.preprocessmain,'preprocessing');
if length(pre)==1 & strcmpi(pre.description,'autoscale')
  setappdata(handles.preprocessmain,'preprocessing',preprocess('default','groupscale'))
end

evritip('analysis_mpca');

%----------------------------------------------------
function gui_deselect(h,eventdata,handles,varargin)
%Change pcsedit back to defualt style.
set(handles.pcsedit,'style','edit')

%Clear table.
mytbl = getappdata(handles.analysis,'ssqtable');
clear(mytbl,'all');

%Get rid of panel objects.
panelmanager('delete',panelmanager('getpanels',handles.ssqframe),handles.ssqframe)

closefigures(handles);
%----------------------------------------------------
function gui_updatetoolbar(h,eventdata,handles,varargin)


set(handles.biplot, 'Enable','off')
if isfield(handles,'openimagegui')
  set(handles.openimagegui,'Enable','off')
end

%----------------------------------------------------
function out = isdatavalid(xprofile,yprofile,fig)
%two-way x
% out = xprofile.data & xprofile.ndims==2;

%multi-way x
out = xprofile.data & xprofile.ndims>2;

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
function calcmodel_Callback(h,eventdata,handles,varargin)

%Refresh handles because of use of function handle with ssqtable. Button
%handles can be out of date.
handles = guihandles(handles.analysis);

options = mpca_guifcn('options');

statmodl = lower(getappdata(handles.analysis,'statmodl'));
if strcmp(statmodl,'calnew') & ~analysis('isloaded','rawmodel',handles) %isempty(getappdata(handles.analysis,'rawmodl'))
  statmodl = 'none';
end

switch statmodl
  case {'none'}
    %prepare X-block for analysis
    x             = analysis('getobjdata','xblock',handles);

    if ndims(x)~=3;
      erdlgpls('MPCA requires a 3-way matrix (time x variable x batch)','Calibrate Error');
      return
    end
    if isempty(x.includ{1});
      erdlgpls('All time points excluded. Can not calibrate','Calibrate Error');
      return
    end
    if isempty(x.includ{2});
      erdlgpls('All variables excluded. Can not calibrate','Calibrate Error');
      return
    end
    if isempty(x.includ{3});
      erdlgpls('All samples excluded. Can not calibrate','Calibrate Error');
      return
    end

    if mdcheck(x);
      ans = evriquestdlg({'Missing Data Found - Replacing with "best guess"','Results may be affected by this action.'},'Warning: Replacing Missing Data','OK','Cancel','OK');
      if ~strcmp(ans,'OK'); return; end
      try
        if strcmpi(getfield(modelcache('options'),'cache'),'on')
          modelcache([],x);
          evritip('missingdatacache','Original data (with missing values) has been stored in the model cache.',1)
        end
      catch
      end
      [flag,missmap,x] = mdcheck(x,struct('toomuch','ask'));
      analysis('setobjdata','xblock',handles,x);
    end

    preprocessing = {getappdata(handles.preprocessmain,'preprocessing')};
    options = mpca_guifcn('options');

    [cvmode,cvlv] = crossvalgui('getsettings',getappdata(handles.analysis,'crossvalgui'));
    if ~strcmp(cvmode,'none')
      maxpc   = min([length(x.includ{1}) length(x.includ{2}) options.maximumfactors cvlv]);
    else  %no cross-val method? Don't let the slider limit the # of LVs
      maxpc   = min([length(x.includ{1}) length(x.includ{2}) options.maximumfactors]);
    end
    pc   = getappdata(handles.pcsedit,'default');

    %don't allow > # of evs (in fact, consider this a reset of default)
    if isempty(pc) | pc>maxpc;
      pc = 1;
    end;

    opts = getappdata(handles.analysis,'analysisoptions');
    if isempty(opts)
      opts = mpca('options');
    end
    opts.display       = 'off';
    opts.plots         = 'none';
    opts.preprocessing = preprocessing;
    opts.samplemode    = 3;
    opts.rawmodel      = 1;

    %calculate all loads and whole SSQ table
    rawmodl    = mpca(x,maxpc,opts);

    %calculate sub-set of that raw model (with limits, etc)
    modl       = mpca(x,pc,rawmodl,opts);
    modl.detail.ssq = modl.detail.ssq(1:min(maxpc,size(modl.detail.ssq,1)),:);

    %Do cross-validation
    if ~strcmp(cvmode,'none')
      modl = crossvalidate(handles.analysis,modl);

      rawmodl.detail.rmsec  = modl.detail.rmsec;
      rawmodl.detail.rmsecv = modl.detail.rmsecv;
      rawmodl.detail.cv     = modl.detail.cv;
      rawmodl.detail.split  = modl.detail.split;
      rawmodl.detail.iter   = modl.detail.iter;
    end

    %UPDATE GUI STATUS
    %set status windows
    setappdata(handles.analysis,'statmodl','calold');
    analysis('setobjdata','model',handles,modl);
    analysis('setobjdata','rawmodel',handles,rawmodl);

    updatessqtable(handles,pc);

  case {'calnew'}
    %change of # of components only
    rawmodl = analysis('getobjdata','rawmodel',handles);

    %prepare X-block for analysis
    x             = analysis('getobjdata','xblock',handles);
    
    mytbl = getappdata(handles.analysis,'ssqtable');
    minpc   = getselection(mytbl,'rows');
    %minpc = get(handles.ssqtable,'Value'); %number of PCs
    [cvmode,cvlv] = crossvalgui('getsettings',getappdata(handles.analysis,'crossvalgui'));
    if ~strcmp(cvmode,'none')
      maxpc   = min([length(x.includ{1}) length(x.includ{2}) options.maximumfactors cvlv]);
    else  %no cross-val method? Don't let the slider limit the # of LVs
      maxpc   = min([length(x.includ{1}) length(x.includ{2}) options.maximumfactors]);
    end

    opts = rawmodl.detail.options;
    opts.display       = 'off';
    opts.plots         = 'none';
    opts.rawmodel      = 1;

    modl = mpca(x,minpc,rawmodl,opts);
    modl.detail.ssq = modl.detail.ssq(1:min(maxpc,size(modl.detail.ssq,1)),:);

    modl.detail.rmsec  = rawmodl.detail.rmsec;
    modl.detail.rmsecv = rawmodl.detail.rmsecv;
    modl.detail.cv     = rawmodl.detail.cv;
    modl.detail.split  = rawmodl.detail.split;
    modl.detail.iter   = rawmodl.detail.iter;

    setappdata(handles.analysis,'statmodl','calold');
    analysis('setobjdata','model',handles,modl);
    updatessqtable(handles,minpc);

end

%apply model to test/validation data (if present)
if analysis('isloaded','validation_xblock',handles)
  %apply model to test data
  modl = analysis('getobjdata','model',handles);
  x    = analysis('getobjdata','validation_xblock',handles);

  opts = [];
  opts.display       = 'off';
  opts.plots         = 'none';
  opts.rawmodel      = 0;
  opts.samplemode    = 3;

  try
    test = mpca(x,modl,opts);
  catch
    erdlgpls({'Error applying model to validation data.',lasterr,'Model not applied.'},'Apply Model Error');
    test = [];
  end
    
  analysis('setobjdata','prediction',handles,test);

else
  %no test data? clear prediction
  analysis('setobjdata','prediction',handles,[]);  
end

analysis('updatestatusboxes',handles);
analysis('toolbarupdate',handles)  %set buttons

%delete model-specific plots we might have had open
h = getappdata(handles.analysis,'modelspecific');
close(h(ishandle(h)));
setappdata(handles.analysis,'modelspecific',[]);

%update plots
updatefigures(handles.analysis);     %update any open figures
figure(handles.analysis)

% --------------------------------------------------------------------
function scorestconbuttoncall(h, eventdata, handles, varargin)

modl = analysis('getobjdata','model',handles);
test = analysis('getobjdata','prediction',handles);

if ~ismember(getappdata(handles.analysis,'statmodl'),{'calold' 'loaded'})
  evriwarndlg(['Model information not available.', ...
      ' Contributions cannot be calculated.'],'T^2 Contributions')
  return
end

fig = getappdata(get(h,'parent'),'target');
figure(fig);
ii = gselect('nearest',pca_guifcn('finddataobj'),1);
if isempty(ii); return; end
if ~iscell(ii); ii = {ii}; end
for k=2:length(ii); ii{1} = or(ii{1},ii{k}); end
ii = find(ii{1});

if isempty(ii);
  return
end
mode = evriquestdlg('What kind of Contributions do you want to display?','Contributions Plot','Variable Summary','Time Summary','Full Contributions','Variable Summary');
if isempty(mode); return; end
pca_guifcn('setplotselection',fig,ii);    %mark these items as selected in plot

myii=ii(1);
[cal,val] = pca_guifcn('sortselection',myii,handles);

%check for reference points
scrs = analysis('getobj','scores',handles);
refset = findset(scrs.object,'class',1,'TCon Reference');
if ~isempty(refset)
  %sort out reference
  tconref = find(scrs.object.class{1,refset}');
  [calref,valref] = pca_guifcn('sortselection',tconref,handles);
  isref  = [false(1,length(cal)) true(1,length(calref)) false(1,length(val)) true(1,length(valref))];
  allcal = [cal;calref];
  allval = [val;valref];
else
  %no reference
  tconref = [];
  allcal = cal;
  allval = val;
end

ii    = [];
loads = [];
tsqs  = [];
x     = [];
samplelabels = {};
mwadetails = [];
if ~isempty(allcal)
  %do for model data...
  ii = cal;
  if ~isempty(cal) %selected sample was in cal set
    mwadetails = modl.detail.mwadetails;
    block = 'xblock';
  end
  loads = modl.loads{1,1}(allcal,:);
  tsqs  = modl.tsqs{1,1}(cal);
  x = analysis('getobjdata','xblock',handles);
  blocklabel = 'Calibration';
end
if ~isempty(allval);
  %do for test data... (MAY be adding to calibration data so do carefully)
  ii = [ii;val];
  if ~isempty(val) %selected sample was in val
    mwadetails = test.detail.mwadetails;
    block = 'validation_xblock';
  end    
  loads = [loads; test.loads{1,1}(allval,:)];
  tsqs  = [tsqs; test.tsqs{1,1}(val)];
  x = analysis('getobjdata','validation_xblock',handles);
  blocklabel = 'Test';
end

pred = modl;  %fake a pred structure to pass to tconcalc
pred.loads{1,1} = loads;  %insert necessary scores into fake pred structure
con = tconcalc(pred,modl);

if ~isempty(tconref)
  %remove reference values and use to correct non-reference values
  conref = nindex(con,isref,1);        %extract t-cons for reference values
  con = nindex(con,~isref,1);          %leave non-ref values in con
  con = scale(con,mean(conref,1));       %do correction to make these RELATIVE t-contributions
end

z    = tsqs;

%expand to include fillers for excluded items
temp = zeros(1,prod(modl.datasource{1}.size(1:2)))*nan;
temp(1,modl.detail.includ{2}) = con;
con = reshape(temp,modl.datasource{1}.size(1),modl.datasource{1}.size(2));
con = copydsfields(modl.detail.mwadetails,dataset(con),[1 2]);
con.name = ['Full Hotelling T^2 Contributions Sample ' num2str(ii)];

if isempty(mwadetails.detail.label{3})
  mytitle = sprintf('%s Sample %u Hotelling T^2 = %5.4g ',blocklabel,ii,z);
else
  mytitle = sprintf(['%s Sample %u ',deblank(mwadetails.detail.label{3}(ii,:)),' Hotelling T^2 = %5.4g '],blocklabel,ii,z);
end

switch mode
  case 'Full Contributions'
    
    plotconfull(handles,con,block);
    
  case {'Variable Summary' 'Time Summary'}
    
    if strcmp(mode,'Variable Summary');
      consummary = mean(con.data(modl.detail.mwadetails.detail.includ{1},:),1);
      mode = 2;
      xlbl = 'Variable';
      mytitle = ['Variable Mean ' mytitle];
      myname = ['Variable T^2 Contributions - Sample ' num2str(ii)];
    else
      consummary = mean(con.data(:,modl.detail.mwadetails.detail.includ{2}),2)';
      mode = 1;
      xlbl = 'Time';
      mytitle = ['Time Mean ' mytitle];
      myname = ['Time T^2 Contributions - Sample ' num2str(ii)];
    end
    
    newfig   = figure('numbertitle','off','name',myname);
    analysis('adopt',handles,newfig);
    analysis('adopt',handles,newfig,'modelspecific');
    
    %store info for click callbacks
    setappdata(newfig,'analysishandle',double(handles.analysis));
    setappdata(newfig,'con',con);
    setappdata(newfig,'mode',mode);
    setappdata(newfig,'block',block);
    
    if isempty(modl.detail.mwadetails.detail.axisscale{mode,1})
      xax            = 1:modl.datasource{1}.size(mode);
    else
      xax            = modl.detail.mwadetails.detail.axisscale{mode,1};
    end
    if ~isempty(modl.detail.mwadetails.detail.title{mode,1})
      xlbl           = modl.detail.mwadetails.detail.title{mode,1};
    elseif ~isempty(modl.detail.mwadetails.detail.labelname{mode,1})
      xlbl           = modl.detail.mwadetails.detail.labelname{mode,1};
    end
    if length(ii) == 1;
      h = bar(xax,consummary','b');
      xlabel(xlbl)
    else
      h = bar(consummary);
      set(gca,'xticklabel','')
    end
    set([h gca],'buttondownfcn','mpca_guifcn(''plotconfull'',gcbf)');
    ylabel('Mean Hotelling T^2 Contribution')
    title(mytitle);
    s                = ' ';
    
    lbls = [];
    if ~isempty(modl.detail.mwadetails.detail.label{mode,1}) & modl.datasource{1}.size(mode)<100;
      lbls = modl.detail.mwadetails.detail.label{mode,1};
    end
    if ~isempty(lbls);
      h = text(xax,max([zeros(1,length(consummary)); consummary]),[s(ones(size(lbls,1),1)) lbls], 'rotation',90);
      set(h,'buttondownfcn','mpca_guifcn(''plotconfull'',gcbf)','interpreter','none');
      ext = get(h,'extent');
      ext = cat(1,ext{:});
      top = max(ext(:,2)+ext(:,4));
      ax = axis;
      if ax(4)<top;
        axis([ax(1:3) top]);
      end
    end
end

 
% --------------------------------------------------------------------
function scoresqconbuttoncall(h, eventdata, handles, varargin)

cal_loaded  = analysis('isloaded','xblock',handles);
val_loaded  = analysis('isloaded','validation_xblock',handles);
modl        = analysis('getobjdata','model',handles);

if ~cal_loaded & ~val_loaded
  evriwarndlg(['Calibration or test data must be available to calculate Q contributions.', ...
      ' Contributions cannot be calculated.'],'Q Contributions')
  return
end
if ~ismember(getappdata(handles.analysis,'statmodl'),{'calold' 'loaded'})
  evriwarndlg(['Model information not available.', ...
      ' Contributions cannot be calculated.'],'Q Contributions')
  return
end

fig = getappdata(get(h,'parent'),'target');
figure(fig);
ii  = gselect('nearest',pca_guifcn('finddataobj'),1);
if isempty(ii); return; end
if ~iscell(ii); ii = {ii}; end
for k=2:length(ii); ii{1} = or(ii{1},ii{k}); end
ii = find(ii{1});

if isempty(ii);
  return;
end
mode = evriquestdlg('What kind of Contributions do you want to display?','Contributions','Variable Summary','Time Summary','Full Contributions','Variable Summary');
if isempty(mode); return; end
pca_guifcn('setplotselection',fig,ii);    %mark these items as selected in plot

myii=ii(1);
[cal,val] = pca_guifcn('sortselection',myii,handles);

%check for reference points
scrs = analysis('getobj','scores',handles);
refset = findset(scrs.object,'class',1,'QCon Reference');
if ~isempty(refset)
  %sort out reference
  qconref = find(scrs.object.class{1,refset}');
  [calref,valref] = pca_guifcn('sortselection',qconref,handles);
  allcal = unique([cal;calref]);
  allval = unique([val;valref]);
  isref  = [ismember(allcal,calref);ismember(allval,valref)];
  onlyconref = [~ismember(allcal,cal);~ismember(allval,val)];
else
  %no reference
  qconref = [];
  allcal = cal;
  allval = val;
end

calx = [];
valx = [];
samplelabels = {};
if ~isempty(allcal)
  %calibration data
  ii = cal;
  if ~cal_loaded
    evriwarndlg(['Original calibration data not available for this point.', ...
      ' Contributions cannot be calculated.'],'Q Contributions')
    return
  end
  calx = analysis('getobjdata','xblock',handles);
  calx = delsamps(calx,setdiff(1:size(calx.data,3),allcal),3,2);
  block = 'xblock';
  blocklabel = 'Calibration';
end
if ~isempty(allval)
  %test data
  ii = val;
  if ~val_loaded
    evriwarndlg(['Original validation data not available for this point.', ...
      ' Contributions cannot be calculated.'],'Q Contributions')
    return
  end
  valx = analysis('getobjdata','validation_xblock',handles);
  valx = delsamps(valx,setdiff(1:size(valx.data,3),allval),3,2);
  blocklabel = 'Test';
  block = 'validation_xblock';
  
end

if ~isempty(cal) & ~isempty(val);
  ii = [cal; val];
end
x = cat(3,calx,valx);
x.include{3} = 1:size(x,3);
[xhat,con] = datahat(modl,x);

if ~isempty(qconref)
  %remove reference values and use to correct non-reference values
  conref = nindex(con,isref,1);          %extract t-cons for reference values
  con    = nindex(con,~onlyconref,1);          %remove ref-only values in con
  x      = nindex(x,~onlyconref,3);
  con    = scale(con,mean(conref,1));  %do correction to make these RELATIVE t-contributions
end

z          = sum((con.^2),2);

%expand con to include fillers for excluded items
temp = zeros(1,prod(modl.datasource{1}.size(1:2)))*nan;
temp(1,modl.detail.includ{2}) = con;
con = reshape(temp,size(x,1),size(x,2));
con = copydsfields(modl.detail.mwadetails,dataset(con),[1 2]);
con.name = sprintf('Full Q Contributions %s Sample %i',blocklabel,ii);

if isempty(x.label{3})
  mytitle = sprintf('%s Sample %u Q Residual = %5.4g ',blocklabel,ii,z);
else
  mytitle = sprintf(['%s Sample %u ',deblank(x.label{3}),' Q Residual = %5.4g '],blocklabel,ii,z);
end

switch mode
  case 'Full Contributions'
    
    plotconfull(handles,con,block);
    
  case {'Variable Summary' 'Time Summary'}
    
    if strcmp(mode,'Variable Summary');
      consummary = mean(con.data(modl.detail.mwadetails.detail.includ{1},:),1);
      mode = 2;
      xlbl = 'Variable';
      mytitle = ['Variable Mean ' mytitle];
      myname = sprintf('Variable Q Contributions - %s Sample %i',blocklabel,ii);
    else
      consummary = mean(con.data(:,modl.detail.mwadetails.detail.includ{2}),2)';
      mode = 1;
      xlbl = 'Time';
      mytitle = ['Time Mean ' mytitle];
      myname = sprintf('Time Q Contributions - %s Sample %i',blocklabel,ii);
    end
    
    newfig   = figure('numbertitle','off','name',myname);
    analysis('adopt',handles,newfig,'modelspecific');
    
    %store info for click callbacks
    setappdata(newfig,'analysishandle',double(handles.analysis));
    setappdata(newfig,'con',con);
    setappdata(newfig,'mode',mode);
    
    if isempty(x.axisscale{mode,1})
      xax            = 1:size(x,mode);
    else
      xax            = x.axisscale{mode,1};
    end
    if ~isempty(x.title{mode,1})
      xlbl           = x.title{mode,1};
    elseif ~isempty(x.labelname{mode,1})
      xlbl           = x.labelname{mode,1};
    end
    if length(ii) == 1;
      h = bar(xax,consummary','b');
      xlabel(xlbl)
    else
      h = bar(consummary);
      set(gca,'xticklabel','')
    end
    set([h gca],'buttondownfcn','mpca_guifcn(''plotconfull'',gcbf)');
    ylabel('Mean Q Residual Contribution')
    title(mytitle);
    s                = ' ';
    
    lbls = [];
    if ~isempty(x) & ~isempty(x.label{mode,1}) & size(x,mode)<100;
      lbls = x.label{mode,1};
    elseif ~isempty(modl.detail.mwadetails.detail.label{mode,1}) & size(x,mode)<100;
      lbls = modl.detail.mwadetails.detail.label{mode,1};
    end
    if ~isempty(lbls);
      h = text(xax,max([zeros(1,length(consummary)); consummary]),[s(ones(size(lbls,1),1)) lbls], 'rotation',90);
      set(h,'buttondownfcn','mpca_guifcn(''plotconfull'',gcbf)','interpreter','none');
      ext = get(h,'extent');
      ext = cat(1,ext{:});
      top = max(ext(:,2)+ext(:,4));
      ax = axis;
      if ax(4)<top;
        axis([ax(1:3) top]);
      end
    end
end


%-------------------------------------------------------
function plotconfull(h,con,block)
% inputs are:
%  h : handles structure for analysis OR handle to figure which has
%      'analysishandle' set as an appdata field (containing handle to
%      analysis figure)
%  con : (optional) dataset of q- or t-contributions or a handle. If omitted, it
%      is assumed that h is a handle pointing to a figure with appdata
%      'con' containing dataset of contributions
%  block : (optional) name of block to which this data should be linked for
%           selections 
%  selected and mode : (optional) mode to plot by and particular items
%      (selected is used for axismenuvalues) 

if ~isstruct(h)
  %callback from summary plot, get info from current figure
  handles = guidata(getappdata(h,'analysishandle'));
  mode    = getappdata(h,'mode');
  block   = getappdata(h,'block');
  selected = get(get(h,'currentaxes'),'currentpoint');
  targfig  = getappdata(h,'fullcontarget');
else
  handles = h;
  targfig = [];
  if nargin<3
    error('block and con must be supplied when called in this manner');
  end
  selected = [];
  mode = [];
end

noinclude = strcmp(getappdata(handles.analysis,'statmodl'),'loaded');
if nargin<2
  con = getappdata(h,'con');
end
if isempty(mode)
  mode = 2;
end
if isempty(selected)
  selected = 1:size(con,mode);
else
  selected = round(selected(1));
end

if isempty(targfig) | ~ishandle(targfig)
  %create a plot of the contributions data and attach it to the model
  
  %share linked data on a new figure
  myprops = [];
  myprops.includechangecallback = ['mpca_guifcn(''loadsincludchange'',h,myobj)'];  
  pgh  = figure;
  myid = setshareddata(pgh,con,myprops);
  linkshareddata(myid,'add',handles.analysis,'analysis');

  %link to x-block (if there)
  xdataid = analysis('getobj',block,handles);
  if ~isempty(xdataid)
    linkshareddata(xdataid,'add',myid,'analysis',struct('linkmap',[1 1; 2 2]));
    linkshareddata(myid,'add',xdataid,'analysis',struct('linkmap',[1 1; 2 2]));
  end

  
  %then make it a plotgui figure
  pgh = plotgui('update','figure',pgh,myid,...
    'name',con.name,...
    'plotby',mode,'axismenuvalues',{0 selected},...
    'viewaxislines',[1 1 1],...
    'noinclude',noinclude);

  setappdata(pgh,'analysishandle',double(handles.analysis));
  analysis('adopt',handles,pgh,'modelspecific');
  
  if ishandle(h)
    setappdata(h,'fullcontarget',pgh);
  end
else
  %figure exists, try adding this selected variable to already shown ones
  plotby = getappdata(targfig,'plotby');
  [ind1,ind2,ind3] = plotgui('GetMenuIndex',targfig);
  
  if plotby==mode;
    axismenuvalues = {ind1 union(ind2,selected) ind3};
  else
    axismenuvalues = {[0] selected};
  end
  plotgui('update','figure',targfig,...
    'plotby',mode,'axismenuvalues',axismenuvalues,...
    'noinclude',noinclude);
end

%-------------------------------------------------------
function updatessqtable(handles,pc)
% Update SSQ table. 
if nargin<2
  pca_guifcn('updatessqtable',handles);
else
  pca_guifcn('updatessqtable',handles,pc);
end


%--------------------------------------------------------------------
function loadsexplore(h,eventdata,handles,varargin)

if strcmp(getappdata(handles.analysis,'statmodl'),'none')
  evriwarndlg(['Model information not available.', ...
      ' Loadings cannot be explored.'],'Explore Loadings')
  return
end

modl  = analysis('getobjdata','model',handles);
loads = analysis('getobjdata','loads',handles);

[targfig,fig] = plotgui('findtarget',gcbf);

if getappdata(targfig,'plotby')~=3;
  erdlgpls('Plot menu must be set to "Slabs" to explore loadings');
  return
end

%grab currently selected PC (or whatever)
inds  = plotgui('GetMenuIndex',fig);
inds  = inds{2};
name = ['Exploring ' loads.label{3}(inds(1),:)];
for j=2:length(inds)
  name = [name sprintf(' & %s',loads.label{3}(inds(j),:))];
end
loads = loads(:,:,inds);  %and ONLY that slab

statmodl = getappdata(handles.analysis,'statmodl');
noinclude = strcmp(statmodl,'loaded');

data = copydsfields(modl.detail.mwadetails,loads,[1 2]);

%share linked data on a new figure
myprops = [];
myprops.includechangecallback = ['mpca_guifcn(''loadsincludchange'',h,myobj)'];
pgh  = figure;
myid = setshareddata(pgh,data,myprops);
linkshareddata(myid,'add',handles.analysis,'analysis');

%link to x-block (if there)
xdataid = analysis('getobj','xblock',handles);
if ~isempty(xdataid)
  linkshareddata(xdataid,'add',myid,'analysis',struct('linkmap',[1 1; 2 2]));
  linkshareddata(myid,'add',xdataid,'analysis',struct('linkmap',[1 1; 2 2]));
end


%then make it a plotgui figure
pgh = plotgui('update','figure',pgh,myid,...
  'plotby',2,...
  'name',name,...
  'noinclude',noinclude);

setappdata(pgh,'analysishandle',double(handles.analysis));
analysis('adopt',handles,pgh,'modelspecific');


%--------------------------------------------------------------------
function loadsincludchange(h,myobj)

handles = guidata(h);
x       = analysis('getobjdata','xblock',handles);

if nargin<2;
  p = analysis('getobjdata','loads',handles);
else
  p = myobj.object;
end

if ~strcmp(getappdata(handles.analysis,'statmodl'),'loaded');
  if length(x.include{1,1}) ~= length(p.includ{1,1}) | any(x.includ{1,1} ~= p.includ{1,1}) ...
      | length(x.include{2,1}) ~= length(p.includ{2,1}) | any(x.includ{2,1} ~= p.includ{2,1})
    %any change in dims of interest?
    x.includ{1,1}      = p.includ{1,1};
    x.includ{2,1}      = p.includ{2,1};
    analysis('setobjdata','xblock',handles,x);
  end
else    %model was "loaded" don't change included variables
  %(theoretically, we have "noinclude" set to 1 so we can't actually make
  %it here so we won't bother "undoing" any include change... plus, it
  %isn't a simple copy to translate from the unfolded include stored in the
  %model to the folded include expected by the data)
end

%--------------------------------------------------------------------
function [modl,success] = crossvalidate(varargin)

[modl,success] = pca_guifcn('crossvalidate',varargin{:});


%--------------------------------------------------------------------
function updatefigures(h)
%update any open figures
pca_guifcn('updatefigures',h);


%----------------------------------------
function closefigures(handles)
%close the analysis specific figures
pca_guifcn('closefigures',handles);

%----------------------------------------------------
function ssqtable_Callback(h, eventdata, handles, varargin)
% Callback of the uicontrol handles.ssqtable.
% Selects number of PCs from the ssq table list box.
% ssqtable value and pcsedit string updated by updatessqtable.

pca_guifcn('ssqtable_Callback',h,[],handles);


%----------------------------------------------------
function  optionschange(h)

function varargout = modeloptimizer(varargin)
%MODELOPTIMIZER - Create model for iterating over analysis models.
%  When called with figure handle snapshots will be taken from figure.
%  After several snapshots are taken a list of unique combinations can be
%  generated in the .combinations field. Combinations can then be used to
%  create a list of unique snapshots know as "model runs", that will then
%  be calculated.
%
% OPTIONS:
%   warn_duplicates = [{'on'}|'off'] Check for and disregard duplicate model snapshots.
%        add_to_run = [{'on'}|'off'] Automatically add snapshot to last run.
%           waitbar = [{'on'}|'off'] Display waitbar.
%
% Model optimizer is a structure with following fields.
% optimizer
%   |
%   +snapshots
%   |  +ID - Uniquie ID for snapshot.
%   |  +NCOMP - Number of components or LVs.
%   |  +OPTIONS - Method options.
%   |  +CVI - Crossvalidation settings.
%   |  +XPREPROCESSING - X block preprocessing structure.
%   |  +YPREPROCESSING - Y block preprocessing structure.
%   |  +XDATA_CACHEID* - Cache ID for X block data.
%   |  +YDATA_CACHEID* - Cache ID for Y block data.
%   |  +modelID - ID name of model used to look model up in cache.
%   |  +errormsg - If model can't be calculated this field is populated with message.
%   |
%   +combinations
%      +Same fields as above but stored as cell arrays.
%   |
%   +Model Runs
%      +Same fields as SNAPSHOT.
%
% NOTE: All other meta parameters go into options structure (e.g., npts for
%       LWR goes into options and is then pulled out when needed).
%
%
%
%I/O: modeloptimizer(figure_handle);%Add snapshot to current model.
%I/O: modeloptimizer(figure_handle,'snapshot');%Add snapshot to current model.
%I/O: modeloptimizer('snapshot',modelOBJ);%Add model to optimizer.
%I/O: modeloptimizer('snapshot',modelID);%Add model to optimizer via modelID (uses modelID to look model up in cache).
%I/O: figureHandle = modeloptimizer;%Get figure handle of GUI.
%I/O: newmodel = modeloptimizer(newdata,optimizerodel);%Apply to new data.
%I/O: newmodel = modeloptimizer(newX,newY,optimizerModel);%Apply to new data.
%
%See also: COMPAREMODLES

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%TODO: Enable editing of PCs edit box.
%TODO: Add modelID in cached model.


%QUESTIONS:
%  1) Will extra y block info be ignored? If user happens to have yblock
%  loaded and ypp can I safely just add it to the optimizer?
%  2) Do we create a _PRED version of modeloptimizer?

if nargin>0;
  try
    if ischar(varargin{1}) & ismember(lower(varargin{1}),evriio([],'validtopics'))
      options = [];
      options.name            = 'options';
      options.warn_duplicates = 'on';
      options.add_to_run      = 'on';%Automatically add snapshot to last run.
      options.waitbar         = 'on';%Show waitbar.
      if nargout==0
        evriio(mfilename,varargin{1},options);
      else
        varargout{1} = evriio(mfilename,varargin{1},options);
      end
      return;
    else
      %Parse inputs and or call sub functions.
      if nargin==1 & (ishandle(varargin{1}) | ismodel(varargin{1}))
        %Simple snapshot of analysis gui.
        varargin{2} = varargin{1};
        varargin{1} = 'snapshot';
      end
      
      if isdataset(varargin{1}) & (ismodel(varargin{2}) | ismodel(varargin{3}))
        %Applying existing model to new data.
        varargout{1} = apply(varargin{:});
        return
      end
      
      if nargout == 0;
        feval(varargin{:}); % FEVAL switchyard
      else
        [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
      end
    end
  catch
    erdlgpls(lasterr,[upper(mfilename) ' Error']);
  end
else
  if nargout == 0;
    modeloptimizergui;
  else
    %No inputs so return GUI handle.
    varargout{1} = modeloptimizergui;
  end
end

%--------------------------------------
function snapshot(myfig,options)
%Get all settings from analysis and add to optimizer model as snapshot.

if nargin<2
  options = modeloptimizer('options');
end

if isempty(myfig)
  return
end

myobj     = [];
thismodel = [];
mid = [];
xid = [];
yid = [];
if ~ishandle(myfig)
  %Get model.
  if ismodel(myfig)
    %Actual model.
    thismodel = myfig;
    mid = safename(thismodel.uniqueid);
    
    myexst = modelcache('exist',mid);%Make sure item is in cache.
    if ~myexst{1}
      %Add to cache. Note that since data is not available it will not be
      %displayed in compare table.
      
      %TODO: Get dataserouce info so data info can be displayed in compare
      %table even without data. Don't add .datasource to options because
      %will become out of sync.
      modelcache(thismodel);
    else
      %Try to get x and y from cache.
      [thismodel,xid,yid] = getcacheitems(mid,'model');
    end
  else
    %Get from cache.
    mid = safename(myfig);
    [thismodel,xid,yid] = getcacheitems(mid,'model');
  end
  if isempty(thismodel)
    error('Model can''t be loaded.')
  end
end

%Check to see if this is a MO model.
if ~isempty(thismodel) & strcmpi(thismodel.modeltype,'modeloptimizer')
  f = modeloptimizergui;
  modeloptimizergui('loadmodel',f,[],guihandles(f),thismodel);
  return
end

%Get model and optimizer.
omodel = get_optimizer;
myit   = omodel.optimizer;

myidx = length(myit.snapshots);
if ~isempty(myit.snapshots(myidx).id)
  myidx = myidx+1;
end

thissnapshot = [];

%Create id.
thissnapshot.id = getid;

if ~isempty(thismodel)
  %Check for supported model.
  if ~ismember(lower(thismodel.modeltype),comparemodels('getallowedmodeltypes'))
    evrierrordlg(['Model Type: ' thismodel.modeltype ' can''t be used for Snapshot. Select a different method from the Analysis menu.'],'Method Not Supported')
    return
  end
  
  %Get dataID.
  if ~isempty(xid)
    thissnapshot.xdata_cacheid = xid;
  end
  
  if ~isempty(yid)
    thissnapshot.ydata_cacheid = yid;
  end
  
  %Get options.
  opts = thismodel.options;
  
  if isfieldcheck(thismodel,'model.detail.modelgroups')
    opts.modelgroups = thismodel.detail.modelgroups;
  end
  
  %Add pp and save options.
  pp = opts.preprocessing;
  thissnapshot.xpreprocessing = pp{1};
  if length(pp)>1
    thissnapshot.ypreprocessing = pp{2};
  end
  
  %Get cv.
  thissnapshot.cvi = {thismodel.detail.cv thismodel.detail.split thismodel.detail.iter};
  
  %Get ncomp.
  thissnapshot.ncomp = thismodel.ncomp;
  
  %Add modelID, this is checked when run is called.
  if ~isempty(mid)
    thissnapshot.modelID = thismodel.uniqueid;
  end
else
  
  handles = guihandles(myfig);
  myobj   = get_guiobj(handles);
  
  %Get dataID.
  xdat = myobj.interface.getXblock;
  if ~isempty(xdat)
    thissnapshot.xdata_cacheid = setdata(xdat);
  end
  
  ydat = myobj.interface.getYblock;
  if ~isempty(ydat)
    thissnapshot.ydata_cacheid = setdata(ydat);
  end
  %Note: if there's no data then this particular snapshot won't work by
  %itself but if it is used to generate combination snapshots then could work
  %if data is in other snapshots.
  
  %Get options.
  opts = myobj.interface.getOptions;
  curanalysis = myobj.interface.getMethod;
  if isempty(curanalysis)
    evrierrordlg('Snapshot require method. Confirm method has been selected from Analysis menu.','No Method Error')
    return
  end
  
  if ismember(curanalysis,{'simca' 'purity' 'cluster'})
    evrierrordlg(['Method (' upper(curanalysis) ') can''t be used for Snapshot. Select a different method from the Analysis menu.'],'Method Not Supported')
    return
  end
  
  if isempty(opts)
    opts = feval(curanalysis, 'options');
  end

  switch curanalysis
    case {'svmda' 'plsda'}
      opts.modelgroups = getappdata(findobj(myobj.handle,'tag','choosegrps'),'modelgroups');      
  end
  %Add pp and save options.
  thissnapshot.xpreprocessing = myobj.interface.getXPreprocessing;
  thissnapshot.ypreprocessing = myobj.interface.getYPreprocessing;
  
  %Get cv.
  thissnapshot.cvi = myobj.interface.getCrossvalidation;
  
  %Get ncomp.
  thissnapshot.ncomp = myobj.interface.getComponents;
  
  %Check calibration status and get modelID if it's calold.
  mystatus = myobj.interface.getCalibrationStatus;
  if strcmp(mystatus,'calold')
    thismodel = myobj.interface.getModel;
    %Add to snapshot.
    thissnapshot.modelID = thismodel.uniqueid;
  end
  
end

%All other meta parameters go into options.
switch opts.functionname
  case {'lwr'}
    if isempty(thismodel)
      %Add a field to options structure for npts.
      opts.npts = myobj.interface.getMetaParameter('npts');
    else
      opts.npts = thismodel.detail.npts;
    end
end

%Save options.
thissnapshot.options = opts;

%Run dub check.
if strcmp(options.warn_duplicates,'on')
  if check_duplicate(myit.snapshots,thissnapshot)
    return
  end
end

%Add to iterator via field name. Do it his way rather than direct
%assignment so can tolerate missing fields.
for myfield = fieldnames(thissnapshot)';
  myit.snapshots(myidx).(myfield{:}) = thissnapshot.(myfield{:});
end

if strcmp(options.add_to_run,'on')
  %Automatically add snapshot to last run.
  myit.modelrun(end).snapshots = add_snapshot(myit.modelrun(end).snapshots,thissnapshot);
end

%myit.snapshots(myidx) = thissnapshot;
omodel.optimizer = myit;

save_optimizer(omodel);

%Update combinations.
combine_snapshots

%--------------------------------------
function drop(h,eventdata,handles,varargin)
%Pass drop to modeloptimizergui.
modeloptimizergui('drop',h,eventdata,handles,varargin{:});

%--------------------------------------
function myid = setdata(mydata)
%Add data to cache and return an id that is saved in the optimizer.
modelcache([],mydata);
myinfo = modelcache('find',mydata);
myid   = myinfo.name;

%--------------------------------------
function parent = add_snapshot(parent,snapshot)
%Add snapthot to a parent (run).

if isempty(parent)
  parent = snapshot;
  return
end

myidx = length(parent);
if ~isempty(parent(myidx).id)
  myidx = myidx+1;
end

for i = fieldnames(snapshot)'
  %Add via field name so can tolerate missing fields. Concate will error if
  %new/missing fields are present.
  parent(myidx).(i{:})=snapshot.(i{:});
end

%--------------------------------------
function move_snapshot(snapshotIDs)
%Move snapshot/s to model runs. If snapshotID is empty, add all current
%snapshots to models.

mymodel = getappdata(0,'evri_model_optimizer');
myit    = mymodel.optimizer;

if nargin==0 | isempty(snapshotIDs)
  snapshotIDs  = {myit.snapshots.id};
end

if ~iscell(snapshotIDs)
  snapshotIDs = {snapshotIDs};
end

%TODO: Iterate through and add snapshots to models.
for i = 1:length(snapshotIDs)
  ssidx = ismember({myit.snapshots.id},snapshotIDs{i});
  if any(ssidx)
    this_snapshot = myit.snapshots(ssidx);
    %Check for duplicates.
    if ~check_duplicate([myit.modelrun.snapshots],this_snapshot)
      %Add model.
      myit.modelrun(end).snapshots = add_snapshot(myit.modelrun(end).snapshots,this_snapshot);
    end
  else
    warning('EVRI:ModeloptimizerNoSnapshot','Can''t locate snapshot, not adding to models.')
  end
end

mymodel.optimizer = myit;
save_optimizer(mymodel);

%--------------------------------------
function clear
%Clear the optimizer out of appdata 0.

setappdata(0,'evri_model_optimizer',[]);

%--------------------------------------
function clear_item(item,myid)
%Clear optimizer or item.

if nargin<2
  myid = [];
end

mymodel = getappdata(0,'evri_model_optimizer');
myit    = mymodel.optimizer;

switch item
  case 'snapshot'
    if isempty(myid)
      myit.snapshots = getemptysnpsh;
    else
      todel = ismember({myit.snapshots.id},myid);
      if any(todel)
        myit.snapshots = myit.snapshots(~todel);
      end
    end
  case 'model'
    if isempty(myid)
      myit.modelrun = getemptyruns;
    else
      todel = ismember({myit.modelrun.snapshots.id},myid);
      if any(todel)
        myit.modelrun.snapshots = myit.modelrun.snapshots(~todel);
      end
    end
    
end

mymodel.optimizer = myit;
save_optimizer(mymodel);

if strcmp(item,'snapshot')
  modeloptimizer('combine_snapshots')
end

%--------------------------------------------------------------------
function snpsh = getemptysnpsh
%Get empty snapshot.
snpsh = make_optimizer;
snpsh = snpsh.snapshots;

%--------------------------------------------------------------------
function mr = getemptyruns
%Get empty snapshot.
mr = modeloptimizer('make_optimizer');
mr = mr.modelrun;

%--------------------------------------
function save_optimizer(mymodel)
%Save optimizer structure to 0.

setappdata(0,'evri_model_optimizer',mymodel);

%--------------------------------------
function mymodel = get_optimizer
%Get optimizer structure.

mymodel = getappdata(0,'evri_model_optimizer');

if isempty(mymodel)
  mymodel = evrimodel('modeloptimizer');
  mymodel.optimizer = make_optimizer;
end

save_optimizer(mymodel);

%--------------------------------------
function myit = make_optimizer
%Make structure of optimizer items.

myit.snapshots(1).id             = [];
myit.snapshots(1).options        = [];
myit.snapshots(1).cvi            = [];
myit.snapshots(1).xpreprocessing = [];
myit.snapshots(1).ypreprocessing = [];
myit.snapshots(1).xdata_cacheid  = [];
myit.snapshots(1).ydata_cacheid  = [];
myit.snapshots(1).ncomp          = [];
myit.snapshots(1).modelID        = [];%ID from modelcahce.
myit.snapshots(1).errormsg       = [];%If empty then no errors.

%Independent
myit.combinations(1).id             = [];
myit.combinations(1).options        = {};
myit.combinations(1).cvi            = {};
myit.combinations(1).xpreprocessing = {};
myit.combinations(1).ypreprocessing = {};
myit.combinations(1).xdata_cacheid  = {};
myit.combinations(1).ydata_cacheid  = {};
myit.combinations(1).ncomp          = [];
%myit.combinations(1).meta(1).name   = '';
%myit.combinations(1).meta(1).value  = {};
myit.combinations(1).hasrun         = 0;

%Run List
myit.modelrun(1).id             = getid;%Might need to change this to empty if we bring back sets.
myit.modelrun(1).run_name       = 'Run 1';%Might need to change this to empty if we bring back sets.
myit.modelrun(1).snapshots      = myit.snapshots(1);
myit.modelrun(1).results        = [];

%--------------------------------------
function myobj = get_guiobj(handles)
%Get gui object.

if isstruct(handles)
  myobj = evrigui(handles.analysis);
else
  myobj = evrigui(handles);
end

%--------------------------------------

function [preds, flags1] =  calculate_preds(xdata, ydata, models)

flags1 = ones(length(models),1);

for i = 1:length(models)
  if ~ismodel(models{i})
    thismodel = modelcache('get',safename(models{i}));
    if ~isempty(thismodel)
      models{i} = thismodel;
      nvar = thismodel.datasource{1}.size(2);
    
      if nvar ~= xdata.size(2)    %Check that the number of variables is correct. 
        flags1(i) = 0;
      end   
   
    else
      %Can't find model in cache so show error. Maybe cache was purged or
      %cache dir changed.
      evrierrordlg('Model not found in modelcache. Cache may have been purged or changed. Try regenerating model or cache directory.','Can''t Locate Model in Cache')
      return
    end
  end
end


modcount = length(models);

preds = cell(modcount,2);
options = modeloptimizer('options');
if strcmp(options.waitbar,'on');
  wh = waitbar(0,'Applying Optimizer Models to Validation Data (Close to Cancel)');
else
  wh = [];
end

for i = 1:modcount
  if ~isempty(wh);
    if ~ishandle(wh)
      %User cancel.
      break
    end
    waitbar(i/modcount,wh);
  end
  try
    
    if flags1(i) ==0
      continue
    end
    
    model = models{i}.apply(xdata,ydata);
    if strcmp('classification', comparemodels('getCategory',model))
      compareOpts = comparemodels('options');
      %[FPR FNR Err P F] (false pos, false neg, classification error, precision, F1)
      falseratespred = comparemodels('getmisclassed', model,0,compareOpts);
      if all(isnan(falseratespred))
        preds = [];
        close(wh)
        return;
      end
      preds{i,2} = falseratespred;
    else
      rmseps = model.detail.rmsep;
      if size(rmseps,2)==1
        rmseps = model.detail.rmsep(:)';  % handle some models like CLS
      else
        rmseps = model.detail.rmsep(:,model.ncomp)';
      end
      preds{i,2} = rmseps;
    end
    preds{i,1} = model.uniqueid;
  catch
    % Ignore error if a model's prediction cannot be found
  end
end

if ~isempty(wh) & ishandle(wh)
  close(wh)
end

%--------------------------------------
function calculate_models(ridx)
%Run models.

options = modeloptimizer('options');
mymodel = get_optimizer;
myit    = mymodel.optimizer;

if nargin<1
  %Use last run.
  ridx = length(myit.modelrun);
end

%See if figure is available to update progress bar.
fig = findobj(allchild(0),'tag','modeloptimizergui');
 

modcount = length(myit.modelrun(ridx).snapshots);
if strcmp(options.waitbar,'on');
  wh = waitbar(0,'Calculating Optimizer Models (Close to Cancel)');
else
  wh = [];
end

%Iterate through run.
for i = 1:modcount
  
  if ~isempty(wh);
    if ~ishandle(wh)
      %User cancel.
      break
    end
    waitbar(i/modcount,wh);
  end
  
  myexst = modelcache('exist',safename(myit.modelrun(ridx).snapshots(i).modelID));%Make sure item is in cache.
  
  if isempty(myit.modelrun(ridx).snapshots(i).id)| myexst{1}
    %If there's no id (empty snapshot) or if it's already been run then just continue.
    continue
  end
  
  %See if model has already been run in other runs. If snapshot ID matches
  %and there's a ModelID then copy ModelID.
  runnext = 0;
  for j = 1:length(myit.modelrun)
    thesemodels = {myit.modelrun(j).snapshots.id};
    thisidx     = find(ismember(thesemodels,myit.modelrun(ridx).snapshots(i).id));
    if ~isempty(thisidx) & ~isempty(myit.modelrun(j).snapshots(thisidx(1)).modelID)
      %Just copy modelid and continue.
      myit.modelrun(ridx).snapshots(i).modelID = myit.modelrun(j).snapshots(thisidx(1)).modelID;
      runnext = 1;
      break
    end
  end
  
  if runnext
    continue;
  end
  
  try
    
    myopts = myit.modelrun(ridx).snapshots(i).options;
    myopts.modeloptimizerID = myit.modelrun(ridx).snapshots(i).id;
    
    model  = evrimodel(myopts.functionname);
    
    %Get data.
    xdat = modelcache('get',myit.modelrun(ridx).snapshots(i).xdata_cacheid);
    ydat = [];
    if ~isempty(myit.modelrun(ridx).snapshots(i).ydata_cacheid)
      ydat = modelcache('get',myit.modelrun(ridx).snapshots(i).ydata_cacheid);
    end
    
    %Add data and preprocessing.
    model.x = xdat;
    if model.isyused
      if isempty(ydat) & isfield(myopts,'modelgroups')
        %no Y but we do have "modelgroups", use that as y
        ydat = myopts.modelgroups;
      end
      model.y = ydat;
    end
    
    myopts.preprocessing = {myit.modelrun(ridx).snapshots(i).xpreprocessing myit.modelrun(ridx).snapshots(i).ypreprocessing};
    myopts.plots = 'none';
    myopts.display = 'off';
    if isfield(myopts,'rawmodel')
      myopts = rmfield(myopts,'rawmodel');
    end
    
    %Options. (copy field-for-field to avoid errors if we have missing
    %fields)
    model = copyoptions(model,myopts);
    
    %All other meta parameters go into options.
    switch lower(myopts.functionname)
      case {'lwr'}
        %Pull npts out of options and add to model.
        model.npts = myopts.npts;
      case {'ann' 'annda'}
        model.nhid = myopts.nhid1;
    end
    
    if isfield(model,'ncomp')%Some models don't have ncomp.
      %Add ncomp or calculate from choosecomp if ncomp is empty.
      if isempty(myit.modelrun(ridx).snapshots(i).ncomp)
        %Get maxlvs from analysis options.
        maxlvs = getfield(analysis('options'),'maximumfactors');
        
        %Create seperate model and get choosecomp results from .ncomp field.
        tempmodel = evrimodel(myopts.functionname);
        tempmodel.x = xdat;
        if tempmodel.isyused
          tempmodel.y = ydat;
        end
        tempmodel = copyoptions(tempmodel,myopts);
        cvi = myit.modelrun(ridx).snapshots(i).cvi;
        try
          tempmodel = tempmodel.crossvalidate(xdat,cvi,maxlvs);
          ncomp = choosecomp(tempmodel);
        catch
          ncomp = [];
        end
        if isempty(ncomp)
          ncomp = 1;
        end
        %Get choosen comp.
        myit.modelrun(ridx).snapshots(i).ncomp = ncomp;
      else
        tempmodel = [];
      end
      
      try
        model.ncomp = myit.modelrun(ridx).snapshots(i).ncomp;
      catch
          % catches the error when attempting to changing .ncomp for MLR
          % and CLS
      end
        
      else
      tempmodel = [];
    end
    
    %Add meta parameters to mode obj. LEVE FOR REFERENCE
    %   for j = 1:length(myit.modelrun(ridx).snapshots(i).meta)
    %     model.(myit.modelrun(ridx).snapshots(i).meta(j).name) = myit.modelrun(ridx).snapshots(i).meta(j).value;
    %   end
    
    %Calibrate.
    model = model.calibrate;
    cvi = myit.modelrun(ridx).snapshots(i).cvi;
    if isnumeric(cvi) | (~isempty(cvi{1}) & ~strcmpi(cvi{1},'none'))%Custom cv or not none.
      %Crossvalidate.
      if ~isempty(tempmodel) & ismodel(tempmodel) & ~model.isclassification
        % Can't copy classification because model.detail.cvclassification
        % won't be copied. 
        %we did crossval when we were choosing ncomp - use those results
        model = copycvfields(tempmodel,model);
        %Add 
      else
        %no crossval results already, do it now
        model = model.crossvalidate(xdat,cvi,myit.modelrun(ridx).snapshots(i).ncomp);
      end
    end
    
    %Cache.
    modelcache(model,{xdat ydat})
    
    %Save id to list.
    myit.modelrun(ridx).snapshots(i).modelID = model.uniqueid;
    myit.modelrun(ridx).snapshots(i).errormsg = [];%Clear error if needed.
    
    if ~isempty(wh) & ~ishandle(wh)
      %User cancel.
      break
    end
    
  catch
    myit.modelrun(ridx).snapshots(i).errormsg = lasterr;
  end
end

if ~isempty(wh) & ishandle(wh)
  close(wh)
end

mymodel.optimizer = myit;

save_optimizer(mymodel);
modelcache(mymodel);

%--------------------------------------
function   model = copyoptions(model,myopts)
%copy options into model/script one field at a time (avoids error
%associated with missing options)

for fyld = fieldnames(myopts)';
  if isfield(model.options,fyld{:})
    model.options.(fyld{:}) = myopts.(fyld{:});
  end
end

%--------------------------------------
function modl = apply(varargin)
%Run model on new data.
%  Make a new model then create model runs from old model and new data.
%
%  INPUTS:

msg = modeloptimizergui('checkcache');
if ~isempty(msg)
  error(msg);
end

%Parse inputs.
xdat    = varargin{1};
mymodel = [];
ydat    = [];
modl    = [];
opts    = [];%Options not used yet but may be passed.

if nargin>1
  switch class(varargin{2});
    case 'dataset'
      ydat    = varargin{2};
    case 'evrimodel'
      mymodel = varargin{2};
    case 'struct'
      opts = varargin{2};
    otherwise
      error(['Unrecognized input (' class(varargin{2}) ') for applying modeloptimizer.'])
  end
end

if nargin>2
  if ismodel(varargin{3})
    mymodel = varargin{3};
  end
end

%If no model then get from appdata(0);
if isempty(mymodel)
  mymodel = get_optimizer;
end
myit = mymodel.optimizer;

%Check for overwrite of model (check to see it's not an empty model).
if ~isempty(mymodel) & ~isempty(mymodel.optimizer.snapshots.id) & ~isempty(mymodel.optimizer.modelrun.snapshots.id)
  myans=evriquestdlg('Clear existing model?', ...
    'Clear Model','Clear','Cancel','Clear');
  switch myans
    case {'Cancel'}
      return
  end
end

%Get new model.
newmodel = evrimodel('modeloptimizer');
newmodel.optimizer = make_optimizer;
newit = newmodel.optimizer;

%NOTE: Will need to sorty out runs in this function if start using them.
ridx = length(myit.modelrun);

%Get dataID.
if ~isempty(xdat)
  xdatid = setdata(xdat);
end

if ~isempty(ydat)
  ydatid = setdata(ydat);
end

%Iterate through run and add new data and remove model ID.
for i = 1:length(myit.modelrun(ridx).snapshots)
  if isempty(myit.modelrun(ridx).snapshots(i).id)
    %If there's no id must be empty snapshot.
    continue
  end
  this_snapshot = myit.modelrun(ridx).snapshots(i);
  
  %Get dataID.
  if ~isempty(xdat)
    this_snapshot.xdata_cacheid = xdatid;
  end
  
  if ~isempty(ydat)
    this_snapshot.ydata_cacheid = ydatid;
  end
  %TODO: Should we create a new ID for the snapshot?
  this_snapshot.modelID = [];
  %Check for duplicates, this might happen if original omodel used more
  %than one dataset.
  if ~check_duplicate([newit.modelrun.snapshots],this_snapshot)
    %newmodels = add_snapshot(newmodels,this_snapshot);
    newit.modelrun(end).snapshots = add_snapshot(newit.modelrun(end).snapshots,this_snapshot);
  end
end

%TODO: Should create new model or write back into model.
newit = combine_runs(newit);
newmodel.optimizer = newit;

save_optimizer(newmodel);

%TODO: Rebuild GUI maybe?
calculate_models

modl = get_optimizer;

%--------------------------------------
function combine_snapshots()
%Scan snapshot structure for unique items in each category and create
%independent "Combinations" list that can be used to create a full
%factorial "run" list of models.

mymodel = get_optimizer;
myit    = mymodel.optimizer;

ignore = {'modelID' 'id'};
fnames = fieldnames(myit.snapshots);
fnames = fnames(~ismember(fnames,ignore));
copts  = comparevars('options');
copts.breakondiff = 1;
newindyvals = [];

cvopts.ignorefield  = {'plots' 'display' 'preprocessing' 'rawmodel' 'blockdetails' 'definitions' 'modeloptimizerID'};
cvopts.breakondiff  = 1;

cvopts_1 = {'cvi' 'cvi_orig'}; % don't compare options.these for ann

wh = waitbar(0,'Finding unique combinations.');
lennms = length(fnames);

% find indices of ann models
optss = {myit.snapshots.options};
snapmodeltypes = cellfun(@(x) lower(x.functionname), optss, 'UniformOutput', false);
isann_flag = ismember(snapmodeltypes, {'ann' 'annda'}); % flag on indices in 1:lenthisf

for i = 1:lennms
  myfield = fnames{i};
  thisuval = [];
  thisfield = {myit.snapshots.(myfield)};
  lenthisf = length(thisfield);
  for j = 1:lenthisf
    waitbar((i/lennms)+(j/(lenthisf*10)),wh,{'Finding unique combinations.' ['Scanning: ' myfield]});
    %find unique values.
    if (strcmp(myfield,'xdata_cacheid') | strcmp(myfield,'ydata_cacheid')) & isempty(thisfield{j})
      continue;
    end
    if strcmp(myfield,'ncomp') & isann_flag(j) % skip compare ncomp for ann
      continue;
    end
    if isempty(thisuval)
      thisuval = thisfield(j);
      continue
    end
    uniqueval = 1;
    for k = 1:length(thisuval)
      if strcmp(myfield,'options')
        if isann_flag(j) % skip compare ncomp for ann, annda,
          opts_1 = cvopts;
          ignorefield_1 = {cvopts.ignorefield{:} cvopts_1{:}};
          opts_1.ignorefield = ignorefield_1;
          uniqueval = ~comparevars(thisuval{k},thisfield{j}, opts_1);
        else
          uniqueval = ~comparevars(thisuval{k},thisfield{j}, cvopts);
        end
      elseif strcmp(myfield,'cvi')
        if ~iscell(thisuval{k}) | strcmp(thisuval{k}{1},'rnd')
          uniqueval = ~comparevars(thisuval{k},thisfield{j});
        else
          uniqueval = ~comparevars(thisuval{k}(1:2),thisfield{j}(1:2));
        end
      else
        uniqueval = ~comparevars(thisuval{k},thisfield{j});
      end
      if ~uniqueval
        break;  %discovered this is NOT unique already, stop testing
      end
    end
    if uniqueval
      thisuval = [thisuval thisfield(j)];
    end
  end
  
  if ~isempty(thisuval)
    newindyvals.(myfield) = thisuval;
  end
end

if ishandle(wh)
  close(wh)
end

%Add new record into independent list.
% myidx = length(myit.combinations);
% if ~isempty(myit.combinations(myidx).id)
%   myidx = myidx+1;
% end
%Uncomment code above if we want to enable sets of combinations. Also
%adjust tree creation code in modeloptimizergui
myidx = 1;

myit.combinations(myidx).id = getid;
for i = fieldnames(newindyvals)'
  myit.combinations(myidx).(i{:})=newindyvals.(i{:});
end

mymodel.optimizer = myit;
save_optimizer(mymodel);

%--------------------------------------
function copy_snapshots(didx,runname)
%Copy all current snapshots to models.

% NOTE: didx and runname not used until multiple snapshots/runs are enabled.

mymodel = get_optimizer;
myit    = mymodel.optimizer;

if nargin<1
  didx = [1:length(myit.snapshots)];
end

if nargin<2
  runname = ['Snapshot Run (' num2str(length(didx)) ' snapshots)'];
end

midx = length(myit.modelrun);
if ~isempty(myit.modelrun(midx).run_name)
  midx = midx+1;
end

myit.modelrun(midx).id        = getid;
myit.modelrun(midx).run_name  = runname;
myit.modelrun(midx).snapshots = myit.snapshots(didx);

myit = combine_runs(myit);

mymodel.optimizer = myit;
save_optimizer(mymodel);

%--------------------------------------
function assemble_combinations(didx,runname)
%Assemble all combinations into models.
% didx = Index of independent tree to run. If empty uses last.
% NOTE: didx and runname not used.

wh = waitbar(0,'Creating models from combinations: Initialize');

mymodel = get_optimizer;
myit    = mymodel.optimizer;

if nargin<1
  didx = length(myit.combinations);
end

if nargin<2
  runname = ['Combinatory Run ' num2str(didx)];
end

ignore = {'hasrun' 'id' 'errormsg'};
fnames = fieldnames(myit.combinations);
fnames = fnames(~ismember(fnames,ignore));

myscales = {};

%If no combo information then don't proceed.
if isempty(myit.combinations(didx).id)
  delete(wh)
  return
end

%Look at first model type and see if y used. May want to test all in
%future but not worrying about it now.
opts = myit.combinations(didx).options;
modlblank = evrimodel(opts{1}.functionname);
isyused   = ~modlblank.isclassification && modlblank.isyused;

waitbar(.25,wh,'Creating models from combinations: Create DOE and factorize');

for i = 1:length(fnames)
  myval = myit.combinations(didx).(fnames{i});
  if strcmp(fnames{i},'xdata_cacheid') | strcmp(fnames{i},'ydata_cacheid') 
    %Check for empty data. 
    myval = myit.combinations(didx).(fnames{i});
    myempty = ~cellfun('isempty',myval);
    mysz = sum(myempty);
    
    if strcmp(fnames{i},'xdata_cacheid') & mysz==0
      evriwarndlg('No X-Block data found in Optimizer model. Add snapshot with X-Block data to create models.', 'Data Not Found')
      if ishandle(wh); delete(wh); end
      return
    end
    
    if (strcmp(fnames{i},'ydata_cacheid') & mysz==0)
      if isyused
        evriwarndlg('No Y-Block data found in Optimizer model. Add snapshot with Y-Block data to create models.', 'Data Not Found')
        if ishandle(wh); delete(wh); end
        return
      else
        mysz = 1;
      end
    end
  else
    %Get length of field.
    mysz = length(myval);
  end

  if mysz==0
    mysz = 1;
  end
  myscales{i} = [1:mysz];
end

%Create fullfactorial doe model and use indexs to assemble snapshot list.
[doe,msg] = doegen('full',fnames,myscales);

midx = length(myit.modelrun);
if ~isempty(myit.modelrun(midx).id)
  midx = midx+1;
end

this_snapshot = [];
myit.modelrun(midx).id       = getid;
myit.modelrun(midx).run_name = runname;

waitbar(.5,wh,'Creating models from combinations: Create models');

doelen = size(doe,1);

original_runs = [myit.modelrun.snapshots];
new_runs = [];
for i = 1:doelen
  this_snapshot.id = getid;
  this_snapshot.modelID = [];
  this_snapshot.errormsg = [];
  for j = 1:length(fnames)
    thisfield = myit.combinations(didx).(fnames{j});
    if isempty(thisfield)
      this_snapshot.(fnames{j}) = [];
    else
      this_snapshot.(fnames{j}) = thisfield{doe.data(i,j)};
    end
  end
  
  % update ann models option.nhid1 using ncomp
  this_snapshot = update_anns(this_snapshot);

  %Don't add if duplicate of any original run, or other new run. Use all runs since we collapse them.
  if ~check_duplicate(original_runs,this_snapshot) & check_include(this_snapshot) & ~check_duplicate(new_runs,this_snapshot)
    this_snapshot.id = getid;
    this_snapshot.modelID = [];
    %Add model.
    myit.modelrun(midx).snapshots = add_snapshot(myit.modelrun(midx).snapshots,this_snapshot);

    % record new runs
    if ~check_duplicate(new_runs,this_snapshot)
      new_runs{end+1} = this_snapshot; 
    end
  end
  if ~isempty(wh) & ~ishandle(wh)
    evrierrordlg('"Add Combinations" Canceled','Add Combindations');
    return
  end
  waitbar(.5+(.5*(i/doelen)),wh)
end

waitbar(1,wh,'Creating models from combinations: Saving optimizer');
myit = combine_runs(myit);

mymodel.optimizer = myit;
save_optimizer(mymodel);

if ishandle(wh); delete(wh); end

%--------------------------------------------------------------------------
function this_snapshot = update_anns(this_snapshot)
% May need to do similarly for other ML models too...
if isfieldcheck(this_snapshot, '.options.functionname') & ismember(lower(this_snapshot.options.functionname), {'ann' 'annda'})
  this_snapshot.ncomp = this_snapshot.options.nhid1; % we don't want to use ncomp meta param, only use option.nhid1
end

%--------------------------------------
function isdup = check_duplicate(slist,snapsht)
%Check for duplicate snapshot in list of snapshots.
% slist = list of snapshots. If slist is type cell and snapsht is struct
%         then compare the cell contents with the struct.
% snapsht = snapshot to be checked.
% isdup = 0/1, 0: differences found; 1: no differences found, is duplicate

opts  = comparevars('options');
opts.ignorefield  = {'id' 'modelID' 'errormsg' 'description' 'options' 'display' 'plots'};
opts.missingfield = 'ignore';
opts.breakondiff  = 1;

isdup = 0;

for j = 1:length(slist)
  if iscell(slist) & isstruct(snapsht)
    mycmp = comparevars(slist{j},snapsht,4,opts);
  else
    mycmp = comparevars(slist(j),snapsht,4,opts);%Returns non-empty if a difference is found.
  end
  %Check everything except options first.
  if isempty(mycmp)
    %No differences found in other fields so now check options.
    sopts = opts;
    sopts.ignorefield  = {'preprocessing'  'display' 'plots'};
    %Preprocessing is pushed out of options and into top level
    %.xpreprocessing field so don't trigger duplicate if
    %options.preprocessing doesn't match. NOTE: We may need more logic here
    %if edge case is found.
    if iscell(slist) & isstruct(snapsht)
      mycmp = comparevars(slist{j}.options,snapsht.options,4,sopts);
    else
      mycmp = comparevars(slist(j).options,snapsht.options,4,sopts);
    end
    if isempty(mycmp)
      %No differences have been found.
      isdup = 1;
      break
    end
  end
end

%--------------------------------------
function out = check_include(snapsht)
%Check if include field for samples matches on X and Y
% snapsht = snapshot to be checked.
% out = 0/1

out = 1;

xid = snapsht.xdata_cacheid;
yid = snapsht.ydata_cacheid;
if isempty(xid) | isempty(yid)
  return
end

xdat = modelcache('get',xid);
ydat = modelcache('get',yid);

if length(xdat.include{1})~=length(ydat.include{1}) | xdat.include{1}~=ydat.include{1}
  out = 0;
end

%--------------------------------------
function myit = combine_runs(myit)
%Combine all runs into one.
%NOTE: Remove this function if we want to re-enable run sets.

myit.modelrun(1).snapshots = [myit.modelrun.snapshots];
myempt = cellfun('isempty',{myit.modelrun(1).snapshots.id});
myit.modelrun(1).snapshots = myit.modelrun(1).snapshots(~myempt);
myit.modelrun = myit.modelrun(1);

%--------------------------------------
function copy_snapshot_newpp(ssidx,newpp)
%Copy a snapshot with updated preprocessing.
% ssidx - index of snapshot to use.
% newpp - nx2 cell array of proprocessing structures to add. Fist column is
%         x-block and second column is y-block.

% NOTE: Not using didx and runname at all so update this if those are
% enabled. 
mymodel = get_optimizer;
myit    = mymodel.optimizer;

this_ss = myit.snapshots(ssidx);

msg = 'Checking for duplicate preprocessing... [Close to Skip]';
wh = waitbar(0,msg);
pplen = length(newpp);
pplenstr = num2str(pplen);
duplicatsfound = 0;
for i = 1:size(newpp,1)
  new_ss = myit.snapshots(ssidx);
  new_ss.id = getid;
  new_ss.xpreprocessing = newpp{i,1};
  if ~isempty(newpp{i,2});
    new_ss.ypreprocessing = newpp{i,2};
  end
  
  if ~check_duplicate(myit.snapshots,new_ss)
    myit.snapshots(end+1) = new_ss;
  else
    duplicatsfound = duplicatsfound + 1;
  end
  if ~ishandle(wh)
    break
  else
    waitbar(i/pplen,wh,{msg ['Preprocessing: ' num2str(i) '/' pplenstr] ['Duplicates Found: ' num2str(duplicatsfound)]});
  end
end

if ishandle(wh)
  close(wh)
  drawnow
end

mymodel.optimizer = myit;
save_optimizer(mymodel);
combine_snapshots
%--------------------------------------
function out = getid
%Get unique id.

out = num2str(now+rand,'%10.10f');


%--------------------------------------------------------------------
function [mymodel,xid,yid] = getcacheitems(myitem,itemkind,handles)
%Get model and data IDs.

mymodel = [];
xid = [];
yid = [];
cacheitmes = modelcache('find',safename(myitem));
mymodel    = modelcache('get',safename(myitem));

if isempty(cacheitmes)
  %Nothing returned from cache.
  %error('Cache item not available for loading. Not items can be loaded.')
  return
end

pdat = [];
pmod = [];
%Make sure dataID is correct x/y order.
for i = 1:length(cacheitmes.links)
  if isempty(pdat)
    pdat = modelcache('getinfo',cacheitmes.links(i).target);%Pdat can be empty if you're loading a model from someone else. Looks like it should be in the cahce but it's not.
    if ~isempty(pdat) & strcmp(pdat.type,'data')
      pdat = modelcache('get',cacheitmes.links(i).target);
      if strcmp(pdat.name,mymodel.datasource{1}.name)
        %Pdat{1} is xblock;
        xid = cacheitmes.links(i).target;
      else
        yid = cacheitmes.links(i).target;
      end
    end
  else
    if isempty(xid)
      xid = cacheitmes.links(i).target;
    else
      yid = cacheitmes.links(i).target;
    end
  end
end

%--------------------------------------
function test

f = analysis;

modeloptimizer('clearoptimizer')

modeloptimizer('snapshot',f)

modeloptimizer('snapshot',f)

modeloptimizer('apply')

myit = getappdata(0,'evri_model_optimizer');

comparemodels({myit.snapshots.modelID})


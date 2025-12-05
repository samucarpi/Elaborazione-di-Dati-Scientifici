function menuCallback(obj,menuobj,eventdata,menutype,callid)
%MENUCALLBACK Callback from menu selection.

%Copyright Eigenvector Research, Inc. 2017
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

mygraph = obj.graph;
if nargin<5
  %Don't have callid, must be calling from context menu. Get callid from
  %graph.
  callid = '';
  mycell = mygraph.Graph.getSelectionCell;
  if ~isempty(mycell)
    callid = char(mycell.getId);
  end
end

if strcmpi(menutype,'mainsave')
  %Spoof save menu call.
  menutype = 'save';
  callid = 'SlaveModel';
end

switch menutype
  case 'load'
    rawdata = [];
    loadsettings = {'double' 'dataset'};%Default is loading data.
    if ismember(callid,{'MasterModel' 'TransferModel'})
      loadsettings = {'struct' 'evrimodel'};
    end
    %Load item.
    [rawdata,name,location] = lddlgpls(loadsettings,['Select ' upper(callid) ' Data']);
    if isempty(rawdata)
      return
    end
    obj.loadItem(callid,rawdata,eventdata)
    updateWindow(obj)
  case 'edit'
    %TODO: Need to save after edit and clear things out.
    try
      myds = obj.(callid);
      if ~isempty(myds)
        editds(myds)
      end
    end
  case 'view'
    switch callid
      case {'SlaveModel' 'MasterModel'}
        if strcmp(callid,'SlaveModel')
          modl = obj.SlaveModel; 
        else
          modl = obj.MasterModel;
        end
        
        if isfield(modl,'loads')
          info = [modlrder(modl)';ssqtable(modl,size(modl.loads{2,1},2))'];
        else
          try
            info = modlrder(modl)';
          catch
            return
          end
        end
        infofig = infobox(info,struct('openmode','reuse','figurename','Model Details'));
        infobox(infofig,'font','courier',getdefaultfontsize);
        setappdata(infofig,'analysisblockmode','model')
        
      case {'calmasterp1' 'calmasterp2'}
        
      case 'TransferModel'
        h = caltransfergui;
        hdls = guihandles(h);
        %Set prepro.
        mypp = obj.makePriorPreprocessing(obj.MasterModel,obj.PreprocessingInsertInd);
        myopts = getappdata(hdls.caltransfergui,'options');
        myopts.preprocessing = {mypp mypp};
        setappdata(hdls.caltransfergui,'options',myopts)
        caltransfergui('x1load_Callback',[], [], hdls, obj.CalibrationMasterXData)
        caltransfergui('x2load_Callback',[], [], hdls, obj.CalibrationSlaveXData)
        caltransfergui('ctm_load_Callback',[], [], hdls, obj.TransferModel)
      otherwise
      myds = obj.(callid);
      if ~isempty(myds)
        editds(myds)
      end
    end
    
  case 'save'
    mydata = [];
    switch callid
      case {'SlaveModel' 'modelslave'}
        mydata = obj.SlaveModel;
        myname = 'SlaveModel';
      case 'slaveppdata'
        mydata = obj.getPreprocessedSlaveDataInd;%Get data for current pp insert index.
        myname = 'ProcessedSlaveData';
      case 'mccttoolobject'
        mydata = copy(obj);
        myname = 'MCCTToolObject';
      otherwise
        mydata = obj.(callid);
        myname = callid;
    end
    
    if ~isempty(mydata)
      [what,where] = svdlgpls(mydata,['Save ' upper(callid) ' Data'],myname);
      if ~isempty(what) & strcmp(callid,'SlaveModel')
        %Keep track of models that have been saved to avoid unnecessary
        %save. Save to appdata on fig so it's only persistent per window
        %not saved in object.
        savedmods = getappdata(obj.figure,'SavedModels');
        savedmods{end+1} = mydata.uniqueid;
        setappdata(obj.figure,'SavedModels',unique(savedmods));
      end
    else
      evriwarndlg(['Model or data not available for ' upper(callid) '.'],'Empty Item');
    end
  case 'buttonclick'
    switch callid
      case {'zoomwin' 'zoomin' 'zoomout' 'zoomdefault'}
        myview  = mygraph.GraphComponent.getGraph.getView;
        compLen = mygraph.GraphComponent.getWidth;
        viewLen = myview.getGraphBounds.getWidth;
        myscale = myview.getScale;
        switch callid
          case 'zoomwin'
            myview.setScale(compLen/viewLen * myview.getScale * .9);
          case 'zoomin'
            myview.setScale(myscale+.1)
          case 'zoomout'
            myview.setScale(myscale-.1)
          case 'zoomdefault'
            myview.setScale(1);
        end
      case 'calcmodel'
        if obj.getCanCalculate
          %Get current Slave Model will calcualte current model if not
          %already done. This callback is for when you load a custom CalT
          %model manually.
          obj.SlaveModel;
          obj.applyAllModels;
          obj.makeAllValidationResults;
          %Update results.
          obj.compareSlaveModels(0);
          %Update table.
          obj.forceUpdateTable = true;
          %Update window to refresh table.
          obj.updateWindow;
          %Make sure correct slave model is loaded into interface.
          tableCallback(obj,[],[]);
        end
      case 'setinsertpp'
        %Prompt user for prepro insert.
        curppinds = obj.preproinsertinds;
        
        newppinds = inputdlg({['Specify location/s to insert calibration transfer preprocessing steps. '...
          'Value of 0 indicates prior to all preprocessing. More than one location can be set (e.g., "0 1 2").']},...
          'Preprocess Insert Indexes',1,{num2str(curppinds)});
        if isempty(newppinds)
          return
        end
        
        newppinds = str2num(newppinds{:});
        newppidns = newppinds(newppinds>=0);
        
        if ~isempty(newppinds)
          obj.preproinsertinds = newppidns;
        end
      case 'maketable'
        
        newtbl = obj.ResultsTable;
        assignin('base','MCCTResultsTable',newtbl);
        openvar('MCCTResultsTable');
      case 'setopts'
        outopts = optionsgui(obj.MCCTToolOptionalInputs);
        if ~isempty(outopts)
          obj.OptoinalInputsMCCTTool = outopts;
          obj.updateWindow;
        end
        
    end
    
  case 'calccombo'
    %Click on combos button.
    
    mycombos = getCombos(guihandles(obj.figure));
    if ~isempty(mycombos)
      try
        %Add combos.
        obj.CalibrationTransferCombinations = mycombos;
        %Calculate all models.
        obj.makeSlaveModelInd(obj.preproinsertinds);
        %Update table.
        obj.forceUpdateTable = true;
        %Update window to refresh table.
        obj.updateWindow;
        %Make sure correct slave model is loaded into interface.
        tableCallback(obj,[],[]);
      catch
        if obj.isvalid 
          erdlgpls({'Unable to calculate models. Try clearing results and adjust paramters.' lasterr},[upper(mfilename) ' Error']);
        end
      end
    end
  case 'setinsertpp'
    %Prompt user for prepro insert.
    curppinds = obj.preproinsertinds;
    
    newppinds = inputdlg({['Specify location/s to insert calibration transfer preprocessing steps. '...
      'Value of 0 indicates prior to all preprocessing. More than one location can be set (e.g., "0 1 2").']},...
      'Preprocess Insert Indexes',1,num2str(curppinds));
    if isempty(newppinds)
      return
    end
    
    newppinds = num2str(newppinds);
    newppidns = newppinds(newppinds>=0);
    
    if ~isempty(newppinds)
      obj.preproinsertinds = newppidns;
    end
  case 'clear'
    
    switch callid
      case 'clearall'
        obj.clearAllData;
        obj.sourceInfo = MCCTTool.makeEmptySourceInfo;
      case 'clearresults'
        obj.clearAllResults;
        obj.sourceInfo = MCCTTool.makeEmptySourceInfo;
    end
    obj.forceUpdateTable = true;%Force a table update.
    obj.updateWindow;
  case 'refresh'
    obj.updateWindow(1);
  case 'delete'
    switch callid
      case ''
        
      otherwise
        obj.(callid) = [];
    end
    obj.updateWindow;
  case 'mainclose'
    close(obj.mainFigure);%Calls initialize/closeGUI sub function.
  case 'plot'
    if strcmp(callid,'ValidationResults')
      myres = obj.ValidationResults;
      plotgui('new',myres,'plotby',2,'viewdiag',1);
    end
    
  case 'options'
    outopts = optionsgui(obj.MCCTToolOptionalInputs);
    if ~isempty(outopts)
      obj.OptoinalInputsMCCTTool = outopts;
      obj.updateWindow;
    end
    
  case {'columnselect'}
    select_columns_Callback(obj,callid)
    obj.forceUpdateTable = true;
    obj.updateWindow
    
  case 'help'
    switch callid
      case 'mainhelp'
        evrihelp('MCCTTool')
      case 'demo'
        [masterpls_model, mp6trans, mp5trans, starchtrans, mp6spec, mp5spec, starch_ds] = MCCTObject.getdemodata;
        obj.CalibrationMasterXData = mp6trans;
        obj.CalibrationSlaveXData = mp5trans;
        obj.CalibrationYData = starchtrans;
        obj.MasterModel = masterpls_model;
        obj.ValidationMasterXData = mp6spec;
        obj.ValidationSlaveXData = mp5spec;
        obj.ValidationYData = starch_ds;
        obj.updateWindow;
    end
end

end

%--------------------------------------------------------------------
function mycombos = getCombos(handles)
%Get combos from settings panel. Used in caltransfer.m
%
% methodcombos - nx5 cell array (modelType, parameterName, min, step, max)
mycombos = [];

if get(handles.ds,'value')
  mycombos = [mycombos; {'ds' '' [] [] []}];
end

if get(handles.pds,'value')
  mycombos = [mycombos; {'pds' 'win' getNum(handles.win_1) getNum(handles.win_step) getNum(handles.win_2)}];
end

if get(handles.dwpds,'value')
  mycombos = [mycombos; {'dwpds' 'win1' getNum(handles.win1_1) getNum(handles.win1_step) getNum(handles.win1_2)}];
  mycombos = [mycombos; {'dwpds' 'win2' getNum(handles.win2_1) getNum(handles.win2_step) getNum(handles.win2_2)}];
end

if get(handles.sst,'value')
  mycombos = [mycombos; {'sst' 'ncomp' getNum(handles.ncomp_1) getNum(handles.ncomp_step) getNum(handles.ncomp_2)}];
end

end

%--------------------------------------------------------------------
function myNum = getNum(hh)
%Get string and make number.
  myNum = str2num(get(hh,'String'));
end

%--------------------------------------------------------------------
function select_columns_Callback(obj,mymenu)
%Select columns to include/exclude and order.

mytbl = obj.currentResultsTable;
thislist = mytbl(1,:);

gopts = obj.MCCTToolOptionalInputs;

ecol = gopts.exclude_columns;
% icol = gopts.include_columns;
% icol = setdiff(icol,ecol);%Don't allow exluded items in include.

switch mymenu
  case 'include'
    %NOT USED
    mylist = setdiff(thislist,ecol);
    [newlist,btn] = listchoosegui(mylist,icol);
    if strcmp(btn,'ok')
      gopts.include_columns = newlist;
    end
  case 'exclude'
    [newlist,btn] = listchoosegui(thislist,ecol);
    if strcmp(btn,'ok')
      gopts.exclude_columns = newlist;
    end
end

obj.MCCTToolOptionalInputs = gopts;
end

classdef MCCTObject < handle & hgsetget
  %MCCTOBJECT Holds all elemets for modelcentric calibration transfer.
  % Object has the properties:
  %   Models:
  %     MasterModel   - Calibration model developed on master instrument.
  %     SlaveModel    - Model derived from master model with CalTranfer step
  %                     inserted into master preprocessing structure array
  %                     with pp steps prior to insertion points removed.
  %                     Looks up or creates a model via .makeSlaveModel.  
  %     TransferModel - CalibrationTransfer model to be inserted into
  %                     SlaveModel. Developed in GUI.
  %     CalibrationTransferCombinations - Matrix of calibration transfer
  %                                       model settings to use nx5 cell
  %                                       (modelType, parameterName, Min, Step, Max)
  %
  %   Data:
  %     CalibrationMasterXData - Calibration X DataSet for master instrument.
  %     CalibrationSlaveXData  - Calibration X DataSet for slave instrument.
  %     CalibrationYData       - Calibration Y DataSet for both master and slave (for regression models).
  %
  %     ValidationMasterXData  - Validation X DataSet for master instrument.
  %     ValidationSlaveXData   - Validation X DataSet for slave instrument.
  %     ValidationYData        - Validation Y DataSet for both master and slave (for regression models).
  %
  %   Other properties:
  %     PreprocessingInsertInd - Preprocessing step of master model to
  %                              insert calTransfer step after in slave
  %                              model. If 0 then instered as first PP step.
  %
  %   Key Methods:
  %     .makeSlaveModelInd(PreProInds) - Creates all models for given
  %                                      prepro step (PreProInds). Input
  %                                      should be one or more integers.
  %     .compareSlaveModels(useFigure) - Compares all (cal) predictions and
  %                                      show other statistics. Optional
  %                                      boolean input will create figure
  %                                      with table of results.
  %   Key Static Methods:
  %     .makeSlaveModel - Takes master model, preprocess insert position,
  %                       and cal transfer model and creats a slave model.
  %
  %   Supported Model Types:
  %     PCA PLS PCR LWR CLS MLR ANN SVM
  %
  %     
  %I/O: MCCTObject();
  %
  %See also: CALTRANSFER, CALTRANSFERGUI, MCCTTool
  
  %Copyright Eigenvector Research, Inc. 2016
  %Licensee shall not re-compile, translate or convert "M-files" contained
  % in PLS_Toolbox for use with any software other than MATLAB®, without
  % written permission from Eigenvector Research, Inc.
  
  
  % Feature Ideas:
  %  Allow specral difference comparison right after all PP done.
  %  Human readalbe names for datasets.
  %  Compare prediction error on test if there.
  %  Concatenate results/pp data for plot. Need classes? Flush out
  %    more and ask Barry. Should be Master vs slave as well as other
  %    options.
  %  Allow multible Calt mehtods.
  
  % Object works in 2 modes, first mode has a single calt model and allows
  % you to try different insert point. Second mode creates all combinations
  % of a given setup. Workflow would be to survey model combinations then
  % fine tune the calt model and insert point.
  
  % Use Case 1 (develop calt model prior):
  %   - Develop calt model outside of object/interface.
  %   - Load data, master model, and caltransfer model into object.
  %   - Create slave model (maybe at several different pp insert points)
  %   - Look at results.
  %   - Export new slave model.
  
  % Use Case 2 (develop calt model inside):
  % - Load data and master model.
  % - Create combos of caltransfer models to try (saved in seperate property of object)
  % - Create slave models from combos
  % - Create all predictions from saved models
  % - Ajust insert pp index
  % - Look at results and decide best caltransfer model.
  % - Export best slave model.
  
  %Questions for Bob:
  %  - If using case 1, overwriting single calt model (with .set) won't
  %    delete any previous models. Should it?
  %  - How to choose samples? Use include?
  %  - Variable matching will be done in caltransfer?
  
  %TODO: Should "custom" models be indicated in saved results.
  %TODO: Some kind of results display.
  %TODO: Send roundup of progress and commit so it can be played with.
  
  properties (Dependent = true)
    %Seperate out properties so it's easier to change in future. All data,
    %models, and meta data are dependent props.
    
    %Data
    CalibrationMasterXData;
    CalibrationSlaveXData;
    CalibrationYData;
    
    ValidationMasterXData;
    ValidationSlaveXData;
    ValidationYData;
    
    %Models
    MasterModel
    SlaveModel
    TransferModel %Default
    
    %Validation results.
    ValidationResults
    
    %Prepro Insert Index Default
    PreprocessingInsertInd
    
    %Save models.
    AllSlaveModelData
    
    %Options
    MCCTObjectOptionalInputs
    
    %Matrix of calibration transfer model settings to use.
    % nx5 cell - modelType parameterName Min Step Max
    CalibrationTransferCombinations
    
    %Results from combinations.
    SavedCombinations
    
    %Compared model resutls table.
    ResultsTable
    
    %Use waitbar when in makeSlaveModelInd creating all slave models.
    UseWaitbar
    
  end
  
  properties (Access = private)
    %Main properties.
    
    %Models
    MasterCalModel
    SlaveCalModel
    SlaveTransferModel
    
    %Cal data.
    MasterCalXData
    SlaveCalXData
    CalYData
    
    %Val data.
    MasterValXData
    SlaveValXData
    ValYData
    
    %Insert point.
    PreproInsertInd = 0;
    
    %Validation results (getValidationResultsData) if validation data is
    %loaded these results are calculated.
    ValResultsData
    
    %Cache of slave models.
    SavedResults = struct('PPInsertIndex',[],...
      'TransferModelType',[],...
      'TransferModelParameters',struct('name','','value',[]),...
      'SlaveModelID',[],...
      'SlaveModel',[],...
      'SlavePredID',[],...
      'SlavePred',[],...
      'ValPred',[],...
      'ValResultsData',[]);
    
    %Save results from model compare.
    SavedCompareTable
    
    %Matrix of calibration transfer model settings to use.
    % nx5 cell - modelType parameterName Min Step Max
    CalTCombinations = cell(5,1);
    
    %Structure that comes from caltransfer.m. Has calt model and
    %transferred data and diff results.
    SavedCombinationResults = [];
    
    %Options
    OptoinalInputsMCCTObject = [];
    
    %Selection of plots available.
    PlotSelection = '';
    
    %Figure handle for plot.
    PlotFigure = [];
    
    %Plot data.
    PlotData = [];
    
    %Last Plot Selection
    PlotLast = '';
    
    %Plotting Info
    PlottedTimeStamps
    LastPlotted
    
    %Using waitbar.
    addwaitbar = 0;
  end
  
  methods
    function obj = MCCTObject(varargin)
      %Set any incoming properties.
      set(obj,varargin{:});
    end
    
    % Calibration data.
    function set.CalibrationMasterXData(obj,val)
      obj.MasterCalXData = obj.adjustvars(val,obj.MasterModel);
      clearAllResults(obj)
    end
    
    function val = get.CalibrationMasterXData(obj)
      val = obj.MasterCalXData;
    end
    
    function set.CalibrationSlaveXData(obj,val)
      obj.SlaveCalXData = obj.adjustvars(val,obj.MasterModel);
      clearAllResults(obj)
    end
    
    function val = get.CalibrationSlaveXData(obj)
      val = obj.SlaveCalXData;
    end
    
    function set.CalibrationYData(obj,val)
      obj.CalYData = val;
      clearAllResults(obj)
    end
    
    function val = get.CalibrationYData(obj)
      val = obj.CalYData;
    end
    
    % Validation data.
    function set.ValidationMasterXData(obj,val)
      obj.MasterValXData = obj.adjustvars(val,obj.MasterModel);
    end
    
    function val = get.ValidationMasterXData(obj)
      val = obj.MasterValXData;
    end
    
    function set.ValidationSlaveXData(obj,val)
      obj.SlaveValXData = obj.adjustvars(val,obj.MasterModel);
    end
    function val = get.ValidationSlaveXData(obj)
      val = obj.SlaveValXData;
    end
    
    function set.ValidationYData(obj,val)
      obj.ValYData = val;
    end
    
    function val = get.ValidationYData(obj)
      val = obj.ValYData;
    end
    
    % Options
    function set.MCCTObjectOptionalInputs(obj,val)
      obj.OptoinalInputsMCCTObject = val;
    end
    
    function val = get.MCCTObjectOptionalInputs(obj)
      if isempty(obj.OptoinalInputsMCCTObject)
        %Can't use defualt in property definition because only gets called
        %once per session. New options won't get used until next session.
        obj.OptoinalInputsMCCTObject = MCCTObject.getDefaultOptions('options');
      end
      val = obj.OptoinalInputsMCCTObject;
    end
    
    % Restults
    function val = get.ResultsTable(obj)
      val = obj.SavedCompareTable;
    end
    
    function set.ResultsTable(obj,val)
      obj.SavedCompareTable = val;
    end
    
    function val = get.ValidationResults(obj)
      %Look up validation results from saved results.
      val = [];
      myres = obj.lookupModelResults;
      if ~isempty(myres) & ~isempty(myres.ValResultsData)
        val = myres.ValResultsData;
      end
    end
    
    function set.ValidationResults(obj,val)
      error('Set ValidationResults not supported.')
    end
    
    %Combinations
    function set.CalibrationTransferCombinations(obj,val)
      %Matrix of calibration transfer model settings to use.
      % nx5 cell - modelType parameterName Min Step Max
      if iscell(val) & size(val,2)==5
        obj.CalTCombinations = val;
      else
        error('Calibration model combinations must be nx5 cell array')
      end
    end
    
    function val = get.CalibrationTransferCombinations(obj)
      val = obj.CalTCombinations;
    end
    
    function val = get.SavedCombinations(obj)
      val = obj.SavedCombinationResults;
    end
    
    % Model data.
    function set.MasterModel(obj,val)
      %Set master model.
      
      %Check for supported type.
      if ismember(lower(val.modeltype),obj.supportedModelTypes)
        if ismember(lower(val.modeltype),{'pls' 'pcr' 'cls' 'mlr' 'anndl'}) &...
            val.datasource{2}.include_size(2) > 1
          %Check for multivariate Y.
          error(['Only univariate Y regression models are accepted for MCCT.']);
        end
        obj.MasterCalModel = val;
        
        %Align variables if they haven't been already
        obj.MasterCalXData = obj.adjustvars(obj.MasterCalXData,val);
        obj.MasterValXData = obj.adjustvars(obj.MasterValXData,val);
        obj.SlaveCalXData = obj.adjustvars(obj.SlaveCalXData,val);
        obj.SlaveValXData = obj.adjustvars(obj.SlaveValXData,val);
        
        %Need to clear any saved slave models if new model loaded. Don't need
        %to clear tranfer models.
        clearAllResults(obj)
      else
        error(['Models of type: [' val.modeltype '] are not supported by MCCTObject. See MCCTObject.supportedModelTypes']);
      end
    end
    
    function val = get.MasterModel(obj)
      val = obj.MasterCalModel;
    end
    
    function val = get.AllSlaveModelData(obj)
      val = obj.SavedResults;
    end
    
    function set.SlaveModel(obj,val)
      warning('EVRI:MCCTObject','A secondary model cannot be set. It will be automatically generated from primary model.');
    end
    
    function slave_model = get.SlaveModel(obj)
      %Create slave model from master model, transfer model and insert
      %point. Will look up saved model and calculate a new model if not
      %created yet.
      slave_model = [];
      if ~isempty(obj.MasterCalModel) & ~isempty(obj.SlaveTransferModel)
        %Check for saved model.
        slave_model = findSlaveModel(obj);
        if isempty(slave_model)
          %Insert tmodel into master to create slave.
          slave_model = obj.makeSlaveModel(obj.MasterCalModel,obj.PreproInsertInd,obj.SlaveTransferModel);
          
          %Save model to cache.
          obj.SavedResults(end+1).PPInsertIndex = obj.PreproInsertInd;
          obj.SavedResults(end).TransferModelType = obj.SlaveTransferModel.transfermethod;
          obj.SavedResults(end).TransferModelParameters = obj.getCalTStructure(obj.SlaveTransferModel);
          obj.SavedResults(end).SlaveModelID = slave_model.uniqueid;
          obj.SavedResults(end).SlaveModel = slave_model;
          obj.SavedResults(end).SlavePred = [];
          obj.SavedResults(end).ValResultsData = [];
          obj.SavedResults(end).ValPred = [];
          obj.SavedResults(end).ValResultsData = [];
        else
          return
        end
        
      else
        return;
      end
    end
    
    function set.TransferModel(obj,val)
      %TODO: Add check to make sure this is a CalT model.
      obj.SlaveTransferModel = val;
      %Don't delete any models if overwrite single transfer model.
    end
    
    function val = get.TransferModel(obj)
      val = obj.SlaveTransferModel;
    end
    
    % Preprocessing insert at.
    function set.PreprocessingInsertInd(obj,val)
      %Set preprocessing default insert at value. Checks for max and min.
      if ~isscalar(val) | val<0
        %Must be scalar >= 0.
        val = 0;
      end
      
      maxinsert = getMaxPreprocessingInsertInd(obj);
      if isempty(maxinsert)
        maxinsert = 0;
      end
      
      if val<=maxinsert
        obj.PreproInsertInd = val;
      else
        warning('EVRI:MCCTObject',['Max PreprocessingInsertInd Value Exceeded - Replacing with max (' num2str(maxinsert) ')'])
        obj.PreproInsertInd = maxinsert;
      end
      
    end
    
    function val = get.PreprocessingInsertInd(obj)
      val = obj.PreproInsertInd;
    end
        
    % Use waitbar.
    function set.UseWaitbar(obj,val)
      obj.addwaitbar = val;
    end
    
    function val = get.UseWaitbar(obj)
      val = obj.addwaitbar;
    end
    
    %- - - - - - - - - - - - - -
    %Other Methods (not set/get)
    function setModelTo(obj,modelid)
      %Set current slave model, pp index, and calt model to existing model.
      %Use private props so as not to cause updates before complete.
      myrec = lookupModelResults(obj,modelid);
      if ~isempty(myrec)
        obj.SlaveCalModel = myrec.SlaveModel;
        obj.SlaveTransferModel = obj.getCalTModleFromSlave(myrec.SlaveModel);
        obj.PreproInsertInd = myrec.PPInsertIndex;
      end
    end
    
    function val = getMaxPreprocessingInsertInd(obj)
      %Number of preprocessing steps in Master Model.
      %Empty equals no model and 0 equals no preprocessing.
      val = [];
      m = obj.MasterModel;
      if ~isempty(m)
        pp = m.detail.options.preprocessing{1};
        val = length(pp);
      end
    end
    
    function clearAllResults(obj)
      %Clear both saved slave models and calibration transfer models. Cal
      %transfer models may include preprocessing from a master model
      %(depending on pp insert index).
      obj.SavedResults = [];
      obj.SavedCombinationResults = [];
      obj.TransferModel = [];
      obj.SavedCompareTable = [];
      obj.ValResultsData = [];
    end
    
    function clearAllData(obj)
      %Clear all loaded data and results.
      
      obj.clearAllResults;
      
      %Models.
      obj.MasterCalModel = [];
      obj.SlaveCalModel = [];
      obj.SlaveTransferModel = [];
      
      %Cal data.
      obj.MasterCalXData = [];
      obj.SlaveCalXData = [];
      obj.CalYData = [];
    
      %Val data.
      obj.MasterValXData = [];
      obj.SlaveValXData = [];
      obj.ValYData = [];
      
    end
    
    function savedmod = findSlaveModel(obj,varargin)
      %Find a saved model based on PP insert index and either CalT model or
      %CalT model type and parameters. Input order is:
      % (OnlyModel, PreProIndex, TransferMethod, TransferMethodParams)
      %Input 'TransferModel' can be model or struct.
      
      savedmod = [];
      
      [OnlyModel,PreProIndex,TransferMethod,TransferMethodParams] = checkInputs(obj,varargin{:});
      
      %All results in structure:
      %  PPInsertIndex,TransferModelType,TransferModelParameters (substruct),SlaveModel,ResultData
      myresults = obj.SavedResults;
      if isempty(myresults)
        return
      end
      
      %Find subset based on PPIndex.
      thisresult = myresults([myresults.PPInsertIndex]==PreProIndex);
      if isempty(thisresult)
        return
      end
      
      %Find subset based on Calt Method.
      thisresult = thisresult(ismember({thisresult.TransferModelType},TransferMethod));
      if isempty(thisresult)
        return
      end
      
      %DS model has no parameters so cut here if DS.
      if strcmpi(TransferMethod,'ds')
        savedmod = thisresult;%Should only be one model.
        if OnlyModel
          savedmod = savedmod.SlaveModel;
        end
      end
      
      %Now thisresult should only include results with same pp index and
      %same transfer method. Now look for parameters.
      for i = 1:length(thisresult)
        for j = 1:length(thisresult(i).TransferModelParameters)%Sing set of params from result set.
          valuecheck = 0;
          for k = 1:length(TransferMethodParams)%Single set of params being searched for.
            %Locate param name being seached.
            pnameidx =  ismember({thisresult(i).TransferModelParameters.name},TransferMethodParams(k).name);
            if any(pnameidx) & thisresult(i).TransferModelParameters(pnameidx).value==TransferMethodParams(k).value
              valuecheck(k) = 1;
            else
              valuecheck(k) = 0;
            end
          end
          if all(valuecheck)
            %All parameters being searched for were found in thisresult.
            savedmod = thisresult(i);
            if OnlyModel
              savedmod = savedmod.SlaveModel;
            end
            break
          end
        end
      end
    end
    
    function slavedata = getPreprocessedSlaveDataInd(obj,varargin)
      %Get slave data with proprocessing applied at given insert point.
      slavedata = [];
      
      makeSlaveModelAt(obj,varargin{:});%Confirm model exists.
      slave_model = findSlaveModel(obj,varargin{:});
      
      if isempty(slave_model)
        return
      else
        slavedata = obj.CalibrationSlaveXData;
        sppx = slave_model.preprocessing{1};
      end
      slavedata = preprocess('apply',sppx,slavedata);
      slavedata.userdata = sppx;
    end
    
    function newmodel = makeSlaveModelAt(obj,varargin)
      %Creates a slave model at a particular pp insert point for given
      %parameters.
      
      %See if model already exists.
      newmodel = obj.findSlaveModel(varargin{:});
      
      if ~isempty(newmodel)
        return
      end
      
      %Get cal transfer model parameters and search for existing calT model
      %based on varargin.
      [OnlyModel,PreProIndex,TransferMethod,TransferMethodParams] = checkInputs(obj,varargin{:});
      
      if isempty(TransferMethod)
        %There may not be an existing (custom) calt model.
        warning('EVRI:MCCTObject',['No transfer method defined. Load transfer model or define/create transfer model combinations.'])
        return
      end
      
      %Get transfer model if it exists.
      savedcaltmod = findCalTransferModel(obj,PreProIndex,TransferMethod,TransferMethodParams);
      
      if isempty(savedcaltmod)
        %Need to build cal transfer model.
        if ~isempty(obj.CalibrationMasterXData) & ~isempty(obj.CalibrationSlaveXData)
          coptions = caltransfer('options');
          %Get preprocessing for insert ind.
          %sppx = obj.makePriorPreprocessing(obj.MasterCalModel,obj.PreproInsertInd);
          %coptions.preprocessing = {sppx sppx};
          %FIXME: If more than one parameter is used the code below will
          %need to be updated.
          switch TransferMethod
            case 'pds'
              coptions.pds.win = [TransferMethodParams.value];
            case 'dwpds'
              coptions.dwpds.win = [TransferMethodParams.value];
            case 'sst'
              coptions.sst.ncomp = [TransferMethodParams.value];
            case 'ds'
              %Nothing to do.
            otherwise
              error(['Transfer method ' TransferMethod ' not recognized.'])
          end
          %[savedcaltmod] = caltransfer(obj.CalibrationMasterXData,obj.CalibrationSlaveXData,TransferMethod,coptions);
          savedcaltmod = obj.makeCalTransferModel(TransferMethod,coptions);
        else
          error('Can''t make secondary model without primary and secondary data.')
        end
      end
      
      %Add cal transfer model to object.
      obj.SlaveTransferModel = savedcaltmod;
      
      %Update insert pp index.
      obj.PreproInsertInd = PreProIndex;
      
      obj.SlaveModel;%Calling get.SlaveModel creates a model and saves it.
      
    end
    
    function makeSlaveModelInd(obj,PreProIndex)
      %For given prepro index, create all cal transfer models and slave
      %models.
      
      modcount = length(PreProIndex);
      if obj.addwaitbar;
        wh = waitbar(0,'Calculating Secondary Models (Close to Cancel)');
      else
        wh = [];
      end
      try
        for i = 1:length(PreProIndex)
          obj.PreprocessingInsertInd = PreProIndex(i);
          obj.makeAllCalTransferCombinations;
          obj.makeAllSlaveModels;
          if ~isempty(wh);
            if ~ishandle(wh)
              %User cancel.
              break
            end
            waitbar((i/modcount)*.5,wh);
          end
        end
        waitbar(.75,wh,'Applying models.');
        obj.applyAllModels;
        waitbar(.85,wh,'Calculating validation results.');
        obj.makeAllValidationResults;
        waitbar(.95,wh,'Calculating model results.');
        obj.compareSlaveModels(0);
      catch
        if ~isempty(wh) & ishandle(wh)
          close(wh)
        end
        rethrow(lasterror)
      end
      if ~isempty(wh) & ishandle(wh)
        close(wh)
      end
    end
    
    function makeAllValidationResults(obj)
      %Make all validation results for saved models.
      for i = 1:length(obj.SavedResults)
        obj.SavedResults(i).ValResultsData = getValidationResultsData(obj,false,obj.SavedResults(i).SlaveModel.uniqueid);
      end
    end
    
    function applyAllModels(obj)
      %Run through all models in obj.SavedResults and creates predictions.
      
      for i = 1:length(obj.SavedResults)
        slave_model = obj.SavedResults(i).SlaveModel;
        if isempty(obj.SavedResults(i).SlavePred)
          %No pred so create.
          
          if ~isempty(obj.SlaveCalXData)
            if slave_model.isyused
              %Y block being used.
              obj.SavedResults(i).SlavePred = slave_model.apply(obj.SlaveCalXData,obj.CalYData);
              obj.SavedResults(i).ValResultsData = [];
            else
              %Create single block pred.
              obj.SavedResults(i).SlavePred = slave_model.apply(obj.SlaveCalXData);
              obj.SavedResults(i).ValResultsData = [];
            end
            obj.SavedResults(i).SlavePredID = obj.SavedResults(i).SlavePred.uniqueid;
          end
        end
        
        if isempty(obj.SavedResults(i).ValPred)
          if ~isempty(obj.SlaveValXData)
            if slave_model.isyused
              %Y block being used.
              obj.SavedResults(i).ValPred = slave_model.apply(obj.SlaveValXData,obj.ValYData);
            else
              %Create single block pred.
              obj.SavedResults(i).ValPred = slave_model.apply(obj.SlaveValXData);
            end
          end
        end
      end
    end
    
    function makeAllSlaveModels(obj)
      %Make all models for current prepro index.
      
      %Below will create a model with current cal transfer model. Do this in
      % case there is a "custom" cal transfer model loaded in
      % .SlaveTransferModel?
      %No, can't do this. If you update PP insert index and calt combos
      % then run .makeSlaveModelAt it may take an old calT model and use it
      % for new PP index. Caused a problem in beta testing.
      %obj.makeSlaveModelAt;
      
      %Make all models that are defined in combinatins.
      mycombos = obj.SavedCombinationResults;
      for i = 1:length(mycombos)
        obj.makeSlaveModelAt(1,obj.PreproInsertInd,mycombos(i).method,obj.getCalTStructure(mycombos(i).model));
      end
      
    end
    
    function applyAllSlaveModels(obj)
      %Create all slave models for given transfermodel at all insert
      %poitns.
      maxinsert = getMaxPreprocessingInsertInd(obj);
      for i = 0:maxinsert
        applySlaveModelAt(obj,i)
      end
      
    end
    
    function makeAllCalTransferCombinations(obj)
      %Make all combinations of calt models for loaded data.
      
      if isempty(obj.MasterCalXData) | isempty(obj.SlaveCalXData) ...
          | isempty(obj.CalTCombinations)
        %Can't calculate.
        warning('EVRI:MCCTObject','Missing items for creating combinations. Primary data, secondary data, and combinations cell array required')
        return
      end
      
      %Get structure of results.
      %calt_results = caltransfer(obj.MasterCalXData,obj.SlaveCalXData,obj.CalTCombinations,coptions);
      calt_results = obj.makeCalTransferModel('combo');
      
      %This isn't a very elegant way of doing this but we don't know number
      %of combos until caltransfer is done so can't prealocate.
      toadd_caltmodels = [];
      for i = 1:length(calt_results)
        %Check for existing and if not present then add.
        savedcaltmod = obj.findCalTransferModel(obj.PreproInsertInd,calt_results(i).method,calt_results(i).model);
        if ~isempty(savedcaltmod)
          continue
        end
        calt_results(i).PPInsertIndex = obj.PreproInsertInd;
        toadd_caltmodels = [toadd_caltmodels calt_results(i)];
      end
      obj.SavedCombinationResults = [obj.SavedCombinationResults toadd_caltmodels];
    end
    
    function out = lookupModelResults(obj,modelid)
      %Look up results based on modelid. If modelid is numeric then
      %result will be straight index using modelid.
      
      out = [];
      if nargin<2 | isempty(modelid)
        %Use current model.
        curmodl = obj.SlaveModel;
        if ~isempty(obj.SlaveModel)
          modelid = obj.SlaveModel.uniqueid;
        else
          return
        end
      end
      sr = obj.SavedResults;
      
      if isempty(sr)
        return
      end
      
      if ~ischar(modelid)
        myidx = modelid;
      else
        myidx = ismember({sr.SlaveModelID},modelid);
        if ~any(myidx)
          %Look in predid.
          myidx = ismember({sr.SlavePredID},modelid);
        end
      end
      
      if any(myidx)
        out = sr(myidx);
      end
      
    end
    
    function mymod = getSlaveModelAt(obj,modelid)
      %Get a slave model based on modelid.
      mymod = [];
      myrec = lookupModelResults(obj,modelid);
      if ~isempty(myrec)
        mymod = myrec.SlaveModel;
      end
    end
    
    function savedcaltmod = findCalTransferModel(obj,ppidx,method,pname,pvalue)
      %Find saved caltransfer model based on method and parameter. Inputs
      %'method' and 'pname' are strings, 'pvalue' is numeric. This method
      %will need to be updated if more parameters are used in caltransfer
      %model creation.
      %
      % NOTE: This only searches combinations and not the "current" model.
      % Including the "current" transfer model leads to problems because
      % it's not necessarily related to a pp index.
      
      savedcaltmod = [];
      
      if isempty(method)
        return
      end
      
      if isstruct(pname) | ismodel(pname)
        %Parameter structure (as returned by checkInputs) was given so expand to pname/value.
        [pname,pvalue] = obj.getCalTParams(pname);
      end
      
      myresults = obj.SavedCombinations;
      if isempty(myresults)
        return
      end
      
      %Find calt models with correct PP index.
      pvalidx = arrayfun(@(x) isequal(x.PPInsertIndex,ppidx), myresults);
      thisresult = myresults(pvalidx);
      if isempty(thisresult)
        return
      end
      
      %Find subset based on Calt Method.
      thisresult = thisresult(ismember({thisresult.method},method));
      if isempty(thisresult)
        return
      end
      
      %Stop here if DS model.
      if strcmp(method,'ds')
        savedcaltmod = thisresult.model;
        return
      end
      
      %Since each model only has one parameter (window or ncomp) we only
      %need to search the pvalue. This will need to be updated if more than
      %one paramter is used.
      pvalidx = arrayfun(@(x) isequal(x.parameter_value,pvalue), thisresult);
      thisresult = thisresult(pvalidx);
      if isempty(thisresult)
        return
      end
      
      %There shouldn't be more than one calt model with the same combo so
      %double check and warn if one is found. Take first one and continue.
      if length(thisresult)>1
        warning('EVRI:MCCTObject',['More than one calibration transfer model round for combination (' ...
          method ', ' pname '=' num2str(pvalue) '). First model being selected.'])
        thisresult = thisresult(1);
      end
      savedcaltmod = thisresult.model;
    end
    
    function results = getValidationResultsData(obj,force,modelid)
      %Calculate results dataset for validation. If second input 'force' is
      %true then won't try lookup of saved results.
      
      results = [];
      missingitems = 0;%Flag for missing data or models.
      if isempty(obj.ValidationMasterXData)|isempty(obj.ValidationSlaveXData)
        missingitems = 1;
      end
      
      if nargin<2
        force = false;
      end
      
      if nargin<3
        modelid = [];
      end
      
      myres = [];
      if ~isempty(modelid)
        myres = obj.lookupModelResults(modelid);
      end
      
      %Look up results.
      if ~force
        if ~isempty(myres)
          results = myres.ValResultsData;
          if ~isempty(results)
            return
          end
        end
      end
      
      mm = obj.MasterModel;
      if isempty(mm)
        missingitems = 1;
      end
      
      if ~isempty(myres)
        ppidx = myres.PPInsertIndex;
        sm = myres.SlaveModel;
      else
        ppidx = obj.PreproInsertInd;
        sm = obj.SlaveModel;
      end
      
      if ~isempty(sm)
        cm = obj.getCalTModleFromSlave(sm);
      else
        missingitems = 1;
      end
      
      if missingitems
        %warning('EVRI:MCCTObject','Data and or model missing for calulating validation results. Try loading data and calculating a slave model.')
        return
      end
      
      
      ps_ops = plotscores('options');
      ps_ops.sct = 0;
      ps_ops.reducedstats = {'q' 't2'};
      
      %TODO: Needs to work without ValidationMasterXData.
      master_pred = mm.apply(obj.ValidationMasterXData);
      master_scores = master_pred.plotscores(ps_ops);
      
      %DIR - Direct apply of Master to slave validation data.
      slave_dir_pred = mm.apply(obj.ValidationSlaveXData);
      slave_dir_scores = slave_dir_pred.plotscores(ps_ops);
      
      slave_pred = sm.apply(obj.ValidationSlaveXData);
      slave_scores = slave_pred.plotscores(ps_ops);
      
      lbls = str2cell(master_scores.label{2,1});
      diag_inds = find(~cellfun('isempty', strfind(lower(lbls), 'reduced')))';
      
      scores_inds = find(~cellfun('isempty', strfind(lower(lbls), 'scores')))';
      
      %Get result data for regression models.
      
      pred_ind = find(~cellfun('isempty', strfind(lower(lbls), 'predicted')))';
      results = [master_scores(:, [diag_inds scores_inds pred_ind])...
        slave_dir_scores(:, [diag_inds scores_inds pred_ind])...
        slave_scores(:, [diag_inds scores_inds pred_ind])];
      var_lables = results.label{2};
      labelprefixlen = length([diag_inds scores_inds pred_ind]);
      
      %Augment source of data (master or slave). Labels are exact
      %duplicate so add prefix.
      labelprefix = reshape(repmat({'[Primary] ' '[Secondary DIR] ' '[Secondary] '},[labelprefixlen 1]),[labelprefixlen*3,1]);
      var_lables = [strvcat(labelprefix{:}) var_lables];
      results.label{2} = var_lables;      
      
      master_pp = obj.makePriorPreprocessing(mm,ppidx);
      master_val_pp = preprocess('apply', master_pp, obj.ValidationMasterXData);
      slave_dir_val_pp = preprocess('apply', master_pp, obj.ValidationSlaveXData);
      slave_val_ct = cm.apply(obj.ValidationSlaveXData);
      
      % now augment results with
      temp = dataset([rmse(master_val_pp.data', slave_dir_val_pp.data')'...
        rmse(master_val_pp.data',slave_val_ct.data')']);
      temp.label{2} = {'RMSE Diff Primary PP' 'RMSE Diff Cal T'};
      temp2 = [];
      if ~isempty(obj.ValidationYData) & mm.isyused
        %Add actual y to last column.
        temp2 = obj.ValidationYData(:,mm.include{2,2});
        temp2.label{2} = {'Y Reference'};
      end
      results = [results temp temp2];
      
      
      
      results.name = ['Validation Summary Results (PPIDX=' num2str(ppidx) ',CalTransMethod=' cm.transfermethod ')'];
      [pname,pval] = obj.getCalTParams(cm);
      mydescrpt = {['Validation Results'];...
                   ['Parent Model = ' mm.uniqueid];...
                   ['Secondary Model = ' sm.uniqueid];...
                   ['Preprocess Insert Index = ' num2str(ppidx)];...
                   ['Transfer Method = ' cm.transfermethod];...
                   ['Transfer Parameter Name = ' pname];...
                   ['Transfer Paramter Value = ' num2str(pval)]};
      results.description = mydescrpt;
    end
    
    function compareSlaveModels(obj,makefigure)
      %Run comparemodels on slave predictions.
      % SavedResults (struct with fields):
      %   'PPInsertIndex'
      %   'TransferModelType'
      %   'TransferModelParameters'
      %   'SlaveModel'
      %   'SlavePred'
      %   'ValPred'
      %   'ValResultsData'
      %
      % Diff calc pseudo code from Bob:
      % Master cal xfer data = CT_m
      % Slave cal xfer data = CT_s
      % Apply any pp prior to insert point to data. Copy only if zero.
      % CT_m_pp = preprocess(?apply?, MMpp(through_insertion_point,CT_m)
      % CT_s_pp = preprocess(?apply?, MMpp(through_insertion_point,CT_s)
      %
      % CT_s_CT = caltransfermodel.appl(CT_s)
      
      %diff1 = calcdifference(CT_m_pp,CT_s_pp)%Difference between Master and Slave data with preprocessing up to insert point and with out CT. 
      %diff2 = calcdifference(CT_m_pp,CT_s_CT)%As above but with CT.
      
      %TODO: Create RMSEC1, RMSE of Y values and mastermodel.apply(CT_s). Comparing Y from apply of Master Model with no modifications to Y of "Slave Model" 
      %TODO: Single column replicate.
      
      if isempty(obj.MasterCalModel)
        warning('EVRI:MCCTObject','No Primary Model available, results can''t be calculated. Load Primary Model.');
        return
      end
      
      slavepred = obj.MasterModel.apply(obj.SlaveCalXData);
      rmsec_1 = [];
      if ~isempty(obj.CalibrationYData)
        rmsec_1 = rmse(obj.CalibrationYData.data,slavepred.pred{2});
      end
      
      mastervalpred = [];
      if ~isempty(obj.ValidationMasterXData)
        if ~isempty(obj.ValidationYData)
          mastervalpred = obj.MasterModel.apply(obj.ValidationMasterXData,obj.ValidationYData);
        else
          mastervalpred = obj.MasterModel.apply(obj.ValidationMasterXData);
        end
      end
      
      %Master cal xfer data = CT_m
      %Slave cal xfer data = CT_s
      %Apply any pp prior to insert point to data. Copy only if zero.
      %CT_m_pp = preprocess(?apply?, MMpp(through_insertion_point,CT_m)
      %CT_s_pp = preprocess(?apply?, MMpp(through_insertion_point,CT_s)
      %
      %CT_s_CT = caltransfermodel.appl(CT_s)
      
      %diff1 = calcdifference(CT_m_pp,CT_s_pp)%Difference between Master and Slave data with preprocessing up to insert point and with out CT. 
      %diff2 = calcdifference(CT_m_pp,CT_s_CT)%As above but with CT.
      
      sr = obj.SavedResults;
      
      if isempty(sr)
        return
      end
      
      %Make DIFF_1 Diff between master and slave with preprocessing applied up to insert point.
      curinds = unique([sr.PPInsertIndex]);
      diff1result = [];
      for i = 1:length(curinds)
        %CT_m_pp = preprocess(?apply?, MMpp(through_insertion_point,CT_m)
        diff1result(i).ind = curinds(i);
        masterpp_prior = obj.makePriorPreprocessing(obj.MasterModel,curinds(i));
        masterdata_prior = preprocess('apply',masterpp_prior,obj.CalibrationMasterXData);
        slavedata_prior = preprocess('apply',masterpp_prior,obj.CalibrationSlaveXData);
        diff1result(i).diff = calcdifference(masterdata_prior,slavedata_prior);
      end
      
      mymodels = {sr.SlavePred};
      mymodels = mymodels(~cellfun('isempty',mymodels));
      
      [columnkeys columnlabels tablevalues] = comparemodels(mymodels);
      mycols = ismember(columnkeys,{'preprox' 'uniqueid'});
      
      %TODO: Make each paramter a seperate column with NaN where not used.
      mycol = {};
      mycolname = {};
      for i = 1:length(sr)
        mycol{i,1} = sr(i).PPInsertIndex;
        mycol{i,2} = sr(i).TransferModelType;

        %Calibration diff ratio.
        masterpp = obj.MasterModel.detail.preprocessing{1};
        slavepp  = sr(i).SlaveModel.preprocessing{1};
        masterdata_masterpp = preprocess('apply',masterpp,obj.CalibrationMasterXData);
        slavedata_masterpp = preprocess('apply',masterpp,obj.CalibrationSlaveXData);
        slavedata_caltpp = preprocess('apply',slavepp,obj.CalibrationSlaveXData);
        
        %Master data should be first argument.
        nocalt_diff = calcdifference(masterdata_masterpp,slavedata_masterpp);
        withcalt_diff = calcdifference(masterdata_masterpp,slavedata_caltpp);
        
        mycol{i,3} = withcalt_diff/nocalt_diff;
        
        mycol{i,4} = [];
        
        if ~isempty(obj.ValidationMasterXData) & ~isempty(obj.ValidationSlaveXData)
          %Validation diff ratio
          masterdata_masterpp = preprocess('apply',masterpp,obj.ValidationMasterXData);
          slavedata_masterpp = preprocess('apply',masterpp,obj.ValidationSlaveXData);
          slavedata_caltpp = preprocess('apply',slavepp,obj.ValidationSlaveXData);
          
          mycol{i,4} = withcalt_diff/nocalt_diff;
        end
        
        rmsc1 = [];
        rmsc2 = [];
        rmsc3 = [];
        rmsc4 = [];
        rmsc5 = [];
        rmsc6 = [];
        
        mmpred = obj.MasterModel.apply(obj.CalibrationMasterXData,obj.CalibrationYData);
        
        %For single block models use the following for RMSE:
        %Tm = scores from master instrument through model
        %Ts = scores from slave instrument through transformed model
        %m = number of samples - sr(i).SlavePred.ncomp
        %k = number of pcs - sr(i).SlavePred.datasource{1}.size(1)
        %RMSE = sqrt(sum(sum((Tm-Ts).^2))/(m*k))
         
        
        try
          %RMSE(CalS,CalM)
          if obj.MasterModel.isyused
            rmsc1 = rmse(sr(i).SlavePred.pred{2},mmpred.pred{2});
          else
            %rmsc1 = mean(rmse(sr(i).SlavePred.scores,mmpred.scores));
            rmsc1 = calcdifference(dataset(mmpred.scores),dataset(sr(i).SlavePred.scores));
            %rmsc1 = sqrt(sum(sum((mmpred.scores-sr(i).SlavePred.scores).^2))/(sr(i).SlavePred.ncomp*sr(i).SlavePred.datasource{1}.size(1)));
          end
        end
        try
          %RMSE(CalS,CalY)
          rmsc2 = rmse(sr(i).SlavePred.pred{2},obj.CalibrationYData.data(:,obj.MasterModel.include{2,2}));
        end
        try
          %RMSE(CalM,CalY)
          rmsc3 = rmse(mmpred.pred{2},obj.CalibrationYData.data(:,obj.MasterModel.include{2,2}));
        end
        try
          %RMSE(ValS,ValM)
          if obj.MasterModel.isyused
            rmsc4 = rmse(sr(i).ValPred.pred{2},mastervalpred.pred{2});
          else
            rmsc4 = calcdifference(dataset(mastervalpred.scores),dataset(sr(i).ValPred.scores));
            %rmsc4 = sqrt(sum(sum((mastervalpred.scores-sr(i).ValPred.scores).^2))/(sr(i).ValPred.ncomp*sr(i).ValPred.datasource{1}.size(1)));
          end
        end
        try
          %RMSE(ValS,ValY)
          rmsc5 = rmse(sr(i).ValPred.pred{2},obj.ValidationYData.data(:,obj.MasterModel.include{2,2}));
        end
        try
          %RMSE(ValM,ValY)
          rmsc6 = rmse(mastervalpred.pred{2},obj.ValidationYData.data(:,obj.MasterModel.include{2,2}));
        end
        
        mycol{i,5} = rmsc1;
        mycol{i,6} = rmsc2;
        mycol{i,7} = rmsc3;
        mycol{i,8} = rmsc4;
        mycol{i,9} = rmsc5;
        mycol{i,10} = rmsc6;
        
        %mycol{i,4} = calcdifference(slavedata_caltpp,masterdata_masterpp);
        %mydiff = diff1result(ismember([diff1result.ind],sr(i).PPInsertIndex));
        %mycol{i,4} = (mydiff.diff-(calcdifference(slavedata_caltpp,masterdata_caltpp)))/mydiff.diff;
        for j = 1:length(sr(i).TransferModelParameters)
          
          thiscolname = [upper(sr(i).TransferModelType) '_' upper(sr(i).TransferModelParameters(j).name)];
          colpos = ismember(mycolname,thiscolname);
          if any(colpos)
            mycol{i,10+find(colpos)} = sr(i).TransferModelParameters(j).value;
          else
            %Make new column.
            mycolname = [mycolname thiscolname];
            mycol{i,end+1} = sr(i).TransferModelParameters(j).value;
          end
        end
      end
      
      %Combine comparemodels.m output with calculated columns.
      tablevalues = [mycol tablevalues(:,mycols)];
      if obj.MasterModel.isyused
        rmslabel = {'RMSE(CalS,CalM)' 'RMSE(ValS,ValM)'};
      else
        rmslabel = {'Cal Diff Scores' 'Val Diff Scores'};
      end
      columnlabels = [{'PP Index' 'TransferType' 'Cal Diff Data' 'Val Diff Data' ...
      rmslabel{1}, 'RMSE(CalS,CalY)', 'RMSE(CalM,CalY)',...
      rmslabel{2}, 'RMSE(ValS,ValY)', 'RMSE(ValM,ValY)'} mycolname columnlabels(mycols)];
      
      obj.SavedCompareTable = [columnlabels; tablevalues];
      
      if makefigure
        f = figure;
        t = uitable(f,'Data',tablevalues,'units','normalized','ColumnName',columnlabels,'FontSize',14);
        t.Position = [0 0 1 1];
      end
    end
    
    function savedcaltmod = makeCalTransferModel(obj,method,coptions)
      %Make a cal transfer model for given method and parameters. Need to
      %apply preprocessing seperately, outside of caltransfer call, so
      %preprocessing is "applied" and not "calibrated". This will allow
      %MasterModel preprocessing to be used without re-calibrating.
      
      if nargin<3
        coptions = caltransfer('options');
      end
      
      sppx = obj.makePriorPreprocessing(obj.MasterCalModel,obj.PreproInsertInd);
      
      temp_master = obj.CalibrationMasterXData;
      temp_slave = obj.CalibrationSlaveXData;      
      
      if ~isempty(sppx)
        temp_master = preprocess('apply',sppx,temp_master);
        temp_slave = preprocess('apply',sppx,temp_slave);
      end
      
      if strcmpi(method,'combo')
        method = obj.CalibrationTransferCombinations;
      end
      
      [savedcaltmod] = caltransfer(temp_master,temp_slave,method,coptions);
      
      %Since preprocessing was applied outside of caltransfer need to add
      %it to the model. NOTE: as stated above, we do this so master model
      %prepro is "applied" and not "recalibrated" when building a new
      %transfer model.
      
      if ~ismodel(savedcaltmod) %Assume structure, note: isstruct returns true if is model.
        %Update pp in each model from survey.
        for i = 1:length(savedcaltmod)
          savedcaltmod(i).model.options.preprocessing = {sppx sppx};
          savedcaltmod(i).model.detail.preprocessing = {sppx sppx};
        end
      else
        %Model object saves pp in 2 places. Not sure why but we should
        %change both so it doesn't confuse things. The .detail version
        %seems to be the one that is used.
        savedcaltmod.options.preprocessing = {sppx sppx};
        savedcaltmod.detail.preprocessing = {sppx sppx};
      end
    end
    
    function canCalc = getCanCalculate(obj)
      %Can a Slave Model be calculated. Used by MCCTool.
      canCalc = 0;
      
      if ~isempty(obj.MasterCalModel) & ...
          ~isempty(obj.SlaveTransferModel) & ...
          ~isempty(obj.MasterCalXData) & ...
          ~isempty(obj.SlaveCalXData)
        canCalc = 1;
        if obj.MasterCalModel.isyused & isempty(obj.CalYData)
          canCalc = 0;
        end
      end
      
    end
    
    function setdisp(obj)
      %Override so doesn't automatically display fields.
    end
    
    function getdisp(obj)
      %Override so doesn't automatically display fields.
    end
    
    function disp(obj)
      %Custom display.
      
      disp(' ')
      disp('Model Centric Calibrations Transfer Object (MCCTOBJECT)')
      disp('-------------------------------------------------------')
      disp('* = required')
      disp(' ')
      dmessage = {};
      dmessage(end+1,:) = {'DATA: ' ' '};
      dmessage(end+1,:) = {' ' ' '};
      
      datastatus = 'empty';
      if ~isempty(obj.CalibrationMasterXData)
        datastatus = obj.CalibrationMasterXData.sizestr;
      end
      dmessage{end+1,1} = ' *CalibrationMasterXData: ';
      dmessage{end,2} = datastatus;
      
      datastatus = 'empty';
      if ~isempty(obj.CalibrationSlaveXData)
        datastatus = obj.CalibrationSlaveXData.sizestr;
      end
      dmessage{end+1,1} = ' *CalibrationSlaveXData: ';
      dmessage{end,2} = datastatus;
      
      datastatus = 'empty';
      if ~isempty(obj.CalibrationYData)
        datastatus = obj.CalibrationYData.sizestr;
      end
      dmessage{end+1,1} = '  CalibrationYData: ';
      dmessage{end,2} = datastatus;
      
      datastatus = 'empty';
      if ~isempty(obj.ValidationMasterXData)
        datastatus = obj.ValidationMasterXData.sizestr;
      end
      dmessage{end+1,1} = '  ValidationMasterXData: ';
      dmessage{end,2} = datastatus;
      
      datastatus = 'empty';
      if ~isempty(obj.ValidationSlaveXData)
        datastatus = obj.ValidationSlaveXData.sizestr;
      end
      dmessage{end+1,1} = '  ValidationSlaveXData: ';
      dmessage{end,2} = datastatus;
      
      datastatus = 'empty';
      if ~isempty(obj.ValidationYData)
        datastatus = obj.ValidationYData.sizestr;
      end
      dmessage{end+1,1} = '  ValidationYData: ';
      dmessage{end,2} = datastatus;
      dmessage(end+1,:) = {' ' ' '};
      dmessage(end+1,:) = {'MODELS: ' ' '};
      dmessage(end+1,:) = {' ' ' '};
      
      datastatus = 'empty';
      if ~isempty(obj.MasterCalModel)
        datastatus = obj.MasterCalModel.description{1};
      end
      dmessage{end+1,1} = ' *MasterCalModel: ';
      dmessage{end,2} = datastatus;
      
      datastatus = 'empty';
      if ~isempty(obj.MasterCalModel) & ~isempty(obj.SlaveTransferModel)
        datastatus = obj.MasterCalModel.description{1};
      end
      dmessage{end+1,1} = '  SlaveCalModel: ';
      dmessage{end,2} = datastatus;
      
      datastatus = 'empty';
      if ~isempty(obj.SlaveTransferModel)
        datastatus = ['Calibration Transfer Model (' upper(obj.SlaveTransferModel.transfermethod) ')'];
      end
      dmessage{end+1,1} = ' *SlaveTransferModel: ';
      dmessage{end,2} = datastatus;
      
      dmessage(end+1,:) = {' ' ' '};
      
      datastatus = 'empty';
      if ~isempty(obj.PreprocessingInsertInd)
        datastatus = num2str(obj.PreprocessingInsertInd);
      end
      
      dmessage(end+1,:) = {'SAVED MODELS: ' ' '};
      dmessage(end+1,:) = {' ' ' '};
      
      datastatus = 'empty';
      if ~isempty(obj.SavedResults)
        datastatus = num2str(length(obj.SavedResults));
      end
      dmessage{end+1,1} = '  No. Secondary Models: ';
      dmessage{end,2} = datastatus;
      
      datastatus = 'empty';
      if ~isempty(obj.SavedCombinationResults)
        datastatus = num2str(length(obj.SavedCombinationResults));
      end
      dmessage{end+1,1} = '  No. CalTransfer Combos: ';
      dmessage{end,2} = datastatus;
      
      dmessage(end+1,:) = {' ' ' '};
      
      datastatus = 'empty';
      if ~isempty(obj.PreprocessingInsertInd)
        datastatus = num2str(obj.PreprocessingInsertInd);
      end
      
      dmessage{end+1,1} = 'Insert At: ';
      dmessage{end,2} = datastatus;
      
      %Concat and write out.
      a = strvcat(dmessage{:,1}); %#ok<*DSTRVCT>
      b = strvcat(dmessage{:,2});
      disp([a b])
    end
    
    
    function [OnlyModel,PreProIndex,TransferMethod,TransferMethodParams] = checkInputs(obj,varargin)
      %Inputs are in order:
      % OnlyModel - [boolean] If retrieving just a model or entire results structure. Some mehtods may not use this but it must be passed.
      % PreProIndex - [integer] Index of where to insert caltransfer model into slave model.
      % TransferMethod - [string] Name of mthod.
      % TransferMethodParams - [struct] Structure of paramters (see .getCalTStructure)
      
      if nargin<2 | isempty(varargin{1})
        %Only return model, not whole result structure.
        OnlyModel=1;
      else
        OnlyModel = varargin{1};
      end
      
      if nargin<3 | isempty(varargin{2})
        PreProIndex = obj.PreproInsertInd;%PreproInsertInd should always have a value.
      else
        PreProIndex = varargin{2};
      end
      
      if nargin<4
        TransferMethod = [];
        if ~isempty(obj.SlaveTransferModel)
          TransferMethod = obj.SlaveTransferModel.transfermethod;
        end
      else
        TransferMethod = varargin{3};
      end
      
      %Convert CalT model to struct for seaching.
      if nargin<5
        TransferMethodParams = [];
        if ~isempty(obj.SlaveTransferModel)
          TransferMethodParams = obj.getCalTStructure(obj.SlaveTransferModel);
        end
      else
        TransferMethodParams = varargin{4};
      end
    end
    
  end
  %========================================================================
  methods (Static)
    function options = getDefaultOptions(varargin)
      options = [];
      if nargin==1 & ischar(varargin{1}) & ~ismember(varargin{1},evriio([],'validtopics'))
        %Not valid evriio call.
        return
      elseif nargin==0
        varargin{1} = 'options';
      end
      options.display = 'off';
      
      if nargout==0
        evriio(mfilename,varargin{1},options)
      else
        options = evriio(mfilename,varargin{1},options);
      end
    end
    
    function options = options(varargin)
      %This is shorthand for options. May not be needed.
      options = MCCTObject.getDefaultOptions(varargin{:});
    end
    
    function modeltypes = supportedModelTypes(varargin)
      %Get list of supported model types.
      modeltypes = {'pca' 'pls' 'pcr' 'lwr' 'cls' 'mlr' 'ann' 'svm' 'anndl' 'xgb'};
    end
    
    function myparams = getCalibrationTransferModelParams(modeltype)
      %Get list of calibration transfer model parameters. If no model type
      %pasted then all model parameters are returned.
      myparams = {'pds'   'win'      'Window (PDS):';
        'dwpds' 'win1'    'Window 1 (DWPDS):' ;
        'dwpds' 'win2'    'Window 2 (DWPDS):' ;
        'sst'   'ncomp'   'Ncomp (SST):' ;
        };
      if nargin > 0
        myloc = ismember(myparams(:,1),lower(modeltype));
        if any(myloc)
          myparams = myparams(myloc,:);
        else
          myparams = [];
        end
      end
      
    end
    
    function [combodesc,combos] = getPlotCombos
      %list of plots and how to title them
      combodesc = {'Primary Instrument' 'Secondary Instrument' 'Primary Instrument Transferred' 'Secondary Instrument Transferred' 'Pre-Transfer Difference' 'Post-Transfer Difference' 'Change in Primary Instrument' 'Change in Secondary Instrument'};
      combos = {1 2 3 4 [1 2] [3 4] [3 1] [4 2]};
    end
    
    function slaveModel = makeSlaveModel(MasterModel,PreProIndex,CalTModel)
      %Create a slave model from master model, insert index, and
      %calibration transfer model.
      %Insert tmodel into master to create slave.
      slaveModel = copymodel(MasterModel);
      calt_pp     = MCCTObject.getTransferModelPreprocessing(CalTModel);
      spp         = slaveModel.detail.preprocessing;
      sppx        = spp{1};%New slave pp struct.
      
      if PreProIndex == 0
        sppx = [calt_pp sppx];
      else
        sppx = [calt_pp sppx(PreProIndex+1:end)];
      end
      spp{1} = sppx;
      
      %Model object saves pp in 2 places. Not sure why but we should
      %change both so it doesn't confuse things. The .detail version
      %seems to be the one that is used.
      slaveModel.options.preprocessing = spp;
      slaveModel.detail.preprocessing = spp;
    end
    
    function caltm = getCalTModleFromSlave(SlaveModel)
      %Get cal transfer model from a slave model.
      caltm = [];
      mypp = SlaveModel.preprocessing{1};
      caltpp = mypp(ismember({mypp.keyword},'caltransfer'));
      if ~isempty(caltpp)
        caltm = caltpp.userdata.calt_model;
      end
    end
    
    function sppx = makePriorPreprocessing(MasterModel,PPIndex)
      %Pull preprocessing from master model prior to insert index.
      sppx = [];
      if ~isempty(MasterModel)
        %Pull preprocessing from Master Model and add any proprocessing to
        %calt options that's prior to insert point.
        mpp = MasterModel.detail.preprocessing{1};
        %Carry over preprocessing steps.
        if PPIndex ~= 0
          sppx = mpp(1:PPIndex);
        end
      end
    end
    
    function caltpp = getTransferModelPreprocessing(TransferModel)
      %Get prepro structure from saved transfer model.
      caltpp    = [];
      if ~isempty(TransferModel)
        caltpp = caltransferset('default');
        %Insert the CalT model.
        caltpp.userdata.calt_model = TransferModel;
      end
      
    end
    
    function calppstruct = getCalTStructure(TransferModel)
      %Get structure of parameters from caltmodel for saving in
      %SavedResults. We use this structure to allow for mulitple parameters
      %in the future. It's technically not needed in this first iteration
      %but the plan is to implement more parameters in the near future.
      calppstruct = [];
      switch TransferModel.transfermethod
        case 'pds'
          calppstruct.name = 'win';
          calppstruct.value = TransferModel.detail.options.pds.win;
        case 'dwpds'
          calppstruct.name = 'win1';
          calppstruct.value = TransferModel.detail.options.dwpds.win(1);
          calppstruct(2).name = 'win2';
          calppstruct(2).value = TransferModel.detail.options.dwpds.win(2);
        case 'sst'
          calppstruct.name = 'ncomp';
          calppstruct.value = TransferModel.detail.options.sst.ncomp;
      end
      
    end
    
    function [pname,pval] = getCalTParams(TransferModel)
      %Create name/value pair from transfermoel or output of
      %getCalTStructure. In some code above it's easier to use name/value
      %parameters than raw output from getCalTStructure so do use this
      %function to return name/value pairs.
      
      pname = [];
      pval  = [];
      if ismodel(TransferModel)
        switch TransferModel.transfermethod
          case 'pds'
            pname = 'win';
            pval = TransferModel.detail.options.pds.win;
          case 'dwpds'
            pname = 'win';
            pval = TransferModel.detail.options.dwpds.win;
          case 'sst'
            pname = 'ncomp';
            pval = TransferModel.detail.options.sst.ncomp;
        end
      else
        if length(TransferModel)==1
          pname = TransferModel.name;
          pval  = TransferModel.value;
        else
          %DWPDS
          if strcmpi(TransferModel(1).name,'win1')
            pname = 'win';
            pval  = [TransferModel(1).value TransferModel(2).value];
          else
            error('Unexpected parameter structure passed to .getCalTParams method.')
          end
        end
      end
      
    end
    
    function [masterpls_model, mp6trans, mp5trans, starchtrans, mp6spec, m5spec, starch_ds] = getdemodata
      %Get demo data and model as used by Barry in recorded video.
      load corn_dso;
      
      starch_ds = conc(:,4);
      options = pls('options');
      options.display = 'off';
      options.plots   = 'none';
      mypp_x = preprocess('default','msc','derivative','mean center');
      
      mypp_y = preprocess('default','autoscale');
      
      options.preprocessing = {mypp_x mypp_y};
      %Create PLS model.
      masterpls_model = pls(mp6spec,starch_ds,6,options);
      
      specnos = [ 77 27 79 72 54 60 32 68 ];
      starchtrans = starch_ds(specnos);
      mp6trans = mp6spec(specnos);
      mp5trans = m5spec(specnos);
      
    end
    
    function obj = test(testcase)
      %Manual assembly of MCCT.
      obj = [];
      
      if nargin<1
        testcase = 1;
      end
      
      %Used in most test cases.
      load corn_dso;
      myconc = conc(:,1); %Use moister.
      
      try
        load('CORN_PLS_Model_test.mat')
      catch
        error('Can''t find Barry''s model.')
      end
      
      switch testcase
        case 1
          %Load data.
          myconc = conc(:,4); %Use only starch.
          
          %Make master model.
          options = pls('options');
          options.display = 'off';
          options.plots   = 'none';
          options.preprocessing = {preprocess('default','msc_median','derivative','mean center') []};
          master_model = pls(m5spec,myconc,3,options);
          
          %Do calibration transfer with insert after P1 (normalize).
          caltopts = caltransfer('options');
          %Insert normalize step into calt model if you always want a
          %particular prepro step used prior to transfer.
          %caltopts.preprocessing = {preprocess('default','normalize') []};
          %[dsmodel,x1,newX2] = caltransfer(m5spec,mp5spec,'ds',caltopts);
          
          caltopts.pds.win        = 5;
          [dsmodel,x1,newX2] = caltransfer(m5spec,mp5spec,'pds',caltopts);
          
          %Initialize object.
          obj = MCCTObject;
          %Add data.
          obj = MCCTObject('CalibrationMasterXData',m5spec,'CalibrationSlaveXData',mp5spec,...
            'CalibrationYData', myconc,'MasterModel',master_model ,'TransferModel', dsmodel,...
            'PreprocessingInsertInd',0);
          
          %Get slave model.
          sm = obj.SlaveModel;
          %Calt in first position (normize is removed, 2 pp steps)
          disp('4 PP steps shown, CalT, MSC, Dreviative, Mean Center')
          pp = sm.preprocessing{1};
          pp.description
          
          %Create second slave model.
          obj.PreprocessingInsertInd = 1;
          sm2 = obj.SlaveModel;
          pp2 = sm2.preprocessing{1};
          disp('3 PP steps shown, CalT, Dreviative, Mean Center')
          pp2.description
          
          %Create second slave model.
          obj.PreprocessingInsertInd = 2;
          sm3 = obj.SlaveModel;
          pp3 = sm3.preprocessing{1};
          disp('2 PP steps shown, CalT, Mean Center')
          pp3.description
          
          %Make slave models for all insert points.
          obj.makeAllSlaveModels
          
          %Get pp data at given insert point. PP used is saved in .userdata
          %field.
          obj.PreprocessingInsertInd = 0;
          mydata0 = obj.getPreprocessedSlaveDataInd;
          
          obj.PreprocessingInsertInd = 1;
          mydata1 = obj.getPreprocessedSlaveDataInd;
          
          obj.PreprocessingInsertInd = 2;
          mydata2 = obj.getPreprocessedSlaveDataInd;
          
          %Plot pp data. NOT FINISHED YET
          %obj.plotSlaveData
          
        case 2
          %Test options.
          opts = MCCTObject.getDefaultOptions;
          
        case 3
          %Test combinations with corn data and Barry model.
          %Load data.
          
          obj = MCCTObject('CalibrationMasterXData',mp6spec,'CalibrationSlaveXData',mp5spec,...
            'CalibrationYData', myconc,'MasterModel',corn_plsmodel,'PreprocessingInsertInd',0);
          
          %Set up calt combonations.
          obj.CalibrationTransferCombinations = {'ds' '' [] [] [];'pds' 'win' 3 2 15;'sst' 'ncomp' 2 1 8};
          
          %Make models for given insert points.
          %obj.makeSlaveModelInd([0 1 2 3])
          obj.makeSlaveModelInd([0 1])
          %Show table of retults.
          obj.compareSlaveModels(1)
          
        case 4
          %Test validation data.
          
          obj = MCCTObject('CalibrationMasterXData',mp6spec,'CalibrationSlaveXData',mp5spec,...
            'CalibrationYData', myconc,'ValidationMasterXData',mp6spec,'ValidationSlaveXData',m5spec,...
            'ValidationYData',myconc, 'MasterModel',corn_plsmodel,'PreprocessingInsertInd',0);
          %Set up calt combonations.
          obj.CalibrationTransferCombinations = {'ds' '' [] [] [];'pds' 'win' 3 2 15;'sst' 'ncomp' 2 1 8};
          
          %Make models for given insert points.
          obj.makeSlaveModelInd([0 1 2 3])
          
        case 5
          %Test all transfer types.
          obj = MCCTObject('CalibrationMasterXData',mp6spec,'CalibrationSlaveXData',mp5spec,...
            'CalibrationYData', myconc,'ValidationMasterXData',mp6spec,'ValidationSlaveXData',m5spec,...
            'ValidationYData',myconc, 'MasterModel',corn_plsmodel,'PreprocessingInsertInd',0);
          obj.CalibrationTransferCombinations = {'ds' '' [] [] [];'pds' 'win' 5 2 9;'dwpds' 'win1' 5 2 11;'dwpds' 'win2' 3 1 7;'sst' 'ncomp' 2 1 8};
          obj.makeSlaveModelInd([1 2 3])
          obj.compareSlaveModels(1)
        case 6
          %Test for single block model.
          load nir_data;
          opts = pca('options');
          opts.display = 'off';
          opts.plots   = 'none';
          opts.preprocessing = {preprocess('default','msc_median','derivative','mean center') []};
          mypcamod = pca(spec1,3,opts);
          %Split data randomly
          ridx = randi([1 30],1,10);
          kidx = setdiff([1:30],ridx);
          spec1_cal = spec1(ridx,:);
          spec1_val = spec1(kidx,:);
          
          spec2_cal = spec2(ridx,:);
          spec2_val = spec2(kidx,:);
          
          obj = MCCTTool('CalibrationMasterXData',spec1_cal,'CalibrationSlaveXData',spec2_cal,...
            'ValidationMasterXData',spec1_val,'ValidationSlaveXData',spec2_val,...
            'MasterModel',mypcamod,'PreprocessingInsertInd',0);
          
          
        case 10
          %Interface call.
          obj = MCCTTool('CalibrationMasterXData',mp6spec,'CalibrationSlaveXData',mp5spec,...
            'CalibrationYData', myconc,'ValidationMasterXData',mp6spec,'ValidationSlaveXData',m5spec,...
            'ValidationYData',myconc, 'MasterModel',corn_plsmodel,'PreprocessingInsertInd',0);
        case 11
          %Make Barry example, same as demo.
          moisture_ds = conc(:,1);
          options = pls('options');
          options.display = 'off';
          options.plots   = 'none';
          mypp_x = preprocess('default','derivative','GLS Weighting','mean center');
          
          %Add additional parameters to GLSW.
          mypp_x(2).userdata.a = 1.5e-05;
          mypp_x(2).userdata.source = 'gradient';
          mypp_x(2).userdata.meancenter = 'yes';
          mypp_x(2).userdata.applymean = 'yes';
          mypp_x(2).userdata.classset = 1;
          
          mypp_y = preprocess('default','autoscale');
          
          options.preprocessing = {mypp_x mypp_y};
          masterpls_model = pls(mp6spec,moisture_ds,2,options);
          
          specnos = [ 77 27 79 72 54 60 32 68 ];
          conctrans = moisture_ds(specnos);
          mp6trans = mp6spec(specnos);
          mp5trans = mp5spec(specnos);
          
          obj = MCCTTool('CalibrationMasterXData',mp6trans,'CalibrationSlaveXData',mp5trans,...
            'CalibrationYData', conctrans,'ValidationMasterXData',mp6spec,'ValidationSlaveXData',mp5spec,...
            'ValidationYData',moisture_ds, 'MasterModel',masterpls_model);
          
        otherwise
          
      end
      
      
    end
    
    function [data] = adjustvars(data,model)
      % make sure the included variables in the data match up with the
      % included variables in the model
      if ~isempty(model) && ~isempty(data)
        if ~isequal(data.include{2,1},model.include{2,1})
          data.include{2,1} = model.include{2,1};
        end
      end
    end
  end
  
end


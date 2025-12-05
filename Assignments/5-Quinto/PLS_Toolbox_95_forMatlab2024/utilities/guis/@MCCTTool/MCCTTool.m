classdef MCCTTool< MCCTObject & matlab.mixin.Copyable
%MCCTTool Modelcentric calibration transfer interface.
%
%See also: CALTRANSFER, CALTRANSFERGUI, MCCTObject

%Copyright Eigenvector Research, Inc. 2017
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
  
  properties
    guiFontSize = getdefaultfontsize;
  end
  
  properties (Access = private)
    %Main figure
    mainFigure
    
    %Graph
    mainGraph
    
    %Options, hold any local changes here then save when close gui. Needs
    %to start out empty then default is added on first call. Can't define
    %default here because it will only happen once per matlab session so
    %any saved options won't get updated if object is instantiated a second
    %time.
    OptoinalInputsMCCTTool = [];
    
    %Save source info (not data itself) of loaded items. This is used for display in GUI.
    sourceInfo = MCCTTool.makeEmptySourceInfo;
    
    %Info box handle.
    infoBoxHandle = [];
    
    %Insert indices for preprocessing. Can be scalar or vector of integers.
    preproInsertIndexes = 0;
    
    %Current results table.
    currentResultsTable = [];
    
    %windowHorizontalSplit = 300; %Pixesl from the top of window for upper panels.
    %defautlFontSize       = getdefaultfontsize;
    %transferMethods       = MCCTTool.getTransferTypes
    %cachetable            = [];
    %caltoptions           = caltransfer('options');
    %appdata               = struct('datasetx1',[],'datasetx2',[],'datasetx1t',[],'datasetx2t',[],'model',[]);%Structure with raw data, calculated data, and model.
    forceUpdateTable = false;%Flag to update table. Sometimes table update gets missed so have to force it.
  end
  
  properties(Dependent, SetAccess=private)
    figure
    graph
    preproinsertinds
    %Result table.
    mainTable
    
  end
  
  properties(Dependent)
    fontSize
    horizontalSplit
    transferTypes
    %Options
    MCCTToolOptionalInputs
  end
  
  methods
    
    function obj = MCCTTool(varargin)
      %Make calt window.
      if nargin>0 & ismodel(varargin{1})
        %Special case, load master model.
        obj.MasterModel = varargin{1};
        varargin = varargin(2:end);
      end
      set(obj,varargin{:});
      obj = initialize(obj);
      if nargout==0
        %This suppresses output but doesn't destroy the object because it's
        %saved in appdata of figure created in initialize. Disp() is also
        %overloaded not to show anything.
        clear obj
      end
    end
    
    function delete(obj)
      %Delete done in intialize.m sub function.
    end
    
    function fig = get.figure(obj)
      fig = obj.mainFigure;
    end
    
    % Result Table
    function set.mainTable(obj,val)
      warning('EVRI:MCCTTool','ETable is appdata in figure created on initialize.');
    end
    
    function val = get.mainTable(obj)
      f = obj.figure;
      val = getappdata(f,'resulttable');
    end
    
    % Options
    function set.MCCTToolOptionalInputs(obj,val)
      obj.OptoinalInputsMCCTTool = val;
    end
    
    function val = get.MCCTToolOptionalInputs(obj)
      if isempty(obj.OptoinalInputsMCCTTool)
        obj.OptoinalInputsMCCTTool = MCCTTool.getDefaultOptions('options');
      end
      val = obj.OptoinalInputsMCCTTool;
    end
    
    function fsize = get.fontSize(obj)
      fsize = obj.defautlFontSize;
    end
    
    function set.fontSize(obj,val)
      obj.defautlFontSize = val;
    end
    
    function ppinds = get.preproinsertinds(obj)
      ppinds = obj.preproInsertIndexes;
    end
    
    function set.preproinsertinds(obj,val)
      obj.preproInsertIndexes = val;
    end
    
    function vsize = get.horizontalSplit(obj)
      vsize = obj.windowHorizontalSplit;
    end
    
    function set.horizontalSplit(obj,val)
      obj.windowHorizontalSplit = val;
    end
    
    function out = get.transferTypes(obj)
      out = obj.transferMethods;
    end
    
    function set.transferTypes(obj,val)
      %Add transfer method.
      error('Method not implemented.')
    end
    
    function out = get.graph(obj)
      out = obj.mainGraph;
    end
    
    function set.graph(obj,val)
      obj.mainGraph = val;
    end
    
    function out = getFigurePosition(obj,myunits)
      if nargin<2
        out = get(obj.figure,'position');
      else
        oldunits = get(obj.figure,'units');
        set(obj.figure,'units',myunits);
        out = get(obj.figure,'position');
        set(obj.figure,'units',oldunits);
      end
    end

  end
  
  methods(Access = private)
    %Callbacks for the applicatoin (figure).
    menuCallback(app,src,evt,varargin)
    dropCallback(app,src,evt,varargin);
    clickCallback(app,src,evt,varargin);
    tableCallback(app,src,evt,varargin);
    loadItem(app,src,evt,handles,ctrl,varargin)
    updateGUI(app,varagin)
    mouseMoveCallback(app,src,evt,varargin);
  end
  
  methods (Static)
    function options = getDefaultOptions(varargin)
      options = [];
      if nargin==1 & ischar(varargin{1}) & ~ismember(varargin{1},evriio([],'validtopics'))
        %Not valid evriio call.
        return
      elseif nargin==0
        varargin{1} = 'options';
      end
      options.defaultColumnWidth = [];
      options.include_columns = {};
      options.exclude_columns = {};
      options.definitions     = @MCCTTool.optiondefs;
      if nargout==0
        evriio(mfilename,varargin{1},options)
      else
        options = evriio(mfilename,varargin{1},options);
      end
    end
    
    function options = options(varargin)
      %This is shorthand for options. May not be needed.
      options = MCCTTool.getDefaultOptions(varargin{:});
    end
    function out = optiondefs
      defs = {
        %name                    tab              datatype        valid                            userlevel       description
        'defaultColumnWidth'     'Display'        'double'        'float(0:inf)'                     'novice'        'Default result table column width in pixels.';
        };
      out = makesubops(defs);
    end
    
    function out = getTransferTypes
      out = {...
        'ds'       'Direct Standardization'                         'stdgen'   'off' {};
        'pds'      'Piecewise Direct Standardization'               'stdgen'   'off' {'pwin' 'pncomp' 'piter' 'ptol' 'pypred'};
        'dwpds'    'Double Window Piecewise Direct Standardization' 'stdgen'   'off' {'pwin' 'pncomp' 'piter' 'ptol' 'pypred'};
        'glsw'     'Generalized Least-Squares Weighting'            'glsw'     'off' {'pwin' 'pncomp' 'piter' 'ptol' 'pypred'};
        'osc'      'Orthogonal Signal Correction'                   'osccalc'  'off' {'pwin' 'pncomp' 'piter' 'ptol' 'pypred'};
        'alignmat' 'Matrix Alignment'                               'alignmat' 'off' {'pwin' 'pncomp' 'piter' 'ptol' 'pypred'};
        };
    end
    
    function out = makeEmptySourceInfo
      %Make empty structure for source information used to udpate tooltip
      %windows and other controls in interface. Structure is filled when
      %data is loaded and or calcualted. Used on construct and when
      %clearing.
      out = struct('CalibrationMasterXData',[],...
        'CalibrationSlaveXData',[],...
        'CalibrationYData',[],...
        'ValidationMasterXData',[],...
        'ValidationSlaveXData',[],...
        'ValidationYData',[],...
        'MasterModel',[],...
        'SlaveModel',[],...
        'TransferModel',[]);
    end
    
    function dropCallbackFcn(jobj,event,varargin)
      %Something getting droppped on figure.
      mygraph = varargin{1};
      fig = mygraph.Parent;
      obj = getappdata(fig,'MCCToolObject');
      obj.dropCallback(jobj,event,varargin{:})
    end
    
    function clickCallbackFcn(jobj,event,varargin)
      %Something getting clicked on figure.
      mygraph = varargin{1};
      fig = mygraph.Parent;
      obj = getappdata(fig,'MCCToolObject');
      obj.clickCallback(jobj,event,varargin{:})
    end
    
    function mouseMoveCallbackFcn(jobj,event,varargin)
      %Something getting clicked on figure.
      mygraph = varargin{1};
      fig = mygraph.Parent;
      obj = getappdata(fig,'MCCToolObject');
      obj.mouseMoveCallback(jobj,event,varargin{:})
    end
    
    function dragOverCallbackFcn(jobj,event,varargin)
      %Dragging over.
      
    end
    
    function zoom
      
    end
    
    function varargout = figureCallback(obj)
      varargout = figCallback(obj);
    end
    
  end
end


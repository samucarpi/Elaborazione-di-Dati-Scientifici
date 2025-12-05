function [ output_args ] = updateWindow(obj,varargin)
%UPDATESTATUSBOXES Update status of graph and other controls.
% Optional second input (varargin{1}) for updating edge position of model
% to validation connector.

%Copyright Eigenvector Research, Inc. 2017
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

handles = guihandles(obj.figure);
mygraph = obj.graph;

opts = obj.MCCTToolOptionalInputs;

edgeupdate = 0;
if nargin==2 & isnumeric(varargin{1})
  edgeupdate = varargin{1};
end

%Object field | tag name | Loaded Style | Unloaded Style
windowdata = {'CalibrationMasterXData'  'CalibrationMasterXData'   'data_loaded2;rounded=1'     'data_unloaded';...
              'CalibrationSlaveXData'   'CalibrationSlaveXData'    'data_loaded2;rounded=1'     'data_unloaded';...
              'CalibrationYData'        'CalibrationYData'         'data_loaded2;rounded=1'     'data_unloaded';...
              'ValidationMasterXData'   'ValidationMasterXData'    'data_loaded2;rounded=1'     'data_unloaded';...
              'ValidationSlaveXData'    'ValidationSlaveXData'     'data_loaded2;rounded=1'     'data_unloaded';...
              'ValidationYData'         'ValidationYData'          'data_loaded2;rounded=1'     'data_unloaded';...
              'MasterModel'             'MasterModel'              'model_loaded'               'model_unloaded';...
              'SlaveModel'              'SlaveModel'               'model_loaded'               'model_unloaded';...
              'TransferModel'           'TransferModel'            'preprocessing_loaded'       'preprocessing_unloaded';...
              'ValidationResults'       'ValidationResults'        'prediction_loaded'          'prediction_unloaded'...
              };
            
%Update data and models.
mdlflag = 0;%Maset model loaded flag (used below).
for i = 1:size(windowdata,1)
  if ~isempty(obj.(windowdata{i,1}))
    SetStyle(mygraph,windowdata{i,2},windowdata{i,3});
    if strcmp(windowdata{i,1},'MasterModel')
      %There is a mastermodel.
      mdlflag = 1;
    end
  else
    SetStyle(mygraph,windowdata{i,2},windowdata{i,4});
  end
end

%Update if y-data is loaded. 
if isempty(obj.CalibrationYData)
  SetVisible(mygraph,{'calytomastermodel' 'calytoslavemodel'},false)
else
  SetVisible(mygraph,{'calytomastermodel' 'calytoslavemodel'},true)
end

if isempty(obj.ValidationYData)
  SetVisible(mygraph,{'valytoresults'},false)
else
  SetVisible(mygraph,{'valytoresults'},true)
end

if mdlflag
  SetStyle(mygraph,'calmasterp1','preprocessing_loaded_blue');
  SetStyle(mygraph,'calmasterp2','preprocessing_loaded_blue');
  SetStyle(mygraph,'calslavep1','preprocessing_loaded_blue');
  SetStyle(mygraph,'calslavep2','preprocessing_loaded_blue');
else
  SetStyle(mygraph,'calmasterp1','preprocessing_unloaded');
  SetStyle(mygraph,'calmasterp2','preprocessing_unloaded');
  SetStyle(mygraph,'calslavep1','preprocessing_unloaded');
  SetStyle(mygraph,'calslavep2','preprocessing_unloaded');
end

if obj.getCanCalculate
  set(handles.calcmodel,'enable','on')
else
  set(handles.calcmodel,'enable','off')
end

%Check results and update table.
curtbl = obj.currentResultsTable;
newtbl = obj.ResultsTable;

if ~comparevars(curtbl,newtbl) | obj.forceUpdateTable
  %TODO: Enable tooltips on table header.
  %Update table.
  obj.forceUpdateTable = false;
  
  if isempty(newtbl)
    clear(obj.mainTable,'data');
  else
    mycolumns = newtbl(1,:);
    showcols = ones(1,size(newtbl,2));
    
    %Remove/add columns based on options.
    ecol = opts.exclude_columns;
%    icol = opts.include_columns;
    if isempty(ecol)
      ecol = {};
    end
%     [junk,icolidx] = setdiff(icol,ecol);%Don't allow exluded items in include.
%     icol = icol(sort(icolidx));%Make sure they're in the orginal order.
    
    if ~isempty(ecol)
      showcols(ismember(lower(mycolumns),lower(ecol))) = 0;
    end
    
%     if ~isempty(icol)
%       shidx = ismember(lower(mycolumns),lower(icol));
%       showcols(shidx) = 1;
%       %Reorder table and columns.
%       shidx0 = [];
%       for i = 1:length(icol)
%         shidx0 = [shidx0 find(ismember(lower(mycolumns),lower(icol(i))))];
%       end
%       neworder = [shidx0 find(~shidx)];
%       showcols  = showcols(neworder);
%       newtbl = newtbl(:,neworder);
%       mycolumns = mycolumns(neworder);
%     end
    
    %ID Column is special. It always needs to be there.
    idloc = ismember(lower(mycolumns),'Model ID');
    %showidcol = showcols(idloc);
    showcols(idloc) = 1;%Force it on.
    
    %Update data.
    newtbl = newtbl(:,logical(showcols));
    %mycolumns = mycolumns(:,logical(showcols));
    mytbl = obj.mainTable;
    mytbl.data = newtbl(2:end,:);
    mytbl.column_labels = newtbl(1,:);
  end
  updatetable(obj.mainTable);%Update is needed for 14a for some reason.
  obj.currentResultsTable = newtbl;
end

%Column width.
if ~isempty(opts.defaultColumnWidth)
  setcolumnwidth(obj.mainTable,[],opts.defaultColumnWidth);
end

enablebutton = 0;
%Update calt enable.
if get(handles.ds,'value')
  enablebutton = 1;
end

%Update parameter values enabled.
if get(handles.pds,'value')
  enablebutton = 1;
  set([handles.win_1 handles.win_step handles.win_2],'enable','on')
else
  set([handles.win_1 handles.win_step handles.win_2],'enable','off')
end

if get(handles.dwpds,'value')
  enablebutton = 1;
  set([handles.win1_1 handles.win1_step handles.win1_2 handles.win2_1 handles.win2_step handles.win2_2],'enable','on')
else
  set([handles.win1_1 handles.win1_step handles.win1_2 handles.win2_1 handles.win2_step handles.win2_2],'enable','off')
end

if get(handles.sst,'value')
  enablebutton = 1;
  set([handles.ncomp_1 handles.ncomp_step handles.ncomp_2],'enable','on')
else
  set([handles.ncomp_1 handles.ncomp_step handles.ncomp_2],'enable','off')
end

%Update calc button
if enablebutton
  set(handles.calcCombosButton,'enable','on');
else
  set(handles.calcCombosButton,'enable','off');
end

for i = 1:size(windowdata,1)
  %Update data info as needed.
  if ~isempty(obj.(windowdata{i,1})) %& isempty(obj.sourceInfo.(windowdata{i,1}))
    switch windowdata{i,1}
      case {'CalibrationMasterXData' 'CalibrationSlaveXData' 'CalibrationYData' ...
          'ValidationMasterXData' 'ValidationSlaveXData' 'ValidationYData' 'ValidationResults'}
        obj.sourceInfo.(windowdata{i,1}) = getdatasource(obj.(windowdata{i,1}),'string');
      case {'MasterModel' 'TransferModel' 'SlaveModel'}
        obj.sourceInfo.(windowdata{i,1}) = modlrder(obj.(windowdata{i,1}))';
    end
  else
    obj.sourceInfo.(windowdata{i,1}) = 'Empty';
  end
end

if edgeupdate
  %Update connectors from model to results. The graph routes them poorly.
  m = mygraph.GraphModel;
  
  %Geometry returned from edge:
  %  m.getGeometry(m.getCell('mastermodeltopred'))
  %Doesn't return any data so need to derive from vertex locations.
  
  %Get location of validation pool and use as offset since edges originate
  %in calibration pool and are oriented there.
  myoffset = m.getCell('validationpool').getGeometry.getX;
  
  %Get locations of val data and val results.
  valxgeo = m.getGeometry(m.getCell('ValidationMasterXData'));
  valedge = valxgeo.getX+valxgeo.getWidth;%Edge of validation x block.
  resultxgeo = m.getGeometry(m.getCell('ValidationResults'));
  resultedge = resultxgeo.getX;%Edge of result block.
  
  %Calculate middle of distance between cells.
  horz_middle = valedge+((resultedge-valedge)/2);
  horz_middle = horz_middle+myoffset;
  
  %Get vertical positions.
  valxbottom = valxgeo.getY;
  resulttop = resultxgeo.getY+resultxgeo.getHeight;
  %Calculate middle btween bottom of val data and top of result.
  vert_middle = resultxgeo.getHeight+((resulttop-valxbottom)/2)-4;%Vertical middle for master.
  
  vert_middle_slave = resultxgeo.getHeight+2*((resulttop-valxbottom)/2)+14;%Vertical middle for master.
  
  %Get geomtery and must make clone.
  geom1 = m.getGeometry(m.getCell('mastermodeltopred'));
  geom2 = m.getGeometry(m.getCell('slavemodeltopred'));
  geom1_copy = geom1.clone;
  geom2_copy = geom2.clone;
  
  %Create points, add to list, then add to geometry.
  newpoint = com.mxgraph.util.mxPoint(horz_middle,vert_middle);
  newpoint2 = com.mxgraph.util.mxPoint(horz_middle,vert_middle_slave);
  
  mypts = java.util.ArrayList;
  mypts.add(newpoint);
  geom1_copy.setPoints(mypts);
  m.setGeometry(m.getCell('mastermodeltopred'),geom1_copy);
  
  mypts = java.util.ArrayList;
  mypts.add(newpoint2);
  geom2_copy.setPoints(mypts);
  m.setGeometry(m.getCell('slavemodeltopred'),geom2_copy);
  
  mmgeo = m.getGeometry(m.getCell('MasterModel'));
  smgeo = m.getGeometry(m.getCell('SlaveModel'));
  mpp = m.getGeometry(m.getCell('calmasterp2'));
  
  %Horizontal position is half distance between right edge of pp and left
  %edge of model.
  ppleftedge = mpp.getX+mpp.getWidth;
  hpos = ppleftedge+((mmgeo.getX-ppleftedge)/2);
  vpos1 = mmgeo.getY+(mmgeo.getHeight/2);
  vpos2 = smgeo.getY+(mmgeo.getHeight/2);
  
  %Get geomtery and must make clone.
  geom1 = m.getGeometry(m.getCell('calytomastermodel'));
  geom2 = m.getGeometry(m.getCell('calytoslavemodel'));
  geom1_copy = geom1.clone;
  geom2_copy = geom2.clone;
  
  %Create points, add to list, then add to geometry.
  newpoint = com.mxgraph.util.mxPoint(hpos,vpos1);
  newpoint2 = com.mxgraph.util.mxPoint(hpos,vpos2);
  
  mypts = java.util.ArrayList;
  mypts.add(newpoint);
  geom1_copy.setPoints(mypts);
  m.setGeometry(m.getCell('calytomastermodel'),geom1_copy);
  
  mypts = java.util.ArrayList;
  mypts.add(newpoint2);
  geom2_copy.setPoints(mypts);
  m.setGeometry(m.getCell('calytoslavemodel'),geom2_copy);
  
end




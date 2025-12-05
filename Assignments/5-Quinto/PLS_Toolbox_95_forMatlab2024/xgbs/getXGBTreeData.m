function xgbtreedata = getXGBTreeData(xgbmodel,withstats,rformat)
%GETXGBTREE Get tree data from XGB model.
%  
% INPUTS:
%        withstats = [true | false] get gain and cover stats from model.
%          rformat = ['text' | 'cell' | 'struct' | 'json'] format of data returned,
%                    if JSON then 'struct' will parse into a structure. 
%
% I/O: xgbtree = getXGBTreeData(xgbmodel,withstats,rformat);
%
%See also: modelToJava

%Copyright © Eigenvector Research, Inc. 2018
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

if nargin<2
  withstats = true;
end

if nargin<3
  rformat = 'struct';
end

dataformat = 'text';
if ismember(rformat,{'struct' 'json'})
  dataformat = 'json';
end

jxgbmodel = modelToJava(xgbmodel.detail.xgb.model);
xgbtreedata = char(jxgbmodel.getModelDump([],withstats,dataformat));

switch rformat
  case 'cell'
    xgbtreedata = str2cell(xgbtreedata);
  case 'struct'
    %TODO: No error here so might break if format ever changes.
    tempdata = struct('nodeid',[],'leaf',[],'depth',[],'split',[],'split_condition',[],...
     'yes',[],'no',[],'missing',[],'gain',[],'cover',[],'children',[]);
   
    for i = 1:size(xgbtreedata,1)
      tempdata = catstruct(tempdata,jsondecode(xgbtreedata(i,:)));
    end
    xgbtreedata = tempdata(2:end);
end

%---------------------------------------
function strct1 = catstruct(strct1,strct2)

strct1(end+1).nodeid = [];%Add place holder.
thisnames = fieldnames(strct2);

for i = thisnames'
  strct1(end).(i{:}) = strct2(end).(i{:});
end

%---------------------------------------
function test

load plsdata;

options = xgb('options');
options.display               = 'off';
options.plots                 = 'none';

options.max_depth     = [3 6 9]; 
options.eta           = [0.1 0.05]; 
options.quiet         = 1;
options.num_round     = 100;
model = xgb(xblock1,yblock1,options);


xgbtreedata = getXGBTreeData(model,true,'text');
xgbtreedata = getXGBTreeData(model,false,'text');
xgbtreedata = getXGBTreeData(model,true,'cell');
xgbtreedata = getXGBTreeData(model,false,'cell');
xgbtreedata = getXGBTreeData(model,true,'json');
xgbtreedata = getXGBTreeData(model,false,'json');
xgbtreedata = getXGBTreeData(model,true,'struct');
xgbtreedata = getXGBTreeData(model,false,'struct');


function [ output_args ] = dropCallback(obj,dropobj,eventdata,varargin)
%DROPCALLBACKFCN Drop action on figure.

%Copyright Eigenvector Research, Inc. 2017
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

mygraph = varargin{1};

dropdata = drop_parse(dropobj,eventdata,'',struct('getcacheitem','on'));
if isempty(dropdata{1})
  %Probably error.
  %TODO: Process workspace vars.
  return
end

mycell = mygraph.Graph.getSelectionCell;
if ~isempty(mycell) & size(dropdata,1)==1
  %If droping a single data onto a newdata node then try to load it.
  myid = char(mycell.getId);
  %if ismember(myid,{'calmasterxblock' 'calslavexblock' 'calyblock' 'valmasterxblock' 'valslavexblock' 'valyblock' 'modelmaster'})
  if ismember(myid,{'CalibrationMasterXData' 'CalibrationSlaveXData' 'CalibrationYData' ...
    'ValidationMasterXData' 'ValidationSlaveXData' 'ValidationYData' 'MasterModel' 'TransferModel'})
    %Data and master model can be loaded via drop.
    obj.loadItem(myid,dropdata{2},eventdata)
  end

end

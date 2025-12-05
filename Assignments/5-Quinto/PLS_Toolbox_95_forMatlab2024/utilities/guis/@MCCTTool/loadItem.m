function loadItem(obj,itemname,itemdata,varargin)
%LOADITEM Load item into interface.
%   Load data or model into interface.

%Copyright Eigenvector Research, Inc. 2017
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%NOTE: Use of 'block' in item name is a keyword used elsewhere to id data
%      nodes.
switch itemname
  case 'CalibrationMasterXData'
    if isdataset(itemdata)
      loadItemSub(obj,'CalibrationMasterXData', itemdata);
    end
  case 'CalibrationSlaveXData'
    if isdataset(itemdata)
      loadItemSub(obj,'CalibrationSlaveXData', itemdata);
    end
  case 'CalibrationYData'
    if isdataset(itemdata)
      loadItemSub(obj,'CalibrationYData', itemdata);
    end
  case 'ValidationMasterXData'
    if isdataset(itemdata)
      loadItemSub(obj,'ValidationMasterXData', itemdata);
    end
  case 'ValidationSlaveXData'
    if isdataset(itemdata)
      loadItemSub(obj,'ValidationSlaveXData', itemdata);
    end
  case 'ValidationYData'
    if isdataset(itemdata)
      loadItemSub(obj,'ValidationYData', itemdata);
    end
  case 'MasterModel'
    if ismodel(itemdata)
      loadItemSub(obj,'MasterModel', itemdata);
    end
  case 'TransferModel'
    if ismodel(itemdata)
      loadItemSub(obj,'TransferModel', itemdata);
    end
  otherwise
    error('Unrecognized item for loading into Cal-transfer Tool.')
end

%Little unsure if this will consistently work so put in try catch, does
%not need to be fatal error.
try
  obj.graph.SetToolTip(itemname,getdatasource(itemdata,'string'))
end

obj.updateWindow;
end

%---------------------------------------
function loadItemSub(obj,myname,myitem)
%Test field and load.

if ~isempty(obj.(myname))
  augbutton = evriquestdlg(['There is existing ' myname ' item. Do you wish to overwrite or cancel?'],...
    'Continue Load Data','Overwrite','Cancel','Overwrite');
  if strcmp(augbutton,'Cancel')
    return
  end
end
obj.(myname) = myitem;
switch myname
  case {'CalibrationMasterXData' 'CalibrationSlaveXData' 'CalibrationYData' ...
    'ValidationMasterXData' 'ValidationSlaveXData' 'ValidationYData'}
    obj.sourceInfo.(myname) = getdatasource(myitem,'string');
  case {'MasterModel' 'TransferModel'}
    obj.sourceInfo.(myname) = modlrder(myitem)';
end

end





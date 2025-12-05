function x = table2dataset(tbl)
%TABLE2DATASET Convert Matlab Table Object to DatasetObject. 
%
%See also: DATASET, PARSEMIXED

%Copyright Eigenvector Research, Inc. 2018
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB, without
% written permission from Eigenvector Research, Inc.

%Get struct with data expanded in each variable field.
tstruct = table2struct(tbl,'ToScalar',true);

%Get fields and data.
myflds   = fieldnames(tstruct);
dataflds = varfun(@isnumeric,tbl,'output','uniform');
%Convert logicals to data. User can move logicals to class field if needed.
logicalflds = varfun(@islogical,tbl,'output','uniform');
dataflds = dataflds | logicalflds;
rawdata  = double(tbl{:,dataflds});

%Make dataset.
x = dataset(rawdata);

%Remove data fields.
myflds(dataflds) = [];

for i = 1:length(myflds)
  %Don't make fatal error if can't add a field.
  try
    switch class(tstruct.(myflds{i}))
      case 'cell'
        x.label{1,end+1}   =  tstruct.(myflds{i});
        x.labelname{1,end} = myflds{i};
      case 'string'
        x.label{1,end+1}   =  char(tstruct.(myflds{i}));
        x.labelname{1,end} = myflds{i};
      case 'categorical'
        x.classid{1,end+1} = cellstr(tstruct.(myflds{i}));
        x.classname{1,end} = myflds{i};
      case 'datetime'
        x.axisscale{1,end+1}   =  datenum(tstruct.(myflds{i}));
        x.axisscalename{1,end} = myflds{i};
      otherwise
        warning('EVRI:Table2DatasetMetaDataUnrecognized',['Unrecognized meta data for: "' myflds{i} '" table field.'])
    end
  catch
    warning('EVRI:Table2DatasetMetaDataFailure',['Could not add label/class/axisscale meta data for: "' myflds{i} '" table field.'])
  end
end

% The 'end' indexing logic doesn't work correctly above so remove the first
% set in each meta field because it's empty.
x = rmset(x,'label',1,1);
x = rmset(x,'class',1,1);
x = rmset(x,'axisscale',1,1);

%Add property data if there.
if ~isempty(tbl.Properties.VariableNames)
  try
    x.description = tbl.Properties.Description;
    x.userdata = tbl.Properties.UserData;
    x.label{2,1} = tbl.Properties.VariableNames(dataflds);
  end
end


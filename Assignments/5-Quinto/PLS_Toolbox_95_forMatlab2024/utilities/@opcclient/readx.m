function result = readx(client, itemname)
%OPCCLIENT/CONNECT read an item from the OPC server.
%
% INPUT
%  itemname: Item tag for the OPC item exposed by the OPC server
% OUTPUT
%    result: Structure with fields
%            itemvalue 
%            itemtimestamp 
%            itemquality
%            itemerrorcode

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

display = false; % expose this later
if display
  disp(sprintf('Reading item %s from OPC server', itemname));
end
VT_EMPTY   =  0;
VT_NULL    =  1;
VT_I2      =  2;   % int16
VT_I4      =  3;   % int32
VT_R4      =  4;   % Single
VT_R8      =  5;   % Double
VY_DATE    =  7;   % double
VT_BSTR    =  8;   % Char
VT_ERROR   = 10;
VT_BOOL    = 11;   % Logical
VT_UNKNOWN = 13;
VT_I1      = 16;   % int8
VT_UI1     = 17;   % uint8
VT_UI2     = 18;   % uint16
VT_UI4     = 19;   % uint32
VT_I8      = 20;   % int64
VT_ARRAY   = 8192; %

jclient = client.jclient;

server = jclient.getServer;

groupname = client.groupname;
group = jclient.getDefaultGroup;    %  following does not work: client.getdefaultgroup;    %server.addGroup(groupname);    % Group. Only matters on client

% Using the Java objects directly
item1 = group.addItem(itemname);       % Item
% Map<String, Result<OPCITEMRESULT>> validateItems ( final String... items )
resultsmap = group.validateItems(itemname);

% and read it
itemstate = item1.read(1);                    % ItemState
itemvalue=itemstate.getValue;                    % JIVariant, getType rets 3 (Int4), as expected
valuetype = itemvalue.getType;
% switch to case using VT_ types. Also, see JIVariant supported types map
switch valuetype
  case VT_ERROR
    if display
      disp('error')
    end
    error('readx: value has Type VT_ERROR')
  case VT_I4
    if display
      disp('int4')
    end
    itemvalue = double(itemvalue.getObjectAsInt);
  case VT_I8
    if display
      disp('int8')
    end
    itemvalue = double(itemvalue.getObjectAsLong);
  case VT_R4
    if display
      disp('r4')
    end
    itemvalue = double(itemvalue.getObjectAsFloat);
  case VT_R8
    if display
      disp('r8')
    end
    itemvalue = itemvalue.getObjectAsDouble;
    
  case (VT_ARRAY+VT_R4)
    if display
      disp('array r4')
    end
    itemvalue = itemvalue.getObjectAsArray;
    itemvalue = itemvalue.getArrayInstance;
    % Use Java function which converts this object array to double[]
    itemvalue = evri.opcda.Helper.convertToPrimitiveArray(itemvalue);
  case (VT_ARRAY+VT_R8)
    if display
      disp('array r8')
    end
    itemvalue = itemvalue.getObjectAsArray;
    itemvalue = itemvalue.getArrayInstance;
    % Use Java function which converts this object array to double[]
    itemvalue = evri.opcda.Helper.convertToPrimitiveArray(itemvalue);
  otherwise
    error('readx: value has Type which is not supported, = %d', valuetype)
end

% date = item
% itemtimestamp=state1.getTimestamp.getTime;
itemtimestampmillisec = itemstate.getTimestamp.getTimeInMillis;
matlabSerialDate      = datenum([1970 1 1 0 0 itemtimestampmillisec / 1000]);
itemtimestamp         = datestr(matlabSerialDate);

result.itemvalue      = itemvalue;
result.itemtimestamp  = itemtimestamp;
result.itemquality    = itemstate.getQuality;;
result.itemerrorcode  = itemstate.getErrorCode;


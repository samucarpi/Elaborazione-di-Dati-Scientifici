function result = writex(client, itemname, value)
%OPCCLIENT/WRITEX write an item from the OPC server.
% Java Item.write returns an int. Appears 0=success.

%Copyright Eigenvector Research, Inc. 2014
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% disp(sprintf('Reading item %s from OPC server', itemname));
jclient = client.jclient;
server = jclient.getServer;
groupname = client.groupname;
group = jclient.getDefaultGroup;    % Group. Only matters on client
item1 = group.addItem(itemname);       % Item
% %--------------------------------------------
itemstate = item1.read(1);                    % ItemState
itemvalue=itemstate.getValue;                    % JIVariant, getType rets 3 (Int4), as expected
valuetype = itemvalue.getType;

if valuetype == 3 | valuetype == 5
  jivariant = org.jinterop.dcom.core.JIVariant( value );
  % write value
  result = item1.write(jivariant); 
else  % e.g. 8197  = array of real8
  % value is matlab vector. Converting value to Java Double[]
  nelements = int32(numel(value));
  jarray = evri.opcda.OpcClient.getDataArray(nelements); 
  for ii=1:nelements
    jarray(ii) = java.lang.Double(value(ii));
  end
  jiarray = org.jinterop.dcom.core.JIArray( jarray, true ); 
  jivariant = org.jinterop.dcom.core.JIVariant( jiarray );
  % write value
  result = item1.write(jivariant); 

end
  
% % Using the Java objects directly
% jiv = org.jinterop.dcom.core.JIVariant(value, 0); % JIVariant. getType returns 5  (Real8)
% % write value
% result = item1.write(jiv); 
% %--------------------------------------------
% itemvalue=itemstate.getValue;                    % JIVariant, getType rets 3 (Int4), as expected
% valuetype = itemvalue.getType;
% if valuetype == 3
%     itemvalue = itemvalue.getObjectAsInt;
% elseif valuetype == 5
%     itemvalue = itemvalue.getObjectAsDouble;
% elseif valuetype == 8197
%     %org.jinterop.dcom.core.JIVariant.VT_ARRAY = 8192 [0x2000]
%     %org.jinterop.dcom.core.JIVariant.VT_R8 = 5 [0x5]
%     itemvalue =client.jclient.getArrayOfReal8(itemstate);
%     % or use the dumper to print out
%     org.openscada.opc.lib.test.VariantDumper.dumpValue(itemstate.getValue);
% %     jia = itemvalue.getObjectAsArray;
% else
%     error('readx: value has Type which is not supported, = %d', valuetype)
% end

function obj = opcclient(varargin)
%OPCCLIENT Creates an opcclient object.
% OPCCLIENT objects allow access to OPC servers supporting OPC Data Access standard v2.05a.
% OPCCLIENT allows connecting to an OPC server from Matlab and reading item values or writing 
% item values to the server. 
% OPCCLIENT functions on Windows platforms only.
%
% Example usage:
% Start an OPC server on the local computer.
% Create a user with admin privileges, for example, "testuser", with example password "test"
%
% Create client instance
% client = opcclient(1);
%
% Connect to OPC Server 
% client.connect(IPaddress, domain, username, password, OPC_server_progID);
% For example; client.connect('10.0.2.15', 'localhost', 'testuser', 'test', 'Matrikon.OPC.Simulation');
%
% Read a single item 
% itemname   = 'Bucket Brigade.Int4';    % This server item tag, is read/write
% [value timestamp quality] = client.read(itemname);
%
% Write a value to a single item
% newvalue = 23;
% res = client.write(itemname, newvalue);
%
% Write an array item
% itemname = 'Random.ArrayOfReal8';
% newvalue = rand(6,1)*10; 
% res = client.write(itemname, newvalue); 
%
% Read its value back
% [value timestamp quality] = client.read(itemname);
%
%I/O: client = opcclient(clientid)
%

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


% Constructor for a opcclient class object.

if nargin==0 % 
  obj = init_fields;
  obj = class(obj, 'opcclient');
  return;
end
firstArg = varargin{1};
if isa(firstArg, 'opcclient') %  used when objects are passed as arguments
  obj = firstArg;
  return;
end

setOPCLogLevel

% construct the fields 
obj = init_fields; 
obj = class(obj, 'opcclient'); 

% Now the real initialization begins
obj.id = varargin{1};

%--------------------------------------------------------------------------
function setOPCLogLevel
% The following limits the the quantity of Java log messages
level = java.util.logging.Level.OFF;  %WARNING;
logger = org.jinterop.dcom.common.JISystem.getLogger();
logger.setLevel(level);

%--------------------------------------------------------------------------
function obj = init_fields
% Initialize all fields to opcclient values 
obj.id               = 100;
obj.groupname        = '-';
%
evrijavasetup
obj.jclient = evri.opcda.OpcClient;


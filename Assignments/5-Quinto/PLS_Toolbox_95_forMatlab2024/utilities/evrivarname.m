function out = evrivarname(vname, ws, var)
%EVRIVARNAME Get a unique variable name for a given workspace.
% Get a unique name for a given workspace. If input 'var' is given then
% function will assign in the variable.
%
%I/O: name = evrivarname(vname, ws, var)
%
%See also: ENCODEDATE, UNIQUENAME

%Copyright © Eigenvector Research, Inc. 2014
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin < 2
  ws = 'base';
end

if nargin == 2 & ~ischar(ws)
  %Second input is a var so make ws workspace.
  var = ws;
  ws = 'base';
end

if nargin<3;
  var = [];
end

%Make sure vname is legal.
try
  %Only works on 14a and newer.
  vname = matlab.lang.makeValidName(vname);
  %NOTE: If user loads a model with long name a second time it will give a
  %warning below.
end

%Initialize output.
out = vname;

%Check if var name exists.
checkvar = sprintf('exist(''%s'');',vname);
if ~evalin(ws, checkvar),
  if ~isempty(var)
    %Assign in.
    assignin(ws, vname, var);
  end
  return;
end

%Name is not unique so add a number to the end.
count = 1;
while 1,
  newname = [vname '' num2str(count)];
  checkvar = sprintf('exist(''%s'');',newname);
  if ~evalin(ws, checkvar),
    %Good name.
    out = newname;
    if ~isempty(var)
      %Assign in.
      assignin(ws, newname, var);
    end
    break;
  else
    count = count + 1;
  end
end

function msg = edit(obj)
%EVRIMODEL/EDIT Overload for EVRIModel Object.
% Input is a model object. Output is a message containing an empty string
% if no errors occurred, or a message specific to the problem encountered
% when opening the specific object.
%
% If no outputs are requested, any errors in opening the model are thrown.
%
%I/O: msg = edit(obj)

%Copyright (c) Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

msg = '';

if exist('isdeployed') & ~isdeployed
  todo = evriquestdlg('Load this model into the model-building interface, or extract and view the raw model contents?','Open Model','Load Model','View Raw Contents','Load Model');
  if isempty(todo)
    return;
  end
  if ~strcmpi(todo,'Load Model')
    %create a name to assign into the base workspace that will contain this
    %model's details
    name = inputname(1);
    if isempty(name);
      name = 'model';
    end
    post = '_content';
    newname = [name post];
    ex = evalin('base',sprintf('exist(''%s'',''var'')',newname));
    ind = 0;
    while ex & ~comparevars(evalin('base',newname),obj.content)
      %name matches an exisiting variable (but not its contents), make a new
      %variable name
      ind = ind+1;
      newname = sprintf('%s%s_%i',name,post,ind);
      ex = evalin('base',sprintf('exist(''%s'',''var'')',newname));
    end
    %assign the contents into that variable name
    assignin('base',newname,obj.content);
    %open that newly created variable in the matlab editor
    openvar(newname);
    return
  end
end

%open the variable in the appropriate GUI (if any)
type = lower(obj.content.modeltype);
if isempty(type)
  return
end

list = analysistypes;
switch type
  case list(:,1)
    %is an analysis method...
    eg = evrigui('analysis');
    eg.drop(obj);
    
  otherwise
    %something else, try opening and dropping
    try
      dropfig = feval(type);
    catch
      %just get an empty
      dropfig = [];
    end
    
    %Fix for 2014b.
    dropfig = double(dropfig);
    
    if isempty(dropfig) | ~isnumeric(dropfig) | ~ishandle(dropfig)
      msg = sprintf('Cannot edit model. See the "%s" function/tool for editing this model type.',type);
    else
      try
        feval(type,'drop',dropfig,[], guidata(dropfig), obj);
      catch
        %do nothing
        msg = lasterr;
      end
    end
    
end

if nargout==0
  if ~isempty(msg)
    error(msg);
  else
    clear msg
  end
end


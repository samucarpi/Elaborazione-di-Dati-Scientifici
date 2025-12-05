function out = drop_parse(obj, ev, windowtarget, options)
%DROP_PARSE Get drop transfer data from object and try to import data.
% INPUTS:
%   obj           : Java drop object.
%   ev            : Java envent object.
%   windowtarget  : If/where to autoimport object.
%                   ''             - [empty string] pass output from autoimport as
%                                    output.
%                   'filelocation' - File path only as output.
%                   'workspace'    - Loaded into workspace.
%                   'analysis'     - Loaded into analysis.
%                   'editds'       - Loaded into editds.
%
% Options: 
%   getcacheitem : [ 'on' | {'off'} ] If item dropped is a cache leaf node,
%                  try to return data from the cache.
%   concatenate  : [ {'on'} | 'off' ] Pass all items to autoimport so they 
%                  get concatenated. 
%
% OUTPUT:
%   out = n,2 cell area. First column is datatype and second column is data.
%         First cell will be empty if error occurs.
%
%
%I/O:  out = drop_parse(obj, ev, windowtarget);
%
%See also: ANALYSIS, BROWSE, EVRIJAVAMETHODEDT

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%NOTE: Using evrijavamethodedt may or may not work on systems prior to 8a
%so direct call had to be made in some cases. These calls could be thread
%unsafe but will likely be ok.

if nargin>0 & ischar(obj)
  options = [];
  options.getcacheitem   = 'off';
  options.concatenate    = 'off';
  
  if nargout==0; evriio(mfilename,obj,options); else; out = evriio(mfilename,obj,options); end
  return; 
end

if nargin<4; options = []; end
options = reconopts(options,mfilename);

%Drops can fail so wrap in try catch and issue warning to use menus
%to load data.

out = {[] []};

if nargin < 3
  windowtarget = '';%Return data in output.
end
drawnow
pause(.05)

try
  %Local transfer 'on' means drag drop all occured within Matlab so
  %DataFlavors method will work.
  %localTrans = get(ev,'LocalTransfer');%'on' 'off'
  
  %ev.getSource;%Get source.
  %ev.getDropTargetContext.getComponent%Get target.
  %ev.getDropTargetContext.getDropTarget.getAcceptedDataFlavor
  
  %Use custom methods.
  mylist = [];
  mystr  = [];
  try
    %Use methods from our custom drop target class.
    mylist = evrijavamethodedt('getTransferDataList',obj);
    if isempty(mylist)
      try
        mylist = obj.getTransferDataList;
      end
    end
    
    if ~isempty(mylist)
      mylist = getfilelist(char(mylist));
    end
    mystr  = char(evrijavamethodedt('getTransferDataStr',obj));
  end
  
  tr = [];%Transferable.
  try
    tr = evrijavamethodedt('getTransferable',obj);
  end
  
  %AWTINVOKE may not work on older systems so try direct call.
  if isempty(tr)
    try
      tr = obj.getTransferable;
    end
  end
  
  if ~isempty(tr)
    tf = [];%TransferFlavors.
    try
      %Can't use EDT here, causes java.lang.reflect.InvocationTargetException error.
      tf = tr.getTransferDataFlavors;
    end
  end
  
  %a = get(ev.getSource,'TransferDataList')
  
  %Scan the flavor list for recognized types. We must do this to find
  %items dropped from within Matlab application (like tree nodes and mat
  %files)
  tf_list = {};
  if ~isempty(tf)
    for i = 1:length(tf)
      tf_list{i} = char(evrijavamethodedt('getHumanPresentableName',tf(i)));
    end
  else
    %NOT USED Try generic string and or list call, most transfer object
    %support both of these methods.
    
  end
  
  if ~isempty(tf_list)
    %Scan the flavor list for recognized types. We must do this to find
    %items dropped from within Matlab application (specifically tree nodes).
    
    if ismember('treepath',lower(tf_list))
      %Return tree node/s
      paths = evrijavamethodedt('getTransferData',tr,tf(1));
      paths = evrijavamethodedt('getPath',paths);
      %paths = tr.getTransferData(tf(1)).getPath;
      for i = 1:length(paths)
        out{i,1} = 'treenode';
        out{i,2} = paths(i);
      end
    elseif ismember('application/x-matlab-variable-list',lower(tf_list))
      %one or more variables from the workspace
      indx = ismember(lower(tf_list),'application/x-matlab-variable-list');
      vlist = tr.getTransferData(tf(indx));
      viter = vlist.listIterator;
      out   = {};
      inbase = evalin('base','who');
      while viter.hasNext
        item = viter.next;
        itemname = item.getVariable;
        if ismember(char(itemname),inbase)
          out(end+1,1:2) = {'file' evalin('base',char(itemname))};
        end
      end
    elseif ~isempty(mylist)
      %Assume it's a file.
      if strcmp(windowtarget,'filelocation')
        %Get file location.
        out = [repmat({'file'},length(mylist),1) mylist(:)]; %make all first-column values 'file' and mylist as second column
      else
        if strcmp(options.concatenate,'on')
          %Get data.
          out = {'file' readfile(mylist,windowtarget)};  %read all as one
        else
          for j = 1:length(mylist)
            out{j,1} = 'file';
            out{j,2} = readfile(mylist{j},windowtarget);
          end
        end
      end
      
    else
      %couldn't load it - exit now
      evriwarndlg('Unable to Drop this object. Please try again or import data using menu items.','Drop Action Error')
      out = {[] []};
      return
    end
    
    %Assume all items being droped
    %If it's a file location, try import.
    %If node, just get node object and return it (similar to how uitree
    %works).
    %Could be Matlab varialbe, not sure how to work with that yet.
    %Could be string.
    %Other items: URL, webpath, pasted data, db connection???
    
  else
    %Transfer flavor failed so try looking at values from custom methods.
    %This happens often when dropping from outside applicaiton but that
    %should be fine since these will likely be files and TransferDataList
    %will work just fine. Sometiems these will be icon locations from tree
    %nodes if tf_list fails so we may need to watch out for this.
    
    %Remove [ and ] from the file string leaving just a comma separated
    %list.
    if strcmp(windowtarget,'filelocation')
      %Get file location.
      out = [repmat({'file'},length(mylist),1) mylist(:)]; %make all first-column values 'file' and mylist as second column
    else
      if strcmp(options.concatenate,'on')
        %Get data.
        out = {'file' readfile(mylist,windowtarget)};  %read all as one
      else
        for j = 1:length(mylist)
          out{j,1} = 'file';
          out{j,2} = readfile(mylist{j},windowtarget);
        end
      end
    end
  end
  if size(out,1)==1 & isempty(out{1,2})
    %one line and the second column (contents) is empty? return all empty
    %so we don't look like we're loading something that isn't there
    out = {[] []};
  end
catch
  evriwarndlg('Unable to Drop this object. Please try again or import data using menu items.','Drop Action Error')
  out = {[] []};
end

if ~isempty(out) & iscell(out) & strcmp('treenode',out{1}) & strcmp(options.getcacheitem,'on')
  %Droping single cache item or multiple items from workspace.
  dropnode = out{end,2};
  myval = evrijavamethodedt('getValue',dropnode);
  tempout = {};
  if strfind(myval,'cachestruct|')
    %Dropping cache item, multiselection not allowed.
    myname = strrep(myval,'cachestruct|','');
    myatts = modelcache('find',myname);
    tempout{1,1} = myatts.type;
    tempout{1,2} = modelcache('get',myname);
   elseif strfind(myval,'demo/')
     %Dropping demo node, spoof call to tree dbl click.
     myname = strrep(myval,'demo/','');
     [demo_data, demo_loadas, demo_idx] = getdemodata(myname);
     tempout = [repmat({'data'},length(demo_data),1) demo_data'];
  else
    %Drops from matlab workspace are handled above. Drops from Browse
    %worspace should be handled here.
    myud = get(dropnode,'UserData');
    if ~isempty(myud) & isfield(myud,'location') & strcmp(myud.location,'workspace')
      %TODO: Allow for more than one leaf dorp.
      tempout{1,1} = 'file';
      tempout{1,2} = evalin('base',char(myud.name));
    else
      %Leaf from some other kind of tree.
      tempout{1,1} = 'treenode';
      tempout{1,2} = myval;
    end
  end
  out = tempout;
end

%--------------------------------------
function out = readfile(in,windowtarget)
%Try to read a file.

out = [];

opts.target = windowtarget;
opts.defaultmethod = 'extension';
opts.error = 'gui';

if isempty(windowtarget)
  [data,name,source] = autoimport(in,opts);
  out = data;
else
  autoimport(in,opts);
end

%--------------------------------------
function outcell = getfilelist(instr)
%Remove [ and ] from the file string leaving just a comma separated
%list.

mylist = strrep(instr,'[','');
mylist = strrep(mylist,']','');
outcell = textscan(mylist,'%s','delimiter',',');
outcell = outcell{:};%Pull out of first cell array.

%Sort list in alphabetical order.
outcell = sort(outcell);


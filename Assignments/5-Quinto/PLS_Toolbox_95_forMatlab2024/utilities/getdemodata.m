function [demo_out, demo_loadas, demo_idx, demo_varname] = getdemodata(demo_name,demo_gui)
%GETDEMODATA Return list of demo data or single demo data record for loading. 
% Input 'demo_name' is the name of the demo data item to return information
% for. If omitted, the consolidated structure of all demo data XML files is
% returned (appropriate for populating demo data trees). Note that if a
% demo_gui name is provided (see below), this filter is applied before
% returning the structure.
%
% Optional second input (demo_gui) specifies a GUI filter for the demo data
% list (to handle multiple hits). Default is to do no filtering.
%
%OUTPUTS:
% demo_out    = Either (a) A structure containing all the demo data (with the
%               demo_gui filter applied) or (b) a cell array containing the
%               data in order of <loadas> tag where (empty where no data is
%               specified) that can be fed directly to analysis load data
%               callback: 
%
%               demo_out = {xblock yblock validation_xblock validation_yblock};
%
% demo_loadass = Cell array of loadas key words. 
%
% demo_idx     = The demo_idx output gives a logical index of data that's
%                contained in demo_out. 
% demo_varname = Cell array of Matlab friendly variable names (e.g., field
%                names contained in the mat file).
%
%I/O: demo_out = getdemodata(demo_name,demo_gui)
%I/O: [demo_out, demo_loadas, demo_idx, demo_varname] = getdemodata(demo_name,demo_gui)
%
%See also: DEMODATA.XML

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

persistent mydata

demo_out = {[] [] [] []};
demo_loadas = {'' '' '' ''};
demo_idx = [0 0 0 0];
demo_varname = {'' '' '' ''};

%Parse the xml file once.
if isempty(mydata)
  %Parse demos from xml file.
  demolist = which('demodata.xml','-all');
  if ~iscell(demolist)
    demolist = {demolist};
  end
  
  %create empty record
  empty  = [];
  empty.name        = '';
  empty.description = '';
  empty.file        = '';
  empty.gui         = '';
  empty.varitem     = {};
  
  mydata = [];

  if isempty(demolist)
    return
  end
  
  %merge in demo from all demo files  
  for onefile = demolist';
    try
      onedata = parsexml(onefile{:},1);
    catch
      evritip(['demoparseerr'],['Unable to parse one or more Demo Data XML files ("' onefile{:} '". Please check file formats.'],1);
    end
    onedata = onedata.dataitem;
    if ~iscell(onedata)
      onedata = {onedata};
    end
    for j=1:length(onedata)
      item = reconopts(onedata{j},empty,1);
      %fill in missing fields
      if ~isfield(item,'description') | isempty(item.description)
        if isfield(item,'name') & ~isempty(item.name)
          item.description = item.name;
        else
          item.description = item.file;
        end
      end
      if isempty(item.name)
        item.name = item.description;
      end
      if isempty(mydata)
        mydata = item;
      else
        mydata(end+1) = item;
      end
    end
  end
  
  if isempty(mydata)
    %If parsing one non-existant folder name you could end up here so
    %return or error will occur below.
    return
  end
  
  %sort
  [nwhat,norder]= sort({mydata.name});
  mydata = mydata(norder);
  
end

%filter for demo_gui name (if any)
thisdata = mydata;
if nargin>=2 & ~isempty(demo_gui);
  idx = ismember({thisdata.gui},demo_gui);
  thisdata = thisdata(idx);
end

%make sure each name appears only once (or else tree will fail)
names = {thisdata.name};
[u,i] = unique(names);
dups = setdiff(1:length(thisdata),i);
thisdata(dups) = [];  %drop duplicates

%return the structure (but only those that met the demo_gui filter)
if nargin==0 | isempty(demo_name)
  demo_out = thisdata;
  return;
end

%filter for name
idx = ismember({thisdata.file},demo_name);
thisdata = thisdata(idx);
if isempty(thisdata)
  return
end
thisdata = thisdata(1);  %make sure it is only one item

[junk, fname, fext] = fileparts(thisdata.file);

if isempty(fext)
  %Load a demo mat file. 
  dat = load(thisdata.file);
  if isempty(thisdata.varitem)
    thisdata.varitem = struct('varname',fieldnames(dat)','loadas','');
  end
else
  rawdat = autoimport(thisdata.file);
  dat.(fname) = rawdat;
  if isempty(thisdata.varitem)
    thisdata.varitem = struct('varname',fname,'loadas','');
  end
end

for i = 1:length(thisdata.varitem)
  if iscell(thisdata.varitem)
    varitem = thisdata.varitem{i};
  else
    varitem = thisdata.varitem(i);
  end
  switch varitem.loadas
    case 'xblock'
      demo_out{1} = dat.(varitem.varname);
      demo_loadas{1} = 'xblock';
      demo_idx(1) = 1;
      demo_varname{1} = varitem.varname;
    case 'yblock'
      demo_out{2} = dat.(varitem.varname);
      demo_loadas{2} = 'yblock';
      demo_idx(2) = 1;
      demo_varname{2} = varitem.varname;
    case 'validation_xblock'
      demo_out{3} = dat.(varitem.varname);
      demo_loadas{3} = 'validation_xblock';
      demo_idx(3) = 1;
      demo_varname{3} = varitem.varname;
    case 'validation_yblock'
      demo_out{4} = dat.(varitem.varname);
      demo_loadas{4} = 'validation_yblock';
      demo_idx(4) = 1;
      demo_varname{4} = varitem.varname;
    otherwise 
      %Append to end.
      demo_out{end+1} = dat.(varitem.varname);
      demo_loadas{end+1} = varitem.loadas;
      demo_idx(end+1) = 1;
      demo_varname{end+1} = varitem.varname;
  end
end

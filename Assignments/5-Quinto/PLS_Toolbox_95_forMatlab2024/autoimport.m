function [data,name,source] = autoimport(varargin)
%AUTOIMPORT Automatically reads specified file. Handles all standard filetypes.
% Automatically identifies a filetype and calls the appropriate reader. If
% no filename is provided, the user is prompted for a desired filetype to
% browse for. If no filename is provided but a specific filetype or method is
% provided, the user is prompted for a file of the given type. If both a
% filename and a method name are provided, the given file will be loaded
% using the specified method disregarding the file extension.
%
% Valid method types and file extensions can be retrieved using the command:
%    autoimport('methods')
%
% If output is requested, the loaded item(s) is/are returned as a single
% output. If no outputs are requested, the items are loaded into the base
% workspace or other action as defined by the options structure.
%
% Otional input (options) controls behavior on file import using one or
% more of the following fields:
%   target : [ {'workspace'} | 'analysis' | 'editds'] Target for file load. If
%            'workspace', file contents are loaded into base workspace (the
%            default behavior). If 'analysis', file contents are
%            automatically dropped into an empty Analysis GUI interface. If
%            'editds', file contents are loaded into a DataSet editor.
%   defaultmethod : [{'prompt'} | 'string' | 'error' | 'extension' | methodname ]
%            Governs how to handle input (filename) when no recognizable
%            file extension can be found. 'prompt' prompts the user to
%            identify the appropriate importer, 'string' interprets the
%            input as a string, 'error' returns an error, 'extension'
%            attempts to find an import function that exactly matches the
%            file extension. Any other valid methodname can also be
%            provided (use autoimport('methods') to get list of valid methods).
%   defaultpromptmethod : [{''}] Default method displayed when using 'prompt' importing.
%   importmethod : [{'editds_defaultimportmethods'}|'editds_imgimportmethods'|functionName]
%            Function to get import method list from.
%   block : [ {'both'} | 'x' | 'y'] If the import method supports x/y block
%            importing then allow option to be used with function  call.
%            Assuming default for workspace to be both. Import calls from
%            analysis will specify which block to load.
%   error : [ 'error' | {'gui'} | 'empty' ] Governs how to handle errors during
%            imports. 'error' returns an untrapped error, 'gui' traps the
%            error and presents an error dialog to the user, 'empty'
%            returns an empty matrix only.
%
%I/O: autoimport(filename,methodname,options)
%I/O: [data,name,source] = autoimport(filename,methodname,options)
%
%See also: AUTOEXPORT, EXPERIMENTREADR, IMAGELOAD, JCAMPREADR, PARSEXML, SPCREADR, TEXTREADR, XYREADR

%Copyright Eigenvector Research, Inc. 2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

persistent importmethods importmethodopt postloadfns

if nargin==1 & ischar(varargin{1}) & ismember(varargin{1},{'io'    'demo'    'help'    'examples'    'example'    'options'    'factoryoptions'    'test'});
  options = [];
  options.target = 'workspace';
  options.defaultmethod = 'prompt';
  options.defaultpromptmethod = '';
  options.importmethod = 'editds_defaultimportmethods';
  options.block = 'both';
  options.error = 'gui';
  if nargout==0; clear data; evriio(mfilename,varargin{1},options); else; data = evriio(mfilename,varargin{1},options); end
  return;
end

%parse inputs
methodname = [];
filename   = [];
options    = [];
switch nargin
  case 0
    %()
  case 1
    %(filename)
    filename   = varargin{1};
    methodname = [];
  case 2
    %(filename,methodname)
    %(filename,options)
    filename     = varargin{1};
    if isstruct(varargin{2})
      options    = varargin{2};
    else
      methodname = varargin{2};
    end
  case 3
    filename   = varargin{1};
    methodname = varargin{2};
    options    = varargin{3};
end
options = reconopts(options,mfilename);

%check for output of "dir"
if isstruct(filename) & isfield(filename,'name') & isfield(filename,'isdir')
  filename = {filename(~[filename.isdir]).name};
end

%Add dir check then get a list and continue.
if iscell(filename) & length(filename)==1
  filename = filename{1};  %when only one filename in cell, convert to string
end
if iscell(filename)
  %check if we have a cell array of folder names (multiple folders dragged,
  %for example)
  d = [];
  for j=1:length(filename)
    d(j) = isdir(filename{j});
    if ~d(j); break; end
  end
  if all(d)
    %ALL are folders? load each separately
    if nargout>0
      data = [];
    end
    for j=1:length(filename);
      if nargout>0
        mydata = autoimport(filename{j},methodname,options);
        [fp,fn,fe] = fileparts(filename{j});
        mydata.label{1} = repmat({fn},size(mydata,1),1);
        data = [data;mydata];
      else
        autoimport(filename{j},methodname,options);
      end
    end
    name = '';
    source = '';
    return
  end
end
if ~iscell(filename) & ~strcmp(filename,'methods') & isdir(filename)
  %Get all files in dir.
  basename = filename;
  filename = dir(filename);
  for j=1:length(filename)
    filename(j).name = fullfile(basename,filename(j).name);
  end
end

try
  %initialize outputs
  data   = [];
  name   = [];
  source = [];
  
  if ~isempty(filename) & isfield(filename,'name')
    %almost certainly the output of "dir", extract names (that aren't
    %folders)
    filename = {filename(~[filename.isdir]).name};
  end
  
  %get default methods
  if ~exist(options.importmethod,'file')
    options.importmethod = 'editds_defaultimportmethods';
  end
  
  if isempty(importmethods) | ~strcmpi(char(importmethodopt),options.importmethod)
    importmethods = feval(options.importmethod);
    importmethodopt = options.importmethod;
  end
  
  %return list of methods if user asked for that
  if strcmp(filename,'methods');
    data = [{importmethods{:,2}},[importmethods{:,3}]];
    data = [data,{'string'}];
    data = unique(data);
    return
  end
  
  %if no methodname given, try to parse from filename
  ext = '';
  if isempty(methodname)
    
    if isempty(filename)
      %no filename? Prompt user for file(s) to load
      [ffilter,fmethod] = editds_inputfilterspec;
      [filename,pth,filter] = evriuigetfile(ffilter,'Select File(s) to Import','multiselect','on');
      if isempty(filename) | (isnumeric(filename) & ~filename)
        if nargout == 0 ; clear data; end
        return;
      end
      if iscell(filename)
        filename = cellfun(@(i) fullfile(pth,i),filename,'uniformoutput',0);
      else
        filename = fullfile(pth,filename);
      end
      methodname = fmethod{filter};
      if strcmpi(methodname,'workspace')
        methodname = 'mat';
      end
    end
    
    if isempty(methodname)
      
      if iscell(filename)
        testfile = filename{1};
      else
        testfile = filename;
      end
      %try to parse methodname from filename
      [pth,base,ext] = fileparts(testfile);
      ext = ext(2:end);
      
      if strcmpi(ext,'mat')
        methodname = 'matlab';
      else
        %look in list for match
        methodname = '';
        for from=1:size(importmethods,1);
          if strcmp(testfile,importmethods{from,2}) | any(strcmp(testfile,importmethods{from,3}));
            %filename IS a methodname or extension recognisible with a method
            methodname = importmethods{from,2};
            if ~iscell(filename)
              filename = [];
            else
              filename = filename(2:end);
            end
            break;
          elseif ismember(lower(ext),importmethods{from,3})
            %extension matches one of our importers
            if isempty(methodname)
              methodname = importmethods{from,2};
            else
              %whoops! Found another with this same format
              if ~iscell(methodname)
                methodname = {methodname};
              end
              methodname{end+1} = importmethods{from,2};
              if ~strcmpi(options.defaultmethod,'error')
                %unless we're supposed to throw an error
                options.defaultmethod = 'prompt';  %FORCE prompt mode
              end
            end
          end
        end
      end
    end
    
  elseif ~isempty(methodname) & ~strcmpi(methodname,'string')
    %methodname passed explictly, see if it is in the list of importer names
    if ~ismember(methodname,importmethods(:,2))
      %not in the importer name list? Look for it in the filetype list
      for from=1:size(importmethods,1);
        if ismember(lower(methodname),importmethods{from,3})
          %"method" matches one of our importer filetypes - copy the method
          %name in instead
          methodname = importmethods{from,2};
        end
      end
    end
  end
  %if still no methodname (e.g. no file given!)
  if isempty(methodname) | iscell(methodname)
    switch options.defaultmethod
      case 'prompt'
        %prompt user
        if ~isempty(filename);
          prompt = 'Import as file type:';
        else
          prompt = 'Import from file type:';
        end
        if isempty(methodname) | ~iscell(methodname)
          mlist = 1:size(importmethods,1);
        else
          mlist = find(cellfun(@(i) any(ismember(methodname,i)),importmethods(:,2)));
        end
        initvalue = min(find(strcmp(options.defaultpromptmethod,importmethods(mlist,1))));
        from = listdlg('ListString',...
          importmethods(mlist,1)',...
          'ListSize',[280 230],...
          'SelectionMode','single',...
          'InitialValue',initvalue,...
          'PromptString',prompt,...
          'Name','Import');
        
        %check for valid selection
        if ~isempty(from)
          from = mlist(from);
          methodname = importmethods{from,2};
        else
          methodname = '';
          from = 1;
        end
        if isempty(methodname)
          if nargout == 0 ; clear data; end
          return
        end
        %store default
        setplspref('autoimport','defaultpromptmethod',importmethods{from,1})
        
      case 'error'
        if iscell(methodname) & length(methodname)>1
          error('Ambiguious file type. Could not identify which import method to use (multiple matches).');
        else
          error('Could not identify valid filetype or method')
        end
        
      case 'extension'
        %use file extension and search for a function which matches
        methodname = ext;
        
      otherwise
        %use defaultmethod as method
        methodname = options.defaultmethod;
        
    end
  end
  
  %-----------------------------------------------------
  %choose importer based on methodname
  
  %handle "clipboard" specially
  if strcmp(methodname,'clipboard');
    filename = clipboard('paste');
    methodname = 'string';
  end
  
  autoexplode = false;   %true indicates a structure should be exploded to its fields
  if isempty(methodname)
    error('Could not identify an importer')
  end
  switch methodname
    %-----------------------------------------------------
    case 'img'
      %Import image data using MIA Toolbox provided DataSet Object and loading
      %tools. Menu item will not be visible if MIA Toolbox not available.
      [data,name,source] = imageload;
      
      %-----------------------------------------------------
    case {'imgother' 'jpg' 'jpeg' 'tif' 'tiff' 'gif' 'bmp' 'png'}
      %Load a non .mat image from file.
      if isempty(filename)
        [data,name,source] = imageload(methodname);
      else
        switch lower(ext)
          case {'jpg' 'jpeg' 'tif' 'tiff' 'gif' 'bmp' 'png'}
            if iscell(filename)
              %If loading into workspace make recursive call and load
              %individually then user can cat as needed, otherwise
              %concat in tile mode.
              if evriio('mia') & (~strcmp(options.target,'workspace') | nargout>0)
                %Tile concat.
                data = image_folder_load(filename);
                data = cat_img(data,'spatial',0);
              else
                %Recursive.
                for j = 1:length(filename)
                  autoimport(filename{j},options);
                end
              end
            else
              data = imread(filename);
              if evriio('mia')
                data = buildimage(data);
              else
                data = dataset(data);
              end
            end
          otherwise
            %Give up and load explicitly...
            [data,name,source] = imageload(methodname);
        end
      end
      %-----------------------------------------------------
    case {'mat' 'matlab'}
      
      if isempty(filename)
        [filename, pathname, filterindex] = evriuigetfile({'*.MAT; *.mat', 'Matlab MAT files'; '*.*', 'All files'}, 'Open Matlab MAT file','MultiSelect', 'on');
        if filterindex==0
          out = [];
          return
        else
          %got one or more filenames? add path to each
          if iscell(filename)
            for lll = 1:length(filenames)
              filenames{lll} = fullfile(pathname,filenames{lll});
            end
          else
            filename = fullfile(pathname,filename);
          end
        end
      end
      
      if ~iscell(filename);
        
        if nargout==0 & strcmpi(options.target,'workspace')
          data = load(filename);
        else
          varlist = whos('-file',filename);
          if length(varlist)>1
            data = [];
            data.var = lddlgpls('*','Load Which Variable...',filename);
          else
            data = load(filename);
          end
        end
      else
        %multiple filenames, read each and combine into a single structure
        data = [];
        for findx = 1:length(filename)
          temp = load(filename{findx});
          for fyld = fieldnames(temp)';
            targfyld = fyld{:};
            if isfield(data,targfyld)
              ind = 0;
              while isfield(data,targfyld)
                ind=ind+1;
                targfyld = [fyld{:} '_' num2str(ind)];
              end
            end
            data.(targfyld) = temp.(fyld{:});
          end
        end
      end
      
      %if only one field, extract it now
      fn = fieldnames(data);
      if length(fn)==1
        data = data.(fn{:});
      else
        autoexplode = true;
      end
      
      %-----------------------------------------------------
    case 'workspace'
      
      if ~isempty(filename)
        data = evalin('base',filename);
        name = filename;
        source = '';
      else
        %try to do intelligent handling to "target"
        opts = {};
        if nargout==0 & strcmp(options.target,'workspace')
          %this will be going to the base workspace
          opts = {struct('exitonall',1)};
        end
        [data,name,source] = lddlgpls('*','Create DataSet from',opts{:});
      end
      
      %-----------------------------------------------------
    case 'spc'
      
      if isempty(filename)
        data = spcreadr;
      else
        data = spcreadr(filename);
      end
      
      %-----------------------------------------------------
    case 'spcs'
      
      data = spcreadr({});  %trigger multiple-file import
      
      %-----------------------------------------------------
    case 'asf'
      
      if isempty(filename)
        data = asfreadr({},struct('nonmatching','error'));
      else
        data = asfreadr(filename);
      end
      
      %-----------------------------------------------------
    case 'xml'
      [data, autoexplode] = getXMLData(filename,methodname,options);
      if isempty(data)
        if nargout == 0 ; clear data; end
        return;
      end
      
      %-----------------------------------------------------
    case 'string'
      if isempty(filename) | filename(1)~='<';
        data = parsexml(['<data class="numeric">' filename '</data>']);
        data = data.data;
        if isempty(data)
          data = parsemixed(filename);
        end
      else
        data = parsexml(filename);
        f = fieldnames(data);
        data = data.(f{:});
      end
      filename = 'data';
      
      %-----------------------------------------------------
    case 'excel'
      
      switch options.error
        case 'error'
          x_opts.parsing = 'automatic';
        otherwise
          x_opts.parsing = 'graphical_selection';
      end
      data = textreadr(filename,[],x_opts);
      
      %-----------------------------------------------------
    case 'excel_strict'
      
      x_opts.parsing = 'auto_strict';
      data = textreadr(filename,[],x_opts);
      
      %-----------------------------------------------------
    case 'text'
      switch options.error
        case 'error'
          x_opts.parsing = 'automatic';
        otherwise
          x_opts.parsing = 'gui';
      end
      data = textreadr(filename,[],x_opts);
      
      %-----------------------------------------------------
    case 'netcdfreadr'
      switch options.error
        case 'error'
          x_opts.massresprompt = 'off';
        otherwise
          x_opts.massresprompt = 'on';
      end
      data = netcdfreadr(filename,x_opts);
      
      %-----------------------------------------------------
    case 'xy'
      
      switch options.error
        case 'error'
          x_opts.parsing = 'automatic';
        otherwise
          x_opts.parsing = 'gui';
      end
      data = xyreadr(filename,x_opts);
      
      %-----------------------------------------------------
    case 'jcamp'
      
      data = jcampreadr(filename);
      
      %-----------------------------------------------------
    case 'file'
      
      data = uiimport;
      if isa(data,'struct') & ~isempty(data);
        for j=fieldnames(data)';
          assignin('base',j{:},getfield(data,j{:}));
        end
      else
        if nargout == 0 ; clear data; end
        return
      end
      
      %-----------------------------------------------------
    case 'smat'
      
      data = secureload(filename);
      
      %-----------------------------------------------------
    case 'visionairxmlreadr'
      %Vision air may or may not have y block coming in.
      
      [data, autoexplode] = getXMLData(filename,methodname,options);
      %-----------------------------------------------------
    case 'plt'
      data = pltreadr(filename);
      %-----------------------------------------------------
    case 'rawread'
      data = rawreadgui(filename);
      %-----------------------------------------------------
    case 'cytospecreadr'
      data = cytospecreadr(filename);
      %-----------------------------------------------------
    case 'rdareadr'
      data = rdareadr(filename);
    case 'spectrum'
      data = abbspectrumreadr(filename);
      %-----------------------------------------------------
    otherwise
      %first check for an appropriately named MAT file with an evriscript
      %object
      methodmat = evriwhich([methodname '.mat']);
      if ~isempty(methodmat)
        %found a MAT file
        sc = load(methodmat);
        f  = fieldnames(sc);
        if length(f)==1;
          sc = sc.(f{:});
          if ~isa(sc,'evriscript')
            error('%s did not contain a valid evriscript object',methodmat)
          else
            sc.filename = filename;
            sc = sc.execute;
            data = sc.data;
          end
        end
      else
        %check for an m-file appropriately named
        if ~exist(methodname,'file')
          error('Could not find an importer for file type "%s"',methodname)
        end
        data = feval(methodname,filename);
      end
      
      %-----------------------------------------------------
  end
  
  %do post-load callback as needed by addon products
  if isempty(postloadfns)
    postloadfns = evriaddon('autoimport_postload');
  end
  for j=1:length(postloadfns)
    data = feval(postloadfns{j},data,filename,methodname);
  end
  
  if nargout==0
    %no outputs requested?
    
    %try to do intelligent handling to "target"
    if ~isempty(data);
      switch options.target
        case 'analysis'
          %push into analysis
          h = findobj(allchild(0),'tag','analysis');
          targ = [];
          for j=1:length(h);
            %if isempty(getappdata(h(j),'dataset'));
            if ~analysis('isloaded','xblock',h(j))
              %locate an analysis window WITHOUT data
              targ = h(j);
              break;
            end
          end
          if isempty(targ); %create empty analysis GUI if none found
            targ = analysis;
          end
          
          %get data in as cell array and "drop" into analysis
          if ~iscell(data)
            data = {data};
          end
          analysis('drop', targ, [], guidata(targ), data{:});
          
        case 'editds'
          editds(data)
          
        case 'workspace'
          %convert root filename into valid Matlab variable name
          if ~autoexplode | ~isstruct(data)
            %if we're using the object we got directly (not exploding OR it
            %isn't a structure)
            targetname = name;
            if isempty(targetname) & ~isempty(filename) & ischar(filename)
              [pth,targetname] = fileparts(filename);
            end
            if isempty(targetname) & isdataset(data)
              targetname = data.name;
            end
            targetname(ismember(targetname,' .;:,')) = '_';
            goodchars = ['A':'Z' '_' 'a':'z' '0':'9'];
            targetname(~ismember(targetname,goodchars)) = '';
            if isempty(targetname)
              %no valid characters - replace with "data"
              targetname = 'data';
            end
            if ismember(targetname(1),['0':'9' '_'])
              %prepend if first character is numeric
              targetname = ['data_' targetname];
            end
            if length(targetname)>50
              %do not allow variable names longer than this number of characters
              targetname = targetname(1:50);
            end
            
            data = struct(targetname,{data});  %force it into a structure
          end
          
          %for each field in the structure, output to workspace
          for f = fieldnames(data)';
            targetname = f{:};
            %make sure targetname is unique before assigning it
            basename = targetname;
            index = 0;
            while ismember(targetname,evalin('base','who'));
              index = index+1;
              targetname = [basename '_' num2str(index)];
            end
            
            %assign to workspace
            assignin('base',targetname,data.(f{:}));
          end
          
      end
    end
    clear data
  end
  
catch
  
  %handle errors during import
  %(we must have options by the time we reach here, so decide based on
  %those options)
  if strcmp(options.error,'gui');
    erdlgpls({'Unable to import file.',lasterr},'Import Failed')
    if nargout == 0 ; clear data; end
    return
  elseif strcmp(options.error,'empty');
    if nargout == 0 ;
      clear data;
    else
      data = [];
    end
  else
    rethrow(lasterror);
  end
  
end

%-----------------------------------------------------
function [data, autoexplode] = getXMLData(filename,methodname,options)
% Get XML data from one or more files.

if ~iscell(filename)
  filename = {filename};
end

autoexplode = false;
if length(filename)>1
  autoexplode = true;
end

for j=1:length(filename);
  thismethodname = methodname;
  if ~isempty(filename{j})
    [fp,fn] = fileparts(filename{j});
    thisdata_y = [];
    
    if checkVA(filename{j})
      thismethodname = 'visionairxmlreadr';
    end
  end
  
  if strcmpi(thismethodname,'xml')
    [thisdata] = xmlreadr(filename{j},1);
  end
  
  if strcmpi(thismethodname,'visionairxmlreadr')
    [thisdata, thisdata_y] = visionairxmlreadr(filename{j},struct('block','both'));
  end
  
  if autoexplode %| ~isempty(thisdata_y)
    autoexplode = true;%Make sure to explode if ydata not empty.
    %More than one file being imported.
    switch thismethodname
      case 'xml'
        data.(safename(fn)) = thisdata;
      case 'visionairxmlreadr'
        if ~isempty(thisdata)
          data.(safename(thisdata.name)) = thisdata;
        end
        if ~isempty(thisdata_y)
          data.(safename([thisdata_y.name '_yblock'])) = thisdata_y;
        end
    end
  else
    %Single file being imported
    
    switch thismethodname
      case 'xml'
        data = thisdata;
      case 'visionairxmlreadr'
        if strcmp(options.block,'both')
          if isempty(thisdata_y)
            %No yblock returned.
            data = thisdata;
          else
            %Assume importing to workspace so create named structure that
            %will get exploded into base workpace.
            autoexplode = true;
            if ~isempty(thisdata)
              data.(safename(thisdata.name)) = thisdata;
            end
            if ~isempty(thisdata_y)
              data.(safename([thisdata_y.name '_yblock'])) = thisdata_y;
            end
          end
        else
          data = thisdata;
          if strcmp(options.block,'y')
            data = thisdata_y;
          end
        end
    end
  end
  
  
end

%----------------------------------------------
function isvafile = checkVA(filename)
%Search first couple of lines in xml file and check for visionair.

isvafile = 0;
%Open file and read each line into cell array.
fid = fopen(filename,'rt');
frewind(fid);
mycount = 0;
while ~feof(fid)
  thisline = lower(fgetl(fid));
  if ~isempty(strfind(thisline,'visionair'))
    isvafile = true;
    break
  end
  if mycount>100
    %Only count to max of first 100 lines. 
    break
  end
  mycount = mycount+1;
end
fclose(fid);





function varargout = experimentreadr(varargin)
%EXPERIMENTREADR Importer for automatic importing and alignment of X and Y blocks.
% Experiment files include a list of data files and their corresponding
% "properties of interest" (y-values). An experiment file is expected to be
% a plain text file or a Microsoft Excel-formatted file. The file should
% consist of at least one column of text strings indicating the files to be
% read and used as samples in the X-block of a regression or classification
% model and one column of numerical values indicating the values to use as
% the corresponding y-block. If no experiment file filename is specified on
% the command line, the user is prompted to locate a suitable file. 
% NOTE: The file names included in an experiment file must include the 
% full paths to the files.
%
% Once loaded, the experiment file can be manipulated, excluding samples
% using the include field of the Row Labels tab, or y-block columns using
% the include field of the Column Labels tab. Samples can be marked as in
% the Calibration or Validation set using the Row Labels tab.
%
% When all manipulations are complete, the user clicks the check-mark
% toolbar button to import all the indicated files and automatically load
% the experiment data into the Analysis GUI. 
%
% FILE FORMATS: The x-block files named can be in any standard readable
% file format. However, experiment files do not currently allow for any
% multi-file formats. Named files must contain only one sample (row) of
% data per file.
%
% HEADER ROW: An experiment file can include an optional header row for the
% filenames and properties of interest. This row can contain text lables
% which will be used to label the y-block columns (i.e. giving a text
% description of the property of interest.)
%
% OVERRIDING FILE FORMAT: If the extension on the specified files does not
% unambiguously identify the importer to be used (e.g. xy files with an
% extension of ".txt" will not be read using the XY importer), then the
% file may supply an additional "header" line above the column headers
% which specifies the file format to expect. This line must contain the
% keyword "format" followed by an equal sign and the name of the import
% method to use. For example:
%   format=xy
% Note that an overriding file format can ONLY be specified when a column
% header row (described above) is also included.
%
% CALIBRATION/VALIDATION: Experiment files can also contain information
% used to split the data into calibration and validation sets. To use this
% feature, include an additional column with the keywords "Calibration" or
% "Validation" next to each file. When the experiment is imported, the data
% will be automatically loaded into the appropriate data blocks. 
% NOTE: other valid synonyms include (all are case insensitive)
%    Calibration = Cal = C     
%    Validation  = Val = V = Test = T
%
% EXAMPLE:
%    filename,concentration,cal/val
%    file1.spc,13.2,cal
%    file2.spc,19.0,cal
%    file3.spc,5.3,cal
%    file4.spc,8.3,val
%  where file1, file2, ..,file4 include the path to the .spc file.
%
% The above would define an experiment with three samples with X-block data
% stored in the indicated files and y-values of 13.2, 19.0, 5.3, and 8.3
% (with a text description of the y-values as "concentration"). The first
% three files would be used for calibration, the last file for validation.
%
%I/O: experimentreadr(filename)
%
%See also: ANALYSIS, AUTOIMPORT, TEXTREADR

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files"
% distributed by Eigenvector Research Inc. for use with any software other
% than MATLAB®, without written permission from Eigenvector Research, Inc.

%I/O NOTE: first output is always empty (to allow autoimport to know this
%method doesn't return real values). Second input will be the handle of the
%DataSet editor created to manage the import

evriiotopics = evriio([],'validtopics');
if nargin<=1 
  %pass back empty matrix if any outputs requested
  if nargout>0
    [varargout{1:nargout}] = deal([]);
  end
  
  %no inputs or dataset as input? create experiment DSO
  if nargin==0 | isempty(varargin{1}) | (ischar(varargin{1}) & size(varargin{1},1)==1 & exist(varargin{1},'file') & ~ismember(varargin{1},evriiotopics))
    if nargin==0
      varargin{1} = [];
      mode = evriquestdlg('Load Experiment file or manually select x-block files?','Load X/Y Experiment Data','Experiment File','Manual Selection','Cancel','Experiment File');
      if isempty(mode) | strcmp(mode,'Cancel')
        return
      end
    else
      %if an empty matrix was passed in, this is a flag indicating we MUST
      %load an experiment file by asking the user to find the file
      mode = 'Experiment File';
    end
    
    switch mode
      case 'Manual Selection'       
        %allow user to specify files to import
        [ffilter,fmethod] = editds_inputfilterspec;
        [FileName,FilePath,FilterInd] = evriuigetfile(ffilter,'Select Files for X-block','MultiSelect','on');
        if isnumeric(FileName)
          return
        end
        setplspref('autoimport','defaultpromptmethod',ffilter{FilterInd,2});
        %get list
        cd(FilePath);
        varargin{1} = FileName;
        
      case 'Experiment File'
        %given an experiment file (or an empty filename)
        if isempty(varargin{1})
          %no filename? prompt user to locate file
          [file,pathname] = evriuigetfile({'*.exp;*.csv;*.txt;*.xls;*.xlsx','Readable Files (EXP,CSV,TXT,XLS,XLSX)';'*.*','All Files (*.*)'},'multiselect','off');
          if isnumeric(file) & file == 0
            out = [];
            return
          end
          varargin = {fullfile(pathname,file)};
        end
        
        %check file type to decide how to read it
        [FilePath,FileName,FileExt] = fileparts(varargin{1});
        if strcmp(FileExt,'.exp')
          type = {'text'};
          %changed from textreadr to text to allow the importtool gui to open if autoimport
          %is used
          %type = {'textreadr'};  %EXPs are text delimited files - use textreadr
        else
          type = {};
        end
        %read file in as a table
        myops = experimentreadr('options');
        switch FileExt
          case {'.xlsx', '.xls'}
            switch myops.hasHeader
              case 'no'
                d_table = readtable(varargin{1},'ReadVariableNames', false);
              otherwise
                d_table = readtable(varargin{1});
            end
          otherwise
            %grab import options so we can use the correct delimiter
            importOps = detectImportOptions(varargin{1},'FileType','text');
            delToUse = importOps.Delimiter;
            switch myops.hasHeader
              case 'no'
                d_table = readtable(varargin{1}, 'ReadVariableNames', false, 'Delimiter', delToUse, 'FileType', 'text');
              otherwise
                d_table = readtable(varargin{1}, 'Delimiter', delToUse, 'FileType', 'text', 'NumHeaderLines', 0);
            end
        end
        %get the variable names from the table
        %check variable names to see if there is a format line in the file
        d_cols = d_table.Properties.VariableNames;
        haveFormat = 0;
        if contains(d_cols{1}, 'format_')
            d = table2cell(d_table(2:end,:));
            myFormat = strsplit(d_cols{1}, '_');
            %fix format to match how it is expected
            formatToUse = strcat('format=', lower(myFormat{2}));
            haveFormat = 1;
        else
            d = table2cell(d_table);
        end
        
        anyNums = cellfun(@isnumeric, d);
        if any(any(anyNums)) %any numbers then import as usual using autoimport
            d = autoimport(varargin{1},type{:});
        else
            %no numbers, so just labels and class info
            %open importtool and set all columns as labels
            impToolsOps = importtool('options');
            cdat.Label = 1:size(d,2);
            [cdata, rdata] = importtool(d, impToolsOps, cdat);
            if isempty(cdata) && isempty(rdata) || isempty(cdata.Label)
                %no labels set in importtool. We need labels so throw an error
                errordlg('No Labels set in Experiment File');
                return;
            end 
        end
        varargin{1} = d;
    end  
  end
  
  d = varargin{1};
  if isnumeric(d)
    %convert numeric to DSO
    d = dataset(d);
    
  elseif ischar(d) & size(d,1)==1 & ismember(d,evriiotopics)
    %EVRIIO call
    options = [];
    options.requiredcolumns = {};
    options.requiredaxisscale = {};
    options.copyclasses = 'on';
    options.hasHeader = 'yes';
    
    if nargout==0; evriio(mfilename,d,options); else; varargout{1} = evriio(mfilename,d,options); end
    return
    
  elseif ischar(d) | iscell(d)
    %should get here if have no numbers experiment file
    rawData = d;
    %create pseudo-empty DSO with only NaNs but labels for rows
    d = dataset(ones(size(rawData,1),1)*nan); %single column of all NaNs
    d.include{2} = [];
    
    if ~isempty(cdata.Label)%cdata from importtool
        for i = 1:length(cdata.Label)
            thisLabel = cdata.Label(i);
            d.label{1,i} = rawData(:,thisLabel);
        end
    end
    d.labelname{1} = 'Filename';
    if ~isempty(cdata.Class)
        for i = 1:length(cdata.Class)
            thisColumn = cdata.Class(i);
            d.class{1,i} = rawData(:,thisColumn);
        end
    end
    if haveFormat %if there was a format line, put in description for use later
        d.description = formatToUse;
    end
    
  elseif isa(d,'evrigui')
    %get data from analysis (and trigger "do not load from files" mode)
    if ~strcmpi(d.type,'analysis')
      error('Experiment Reader cannot work with this interface')
    end
    %get y-block(s) from analysis and mark as cal/val
    obj  = d;
    d    = obj.getYblock;
    fakey = false;
    if isempty(d)
      fakey = true;
      if ~isempty(obj.getXblock) & isdataset(obj.getXblock)
        d = dataset(ones(size(obj.getXblock,1),1)*nan);  %single column of all NaNs
        d.include{2} = [];
        d = copydsfields(obj.getXblock,d,1);
      else
        %no X calibration data? fake y is a ZERO row but ONE column 
        d = dataset(nan);
        d.include{2} = [];
        d = d([],:);
      end
    end
    cv   = zeros(1,size(d,1));
    
    %find any existing cal/val set (so we don't create multiple)
    sets = d.classname(1,:);  %sample class names
    calval = min(strmatch(calvalname,sets));
    if isempty(calval)
      %figure out where we'll add this class
      calval = max(find(cellfun('isempty',d.class(1,:))));
      if isempty(calval)
        %no empty classes, add one
        calval = size(d.class,2)+1;
      end
    end
    
    if ~fakey
      %see if there is a validation set
      yval = obj.getYblockVal;
      if ~isempty(yval) & ~isempty(obj.getXblockVal)
        d  = [d; matchvars(d,yval)];
        cv = [cv ones(1,size(yval,1))];  %add 'val' for all these samples
      end
    else %fake y...
      %add whatever x-block validation is there
      if ~isempty(obj.getXblockVal)
        yval = obj.getYblockVal;
        if size(d,1)==0 & ~isempty(yval)
          %calibration data was empty, but yval is not...
          d = copydsfields(obj.getXblockVal,yval,1);
          cv = ones(1,size(yval,1));  %add 'val' for all these samples
        else
          %no validation y either, fake it
          nsamples = size(obj.getXblockVal,1);
          valy = dataset(nan(nsamples,size(d,2)));
          valy = copydsfields(obj.getXblockVal,valy,1);
          valy.include{2} = [];
          d  = [d; valy];
          cv = [cv ones(1,nsamples)];  %add 'val' for all these samples
        end
      end
    end
    
    %add classes for the samples
    d.classname{1,calval}   = calvalname;
    d.classlookup{1,calval} = calvallookup;
    d.class{1,calval}       = cv;
    
    FilePath = obj;    
    
  elseif isdataset(d)
    %all set - do nothing
    
  else
    error('Unrecognized input format');
    
  end
  
  options = reconopts([],mfilename);
  %check for required columns and add if not there
  if ~isempty(d)
    %add required data columns
    lbls = d.label{2};
    lbls = str2cell(lower(lbls));
    for index = 1:size(options.requiredcolumns,1);
      columnname = options.requiredcolumns{index,1};
      defaultvalue = options.requiredcolumns{index,2};
      if ~ismember(lower(columnname),lbls)
        additem = dataset(ones(size(d,1),1).*defaultvalue);
        additem.label{2} = columnname;
        d = [d additem];
      end
    end
    
%     if ~isempty(d.include{2})
%       d = d(:,d.include{2});  %drop excluded columns if we have something to keep
%     end
    
    %add required axisscales
    axlbls = lower(d.axisscalename(1,:));
    for index = 1:size(options.requiredaxisscale,1);
      columnname = options.requiredaxisscale{index,1};
      defaultvalue = ones(size(d,1),1).*options.requiredaxisscale{index,2};
      if ~ismember(lower(columnname),axlbls)
        %see if we find a data column with this label, if so move it to
        %axisscale
        ind = find(ismember(lbls,lower(columnname)));
        if ~isempty(ind)
          ind = ind(1);  %just in case there is more than one with this label
          defaultvalue = d.data(:,ind);  %use values from that column
          if size(d,2)==1
            %if no columns left, fill in empty, excluded NaN column
            d.data(:,ind) = NaN;
            d.include{2} = [];
            d.label{2} = '';
          else
            %if there are other columns, hard-delete this one
            d = delsamps(d,ind,2,2);  %hard delete this column
            d.label{2} = d.label{2}([1:ind-1 ind+1:end],:);
          end
        end
        
        %find free set
        ind = min(find(all([cellfun('isempty',d.axisscale(1,:)) 1;cellfun('isempty',d.axisscalename(1,:)) 1])));
        %and add needed axisscale
        d.axisscale{1,ind} = defaultvalue;
        d.axisscalename{1,ind} = columnname;
      end
    end
    
  end
  
  d.name = 'Experiment File';
 
  %remove white spaces in label names
  lbls_all = d.label{1,1};
  lbls_fixed = cell(size(lbls_all,1),1);
  for bb = 1:size(lbls_all, 1)
    lbls_inds = lbls_all(bb,:);
    lbls_fixed{bb,1} = strtrim(lbls_inds);
  end
  d.label{1,1} = lbls_fixed; %gets converted to char array
  
  %share data and link to it
  %NOTE: we store this in 0 because we need to store some special
  %properties and want to keep the DataSet Editor as a client ONLY
  myid = setshareddata(0,d,struct('calvalset',[],'plotsettings',{{'plotby',2,'viewclasses',1}}));
  linkshareddata(myid,'add',0,mfilename)
  
  %create EDITDS figure for this DSO, with appropriate controls
  %DISABLED:  'import'    'importybtn'    'experimentreadr(''importy'',gcbf)'    'enable'    'Import y-values from file'                'off'    'push'
  mytoolbar = {
    'newcolumn' 'newybtn'       'experimentreadr(''newy'',gcbf)'       'enable'    'Add blank column for new y-values'        'off'     'push'
    'newrow'    'newsamplesbtn' 'experimentreadr(''addsamples'',gcbf)' 'enable'    'Add new samples'                          'off'     'push'
    'calval'    'setcalvalbtn'  'experimentreadr(''setcalval'',gcbf)'  'enable'    'Set calibration/validation sample status' 'on'      'push'
    'gear'      'autosplit'     'experimentreadr(''autosplit'',gcbf)'  'enable'    'Automatically split data into cal/val sets' 'off'   'push'
    'help'      'splithelp'     'experimentreadr(''splithelp'',gcbf)'  'enable'    'Get help on this interface'                 'off'   'push'
    'cluster'   'addclassbtn'   'experimentreadr(''addclass'',gcbf)'   'enable'    'Add sample classes for classification'    'off'     'push'
    'plot'      'dseplotdata'   'experimentreadr(''viewplot'',gcbf)'   'enable'    'View Plot of Data'                        'on'      'push'
    'Deselect'  'dsedeselect'        'editds(''menu'',gcbo,[],guidata(gcbf))'        'enable' 'Deselect All'                  'on'      'push'
    'ok'        'okbtn'         'experimentreadr(''ok'',gcbf)'         'enable'    'Accept experiment setup'                  'on'      'push'
    'cancel'    'cancelbtn'     'experimentreadr(''cancel'',gcbf)'     'enable'    'Discard experiment setup'                 'off'     'push'
    };
  if isempty(d.data)
    allowed = -1;
  elseif all(isnan(d.data));
    allowed = 1;
  else
    allowed = [0 1 2];
  end
  edith = editds(myid,'toolbar',mytoolbar,'allowedmodes',allowed);
  set(edith,'closerequestfcn','experimentreadr(''cancel'',gcbf);');
  
  %get analysis handle to use
  if isa(FilePath,'evrigui') & strcmpi(FilePath.type,'analysis')
    %use the one we got the data from
    ah = FilePath.handle;
    setcalval(edith); %AND make sure we're in cal/val mode
  else
    ah = gcbf;
    if isempty(ah) | ~ishandle(ah) | ~strcmp(get(ah,'tag'),'analysis')
      ah = [];
    end
  end
  setappdata(edith,'analysishandle',ah);
  setappdata(edith,'FilePath',FilePath);

  updatetoolbar(myid);
  setcalval(edith,true);   %make sure cal/val exists in DSO

  if nargout>0
    varargout = {[],edith};
  end
  return  
end

if nargout==0
  feval(varargin{:})
else
  [varargout{1:nargout}] = feval(varargin{:});
end

%------------------------------------------------------------------
function  out = calvalname 
out = 'Sample Type';

function out = calvallookup 
strs = calvalstrings;
out = {
  0 strs{1}{1}
  1 strs{2}{1}
  };

function out = calvalstrings
%First column is primary expected string (and the strings which will be
% used in the lookup table) 
% Each additional column represents a string which should be converted to
% the given class number. The first string in each row is the ones that
% will be used in the lookup table.

out = {
  {'Calibration' 'Cal' 'C'}
  {'Validation' 'Val' 'V' 'Test' 'T'}
  };

%-----------------------------------------------------------------
function updateshareddata(dest,myobj,keyword,userdata)

if strcmp(keyword,'class')
    
  %Find which class set is the cal/val class
  if isfield(myobj.properties,'calvalset')
    calval = myobj.properties.calvalset;
  else
    calval = [];
  end
  if isempty(calval)
    %Not stored as a property... check class names
    sets = myobj.object.classname(1,:);  %sample class names
    calval = min(strmatch(calvalname,sets));
    if ~isempty(calval)
      %found one? store it as calvalset in properties
      updatepropshareddata(myobj.id,'update',struct('calvalset',calval),'calvalset')
    end
  end
  %check the classlookuptable of that class
  saveobj = false;
  if ~isempty(calval)
    classlookup = myobj.object.classlookup{1,calval};
    if isempty(myobj.object.class{1,calval})
      %no class at all? reset to all 0s
      myobj.object.class{1,calval} = zeros(1,size(myobj.object,1));
      saveobj = true;
    end
    mylookup = calvallookup;
    if ~strcmp(myobj.object.classname{1,calval},calvalname) ...
        | size(classlookup,1)~=2 ...
        | any(~ismember(myobj.object.class{1,calval},[mylookup{:,1}])) ...
        | any(~ismember(myobj.object.classlookup{1,calval}(:,2),mylookup(:,2)))
      %reset if number of classes changes
      myobj.object.classlookup{1,calval} = calvallookup;
      myobj.object.classname{1,calval} = calvalname;
      saveobj = true;
    end
  end
  
  if saveobj
    setshareddata(myobj.id,myobj.object,'');
  end
  
  updatetoolbar(myobj.id)
  
elseif ~strcmp(keyword,'delete')
  updatetoolbar(myobj.id)
end

%-----------------------------------------------------------------
function propupdateshareddata(dest,myobj,keyword,userdata)

%find editds handle
updatetoolbar(myobj.id)

%-----------------------------------------------------------------
function updatetoolbar(myid)

links = myid.links;
fig = strmatch('editds',{links.callback});
if ~isempty(fig) & ishandle(links(fig).handle)
  fig = links(fig).handle;
  wasnodata = ismember(1,getappdata(fig,'disallowedmodes'));
  havedata  = ~isempty(myid.object.data);
  if wasnodata & havedata
    %now have data, we didn't before
    setappdata(fig,'disallowedmodes',[-1]);
  end
  
  %set toolbar buttons as needed
  handles = guidata(fig);
  if isfield(handles,'okbtn')
    %we have the buttons, do the status of each
    if ~havedata
      enb = 'off';
    else
      enb = 'on';
    end
    set([handles.okbtn handles.addclassbtn handles.setcalvalbtn],'enable',enb)
    
  end
  
  FilePath = getappdata(fig,'FilePath');
  if isa(FilePath,'evrigui')
    set([handles.addclassbtn handles.newsamplesbtn handles.newybtn handles.setcalvalbtn],'visible','off')
    set([handles.autosplit handles.splithelp],'visible','on');
  else
    set([handles.autosplit handles.splithelp],'visible','off');
  end
  
end


%-----------------------------------------------------------------
function importy(fig)

%-----------------------------------------------------------------
function newy(fig)

[data,myid] = editds('getdataset',fig);

if size(data,2)==1 & all(isnan(data.data))
  %no data existed before
  data.data(:,1) = 0;
  data.include{2} = 1;
  experimentreadr(data);
  delete(fig);
else
  myid.object = [data zeros(size(data,1),1)];
end

%-----------------------------------------------------------------
function addsamples(fig)

[data,myid] = editds('getdataset',fig);

if size(data,2)==1 & all(isnan(data.data))
  %no data existed before
  fill = nan;
else
  fill = zeros(1,size(data,2));
end
myid.object = [data;fill];

%-----------------------------------------------------------------
function setcalval(fig,silent)

if nargin<2
  silent = false;
end

%get data
[data,myid] = editds('getdataset',fig);

%check for Cal/Val class and add if not there
newset = myid.properties.calvalset;
if isempty(newset)
  clsname = data.classname;
  newset  = strmatch(calvalname,clsname(1,:));
  if isempty(newset)
    %default values if we don't find labels which match expected classes
    calvalvalues = zeros(1,size(data,1));
    
    %look if there is a LABEL set with these values
    expected = calvallookup;
    expectedstr = calvalstrings;
    for setind=1:length(data.label(1,:));
      mylabels = lower(str2cell(data.label{1,setind}));
      if ~isempty(mylabels) & isempty(setdiff(unique(mylabels),lower([expectedstr{:}])))
        %found a label set which contains only strings similar to those
        %expected for the cal/val class set
        for cls=1:length(expectedstr);
          calvalvalues(ismember(mylabels,lower(expectedstr{cls}))) = expected{cls,1};
        end
        break;
      end
    end
    
    %add new class
    cls = data.class;
    newset = min(find([cellfun('isempty',cls(1,:)) 1]));
    
    %create cal/val set
    data.classname{1,newset} = calvalname;
    data.classlookup{1,newset} = calvallookup;
    data.class{1,newset} = calvalvalues;
    
    setshareddata(myid,data,'class');
  end

  %store set number in properties of shared data
  updatepropshareddata(myid,'update',struct('calvalset',newset),'calvalset')
end

if ~silent
  %put editds into correct tab and set class to be cal/val class
  editds('setmode',fig,1)
  
  %and set class selector to be class
  handles = guidata(fig);
  options = getappdata(fig,'options');
  myhandle = ['c' num2str(strmatch('class',options.fieldname)) 'set'];
  set(handles.(myhandle),'value',newset)
  editds('table','selectset',fig,handles.(myhandle))  %tell Editds we made this change
end

%-----------------------------------------------------------------
function autosplit(fig)

obj = getappdata(fig,'FilePath');

if isa(obj,'evrigui')

  %get data and assure there is a cal/val set
  setcalval(fig)
  [data,myid] = editds('getdataset',fig);
  cvset      = myid.properties.calvalset;
  currentval = data.class{1,cvset};
  incl       = data.include{1};
  norigcal   = size(obj.getXblock,1);
  if any(currentval(1:norigcal)==1) | any(currentval(norigcal+1:end)==0)
    r = evriquestdlg('Some samples have already been manually moved between Calibration and Validation sets. Reset all samples back to original placement before selection or select again from current split?','Reset Cal/Val','Reset','Select from Current Split','Cancel','Reset');
    switch r
      case {'Cancel' ''}
        return;
      case 'Reset'
        use = 1:norigcal;
      otherwise  %select from current cal samples (moving some into validation
        use = find(~currentval);
    end
  else
    use = find(~currentval);
  end  
  
  if ~isempty(obj.getXblockVal) | length(use)<size(data,1)
    %decide which direction to select
    seldir = evriquestdlg({'Select which direction:',' ',...
      '* Remove samples from calibration (Calibration -> Validation) or ',...
      '* Add samples to calibration (Validation -> Calibration)'},'Selection Direction','Remove From Calibration','Add To Calibration','Cancel','Remove From Calibration');
    switch seldir
      case {'Cancel' ''}
        return;
      case 'Remove From Calibration'
        mustuse = [];
      case 'Add To Calibration'
        mustuse = use;
        use = setdiff(1:size(data,1),use);
    end
  else
    %no validation samples
    mustuse = [];
  end
  haveYBlock = false;
  if ~isempty(obj.getYblock)
    haveYBlock = true;
  end
[mthd,splitoptions,blockToUse] = splitdialogfig(guihandles(fig),obj,haveYBlock);

  
  if isempty(mthd); return; end

  %get percentage to keep
  pct = [];
  while isempty(pct) | ~isfinite(pct) | length(pct)>1
    [mpos,screenratiox,screenratioy] = getmouseposition(fig);
    pct = inputdlg('Percentage to Keep','Select',1,{'66'},struct('Resize','on'));
    if isempty(pct); return; end
    pct = str2num(pct{1});
  end
  
  %get model (or build one if none exists)
  model = obj.getModel;
  noscores = ~ismember(lower(obj.getMethod),{'pca' 'pls' 'npls' 'mcr' 'pcr' 'lwr' 'cls' 'plsda' 'parafac'});

  wb = waitbar(1/3,'Automatic Cal/Val Selection');  

  sc = [];
  if ~noscores & ~isempty(model)
    %Now we MUST have a model...
    %get predictions
    pred = obj.getPrediction;
    if isempty(pred) & ~isempty(obj.getXblockVal)
      obj.calibrate;
      pred = obj.getPrediction;
      if isempty(pred)
        noscores = true;
      end
    end
    if ishandle(wb);  wb = waitbar(1/2,wb); else return; end
    
    if ~noscores
      %get scores dataset
      sc = plotscores(model,pred,struct('sct',1));
      sc = sc(:,1:size(model.loads{1},2));  %grab only the scores
      sc.include{1} = incl;
    end
  else
    noscores = true;
  end
  if noscores | isempty(sc)
    %no scores - base on raw data (we get here if the method didn't have
    %scores or we had some problem getting the scores from the model and/or
    %predictions
    sc = [obj.getXblock; obj.getXblockVal];
    sc.include{1} = incl;
  end
  
  if ishandle(wb);  wb = waitbar(2/3,wb); else return; end
  y = [];
  switch lower(mthd)
    case 'nearest neighbor'
      [scsel,sel] = reducennsamples(sc(use,:),ceil(length(use)*(pct/100)));
      incal = use(sel);
      
    otherwise
      switch lower(mthd)
        case 'kennard-stone'
          splitoptions.algorithm = 'kennardstone';
        case 'onion'
          splitoptions.algorithm = 'onion';
        case 'duplex'
          splitoptions.algorithm = 'duplex';
        case 'spxy'
          splitoptions.algorithm = 'spxy';
          y = obj.getYblock;
        case 'random'
          splitoptions.algorithm = 'random';
      end
      splitoptions.fraction = pct/100;
      if strcmp(splitoptions.algorithm,'kennardstone') & size(sc(use),1) > 5000
        out = evriquestdlg('Using Kennard-Stone with more than 5000  samples is computationally intensive and may take a long time to execute. Would you like to continue with Kennard-Stone or instead use the quicker ''Onion'' sample selection method?','Execution Time Warning', 'Continue' , 'Cancel','Use Onion method' ,'Cancel');
        if strcmp(out,'Cancel')
           if ishandle(wb); 
             delete(wb); 
           end
          return 
        end
        if strcmp(out, 'Use Onion method')
          splitoptions.algorithm ='onion';
        end
      end
      if haveYBlock && splitoptions.usereplicates && strcmp(blockToUse,'yblock')
        classSetToUse = splitoptions.repidclass;
        classInfoToUse = data.class{1,classSetToUse};
        sc.class{1,end+1} = classInfoToUse;
        splitoptions.repidclass = size(sc.class(1,:),2);
      end
      if ~isempty(y)
        splits = splitcaltest(sc(use,:),splitoptions,y(use,:));
      else
        splits = splitcaltest(sc(use,:),splitoptions);
      end
      incal  = use(splits.class==-1);
      
  end
  
  %match output of splitcaltest with what we need here
  newclass          = ones(1,size(data,1));  %start with everything in validation (including excluded and current vals)
  newclass(incal)   = 0;  %then, convert ONLY those that were marked as "cal" from the auto-split set back as cal
  newclass(mustuse) = 0;  %also mark ones we MUST USE as cal
  myid.object.class{1,cvset} = newclass;

  if ishandle(wb);  delete(wb); end
  
  figure(fig);
  
  evrihelpdlg('Validation samples have been selected from all available Calibration samples. Click the "Accept Experiment Setup" toolbar button to accept this split of data.','Selection Complete');
  
end

%-----------------------------------------------------------------
function splithelp(varargin)

evrihelp('automatic_sample_selection');

%-----------------------------------------------------------------
function viewplot(fig)

[data,myid] = editds('getdataset',fig);
targ = [];

%look for plotgui figure which is linked to this data
links = myid.links;
relatives = [links.handle];
relatives = relatives(ishandle(relatives));
for h = relatives(:)';
  if strcmp(getappdata(h,'figuretype'),'PlotGUI');
    targ = h;
    break;
  end
end

if isempty(targ)
  %no target? we'll create one
  calval = myid.properties.calvalset;
  if isempty(calval)
    calval = 1;
  end
  plotsettings = myid.properties.plotsettings;
  newpg = plotgui('new',myid,plotsettings{:},'viewclassset',calval);
else
  figure(targ);
end


%-----------------------------------------------------------------
function addclass(fig)

%get data
[data,myid] = editds('getdataset',fig);

%check for empty class
cls = data.class;
if isempty(cls{1,1})
  newset = 1;
else
  newset = min(find(cellfun('isempty',cls(1,:))));
  if isempty(newset)
    newset = size(cls,2)+1;
  end
end

%put editds into correct tab 
editds('setmode',fig,1)

%and set class set selector to new class
handles = guidata(fig);
options = getappdata(fig,'options');
myhandle = ['c' num2str(strmatch('class',options.fieldname)) 'set'];
set(handles.(myhandle),'value',newset)
editds('table','selectset',fig,handles.(myhandle))  %tell Editds we made this change


%-----------------------------------------------------------------
function ok(fig)
%OK button

[yblk,myid] = editds('getdataset',fig);
ah = getappdata(fig,'analysishandle');

FilePath = getappdata(fig,'FilePath');

try
  %PROCESS DSO NOW
 
  if ~isa(FilePath,'evrigui')
    
    waitbarhandle = waitbar(0.2,'Loading Experiment Data');
    drawnow;

    %hard-delete any excluded files
    yblk = nindex(yblk,yblk.include{1},1);
    
    %Load X-block based on filenames
    filenames = str2cell(yblk.label{1,1});
    if isempty(filenames)
      answer = evriquestdlg('No filenames have been entered. Do you want to manually locate corresponding files or cancel and go back to editing the experiment file?','No Filenames Found','Manual Load','Cancel','Manual Load');
      if strcmp(answer,'Cancel')
        delete(waitbarhandle);
        return
      end
    end
    
    %See if a format was specified in the headers
    format = '';
    cmts = yblk.description;
    line = strmatch('format',lower(cmts));
    if ~isempty(line);
      try
        [junk,format] = strtok(cmts(line,:),'=');
        format = strtrim(format(2:end));  %drop = and any additional spaces
      catch
        %any parsing errors?
        evriwarndlg(['Unable to understand file format header "' strtrim(cmts(line,:)) '"'],'Format Header Unrecognized');
      end
    end
    
    %verify all files exist (doesn't guarantee all are readable, but that
    %they are THERE at least)
    bad = zeros(1,length(filenames));
    for j = 1:length(filenames)
      bad(j) = ~exist(filenames{j},'file');
    end
    if all(bad)
      delete(waitbarhandle);
      if ~strcmpi(pwd,FilePath) & ~isempty(FilePath);
        cd(FilePath);
        ok(fig);
      else
        action = evriquestdlg({'The files specified could not be loaded. They must be in the current working directory which is now:' ' ' ['   ' pwd ] },'Files Not Found','Change Directory','Cancel','Change Directory');
        if strcmp(action,'Change Directory')
          newdir = uigetdir(pwd);
          if ~isnumeric(newdir)
            cd(newdir);
            ok(fig);
          end
        end
      end
      return
    end
    if any(bad)
      myid.object.include{1} = intersect(yblk.include{1},find(~bad));
      delete(waitbarhandle);
      action = evriquestdlg({'One or more of the files specified could not be loaded. These files have been marked as "excluded" (see the "Incl." column on Row Labels).' ' ' 'Click OK to ignore these files. Click Cancel to review the excluded files, fix the filenames and re-include the files.'},'Files Not Found','OK','Cancel','OK');
      if strcmp(action,'OK')
        ok(fig);
      end
      return
    end
    
    waitbar(0.4,waitbarhandle);
    
    xblk = autoimport(filenames,format);
    if isempty(xblk)
      delete(waitbarhandle);
      return
    end
    
    if size(xblk,1)~=size(yblk,1)
      evrierrordlg('The specified files did not contain one sample per file as required by an experiment file. You must read this data manually.','Invalid x-block file format');
      delete(waitbarhandle);
      return
    end
    
    waitbar(0.8,waitbarhandle);
    
    %copy sample-mode axisscales over to x and erase from y
    for j=1:size(yblk.axisscale(1,:));
      xblk.axisscale{1,j} = yblk.axisscale{1,j};
      xblk.axisscalename{1,j} = yblk.axisscalename{1,j};
      yblk.axisscale{1,j} = [];
      yblk.axisscalename{1,j} = '';
    end

    %Copy over other classes from yblk to xblk in case user had other class
    %information in an experiment file.
    eropts = experimentreadr('options');
    if strcmpi(eropts.copyclasses,'on')
      %Not sure if autoimport will add classes to xblk so create
      %offset and don't overwrite.
      setoffset = length(xblk.class(1,:));
      if isempty(xblk.class{1,setoffset})
        %Most likely case is there is no class info so first set is empty
        %and offset is actually 0;
        setoffset = setoffset-1;
      end

      for b_ind = 1:length(yblk.class(1,:))
          xblk.class{1,b_ind+setoffset}       = yblk.class{1,b_ind};
          xblk.classname{1,b_ind+setoffset}     = char(yblk.classname{1,b_ind});
          xblk.classlookup{1,b_ind+setoffset}   = yblk.classlookup{1,b_ind};
      end

      %Remove the calval set. 
      xblk = rmset(xblk,'class',1,myid.properties.calvalset);
    end

  else
    waitbarhandle = waitbar(0.5,'Preparing Split Data');
    drawnow;


    %evrigui object - read x from that object
    obj = FilePath;
    xblk = obj.getXblock;
    if ~isempty(obj.getXblockVal) & (isempty(obj.getYblock) | ~isempty(obj.getYblockVal))
      %get validation data IFF no y-blocks are there OR BOTH y-blocks are there
      xblkv = matchvars(xblk,obj.getXblockVal);
      xblk = [xblk;xblkv];
    end
    if size(xblk,1)~=size(yblk,1)
      evrierrordlg('Sorry. The X data in the Analysis Window does not match the Y data. Cal/Val manipulation cannot be done through this interface. Cut/Paste data manually.','Data Mismatch');
      return
    end
    
  end
  
  %get cal and val assignments from class in y-block
  calval = yblk.class{1,myid.properties.calvalset};
  yblk = rmset(yblk,'class',1,myid.properties.calvalset);
  
  %hard-delete columns with all missing data
  nodata = all(isnan(yblk.data));
  if any(nodata)
    yblk = delsamps(yblk,find(nodata),2,2); %hard delete those columns
  end

  %copy sample-mode include field over
  xblk.include{1} = yblk.include{1};
  
  %extract into cal and val and x and y blocks
  xcal = nindex(xblk,calval==0,1);
  xval = nindex(xblk,calval==1,1);
  
  if ~isempty(yblk)
    ycal = nindex(yblk,calval==0,1);
    yval = nindex(yblk,calval==1,1);
  else  %no y-values
    ycal = dataset([]);
    yval = dataset([]);
  end
  
  %create analysis (or open existing one)
  if isempty(ah) | ~ishandle(ah)
    ah = evrigui('analysis','-reuse');
  else
    ah = evrigui(ah);
  end
%   if isempty(ah.getMethod) & ~isempty(ycal)
%       ah.setMethod('pls');
%   end
  %check if doing custom cross validation and update
  updateCrossVal = 0;
  if isnumeric(ah.getCrossvalidation)
    %using custom cross validation
    %need to update custom cvi
    custom_cvi = ah.getCrossvalidation;
    newCustom_cvi = nindex(custom_cvi',calval==0,1);
    updateCrossVal = 1;
    ah.setCrossvalidation({'none'}); %temporarily set to none
  end
    
  
  %Push into analysis
  if ~isempty(xcal)
    ah.clearBothCal;
    ah.clearBothVal;
    ah.setXblock(xcal);
    ah.setYblock(ycal);
    if updateCrossVal %update custom cross val after clearing and setting xcal
      ah.setCrossvalidation({'custom' newCustom_cvi});
    end
  elseif isa(FilePath,'evrigui')
    %took from the GUI to start, clear calibration data if xcal was empty
    ah.clearBothCal;
  end
  if ~isempty(xval)
    ah.clearBothVal;
    ah.setXblockVal(xval);
    ah.setYblockVal(yval);
  end
  
  delete(fig)
  delete(myid)
catch
  evrierrordlg(['Unable to load experimental data: ' lasterr],'Import failed');
end
delete(waitbarhandle)

%-----------------------------------------------------------------
function cancel(fig)
%cancel - delete myid (which will close GUI and force caller to abandon
%building of DSO)

[data,myid] = editds('getdataset',fig);
if ~isempty(myid) & ~isa(getappdata(fig,'FilePath'),'evrigui')
  %if NOT called to readjust existing data? ask if we should throw the data away
  confirm = evriquestdlg('Discard experiment data and abort import?','Discard Experiment','Discard','Cancel','Discard');
  if strcmp(confirm,'Cancel')
    return
  end
end
delete(fig)
delete(myid)


%-----------------------------------------------------------------
% function [mthd,sopts] = splitdialogfig(handles,myclasses,myclassnames)
function [mthd,sopts,blockToUse] = splitdialogfig(handles,obj,haveYblock)
%Create and display split caltest settings.
%  mthd - return value.
%  sopts - options structure for splitcalltest.

mthd = [];
sopts = splitcaltest('options');
blockToUse = [];

mthd_types = {'Kennard-Stone' 'Onion' 'Duplex' 'Random' 'SPXY'};
if ~haveYblock
  mthd_types{1, end} = '<HTML><font color="gray">SPXY - Requires Y block data and no Y block loaded.</font></HTML>';
end

fontsize = getdefaultfontsize('normal');

fig = figure(...
  'visible','off',...
  'busyaction','cancel',...
  'integerhandle','off',...
  'tag','splitdialog',...
  'menubar','none',...
  'numbertitle','off',...
  'units','pixels',...
  'name','Data Split Dialog');
if haveYblock
  offset = 30; %offset for choosing X or Y block to select replicate class set
else
  offset = 0;
end
pos = get(fig,'position');
pos(3) = 400; 
pos(4) = 350+offset;
set(fig,'position',pos,'CloseRequestFcn', {@splitdialogfig_callback,fig});

centerfigure(fig)
%positionmanager(fig,'splitdialog') %set fig to previously stored position and make sure on-screen
btm = 198+offset;
%btm = 148;
alg_panel = uipanel('tag','alg_panel','units','pixels','title','Algorithm:','fontsize',fontsize,'position',[4 btm 394 150]);

%Make dropdown of algorithm.
%method_lbl = uicontrol('style','text','tag','algorithm_label','String','Algorithm:','units','pixels','position',[4 45 388 20],...
%  'HorizontalAlignment','left','background',myclr,'Fontsize',fontsize,'parent',alg_panel);

%Method dropdown menu.
method_ctrl = uicontrol('style','popupmenu','tag','method_ctrl','String',mthd_types,'units','pixels','position',[4 110 384 20],...
  'HorizontalAlignment','left','Fontsize',fontsize,'callback',{@splitdialogfig_callback,fig,haveYblock},'parent',alg_panel);

%Help text.
helpstr = {
  ' * Kennard-Stone selects a subset of samples which uniformly cover the data set and includes exterior samples as the calibration set. The remainder are placed in the test set.',...
  ' * Onion selects an exterior set of samples for calibration and the next exterior layer as test samples. The procedure is repeated for (nonion) layers with the remainder interior samples randomly assigned to calibration and test sets.',...
  ' * Duplex selects the two samples farthest apart and assigns to the calibration set and removes from consideration. Then, the next two samples which are farthest apart are assigned to the test set and removed from consideration. Then alternates assigning each remaining sample to the cal and test sets based on the distance to the points already selected.',...
  ' * Random will split the data into calibration and test sets randomly. Useful for large, unordered datasets.',...
  ' * SPXY takes X and Y data into account to select samples that provide uniform coverage of the dataset and include samples on the boundary of the data set.'...
  };

setappdata(fig,'helpstrings', helpstr);
help_lbl = uicontrol('style','text','tag','help_label','String',helpstr{1},'units','pixels','position',[4 5 380 100],'parent',alg_panel);
btm = btm-78;
%btm = btm-108;

mahal_string = 'Mahalanobis - uses the covariance matrix';
dist_panel = uipanel('tag','dist_panel','units','pixels','title','Distance Measure:','fontsize',fontsize,'position',[4 btm 394 70]);
euclidean_radioBtn = uicontrol('style','radiobutton','tag','euclidean_radio','String','Euclidean','Value', 1,'units','pixels','position',[4 28 300 20],'parent',dist_panel,...
  'enable','on','callback',{@splitdialogfig_callback,fig});
mahal_radioBtn = uicontrol('style','radiobutton','tag','mahal_radio','String',mahal_string,'units','pixels','position',[4 4 300 20],'parent',dist_panel,...
  'enable','on','callback',{@splitdialogfig_callback,fig});
distclr = get(dist_panel,'BackgroundColor');
set([euclidean_radioBtn mahal_radioBtn], 'HorizontalAlignment','left','background',distclr,'Fontsize',fontsize);

btm = btm-(70+offset);
rep_panel = uipanel('tag','rep_panel','units','pixels','title','Replicates','fontsize',fontsize,'position',[4 btm 394 (70+offset)]);
%rep_panel = uipanel('tag','rep_panel','units','pixels','title','Replicates','fontsize',fontsize,'position',[4 btm 394 100]);
repclr = get(rep_panel,'BackgroundColor');

%Replicate controls.
rep_lbl = uicontrol('style','text','tag','rep_label','String','Keep Replicates Together:','units','pixels','position',[4 (32+offset) 200 20],'parent',rep_panel);
rep_ctrl = uicontrol('style','checkbox','tag','rep_ctrl','String','','units','pixels','position',[188 (32+offset) 150 20],...
  'callback',{@splitdialogfig_callback,fig,haveYblock},'parent',rep_panel);

if haveYblock
  block_lbl = uicontrol('style','text','tag','block_label','String','Classes from:','units','pixels','position',[4 36 200 20],'parent',rep_panel);
  xblock_radioBtn = uicontrol('style','radiobutton','tag','xblock_radio','String','X-Block','units','pixels','position',[188 36 100 20],'parent',rep_panel,...
    'enable','off','callback',{@block_radioBtn_callback,fig,obj});
  yblock_radioBtn = uicontrol('style','radiobutton','tag','yblock_radio','String','Y-Block','units','pixels','position',[258 36 100 20],'parent',rep_panel,...
    'enable','off','callback',{@block_radioBtn_callback,fig,obj});
  set([block_lbl xblock_radioBtn yblock_radioBtn], 'HorizontalAlignment','left','background',repclr,'Fontsize',fontsize);
end

if haveYblock
  data = obj.getYblock;
else
  data = obj.getXblock;
end
classsetnames = getclassNames(data);

class_lbl = uicontrol('style','text','tag','class_label','String','Replicate Class Set:','units','pixels','position',[4 6 200 20],'parent',rep_panel);
class_ctrl = uicontrol('style','popupmenu','tag','class_ctrl','String',classsetnames,'units','pixels','position',[188 10 176 20],...
  'callback',{@splitdialogfig_callback,fig},'parent',rep_panel,'enable','off');
btm = btm-38;
helpbtn = uicontrol('style','pushbutton','tag','helpbtn','String','Help','units','pixels','position',[84 btm 100 28],'callback',{@splitdialogfig_callback,fig});
okbtn = uicontrol('style','pushbutton','tag','okbtn','String','OK','units','pixels','position',[190 btm 100 28],'callback',{@splitdialogfig_callback,fig});
cancelbtn = uicontrol('style','pushbutton','tag','cancelbtn','String','Cancel','units','pixels','position',[296 btm 100 28],'callback',{@splitdialogfig_callback,fig});

%set([help_lbl1 help_lbl2 rep_lbl rep_ctrl class_lbl class_ctrl okbtn cancelbtn helpbtn],'HorizontalAlignment','left','background',repclr,'Fontsize',fontsize)
set([help_lbl rep_lbl rep_ctrl class_lbl class_ctrl okbtn cancelbtn helpbtn],'HorizontalAlignment','left','background',repclr,'Fontsize',fontsize)
set([rep_lbl rep_ctrl class_lbl class_ctrl okbtn cancelbtn helpbtn],'HorizontalAlignment','left','background',repclr,'Fontsize',fontsize)

%Set color to better look.
%set([help_lbl1 help_lbl2],'background',repclr);
set(help_lbl,'background',repclr);
set([method_ctrl class_ctrl],'background','white');

%Refresh handles.
handles = guihandles(fig);

%Set units normalized here after we have everything normally placed so
%larger font size screens can expand as needed.
set([allchild(fig); allchild(rep_panel); allchild(alg_panel)],'units','normalized');

set(fig,'visible','on','color',repclr);

if get(0,'ScreenPixelsPerInch')>100
  %Upsize figure if zoom font.
  set(fig,'position',pos*1.25)
end

uiwait(fig);

okpress = getappdata(fig,'okpressed');
if ~isempty(okpress)
  mthdv = get(method_ctrl,'Value');
  mthd  = mthd_types{mthdv};%Selected method.
  
  if get(handles.rep_ctrl,'Value')
    %Get and check replicate class.
    clsl = get(handles.class_ctrl,'string');
    clsv = get(handles.class_ctrl,'value');
    myval = clsl(clsv);
    if iscell(myval)
      myval = myval{1};
    end
    if strcmp(myval,'Empty Class')
      erdlgpls('Replicate Class not found, disabling keep replicates together option.','Replicate Class Not Found')
      sopts.usereplicates = 0;
    else
      sopts.usereplicates = 1;
      sopts.repidclass = clsv;
    end
  end
  if haveYblock
    if get(handles.yblock_radio,'Value')
      blockToUse = 'yblock';
    elseif get(handles.xblock_radio, 'Value')
      blockToUse = 'xblock';
    end
  end
  if get(handles.euclidean_radio,'Value')
    sopts.distmeasure = 'euclidean';
  elseif get(handles.mahal_radio,'Value')
    sopts.distmeasure = 'mahalanobis';
  end
end

if ishandle(fig)
  delete(fig);
end

%-----------------------------------------------------------------
function splitdialogfig_callback(varargin)

get(varargin{1},'tag');

hdl     = varargin{1};
fig     = varargin{3};
handles = guihandles(fig);
haveYblock = 0;
if nargin == 4
  haveYblock = varargin{4};
end

if strcmp(get(hdl,'tag'),'helpbtn')
  splithelp;
  return
end

if strcmp(get(hdl,'tag'),'okbtn')
  %Closed or canceled.
  setappdata(fig,'okpressed',1);
end

if strcmp(get(hdl,'tag'),'rep_ctrl')
  %Enable/disable class and check for class.
  
  hval = get(handles.rep_ctrl,'value');
  if hval
    %Enable class set chooser.
    if haveYblock
      set(handles.xblock_radio,'enable','on');
      set(handles.yblock_radio,'enable','on');
      set(handles.yblock_radio,'Value',1);
    end
    set(handles.class_ctrl,'enable','on')
  else
    set(handles.xblock_radio,'enable','off');
    set(handles.yblock_radio,'enable','off');
    set(handles.class_ctrl,'enable','off')
    set(handles.yblock_radio,'Value',0);
    set(handles.xblock_radio,'Value',0);
  end
end

if strcmp(get(hdl,'tag'), 'euclidean_radio')
  set(handles.euclidean_radio, 'Value',1)
  set(handles.mahal_radio,'Value',0);
end
if strcmp(get(hdl,'tag'), 'mahal_radio')
  set(handles.euclidean_radio, 'Value',0)
  set(handles.mahal_radio,'Value',1);
end

if strcmp(get(hdl,'tag'),'class_ctrl')
  %Check for valid classes.
  clsl = get(handles.class_ctrl,'string');
  clsv = get(handles.class_ctrl,'value');
  myval = clsl(clsv);
  if iscell(myval)
    myval = myval{1};
  end
  if strcmp(myval,'Empty Class')
    erdlgpls('DataSet must have valid sample class set to use replicate grouping. Edit dataset and add classes before using this feature.','Classes Needed')
  end
end

if strcmp(get(hdl,'tag'),'method_ctrl')
  methodValue = get(handles.method_ctrl, 'value');
  methodString = get(handles.method_ctrl, 'string');
  myMethod = methodString{methodValue};
  if contains(myMethod, 'SPXY') & ~haveYblock
    set(handles.okbtn, 'enable', 'off');
  elseif strcmp(get(handles.okbtn,'enable'),'off')
    set(handles.okbtn, 'enable', 'on');
  end
  helpStr = getappdata(fig, 'helpstrings');
  helpStrToShow = helpStr{methodValue};
  set(handles.help_label, 'String', helpStrToShow);    
end
  
if ismember(get(hdl,'tag'),{'okbtn' 'cancelbtn' 'splitdialog'})
  uiresume
end

% if strcmp(get(hdl,'tag'),'cancelbtn') & ishandle(fig)
%   delete(fig);
% end


function block_radioBtn_callback(varargin)
get(varargin{1},'tag');

hdl     = varargin{1};
fig     = varargin{3};
handles = guihandles(fig);
obj = varargin{4};
%xblock_radioVal = get(handles.xblock_radio,'Value');

if strcmp(get(hdl,'tag'),'xblock_radio')
  set(handles.xblock_radio,'Value', 1);
  set(handles.yblock_radio,'Value', 0);
  data = obj.getXblock;
elseif strcmp(get(hdl,'tag'),'yblock_radio')
  set(handles.xblock_radio,'Value', 0);
  set(handles.yblock_radio,'Value', 1);
  data = obj.getYblock;
end

classsetnames = getclassNames(data);
set(handles.class_ctrl, 'String', classsetnames);

function classNamesToUse = getclassNames(data)

myclasses = data.class(1,:);
myclassnames = data.classname(1,:);
%Parse class information.
for i = 1:length(myclasses)
  if ~isempty(myclasses{i})
    if ~isempty(myclassnames{i})
      classsetnames{i} = myclassnames{i};
    else
      classsetnames{i} = ['Class Set ' num2str(i)];
    end
  else
    classsetnames{i} = 'Empty Class';
  end
end

classNamesToUse = classsetnames;
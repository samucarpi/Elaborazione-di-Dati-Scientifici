function [ds_out,msg] = struct2ds(ds_struct)
%STRUCT2DS Convert a structure into a dataset object.
% Attempts to convert fields of a structure (in) into corresponding fields
% in a DataSet object (out). Field names and contents should be the same as
% those in a DataSet object. Some fields (such as history and moddate)
% cannot be copied over and will be ignored.
%
% One critical difference between standard DataSet object field formats and
% what is expected in the input structure is that the fields: label, class,
% axisscale, title, and include are cells with three modes (instead of the
% usual two) where the indices representing:
%    {mode, val_or_name, set}
% The first and thrid dimensions are the same as with the standard indices
% for these fields, but the second is the value "1" for the actual value
% for the field and "2" for the name (usually stored in the DataSet object
% in a field named "____name", such as "classname")
%
% INPUT:
%    in = Structure containing one or more fields appropriate for a DataSet
%         object. See the DataSet object documentation for information and
%         format of these fields
% OUTPUTS:
%   out = DataSet object created from the contents of the input structure.
%   msg = Text of any error/warning messages discovered during the
%          conversion. Returned as empty if no errors were found.
%
% If only one output is requested, any discovered errors/warnings will be
% displayed on the screen.
%
%I/O: [ds_out,msg] = dataset.struct2dataset(ds_struct)
%
%See also: DATASET, EDITDS

%Copyright © Eigenvector Research, Inc. 2006

msg = {};

%prepare empty DSO
ds_out = dataset;

%not a structure? try making a dataset out of what they passed
if ~isstruct(ds_struct)
  ds_out.data = ds_struct;
  return
end

%check for fields we don't know how to place
fields = {  'name'  'type'  'author'  'date'  'moddate'  'imagesize'  'imagemode'  ...
  'data'  'label'  'axisscale'  'imageaxisscale' 'title'  'class' 'include' ...
  'description'  'userdata'  'datasetversion'  'history' 'uniqueid'};
namefields = {'labelname' 'axisscalename' 'imageaxisscalename' 'titlename' 'classname'};
if str2num(ds_out.datasetversion)>=5.0;
  %DSO v5 includes a few new fields
  fields = [fields {'classlookup' 'axistype' 'imageaxistype'}];
end

nomatch = setdiff(fieldnames(ds_struct),[fields namefields]);
if ~isempty(nomatch)
  msg = [msg {'Some fields in the input structure do not have matching fields in a DataSet object and have been discarded.'} ...
    {sprintf('   - %s\n',nomatch{:})}];
end

explictnamefields = any(ismember(fieldnames(ds_struct),namefields));
if ~explictnamefields
  %so far, it appears the name fields are mixed in with the label content
  for labelfield = {'label' 'class' 'axisscale'};
    if isfield(ds_struct,labelfield{:});
      val = ds_struct.(labelfield{:});
      if ndims(val)>2
        break;  %found at least one which is expilitly n-way (includes names)
      elseif size(val,2)>1
        if any(~cellfun('isclass',val(:,2),'char')) | any(cellfun('size',val(:,2),1)>1)
          %found something in column 2 which does NOT appear to be a name, we
          %must assume they have name fields explictly (but all are empty)
          explictnamefields = 1;
          break;
        end
      end
    end
  end
end
discarded_invalid = {};  %holds the list of could-not-convert fieldnames

%copy these over directly
fields = {'name' 'author' 'data' 'type' 'description' 'userdata'};
if str2num(ds_out.datasetversion)>=4.0 & isfield(ds_struct,'type') & strcmp(ds_struct.type,'image')
  %copy image info (if image mode and is available for the DSO version)
  fields = [fields {'imagesize' 'imagemode'}];
end

%Flag for empty array.
emptyArrayFlag = false;

if isfield(ds_struct,'data');
  try
    if ischar(ds_struct.data);
      %try to force data to be numeric
      ds_struct.data = str2num(ds_struct.data);
    end
  end
  if isempty(ds_struct.data)
    if any(size(ds_struct.data)>0)
      %Specail case of empty array. Spoof a non empty array with NaN so we
      %can add meta data because can't assign meta with data empty. 
      oldArraySize = size(ds_struct.data);
      newArraySize = oldArraySize;
      newArraySize(newArraySize==0)=1;
      ds_struct.data = nan(newArraySize);
      emptyArrayFlag = true;
    else
      error('Data field evaluates to empty (check for invalid characters).')
    end
  end
end

for f = fields;
  if isfield(ds_struct,f{:})
    try
      ds_out = setfield(ds_out,f{:},getfield(ds_struct,f{:}));
    catch
      discarded_invalid = [discarded_invalid f];
    end
  end
end

%copy these over specially
fields = {'label' 'axisscale' 'title' 'class' 'include'};
if str2num(ds_out.datasetversion)>=5.0;
  %DSO v5 includes a few new fields
  fields = [fields {'classlookup' 'axistype' 'imageaxistype'}];
end
discarded_notcell = {};
for f = fields;
  if isfield(ds_struct,f{:})
    val = getfield(ds_struct,f{:});
    if ~iscell(val);
      discarded_notcell = [discarded_notcell f];
      continue;
    end

    setmode = 2;      %if name fields are given explictly, sets are mode 2
    if ~explictnamefields & ~ismember(f{:},{'axistype','classlookup','imageaxistype'})
      %if name fields are NOT given explictly, they are assumed
      %mixed in with mode 2 of these fields. Therefore mode 3 is sets.
      % (EXCEPT: axistype, imageaxistype and classlookup in which mode 2 is ALWAYS sets
      setmode = 3;
    end
    if strcmp(f{:},'include')
      val = val(:);  %make it a column vector ALWAYS
      val = val(1:ndims(ds_out.data));
    end

    for mode = 1:size(val,1);
      for set = 1:size(val,setmode);
        %copy first column of cell into field itself
        try
          S   = substruct('.',f{:},'{}',{mode,set});
          subval = nindex(val,{mode set},[1 setmode]);
          ds_out = subsasgn(ds_out,S,subval{1});
        catch
          discarded_invalid = [discarded_invalid f];
        end
        if ~explictnamefields
          if size(val,2)>1;
            %copy second column of cell into ____name
            try
              if ismember(f{:},{'axistype','imageaxistype','classlookup','include'}); continue; end  %skip this for include
              S   = substruct('.',[f{:} 'name'],'{}',{mode,set});
              ds_out = subsasgn(ds_out,S,val{mode,2,set});
            catch
              discarded_invalid = [discarded_invalid {[f{:} 'name']}];
            end
          end
        else
          %copy name fields explictly
          if ismember(f{:},{'axistype','imageaxistype','classlookup','include'}); continue; end  %skip this for some fields
          try
            nameval = getfield(ds_struct,[f{:} 'name']);
          catch
            nameval = {};
          end
          try
            S   = substruct('.',[f{:} 'name'],'{}',{mode,set});
            ds_out = subsasgn(ds_out,S,nameval{mode,set});
          catch
            discarded_invalid = [discarded_invalid {[f{:} 'name']}];
          end

        end
      end
    end
  end
end

%give notes if something went wrong
if ~isempty(discarded_notcell);
  msg = [msg {'Some fields were expected to be cells but were not.' 'These fields have been discarded.'} ...
    {sprintf('   - %s\n',discarded_notcell{:})}];
end
if ~isempty(discarded_invalid);
  msg = [msg {'Some fields were not in the correct format for a DataSet object and have been discarded.'} ...
    {sprintf('   - %s\n',discarded_invalid{:})}];
end

if emptyArrayFlag
  %Use delsamps to get back to empty array.
  emptyDim = find(oldArraySize==0);
  ds_out = delsamps(ds_out,1,emptyDim(1),2);
end

%handle messages
if ~isempty(msg);
  msg = [msg {'Please see the documentation for the DataSet object to learn more about the correct format for these fields'}];

  %show messages (if not requested as output)
  if nargout <2
    disp(sprintf('%s\n',msg{:}));
  end
end
end

%Overload of nindex in private folder caused weird errors in crossval.
%Moved to sub function here. Only used for struct2ds at this point. 
%---------------------------------------
function x = nindex(x,indices,modes)
%NINDEX Generic subscript indexing for n-way arrays.
% NINDEX allows indexing into an n-way array without concern to the actual
% number of modes in the array. Requires n-way array (x) a cell of
% requested indices (indices) (e.g. {[1:5] [10:20]} ) and the modes to which
% those indicies should be applied (modes). Any additional modes not
% specified in (indices) will be returned as if reffered to as ':' and
% returned in full. If (modes) omitted, it is assumed that indices should
% refer to the first modes of (x) up to the length of (indices).
%
% EXAMPLES:
%   x = nindex(x,{1:5});      %extract indices 1:5 from mode 1 (rows) of any n-way array
%   x = nindex(x,{1:5},3);    %extract indices 1:5 from mode 3 of any n-way array 
%   x = nindex(x,{1:10 1:5},[5 8]);  %extract 1:10 from mode 5 and 1:5 from mode 8
%   x = nindex(x,{1:10 1:5});  %extract 1:10 from mode 1 and 1:5 of mode 2
%     The last example is equivalent to performing:
%         x = x(1:10,1:5);          %for a 2-way array or
%         x = x(1:10,1:5,:,:,:);    %for a 5-way array
% Note, the use cell notation can be omitted on indices if only one mode is
% being indexed:   x = nindex(x,5:10,3);  %is valid
%
%I/O: x = nindex(x,indices,modes)
%
%See also: NASSIGN

%Copyright Eigenvector Research, Inc. 2003
%JMS 8/13/03

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  if nargout==0; clear x; evriio(mfilename,varargin{1},options); else; x = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin<2;
  error('insufficient inputs');
end

nd = ndims(x);

%extract from cell if we have only one dim
if ~isa(indices,'cell')
  indices = {indices};
end

%assume indices refers to first length(indices) modes if modes not specified
if nargin<3  
  modes = 1:length(indices);
end

if length(modes)~=length(indices);
  error('Number of indexing items and number of modes do not match');
end

subs = cell(1,nd);
[subs{1:nd}] = deal(':');   % gives  {':' ':' ':' ...}
[subs{modes}]  = deal(indices{:});        % insert indices into appropriate dim

%drop any extra modes they tried indexing into
if length(subs)>nd;
  subs = subs(1:nd);
end  

S      = [];
S.subs = subs;
S.type = '()';
x = subsref(x,S);
end

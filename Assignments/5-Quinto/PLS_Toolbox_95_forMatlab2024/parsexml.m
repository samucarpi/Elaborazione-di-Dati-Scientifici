function [object,theStruct] = parsexml(filename,nooutertag)
% PARSEXML Convert XML file to a MATLAB structure.
% Creates a Matlab object from an XML file. The format of the file must follow
% that used by ENCODEXML. Each XML tag will be encoded as a field in a
% Matlab structure. The top-level tag will be the single field in the top-
% level of the returned structure. All sub-tags will be sub-fields.
% Contents of the fields are specified using the class attributes of each tag.
% When class is omitted, a single-entry (non-array) structure is assumed.
% Tags with the attribute 'class' will be encoded using the followng rules:
%  class="string"   : Contents encoded as string or padded string array.
%        If multiple row string, each row should be enclosed in <sr> tags. 
%  class="numeric"  : Default format for tag is a comma-delimited list of
%        values with rows delimited by semicolons. Each row must have the
%        same number of entries (each row must be equal in length) or an error
%        will result. Multi-way matricies can be encapulated in <tn mode="i">
%        tags where i is the mode that the enclosed item expands on (i>=3).
%
%        Encoding: Numeric class contents can be encoded as comma-separated
%        values (csv) which is the default, or using base64 encoding. The
%        encoding attribute can be supplied to specify when the contents
%        are encoded using other than CSV. Options include:
%            encoding = "csv"           (default)
%            encoding = "base64"
%
%        When base64 encoding is used, the additional attribute precision
%        can be included to specify the precision of the numerical values
%        encoded. Options include: 
%           precision="64"   for 64-bit double precision values (default)
%           precision="32"   for 32-bit single precision values
%           precision="8"    for 8-bit unsigned integer values
%           precision="1"    for boolean logical values
%
%  class="cell"     : Contents encoded as Matlab cell. The format of the
%        contents is same as HTML table tags (<tr> for a new row, <td> for a
%        new container/column) with the added tag of <tn mode="i"> to
%        describe a multi-dimensional cell (see class="numeric").
%  class="structure": Used for struture arrays ONLY. Contents encoded into
%        a structure array use array notation identical to that described
%        for class="cell". If a structure is size [1 1] then it does not
%        need to use array notation and must not be marked with this class
%        attribute. Instead, the contents of the structure should simply be
%        enclosed within the tag as sub-tags.
%  class="dataset"  : Contents will be interpreted as a DataSet Object. Any
%        Any tags that do not map to valid DataSet Object fields will be
%        be ignored. See the DataSet definition for details on valid fields
%        and ENCODEXML for examples of the DataSet XML format.
%
% NOTE: "Size" attribute: Tags of class "numeric", "cell", or "structure"
%   (structure-array only) should also include the attribute size="[...]" 
%   which gives the size of the tag's contents. The size value must be
%   enclosed in square brackets and must be at least two elements long
%   (use [0,0] for empty). For example,
%     <myvalue class="numeric" size="[3,4]">
%   says that the field myvalue will be numeric with 3 rows and 4 columns.
%   Size can be multi-dimensional as needed: (size="[2,4,6,2]" implies that
%   the tag contents will be a 4-dimensional array of the given sizes.
%
% INPUT:
%  filename   = XML filname to convert. If input (filename) is omitted, the
%               user will be prompted for a file name to read.
%
% OPTIONAL INPUT:
%  nooutertag = [ {false} | true ] when set to "true" this input indicates
%               that the outer-most xml object should be stripped from the
%               resulting output (object). This allows direct access to the
%               object itself rather than a structure with the object as the
%               first and only field of that structure.
%
% OUTPUTS:
%      object = MATLAB object.
%   theStruct = is the pre-parsed XML object and allows access to raw field
%               attributes and other content that cannot be converted into
%               a Matlab object.
%
%I/O: [object,theStruct] = parsexml(filename,nooutertag);
%
%See also: AUTOIMPORT, ENCODEXML, XMLREADR, TEXTREADR

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% For improved performance consider using VTD library.
%   https://vtd-xml.sourceforge.io/
%   https://www.codeproject.com/Articles/23516/VTD-XML-XML-Processing-for-the-Future-Part-I


if nargin==1 & ischar(filename) & ismember(filename,{ 'io' 'demo' 'help' 'options' 'factoryoptions' 'test' 'clearlicense' 'release' })
  options = [];
  if nargout==0; evriio(mfilename,filename,options); else; object = evriio(mfilename,filename,options); end
  return; 
end

object = [];
theStruct = [];
if nargin<1 | isempty(filename)
  [file,pathname] = evriuigetfile({'*.xml;','Readable Files';'*.*','All Files (*.*)'});
  if file == 0
    return
  end
  filename = [pathname,file];
end

%if this is a string (not a filename), convert to java source
%WARNING! this logic carefully avoids the use of the "exist" function
%because it will cache ALL calls to it leading to a memory leak. In fact,
%we've replaced "exist" by a call to safeisfile() which uses java methods
%to avoid caching. Plus, we do some "pre-testing" for things that are
%clearly not filenames (too long or strange characters).
if ~iscell(filename) & (length(filename)>500 ...
    | (length(filename)>6 & filename(1)=='<') ...
    | (length(filename)>4 & length(filename)<500 & ~strcmp(filename(end-3:end),'.xml') & ~safeisfile(filename)))  
  sr = java.io.StringReader(filename);
  filename = org.xml.sax.InputSource(sr);
  sourcefilename = 'Passed String Input';
else
  if iscell(filename)
    if length(filename)>1
      error('Only one XML file can be imported at a time')
    end
    filename = filename{1};
  end
  sourcefilename = filename;
  filename = org.xml.sax.InputSource(java.io.FileReader(filename));
  filename.setEncoding('UTF-8');   % Can read umlauts, etc.
end

%create DOM
try
  tree = xmlread(filename);
%    tree = xmlread(filename);
catch
  info = str2cell(lasterr);
  error('Failed to parse as XML: %s',info{min(end,2)});
end

% Recurse over child nodes. This could run into problems 
% with very deeply nested trees.
try
  theStruct = parseChildNodes(tree);
catch
  lasterr_str = lasterr;
  error(['Failed to parse as XML: ' lasterr_str]);
%   info = str2cell(lasterr);
%   error(['Failed to parse as XML: ' info{min(end,2)}]);
end

% Convert that structure into a Matlab object
try
  object = construct(theStruct,sourcefilename);   
catch
  info = str2cell(lasterr);
  error(['Unable to construct object from parsed XML.\nCheck file size. When parsing large files, '...
    'greater than 30MB, more memory (heap space) may be needed by the JVM.\n\n%s'],info{min(end,2)})
end

if nargin>1 & nooutertag
  %dump outer tag if not desired
  fn = fieldnames(object);
  object = object.(fn{1});
end

% ----- Subfunction PARSECHILDNODES -----
function children = parseChildNodes(theNode)
% Recurse over node children.
children = [];
if theNode.hasChildNodes
   childNodes = theNode.getChildNodes;
   numChildNodes = childNodes.getLength;
   allocCell = cell(1, numChildNodes);

   children = struct(             ...
      'Name', allocCell, 'Attributes', allocCell,    ...
      'Data', allocCell, 'Children', allocCell);

    index = 0;
    for count = 1:numChildNodes
        theChild = childNodes.item(count-1);
        if strcmp(char(theChild.getNodeName),'#text') continue; end
        parsedChild = makeStructFromNode(theChild);
        index = index+1;
        children(index) = parsedChild;
    end
    children = children(1:index); %drop unused slots

end

% ----- Subfunction MAKESTRUCTFROMNODE -----
function nodeStruct = makeStructFromNode(theNode)
% Create structure of node info.

name = char(theNode.getNodeName);
attr = parseAttributes(theNode);
child = parseChildNodes(theNode);
nodeStruct = struct('Name', name,'Attributes', attr,'Data', '','Children', child);

try
  nodeStruct.Data = deblank(char(theNode.getTextContent));
catch
%   info = str2cell(lasterr);
  lasterr_str = lasterr;
  error(['Failed to parse as XML: ' lasterr_str]);
%   nodeStruct.Data = '';
end

% ----- Subfunction PARSEATTRIBUTES -----
function attributes = parseAttributes(theNode)
% Create attributes structure.

okchars = ['a':'z' '0':'9' 'A':'Z' '_'];

attributes = struct;
if theNode.hasAttributes
   theAttributes = theNode.getAttributes;
   numAttributes = theAttributes.getLength;

   for count = 1:numAttributes
      attrib = theAttributes.item(count-1);
      attname = char(attrib.getName);
      attname(~ismember(attname,okchars)) = '_';
      attributes.(attname) = char(attrib.getValue);
   end
end

%==========================================================================
%--------------------------------------------------
function data = construct(item,sourcefile)
%construct Matlab objects from XML

persistent local_sourcefile

if nargin>1
  local_sourcefile = sourcefile;
end

data = [];
for j = 1:length(item);
  if strcmp(item(j).Name,'#comment'); continue; end
  if ~isfield(item(j).Attributes,'class')
    item(j).Attributes.class = '';
  end
  if ~isfield(item(j).Attributes,'size')
    item(j).Attributes.size = '';
  end
  if isfield(item(j).Attributes,'name')
    item(j).Name = item(j).Attributes.name;
  end
  switch item(j).Attributes.class
    %- - - - - - - - - - - - - - - - - -
    case 'cell'
      %handle cells
      data.(item(j).Name) = parsecell(item(j).Children);

      %- - - - - - - - - - - - - - - - - -
    case 'struct'
      %handle explicit structures (usually structure arrays)
      data.(item(j).Name) = parsestruct(item(j).Children);

      %- - - - - - - - - - - - - - - - - -
    case 'string'
      %handle strings (as single row or multi-row)
      if isempty(item(j).Children)
        %single-row string
        data.(item(j).Name) = item(j).Data;
      else
        %multi-row string
        temp = '';
        for k=1:length(item(j).Children);
          if strcmp(item(j).Children(k).Name,'sr')
            str = item(j).Children(k).Data;
            if isempty(str); str = ' '; end  %use spaces so empty strings don't disappear
            temp = strvcat(temp,str);
          end
        end
        data.(item(j).Name) = temp;
      end

      %- - - - - - - - - - - - - - - - - -
    case 'dataset'
      %handle dataset object
      temp = construct(item(j).Children);
      if ~isfield(temp,'data') || isempty(temp.data)
        error('Missing or invalid contents for "Data". Field required for DataSet object');
      end
      data.(item(j).Name) = struct2dataset(temp);
      data.(item(j).Name) = addsourceinfo(data.(item(j).Name),local_sourcefile);

    case 'dso'
      %handle quick-dataset format of dataset object
      data.(item(j).Name) = struct2dso(construct(item(j).Children));
      data.(item(j).Name) = addsourceinfo(data.(item(j).Name),local_sourcefile);
      
      %- - - - - - - - - - - - - - - - - -
    case 'numeric'
      %handle standard numeric field
      if ~isempty(item(j).Children)
        data.(item(j).Name) = parsenumeric(item(j).Children);
      else
        %look for parsing and precision flags
        if isfield(item(j).Attributes,'encoding')
          encoding = lower(item(j).Attributes.encoding);
        else
          encoding = 'csv';
        end
        if isfield(item(j).Attributes,'precision')
          precision = str2num(item(j).Attributes.precision);
        else
          precision = 64;
        end

        try
          str = item(j).Data;
          switch encoding
            case 'csv'
              str(ismember(str,[10 13])) = [];  %drop line feeds and carriage returns
              val = str2num(str);
            case 'base64'
              val = evribase64.decode(item(j).Data,precision);
              if isfield(item(j).Attributes,'size')
                sz = str2num(item(j).Attributes.size);
                if ~isempty(sz) & prod(sz)<=length(val) %if size will WORK with the decoded data, reshape it
                  if prod(sz)<length(val); 
                    val = val(1:prod(sz));  %truncate if too long
                  end
                  val = reshape(val,sz);
                end
              end
              
          end
          data.(item(j).Name) = val;
        catch
          %unable to convert
          data.(item(j).Name) = [];
        end
      end
            
      %- - - - - - - - - - - - - - - - - -
    otherwise
      if length(item(j).Children)>0
        %handle implict structure (sub-tags)
        newval = construct(item(j).Children);
        
        myclass = item(j).Attributes.class;
        if exist(myclass,'file') | exist(myclass,'class')
          try
            tempobj = feval(myclass);
          catch
            %NOT a valid object (or at least we couldn't create an empty
            %instance of one)
            tempobj = [];
          end
          if isa(tempobj,myclass) 
            %did we manage to create an empty object of this class?
            if ismember('parsexml',methods(tempobj))  %does it have a parsexml method?
              %create using object's parsexml method
              newval = parsexml(tempobj,newval);
            else
              error('Unable to create object "%s". No XML parser for this class.',myclass)
            end
          end             
        end
      else
        %assumed string
        newval = item(j).Data;
      end
      if ~isfield(data,item(j).Name)
        data.(item(j).Name) = newval;
      else
        if iscell(data.(item(j).Name))
          data.(item(j).Name) = [data.(item(j).Name);{newval}];
        else
          data.(item(j).Name) = {data.(item(j).Name);newval};
        end
      end

  end
end
  
%--------------------------------------------
function data = parsecell(item,data,ind)

if nargin==1;
  ind = {0 0};
  data = {};
end

for j=1:length(item);
  if strcmp(item(j).Name,'tr')
    ind{1} = ind{1}+1;
    ind{2} = 0;
    data = parsecell(item(j).Children,data,ind);
  elseif strcmp(item(j).Name,'tn')
    mymode = str2num(item(j).Attributes.mode);
    if length(ind)<mymode
      ind{mymode} = 1;
    else
      ind{mymode} = ind{mymode}+1;
    end
    [ind{1:mymode-1}] = deal(0);
    data = parsecell(item(j).Children,data,ind);
  elseif strcmp(item(j).Name,'td')
    ind{2} = ind{2}+1;
    temp = construct(item(j));
    data{ind{:}} = temp.td;
  end
end

%--------------------------------------------
function data = parsestruct(item,data,ind)

if nargin==1;
  ind = {0 0};
  data = [];
end

for j=1:length(item);
  if strcmp(item(j).Name,'tr')
    ind{1} = ind{1}+1;
    ind{2} = 0;
    data = parsestruct(item(j).Children,data,ind);
  elseif strcmp(item(j).Name,'tn')
    mymode = str2num(item(j).Attributes.mode);
    if length(ind)<mymode
      ind{mymode} = 1;
    else
      ind{mymode} = ind{mymode}+1;
    end
    [ind{1:mymode-1}] = deal(0);
    data = parsestruct(item(j).Children,data,ind);
  elseif strcmp(item(j).Name,'td')
    ind{2} = ind{2}+1;
    temp = construct(item(j));
    if isempty(data)
      data = temp.td;
    end
    data(ind{:}) = temp.td;
  end
end

%--------------------------------------------
function data = parsenumeric(item,data,ind)

if nargin==1;
  ind = {1 1};
  data = [];
end

for j=1:length(item);
  if strcmp(item(j).Name,'tn')
    mymode = str2num(item(j).Attributes.mode);
    if length(ind)<mymode
      ind{mymode} = 1;
    else
      ind{mymode} = ind{mymode}+1;
    end
    [ind{1:mymode-1}] = deal(1);
  end

  if ~isempty(item(j).Children)
    %if this object has children, parse them and use that as the value
    temp = parsenumeric(item(j).Children);
  else
    %No children - convert whatever data into numeric and store
    try
      temp = str2num(item(j).Data);
    catch
      %unable to convert
      temp = [];
    end
  end
  
  %try adding data to current data
  if length(ind)>2;
    if isempty(data);
      data = zeros(size(temp));
    end
    while ndims(data)<length(ind);
      %add extra modes as needed (if trying to index into new modes)
      data = cat(ndims(data)+1,data,zeros(size(data)));
    end
    data = nassign(data,temp,ind(ndims(temp)+1:end),ndims(temp)+1:length(ind));
  else
    data = temp.tr;
  end
end

%----------------------------------------------------------
function out = struct2dso(in)
% converter for short-hand DSO format.
% main use of this format is easier entry of classes, labels, and
% axisscales. Each set is indicated with a <set> tag and gives the mode for
% which the set applies, the name of the set (if any) and the content for
% the field (must be appropraite for the given field). When one or more
% sets are already defined for a mode, additional sets on that mode are
% automatically inserted into the next available set position.
%   <class>
%     <set>
%       <mode>1</mode>
%       <name>set name</name>
%       <content>1,2,3,4,5</content>
%     </set>
%     <set>
%       <mode>2</mode>
%       <name>set name</name>
%       <content>1,2,3</content>
%     </set>
%   </class>

out = dataset([]);
if ~isfield(in,'data');
  return
end

try
  fieldname = {'data'};
  out = dataset(in.data);
  
  %handle informational fields
  for fieldname = {'name','author','userdata','description','type','imagesize','imagemode'};
    if isfield(in,fieldname{:});
      out.(fieldname{:}) = in.(fieldname{:});
    end
  end

  %handle context fields
  for fieldname = {'class','axisscale','label','title','include'}
    setnumber = zeros(1,ndims(out));
    if isfield(in,fieldname{:})
      toadd = in.(fieldname{:}).set;
      if ~iscell(toadd);
        toadd = {toadd};
      end
      for j=1:length(toadd);
        if ~isfield(toadd{j},'content')
          continue
        end
        if ~isfield(toadd{j},'mode');
          toadd{j}.mode = '1';
        end
        if ~isfield(toadd{j},'name')
          toadd{j}.name = '';
        end
        mode = toadd{j}.mode;
        if ischar(mode);
          mode = str2double(mode);
        end

        %determine which set this needs to be
        setnumber(mode) = setnumber(mode) + 1;
        if strcmp(fieldname{:},'include') && setnumber(mode)>1; 
          continue; %do NOT allow multiple sets in include
        end 

        if ismember(fieldname{:},{'axisscale'}) && ischar(toadd{j}.content)
          %String passed for axisscale? check for date
          try
            ts = datenumplus(toadd{j}.content);
          catch
            ts = [];
          end
          if isempty(ts)
            if size(toadd{j}.content,2)>=16 & all(all([toadd{j}.content(:,5)=='-' toadd{j}.content(:,8)=='-' toadd{j}.content(:,11)==' ']))
              try
                %format: yyyy-mm-dd HH:MM:SS  (or similar)
                ts = datenum(toadd{j}.content,'yyyy-mm-dd HH:MM:SS');
              catch
                ts = [];
              end
            end
          end
          toadd{j}.content = ts;
        end
        
        %actually add content to DSO
        out.(fieldname{:}){mode,setnumber(mode)} = toadd{j}.content;
        %and add name to DSO
        if ~strcmp(fieldname{:},'include')
          out.([fieldname{:} 'name']){mode,setnumber(mode)} = toadd{j}.name;
        end
        
      end
    end
  end
  
catch
  %no errors - just return what we've got
  out.description = {'Warning: Incomplete DSO due to formatting error.' ['Error assigning field: ' fieldname{:}] lasterr};
end

%----------------------------------------------------------
function out = safeisfile(file)

out = java.io.File(file).isFile;

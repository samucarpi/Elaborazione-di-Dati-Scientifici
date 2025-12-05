function out = encodexml(in,fieldname,level, options)
%ENCODEXML Convert standard data types into XML-encoded text.
% Converts a standard Matlab variable (var) into a human-readable XML
% format. The optional second input ('name') gives the name for the
% object's outer wrapper and the optional third input ('filename.xml')
% gives the name for the output file (if omitted, the XML is only returned
% in the output variable). For more information on the format, see the
% PARSEXML function.
%
% Example:
%     z.a = 1;
%     z.b = { 'this' ; 'that' };
%     z.c.sub1 = 'one field';
%     z.c.sub2 = 'second field';
%     encodexml(z,'mystruct')
%   Returns...
%     <mystruct>
%       <a class="numeric" size="[1,1]">1</a>
%       <b class="cell">
%         <tr>
%           <td class="string">this</td>
%         </tr>
%         <tr>
%           <td class="string">that</td>
%         </tr>
%       </b>
%       <c>
%         <sub1 class="string">one field</sub1>
%         <sub2 class="string">second field</sub2>
%       </c>
%     </mystruct>
%
% Notes:
%  * Objects can overload the encodexml method in order to define how the
%    object should be encoded. If not defined, the object's contents will
%    be written as-is with the outer-tag's class set to the class of the
%    obejct.
%  * A class can be "spoofed" by creating a structure and adding a field
%    named "encodexmlclass" with the character description of how to encode
%    the class:
%          a.encodexmlclass = 'fakeclass'
%          a.data = [1 2 3 4];
%    would be encoded as:
%         <a class="fakeclass">
%           <data class="numeric" size="[1,4]">1,2,3,4</data>
%         </a>
%    This can be used by objects to create overloaded encodexml methods.
%
%I/O: xml = encodexml(var)
%I/O: xml = encodexml(var,'name')
%I/O: xml = encodexml(var,'name','outputfile.xml')
%
%See also: ENCODE, PARSEXML

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

out = [];
%parse various inputs (non-recursive calls only)

if nargin < 4
  options.compact ='no';
end


if nargin<3 | ischar(level);
  %top-level instance of call
  toplevel = 1;
  if nargin<2
    if isa(in,'struct');
      fieldname = '';
      if nargin<3;
        level = 0;
      end
    else
      fieldname = inputname(1);
      if isempty(fieldname)
        fieldname = 'ans';
      end
      if nargin<3;
        level = 1;
      end
    end
  elseif nargin<3;
    level = 1;
  end

  %no outputs? ask user for filename
  if nargout==0 & (~ischar(level) | isempty(level))
    [outputfilename,pth] = evriuiputfile({  '*.xml' 'XML eXtended Markup Language (*.xml)' });
    if isnumeric(outputfilename)
      level = '';
    else
      level = fullfile(pth,outputfilename);
    end
  end

  %if level is a filename rather than an actual level, store filename and set
  %level to first (1)
  if isa(level,'char')
    outputfilename = level;
    level = 1;
  else
    outputfilename = '';
  end

else
  %all recursive calls end up here
  toplevel = 0;
  outputfilename = '';
end  

%do parsing
cl = class(in);
switch cl
  %-----------------------------------
  case 'struct'
    
    if isfield(in,'encodexmlclass')
      %passed a special flag indicating the class of this object?
      %extract that class and use it
      mycl = {in.encodexmlclass};
      mycl = mycl{1};
      %make sure we've got an outer wrapper to show class in
      if level==0 & isempty(fieldname)
        %lowest level? fake one level down with this as sub-field
        fieldname = mycl;
        level = level+1;
      end
      %drop class from structure
      in = rmfield(in,'encodexmlclass');
    else
      mycl = cl;
    end
    
    if any(size(in)>1)
      sz = size(in);
      attributes = ['class="' mycl '" ' sprintf('size="[%i',sz(1)) sprintf(',%i',sz(2:end)) ']"'];
      out = [out openfield(fieldname,level,1,attributes)];
      out = encodestruct(in,out,level);
      out = [out closefield(fieldname,level,1)];
    else
      if ~strcmpi(mycl,cl)
        attributes = ['class="' mycl '"'];
      else
        attributes = '';
      end
      
      out = [out openfield(fieldname,level,1,attributes)];
      if ~isempty(in)
        for f = fieldnames(in)';
          fyld = f{:};
          out = [out encodexml(getfield(in,fyld),fyld,level+1)];
        end
      end
      out = [out closefield(fieldname,level,1)];
    end

  %-----------------------------------
  case 'cell'
    if isempty(in);
      out = [out openfield(fieldname,level,1,'class="cell" /')];
    else
      sz = size(in);
      attributes = ['class="cell" ' sprintf('size="[%i',sz(1)) sprintf(',%i',sz(2:end)) ']"'];
      out = [out openfield(fieldname,level,1,attributes)];
      out = encodecell(in,out,level);      
      out = [out closefield(fieldname,level,1)];
    end

  %-----------------------------------
  case 'char'
    if isempty(in);
      out = [out openfield(fieldname,level,1,'class="string" /')];
    else
      transmap = {
        '&' '&amp;'
        '<' '&lt;'
        '>' '&gt;'
        '\' '\\'
        '%' '%%'
        char(0) ' '
        };
      sz = size(in,1);
      openstr = openfield(fieldname,level,sz>1,'class="string"');
      out = [out openstr];
      for j=1:sz;
        if sz>1
          out = [out openfield('sr',level+1,0)];
        end
        trans = in(j,:);
        for k = 1:size(transmap,1)
          trans = strrep(trans,transmap{k,1},transmap{k,2});
        end
        
        if any(trans>127) | any(trans<32)
          %Need to encode out-of-range characters.
          trans = convertSpecialChars(trans);
        end
        
        out = [out trans];
        if sz>1
          out = [out closefield('sr',level+1,0)];
        end
      end
      out = [out closefield(fieldname,level,sz>1)];
    end

  %-----------------------------------
  case 'dataset'
    
    if exist('options', 'var') && strcmp(options.compact, 'yes')
      toparse = {'name'  'type'  'author'  'date'  'moddate'  'imagesize'  'imagemode'...
      'data'  'label'  'labelname'  'axisscale'  'axisscalename' 'axistype' 'title'  'titlename'...
      'classlookup' 'class'  'classname' 'include'  'userdata' };
    else
      toparse = {'name'  'type'  'author'  'date'  'moddate'  'imagesize'  'imagemode'...
      'data'  'label'  'labelname'  'axisscale'  'axisscalename' 'axistype' 'title'  'titlename'...
      'classlookup' 'class'  'classname' 'include'  'description'  'userdata'  'datasetversion'  'history'};
    end  
    

  
    out = [out openfield(fieldname,level,1,'class="dataset"')];
    record = in;
    for f = toparse;
      fyld = f{:};
      out = [out encodexml(getfield(record,fyld),fyld,level+1)];
    end
    out = [out closefield(fieldname,level,1)];

  %-----------------------------------
  case 'function_handle'
    tempin = [];

    out = [out openfield(fieldname,level,1,'class="function_handle"')];
    try
      out = [out encodexml(functions(in),'',level)];
    catch
      warning('EVRI:EncodexmlBadClass',['Cannot XML encode variable of class ' cl '. Replacing with warning message.']);
      out = [out openfield(fieldname,level,0,['class="' cl '"'])  'Unencodable function_handle'  closefield(fieldname,level)];
    end
    out = [out closefield(fieldname,level,1)];

  %-----------------------------------
  otherwise
    if isnumeric(in) | islogical(in)
      in = full(in);
      if isempty(in);
        out = [out openfield(fieldname,level,1,'class="numeric" size="[0,0]" /')];
      else
        sz = size(in);
        nmode = ndims(in);
        if prod(sz)<inf %options.base64threshold  %NOT ENABLED yet - need options to control
          encls = '';
          usebase64 = false;
        else
          encls = ' encoding="base64" precision="64"';
          usebase64 = true;
        end
        attributes = ['class="numeric"' encls ' ' sprintf('size="[%i',sz(1)) sprintf(',%i',sz(2:end)) ']"'];
        out = [out openfield(fieldname,level,nmode>2,attributes)];
        
        if usebase64
          out = [out evribase64.encode(in)];
        elseif nmode>2
          out = encodenwaydata(in,out,level);
        else
          for j = 1:sz(1);
            %for each row of the matrix
            if sz(1)>1 & j==1;
              row = '\n';  %if more than one row, add end of line char (not XML but more readable)
            else
              row = '';
            end
            if sz(1)>1;
              row = [row blanks(max(0,level)*2)];
            end
            if size(in,2)>1;
              row = [row sprintf('%.12g,',(in(j,1:end-1)))];  %add one number for each column
            end
            row = [row sprintf('%.12g',(in(j,end)))];  %add one number for last column
            if sz(1)>1
              if j<sz(1);
                row = [row ';'];  %if more than one row, add end of line char
              end
              row = [row '\n'];  %and add pretty-print (not XML, but more readable)
            end
            rows{j} = row;
          end
          out = [out rows{:}];
        end
        out = [out closefield(fieldname,level,sz(1)>1)];
      end
    else
      %other class...
      try
        myobj = struct(in);
        myobj.encodexmlclass = class(in);
        out = [out openfield(fieldname,level,1,['class="' cl '"']) encodexml(myobj,'',level+1) closefield(fieldname,level,1)];
      catch
        warning('EVRI:EncodexmlBadClass',['Cannot XML encode variable of class ' cl '. Replacing with warning message.']);
        out = [out openfield(fieldname,level,0,['class="' cl '"'])  'Unencodable Object'  closefield(fieldname,level)];
      end
    end
end

if isempty(out); out = ' '; end
if toplevel;
  if isempty(outputfilename)
    out = sprintf(out);
  else
    [fid,message] = fopen(outputfilename,'w');
    if fid<0
      error(message)
    end
    evripause(.1)
    fprintf(fid,out);
    evripause(.1)
    fclose(fid);
    if nargout==0
      clear out
    end
  end
end

%===================================================
function  out = openfield(fyld,level,newline,attributes);

if nargin<3;
  newline = 0;
end
if nargin<4;
  attributes = '';
elseif ~isempty(attributes) & attributes(1)~=' '
  attributes = [' ' attributes];
end

out = [];
if ~isempty(fyld);
  out = [out blanks(max(0,level-1)*2) '<' fyld attributes '>'];
  if newline
    out = [out '\n'];
  end
end

%===================================================
function  out = closefield(fyld,level,indent);

if nargin<3;
  indent = 0;
end

out = [];
if ~isempty(fyld);
  if indent
    out = [out blanks(max(0,level-1)*2)];
  end
  out = [out '</' fyld '>\n'];
end

%===================================================
function out = encodedata(in,out,level)
%encode any n-way data object

if ndims(in)<=2
  out = [out encodexml(in,'td',level+2)];
else
  %n-way
  nmode = ndims(in);
  for i = 1:size(in,nmode)
    out = [out openfield('tn',level+1,1,sprintf('mode="%i"',nmode))];
    out = encodecell(nindex(in,{i},nmode),out,level+1);
    out = [out closefield('tn',level+1,1)];
  end
end


%===================================================
function out = encodecell(in,out,level)
%encode any n-way cell object

if ndims(in)<=2
  for i1 = 1:size(in,1);
    out = [out openfield('tr',level+1,1)];
    for i2 = 1:size(in,2);
      out = [out encodexml(in{i1,i2},'td',level+2)];
    end
    out = [out closefield('tr',level+1,1)];
  end
else
  %n-way
  nmode = ndims(in);
  for i = 1:size(in,nmode)
    out = [out openfield('tn',level+1,1,sprintf('mode="%i"',nmode))];
    out = encodecell(nindex(in,{i},nmode),out,level+1);
    out = [out closefield('tn',level+1,1)];
  end
end

%===================================================
function out = encodenwaydata(in,out,level);
%handle n-way matrix

nmode = ndims(in);
for i = 1:size(in,nmode)
  out = [out openfield('tn',level+1,nmode>3,sprintf('mode="%i"',nmode))];
  if nmode>3;
    out = encodenwaydata(nindex(in,{i},nmode),out,level+1);
  else
    out = [out encodexml(nindex(in,{i},nmode),'',level+1)];
  end
  out = [out closefield('tn',level+1,1)];
end

%===================================================
function out = encodestruct(in,out,level)
%encode any n-way struct object

if ndims(in)<=2
  for i1 = 1:size(in,1);
    out = [out openfield('tr',level+1,1)];
    for i2 = 1:size(in,2);
      out = [out encodexml(in(i1,i2),'td',level+2)];
    end
    out = [out closefield('tr',level+1,1)];
  end
else
  %n-way
  nmode = ndims(in);
  for i = 1:size(in,nmode)
    out = [out openfield('tn',level+1,1,sprintf('mode="%i"',nmode))];
    out = encodestruct(nindex(in,{i},nmode),out,level+1);
    out = [out closefield('tn',level+1,1)];
  end
end

%===================================================
function in = convertSpecialChars(in)
%Transcode special characters into xml numeric character reference using
%code point notation &#nnnn; where nnnn is the code point in decimal form.

idx = ismember(in,[0:8 11:12 14:31]);  %everything except 9, 10, and 13
in(idx) = [];  %DROP control characters (they simply aren't allowed)

%NOTE: if we wanted to convert 9, 10 and 13 into &#00n format, we would
%need to add them to the idx test below. However, we will NOT be doing so
%at this time because it may break customer's code that expects these to
%come across in "raw" format.
idx = in(in>127);
idx = unique(idx);
for i = idx
  in = strrep(in,i,['&#' num2str(double(i)) ';']);
end

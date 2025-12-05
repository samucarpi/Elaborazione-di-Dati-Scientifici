function str = encode(item,varname,varindex,options)
%ENCODE Translates a variable into matlab-executable code.
% The created code can be eval'd or included in an m-file to
%  reproduce the variable. This is essentially an inverse function of
%  "eval" for variables.
%
% INPUTS
%   item = variable to encode
%
% OPTIONAL INPUTS
%   varname = the name to use for the craeted variable in the code. If
%             omitted, the input variable name will be used. If empty,
%             leading code which does assignment is omitted.
%  varindex = an internal index number used for struct and cell
%             assignments when multiple layers of complex variable types
%             are detected.
%   options = structure containing one or more of the following fields:
%
%     max_array_size : [10000] Maximum size allowed for any array
%             dimension. Arrays with any size larger than this will be
%             returned as simply [NaN]
%
%     structformat : [ 'struct' | {'dot'} ] defines how structures are
%             encoded. 'struct' uses a "struct('a',val)" style (but can get
%             very complex with large structures). 'dot' uses "x.a = val"
%             format which is easier to read, but less compact.
%
%     forceoneline : [ {'off'} | 'on' ] remove all line breaks and ellipses
%             from output. WARNING: this can cause a VERY long line on big
%             objects and may exceed the maximum line length of editors or
%             even MATLAB.
%
%     includeclear : [ 'off' | {'on'} ] use "clear" commands before
%             assignment statements (may be required to avoid warnings when
%             existing variables are replaced.)
%
%     compression : [ 'format' | 'speed' |{'runs'}] defines how to compress
%             the display of numeric values. 
%               'format' identifies the most compact format for each given
%                         number. The most compact form for arrays of mixed
%                         floating point and integer values, but slow.
%               'speed'  identifies the most compact format for groups of
%                         numbers and provides the fastest conversion.
%                         Vectors with mixed integer and floating point
%                         will be less compact in size.                        
%               'runs'   identifies runs of numbers and compresses them
%                         using Matlab's colon notation. Also compresses
%                         groups of identicial numbers. Best format for
%                         vectors and arrays with repeating numbers and
%                         linearly increasing or decreasing series.
%                         Intermediate in speed.
%
%    floatdigits : [ 12 ] number of digits to show in floating point
%                          numbers.
%
%    wrappedobject : [ {'off'} | 'on' ] indicates when the item being
%                    passed is an object wrapped in a cell array in order
%                    to "hide" it from the overloaded method. When 'on',
%                    encode will strip the object out of the cell before
%                    encoding it recursively. This approach allows all the
%                    input logic to reside here.
%
% Output is a string (str) which can be inserted into an m-file or passed
% to eval for execution.
%
%Example: Create code to reproduce a preprocessing structure
%   p=preprocess('default','meancenter'); encode(p)
%
%I/O: str = encode(item,varname)
%I/O: str = encode(item,varname,varindex,options)
%I/O: str = encode(item,options)
%
%See also: ENCODEXML, PARSEXML

%NOTE: ENCODE is a recursive function. A plain call with just a single
%input is interpreted as a user's call. In subsequent calls by encode
%itself, there are two additional inputs:
% (varname) the string name of the variable being encoded and
% (varindex) an internal index number used for struct and cell assignments
%   when multiple layers of complex variable types are detected.

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS 2/25/02 revised coding of internal function for release
%jms 7/02-8/02 added support for strings with \, fixed extra/missing ; bugs
%jms 10/16/03 -fixed failure on string with '%' in it
%  -increased array row length to 30
%jms 2/27/04 -added support for multi-way arrays, char arrays, dataset
%    objects and fixed various line-break bugs
%jms 6/30/04 -added support for compressed vectors (using x1:step:x2
%    format), fixed dataset encoding bug
%jms 8/11/05 -fix vector compression bug
%     -fix string array encode bug


if nargin < 3 | isstruct(varindex);   %inital user's call
  if nargin==1;
    if isstr(item) & ismember(item,evriio([],'validtopics'));
      options = [];
      options.max_array_size = 50000;      %maximum allowable array size for encoding
      options.structformat = 'dot';
      options.forceoneline = 'off';
      options.includeclear = 'on';
      options.compression  = 'runs';
      options.floatdigits  = 12;
      options.wrappedobject = 'off';

      if nargout==0; evriio(mfilename,item,options); else; str = evriio(mfilename,item,options); end
      return;
    end

    %user gave only data
    options = [];
    varname = '';
    noprefix = false;

  elseif nargin==2 & isstruct(varname)
    %user gave options
    options = varname;
    varname = '';
    noprefix = false;
  else
    %user gave variable name
    noprefix = isempty(varname);
    options = [];
  end

  if nargin>2
    options = varindex;
  end
  options = reconopts(options,'encode');
  
  prefix = '';
  suffix = '';
  if ~noprefix

    %infer variable name from input variable
    if isempty(varname)
      varname = inputname(1);
      if isempty(varname);
        varname = 'ans';    %output of function is input here? just use "ans" as output var name
      end
    end
    
    if strcmp(options.includeclear,'on');
      prefix = ['clear ' varname ';\n'];
    end
    suffix = ';';
  end
  
  if strcmpi(options.wrappedobject,'on')    %cell-array-wrapped object
    item = item{1};  %extract from cell array for encoding
  end

  %do the encoding
  try
    str = [prefix encode(item,varname,0,options) suffix];
    str = sprintf(str);    %translate into recursive encode call

    if strcmp(options.forceoneline,'on')
      str = strrep(str,'...',''); %dump ellipses
      str = strrep(str,char(10),'');  %dump line breaks
    end

  catch
    error(lasterr)
  end
  return

end
if nargin<4;
  options = encode('options');
end

if ~isempty(varname);
  varname = [varname ' = '];
end

if strcmpi(class(item),'string')
  %TODO: Maybe add case for strings below.
  % See: matlab.io.saveVariablesToScript 
  % See: convertCharsToStrings()
  % See: https://www.mathworks.com/matlabcentral/fileexchange/24447-generate-m-file-code-for-any-matlab-variable
  item = char(item);
end

switch class(item)
  % - - - - - - - - - - - - - - - - - - -
  case 'char'

    if size(item,1)<=1;
      %row string vector
      prefix = '';
      suffix = '';
      
      %replace all ' with ''
      pos = findstr(item,'''');
      if ~isempty(pos);
        inds = [1 pos(1); pos(1:end-1)' pos(2:end)'; pos(end) length(item)];
        ex=[];
        for k=1:size(inds,1);
          ex=[ex inds(k,1):inds(k,2)];
        end;
        item = item(ex);
      end

      %replace all % with %%
      pos = findstr(item,'%');
      if ~isempty(pos);
        inds = [1 pos(1); pos(1:end-1)' pos(2:end)'; pos(end) length(item)];
        ex=[];
        for k=1:size(inds,1);
          ex=[ex inds(k,1):inds(k,2)];
        end;
        item = item(ex);
      end

      %drop out of string for "bad" characters
      bad = find(item<32);
      if ~isempty(bad)
        for k=length(bad):-1:1;
          item = [item(1:bad(k)-1) ''' ' num2str(double(item(bad(k)))) ' ''' item(bad(k)+1:end)];
        end
        prefix = '[';
        suffix = ']';
      end     

      %replace '\' with '\\'
      pos = findstr(item,'\');
      if ~isempty(pos);
        inds = [1 pos(1); pos(1:end-1)' pos(2:end)'; pos(end) length(item)];
        ex   = [];
        for k=1:size(inds,1);
          ex=[ex inds(k,1):inds(k,2)];
        end;
        item = item(ex);
      end

      str=[varname prefix '''' item '''' suffix ];

    else

      %column vector or array
      if ndims(item)>2;
        warning('EVRI:Encode','ENCODE - Multi-way strings not supported, using NaN.')
        str = [varname '[ NaN ]'];
        return;
      end

      %run through rows
      str=[varname '['];
      varindex = varindex + 1;
      for ind = 1:size(item,1)-1;
        str = [str encode(item(ind,:),[],varindex,options) ';'];
        if (length(str)-max([0 findstr(str,'\n')]))>80;
          str = [str '...\n'];
        end
      end
      str = [str encode(item(end,:),[],varindex,options) ']'];

    end
    % - - - - - - - - - - - - - - - - - - -
  case 'function_handle'

    if ~isempty(varname);
      myvar = [varname(1:end-3)];
      str = '';
    elseif issimple(item,options)
      myvar = '';
      str = '';
    else
      myvar = ['ETemp' num2str(varindex)];
      str = ['clear ' myvar];
    end
    varindex = varindex + 1;

    try
      info = functions(item);
      if strcmp(info.type,'simple')
%         str = [encode(['@' info.function],myvar,varindex,options)];
        str = [myvar ' = @' info.function];
      else
        str = [encode(functions(item),myvar,varindex,options)];
      end
    catch
      str=[varname '''Unresolvable function handle'''];
    end

    % - - - - - - - - - - - - - - - - - - -
  case {'int8','uint8','int16','uint16','int32','uint32','single','double','logical'}

    if any(size(item)>options.max_array_size);
      warning('EVRI:Encode',['ENCODE - Variable too large for encoding (' ...
        varname ' size ' mat2str(size(item)) ' max allowed ' ...
        int2str(options.max_array_size) ' ), using NaN. Increase options.max_array_size to allow larger size.'])
      str = [varname '[ NaN ]'];
      return;
    end

    sz = size(item);
    if length(sz)<=2;
      %do column vectors as a ROW vector, transposed (if columns < rows)
      if sz(1)>1 & sz(2)<sz(1);
        trans=1;
        item = item';
        sz = sz([2 1]);
      else
        trans=0;
      end;

      %display item
      if sz(1)>1;
        %more than 1 row
        str=[varname '[ ' ];
        for j = 1:sz(1)-1;
          str = [str dispvect(item(j,:),options) ';\n '];
        end
        str = [str dispvect(item(end,:),options)];
        str = [str ' ]'];
        if trans; str=[str '''']; end
      else
        %only one row
        if sz(2)> 1;
          %more than one column
          str=[varname '[ ' dispvect(item,options) ' ]'];
          if trans; str=[str '''']; end
        else
          %empty or scalar
          if prod(sz)==0
            str = [varname '[ ]'];
          else
            str = [varname dispvect(item,options)];
          end
        end
      end
    else
      %multi-way
      varindex = varindex + 1;
      str = [varname];
      str = [str 'cat(' num2str(length(sz)) ','];
      s.type = '()';
      s.subs = cell(1,length(sz));
      [s.subs{:}] = deal(':');
      for ji = 1:sz(end);
        s.subs{end} = ji;
        subitem = subsref(item,s);
        str = [str encode(subitem,[],varindex,options)];
        if ji < sz(end);
          str = [str ',...\n'];
        else
          str = [str ')'];
        end
      end
    end

    % - - - - - - - - - - - - - - - - - - -
  case 'struct'

    sz = size(item);
    flds = fieldnames(item)';
    
    if isempty(flds)
      str = 'struct';
      if ~isempty(varname);
        str = [varname str];
      end
      return
    elseif all(sz)==0;
      strs = sprintf('''%s'',{},',flds{:});
      str = ['struct(' strs(1:end-1) ')'];
      if ~isempty(varname);
        str = [varname str];
      end
      return
    end

    if issimple(item,options)
      %simple to encode object? we can do it by struct command

      strs = '';
      lastbreak = 0;
      for fl=flds;
        itemcell = reshape({item.(fl{:})},sz);
        itemcell = encode(itemcell,'',varindex,options);
        itemcell = strrep(itemcell,'\n','');  %dump line breaks
        strs = [strs sprintf('''%s'',',fl{:}) itemcell ','];
        if (length(strs)-lastbreak)>80 & ~strcmp(fl{:},flds{end})
          %line is quite long and this isn't the last item... add line break
          strs = [strs sprintf('...\n ')];
          lastbreak = length(strs);
        end          
      end
      str = ['struct(' strs(1:end-1) ')'];
      if ~isempty(varname);
        str = [varname str];
      end
      
    else
      %complicated or otherwise difficult object, or not allowed
      %use direct build format
      if ~isempty(varname);
        myvar = [varname(1:end-3)];
        str = '';
        varindex = varindex + 1;
      else
        varindex = varindex + 1;
        myvar = ['ETemp' num2str(varindex)];
        str = ['clear ' myvar];
      end

      if sz(1)==1; sz=sz(2); end  %shrink to single-index if row vector
      for j=1:prod(sz);
        if ~isempty(flds);
          %create line for each field in structure
          for fl=flds;
            subitem = getfield(item(j),fl{:});
            if prod(sz)>1;
              if length(sz)==1;
                %row vector? give number only
                ind = num2str(j);
              else
                %matrix, give full indices
                ind = {};
                [ind{1:length(sz)}] = ind2sub(sz,j);
                ind = [num2str(ind{1}) sprintf(',%i',ind{2:end})];
              end
              strs = [encode(subitem,[myvar '(' ind ').' fl{:}],varindex,options)];
            else
              strs = [encode(subitem,[myvar '.' fl{:}],varindex,options)];
            end
            if isempty(str);
              str = strs;
            else
              str = [str ';\n' strs];
            end
          end
        else
          %empty structure?
          strs = [myvar ' = struct'];
          if isempty(str);
            str = strs;
          else
            str = [str ';\n' strs];
          end
        end
      end
      if isempty(varname);
        str = [str ';\n' varname 'ETemp' num2str(varindex) '; clear ETemp' num2str(varindex)];
      end
    end

    % - - - - - - - - - - - - - - - - - - -
  case 'cell'

    if issimple(item,options) & varindex<10;
      %this code handles "friendly" cells which can be entered directly (no structures in this cell)
      if isempty(varname);
        str = '';
      else
        str = [varname];
      end
      switch length(item)
        case 0
          str = [str '{}'];
        otherwise
          str = [str '{ '];
          strs = [];
          
          for k = 1:size(item,1);
            for j = 1:size(item,2);
              subitem = item{k,j};
              strs = [strs encode(subitem,[],varindex,options) ' '];
            end
            if k<size(item,1);
              strs = [strs '; '];
              if length(strs)>40;
                str = [str strs '\n'];
                strs = [];
              end
            end
          end
          str = [str strs '}'];
          
      end

    else
      %this code handles "unfriendly" cells which can't be entered directly (e.g. structures in cells)

      if ~isempty(varname);
        myvar = [varname(1:end-3)];
        str = '';
        varindex = varindex + 1;
      else
        varindex = varindex + 1;
        myvar = ['ECTemp' num2str(varindex)];
        str = ['clear ' myvar];
      end

      switch length(item)
        case 0
          str = [myvar ' = {}'];
        otherwise
          sz = size(item);
          if length(sz)==2 & sz(1)==1; sz=sz(2); end  %shrink to single-index if row vector
          for j=1:prod(sz);
            %convert each item in cell
            subitem = item{j};
            if length(sz)==1;
              %row vector? give number only
              ind = num2str(j);
            else
              %matrix, give full indices
              ind = {};
              [ind{1:length(sz)}] = ind2sub(sz,j);
              ind = [num2str(ind{1}) sprintf(',%i',ind{2:end})];
            end
            strs = [encode(subitem,[myvar '{' ind '}'],varindex,options)];
            if isempty(str);
              str = strs;
            else
              str = [str ';\n' strs];
            end
          end
      end
    end

    % - - - - - - - - - - - - - - - - - - -
  case 'dataset'

    if varindex>1
      myvar = ['ECTemp' num2str(varindex)];
    else
      myvar = varname(1:end-3);
    end
    str = [[myvar ' = dataset('] encode(item.data,[],varindex,options) ');\n'];
    %get other fields
    subitem = [];
    for fldname = {'name' 'author'};
      subitem.(fldname{:}) = item.(fldname{:});
    end
    str = [str encode(subitem,myvar,varindex+10,options) ';\n'];  %varindex>10 triggers complex mode ALWAYS

    classlookupvar = ['ECTemp_lookup' num2str(varindex)];
    for j=1:size(item.classlookup,1);
      for k=1:size(item.classlookup,2);
        table = item.classlookup{j,k};
        if ~isempty(table)
          str = [str ...
            encode(table,classlookupvar) '\n ' ...
            myvar sprintf('.classlookup{%i,%i}',j,k) '=' classlookupvar ';\n ' ...
            'clear ' classlookupvar ';\n'];
        end
      end
    end
    %get other fields
    subitem = [];
    for fldname = {'class' 'axisscale' 'axistype' 'label' 'title' 'include' 'classname' 'axisscalename' 'labelname' 'titlename'...
        'description' 'userdata'};
      subitem.(fldname{:}) = item.(fldname{:});
    end
    str = [str encode(subitem,myvar,varindex+10,options)];  %varindex>10 triggers complex mode ALWAYS
    if varindex>1
      str = [str ';\n'];
      str = [str varname myvar ';\n'];
      str = [str 'clear ' myvar];
    end

  otherwise
     warning('EVRI:Encode',['ENCODE not defined for class ' class(item) ' (' varname '), using NaN.'])
    str = [varname 'NaN']; %encode([nan],varname,varindex,options);

end


%-------------------------------------------
function s = dispvect(items,options)
% display row vector in appropriate format

ffrmt = sprintf('%%.%ig',options.floatdigits);  %floating point format

s='';
wasclass = class(items);
if islogical(items)
  s = [s 'logical([ '];
elseif ~isa(items,'double')
  s = [s class(items) '([ '];
  items = double(items);
end

switch options.compression
  case 'runs'
    %Locate runs of numbers (any step size) and combine into :: format runs
    %slower method, but takes less space
    steps    = double(diff(items));
    steps(abs(steps)/length(items)<eps*4) = 0;
    sigfig   = 4;
    stepsadj = double(max(abs(items)));
    if stepsadj == 0;
      stepsadj = 1;
    end
    stepsrnd = steps./10.^floor(log10(stepsadj));  %steps must not require more than "sigfig" significant digits to create a run
    stepsrnd = abs((stepsrnd-round(stepsrnd*(10.^sigfig))/(10.^sigfig))./length(steps))<eps;
    count    = 1;
    ind      = 1;
    while ind<=length(items);
      if ind<length(steps) & abs(steps(ind)-steps(ind+1))<=eps*4 & stepsrnd(ind) & stepsrnd(ind+1);% & (abs(steps(ind))>1e-6 | abs(steps(ind))<=eps)
        if count==1;
          runstart = ind;
          step     = steps(ind);
        end
        count = count+1;
      else  %step to next two items do not match - handle last run or item
        if count==1;
          item = items(ind);
          if islogical(item);
            s = [s sprintf('%i ',item)];
          elseif item==fix(item);
            s = [s sprintf('%i ',item)];
          else
            s = [s sprintf([ffrmt ' '],item)];
          end
        else
          count = count+1;
          ind   = ind+1;
          switch step
            case 0;
              s = [s sprintf([ffrmt '*ones(1,%i) '],items(runstart),count)];
            case 1;
              s = [s sprintf([ffrmt ':' ffrmt ' '],items(runstart),items(ind))];
            otherwise
              % Formatted representation of a 'run' of values can lead to a 
              % misrepresentation of the run. The formatted run start and 
              % end values can describe a shorter range than the true start 
              % and end values. Avoid this by comparing the range using
              % formatted limits against formatted step times the number of
              % items. Should agree within roundoff error.
              xfmt1 = num2precision(items(runstart), options.floatdigits);
              xfmt2 = num2precision(items(ind), options.floatdigits);
              stepfmt = num2precision(step, options.floatdigits);
              undercounting = abs(abs(xfmt2-xfmt1) < abs(stepfmt)*(ind-runstart))>eps;
              
              if undercounting
                s = [s sprintf('linspace(%.12g,%.12g,%i) ',items(runstart),items(ind),count)];
              else
                s = [s sprintf([ffrmt ':' ffrmt ':' ffrmt ' '],items(runstart),step,items(ind))];
              end
          end
          count = 1;
        end
%         if (length(s)-max([0 findstr(s,'\n')]))>80 & ind~=length(items);
%           s = [s '...\n'];
%         end
      end
      ind   = ind +1;
    end

  case 'speed'

    %get format first
    if islogical(items(1));
      frmt = '%i ';
      rowwidth = 1000;
    elseif all(items==fix(items));
      frmt = '%i ';
      rowwidth = 600;
    else
      frmt = [ffrmt ' '];
      rowwidth = 400;  % # of items in a row
    end
    
    %convert in blocks (ignoring runs)
    for ind = 1:rowwidth:length(items)
      sub = items(ind:min(ind+rowwidth-1,end));
      switch ind
        case 1
          s = [s sprintf(frmt,sub)];
        otherwise
          s = [s sprintf('...\n') sprintf(frmt,sub)];
      end
      
    end

  case 'format'
    %display all items in a vector however they look
    
    for ind = 1:length(items);
      item = items(ind);
      if islogical(item);
        s = [s sprintf('%i ',item)];
      elseif item==fix(item);
        s = [s sprintf('%i ',item)];
      else
        s = [s sprintf([ffrmt ' '],item)];
      end
      if (length(s)-max([0 findstr(s,'\n')]))>80 & ind~=length(items);
        s = [s '...\n'];
      end
    end
end
if islogical(items)
  s = [s ']) '];
elseif ~strcmp(wasclass,'double')
  s = [s ']) '];
end
s=s(1:end-1);

%---------------------------------------------
function out = issimple(item,options)
% returns false if item contains any structures

if ndims(item)>2
  %multi-way is not simple
  out = false;

elseif isa(item,'cell');
  %cell item... parse cell items for complexity
  out = true;  %assume simple until we find otherwise
  for k = 1:prod(size(item));
    out = out & issimple(item{k},options);
  end

elseif ismember(class(item),{'struct','function_handle'}) ...
    & ndims(item)<3 & strcmp(options.structformat,'struct')
  out = true;
  
elseif ~isnumeric(item) & ~isstr(item)
  %structure or other odd class is not simple
  out = false;

else
  %something else, assume simple
  out = true;
end

%--------------------------------------------------------------------------
function [res] = num2precision(x, p)
% return x to p significant digits in same manner as %.<p>g formatting
abslogx=log10(abs(x));
x1 = x*10^(-floor(abslogx));
x2 = round(x1*10^(p-1))/10^(p-1); % 'fix' would truncate additional digits
res = x2*10^floor(abslogx);       % but 'round' is what %.12g formatting does


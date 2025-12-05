function [status,msg] = comparevars(a,b,level,options)
%COMPAREVARS Compares two variables of any type and returns differences.
% Given any two variables (a) and (b), COMPAREVARS looks for any
% differences. This function operates on any standard Matlab data type or a
% DataSet object and does not give an error when variables of two different
% types are passed.
% The optional third input (options) is a standard options structure
% containing one or more of the following fields:
%
%    ignoreclass   : {} Cell array of classes which should be ignored
%                     during the comparison. If a structure or cell
%                     contains any objects of these classes, the values
%                     will not be compared. NOTE: any numeric class
%                     (double, uint8, single) should be referred to as
%                     'numeric' to ignore comparisons.
%    ignorefield   : {} Specifies one or more structure fields
%                     which should be ignored (not compared) in any structure.
%    missingfield  : [ 'ignore' | {'difference'} ] specifies how to handle when
%                     one of two input structures does not contain the same
%                     fields as the other. 'ignore' simply ignores missing
%                     fields. 'difference' returns this mismatch as a noted
%                     difference.
%    breakondiff   : [{0}|1] Stop compare when first diff is found.
%
% With no outputs, the differences between the variables (or "None Found")
% is displayed. With one output, the boolean result of the comparison
% (status) is returned (1 = variables are completely equivalent). With two
% outputs, the comparison result is returned and a cell array of strings is
% returned listing the differences as a description (msg).
%
%I/O: [status,msg] = comparevars(a,b,options);
%
%See also: CELLNE

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS 10/2006

status = {};
msg= '';
if nargin<4
  %initial call
  
  if nargin==1 && ischar(a);
    options = [];
    options.ignoreclass = {};
    options.ignorefield = {};
    options.missingfield = 'difference';
    options.breakondiff  = 0;
    if nargout==0; clear status; evriio(mfilename,a,options); else; status = evriio(mfilename,a,options); end
    return;
  end
  
  %handle options
  if nargin>2
    options = level;
  else
    options = [];
  end
  options = reconopts(options,mfilename);
  numericflag = ismember(options.ignoreclass,{'double','single','uint8','int8','uint16','int16','uint32','int32','uint64','int64'});
  if any(numericflag)
    options.ignoreclass(numericflag) = {'numeric'};
  end
  
  
  status = comparevars(a,b,0,options);
  
  if isempty(status)
    msg = {'No Differences Found'};
    status = 1;
  else
    msg = status;
    status = 0;
  end
  if nargout == 0
    disp(char(msg))
    clear status msg
  end
  return
end

cls = class(a);  %get class of a
if ismodel(a) | ismodel(b)
  %special case - handle models separately (so old and new are compared)
  cls = 'evrimodel';
  if ~ismodel(a) | ~ismodel(b)
    status = {[blanks(level*2) 'Variables are not similar classes']};
    return;
  end
elseif ~strcmp(cls,class(b))
  %not a model -do a standard comparison
  status = {[blanks(level*2) 'Variables are not similar classes']};
  return
end

if isnumeric(a)
  cls = 'numeric';
end
switch cls
  case options.ignoreclass
    %ignore what classes...
    return
end

if ndims(a)~=ndims(b)
  status = {[blanks(level*2) 'Number of variable dimensions do not match']};
  return
end

switch cls
  case 'cell'
    if ~all(size(a)==size(b))
      status = {[blanks(level*2) 'Cell array sizes do not match']};
      return
    end
    for k=1:numel(a);
      onestatus = comparevars(a{k},b{k},level+1,options);
      if ~isempty(onestatus);
        [inds{1:ndims(a)}] = ind2sub(size(a),k);
        status = [status;{[blanks(level*2) '{' sprintf('%i',inds{1}) sprintf(',%i',inds{2:end}) '}']};onestatus];
        if options.breakondiff
          break
        end
      end
    end
    
  case 'struct'
    if ~all(size(a)==size(b))
      status = {[blanks(level*2) 'Structure array sizes do not match']};
      return
    end
    fylds = union(fieldnames(a),fieldnames(b));
    for k=1:length(a);
      for j=1:length(fylds);
          switch fylds{j}
            case options.ignorefield
              continue;
          end
          onestatus = [];
          try
            if ~isfield(b,fylds{j}) | ~isfield(a,fylds{j})
              if strcmp(options.missingfield,'ignore')
                continue;  %skip this variable
              else
                if ~isfield(b,fylds{j})
                  item = 'b';
                else
                  item = 'a';
                end
                onestatus = [[blanks(level*2+2)] 'Does not exist in (' item ')'];
                if options.breakondiff
                  status = [status;{[blanks(level*2) '.' fylds{j} '']};onestatus];
                  break
                end
              end
            else
              asub = a(k).(fylds{j});
              bsub = b(k).(fylds{j});
            end
          catch
            if strcmp(options.missingfield,'ignore')
              continue;  %skip this variable
            else
              onestatus = lasterr;
            end
          end
          if isempty(onestatus);
            onestatus = comparevars(asub,bsub,level+1,options);
          end
          if ~isempty(onestatus)
            status = [status;{[blanks(level*2) '.' fylds{j} '']};onestatus];
            if options.breakondiff
              break
            end
          end
        
      end
    end
    
  case 'dataset'
    status = comparevars(a.data,b.data,level+1,options);
    
  case 'char'
    if ~strcmp(a,b)
      status = {[blanks(level*2) 'Strings do not match']};
    end
    
  case {'numeric' 'logical' 'char'}
    if ~all(size(a)==size(b))
      status = {[blanks(level*2) 'Array sizes do not match']};
      return
    end
    if ~all(isfinite(a(:))==isfinite(b(:)));
      status = {[blanks(level*2) 'Non-finite values in variables do not match']};
    else
      if ~all(isnan(a(:))==isnan(b(:)))
        status = {[blanks(level*2) 'NaN values in variables do not match']};
        return;
      end
      if all(~isfinite(a(:))); return; end  %all infinite - just accept as-is
      
      a = double(a);
      b = double(b);
      afin = a(isfinite(a(:)));
      bfin = b(isfinite(a(:)));
      sclmax  = max(abs([afin(:);bfin(:)]));
      if sclmax==0; sclmax = 1; end
      scldiff = abs(afin-bfin)./max(1,sclmax);
      if any(scldiff>1e-8)
        status = {[blanks(level*2) 'Contents do not match']};
      end
    end
    
  case 'evrimodel'
    if ~strcmp(a.modeltype,b.modeltype)
      status = {[blanks(level*2) 'Modeltypes do not match']};
      return;
    end
    for f = {'loads' 'pred' 'reg' 'ssqresiduals' 'tsqs' 'wts'}
      if isfield(a,f{:}) & isfield(b,f{:})
        onestatus = comparevars(a.(f{:}),b.(f{:}),level+1,options);
        if ~isempty(onestatus)
          status = [status;{[blanks(level*2) '.' f{:} '']};onestatus];
          if options.breakondiff
            break
          end
        end
      end
    end
    if isfield(a,'detail') & isfield(b,'detail')
      %now handle details (but ignore missing fields)
      tempoptions = options;
      tempoptions.missingfield = 'ignore';
      onestatus = comparevars(a.detail,b.detail,level+1,tempoptions);
      if ~isempty(onestatus)
        status = [status;{[blanks(level*2) '.detail']};onestatus];
      end
    end
    
  otherwise
    %do not compare
    
end


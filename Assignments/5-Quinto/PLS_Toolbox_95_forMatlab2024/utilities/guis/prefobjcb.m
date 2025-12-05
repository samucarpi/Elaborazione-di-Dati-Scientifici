function varargout = prefobjcb(varargin)
%Callback utility for optionsgui.
%
%See also: OPTIONSGUI, PREFOBJPLACE

%Copyright Eigenvector Research 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk 10/31/05
%rsk 11/30/05 Change font size in Display text box.
%rsk 05/09/06 Add custom load function (initially for parafac).

if nargin>0;
  try
    switch lower(varargin{1})
      case evriio([],'validtopics')
        options = prefobjplace('options');
        %add guifcn specific options here
        if nargout==0
          evriio(mfilename,varargin{1},options)
        else
          varargout{1} = evriio(mfilename,varargin{1},options);
        end
        return; 
      otherwise 
        if nargout == 0;
          feval(varargin{:}); % FEVAL switchyard
        else
          [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
        end
    end
  catch
    if ~isempty(gcbf);
      set(gcbf,'pointer','arrow');  %no "handles" exist here so try setting callback figure
    end
    erdlgpls(lasterr,[upper(mfilename) ' Error']);
  end   
end

% --------------------------------------------------------------------
function loadmatrix(h, eventdata, handles, varargin)
%Load matrix/vector data into options sturct.
%Add checking at end of load (from the valid field of optiondefs).
prfdata = getappdata(h,'optinfo');
newopts = getappdata(prfdata.target,'newopts');

if regexp(prfdata.name,'Mode\d*_Cell')
  omode = str2num(prfdata.name(regexp(prfdata.name,'_Mode\d*_Cell')+5:end-5)); %Integer
else
  omode = 1;
end

if strfind(prfdata.valid,'loadfcn')
  %Userdefined function for loading and validating data.
  fcn = deblank(prfdata.valid);
  fcn = fcn(strfind(fcn,'=')+1:end);
  x = findfield(newopts,prfdata.name);
  try
    set(handles.optionsgui,'pointer','watch','visible','off')
    rawdata = feval(fcn,x);
    set(handles.optionsgui,'pointer','arrow','visible','on')
    optionsgui('updategui',handles,[])
  catch
    set(handles.optionsgui,'pointer','arrow','visible','on')
    dlgans = evriquestdlg(['Unable to run custom load function. Try loading from workspace or file?'],'Load Problem');
    if strcmp(dlgans,'Yes')
      dlgsetting = {'*'};
      [rawdata,name,location] = lddlgpls(dlgsetting,'Load Options Field Data');
    end
  end
elseif strcmp(prfdata.datatype,'preprocessing') | strcmp(prfdata.name,'preprocessing') | strcmp(prfdata.cellname,'preprocessing')
  rawdata = preprocess(newopts.preprocessing{omode});
elseif strcmp(prfdata.datatype,'directory')
  x = findfield(newopts,prfdata.name);
  rawdata = uigetdir(x,prfdata.name);
  if isnumeric(rawdata)
    rawdata = [];
  end
else 
  switch prfdata.datatype
    case 'dataset'
      dlgsetting = {'*'};
    otherwise
      dlgsetting = {'double'};
  end
  [rawdata,name,location] = lddlgpls(dlgsetting,'Load Options Field Data');
  if strcmp(prfdata.datatype,'dataset') & ~isempty(rawdata) & ~isdataset(rawdata)
    rawdata = dataset(rawdata);
  end
end

%If rawdata is empty then user must have canceled above.
if ~isempty(rawdata) 
  if isvalid(rawdata,prfdata,newopts)
    sizestr(rawdata,prfdata)
    newopts = addfield(newopts,prfdata.name,rawdata);%Add new value to options field.
  else
    erdlgpls(['Option value for ''' prfdata.name ''' not valid. Check help for accepted range of values for this field.'],'Invalid Setting')
  end
end
setnewopts(prfdata.target, newopts);%Add options.

% --------------------------------------------------------------------
function clearmatrix(h, eventdata, handles, varargin)
%Clear value in field.
prfdata = getappdata(h,'optinfo');
newopts = getappdata(prfdata.target,'newopts');

%If original value is struct the reset rather than cancel. Empty value will
%cause error for loadfcn.
x = findfield(newopts,prfdata.name);
if ~isstruct(x)
  x = [];
end

newopts = addfield(newopts,prfdata.name,x);%Add new value to options field.
setnewopts(prfdata.target, newopts);%Add options.
sizestr(x,prfdata)

% --------------------------------------------------------------------
function loadmode(h, eventdata, handles, varargin)
%Load simple vector for modes/slabs. Can handle float datatype.
%Attempts to check valid statement for each value in seperate call to valid().

prfdata = getappdata(h,'optinfo');
newopts = getappdata(prfdata.target,'newopts');
strval = get(h,'String');

%Check for only numeric arguments. 
ns = str2num(strval);
if isempty(ns)
  erdlgpls('Values must be numbers separated by a space (e.g. "3 4 8 5"). Please use specified format.', 'Formatting Error')
  set(h,'String',despace(getfield(newopts,prfdata.name)))
  return
end

%TODO: add check of each number.
for i = 1:length(ns)
  if ~isvalid(ns(i),prfdata,newopts)
    erdlgpls(['Option value for ''' prfdata.name ''' not valid. Check help for accepted range of values for this field.'],'Invalid Setting')
    set(h,'String',despace(getfield(newopts,prfdata.name)))
    return
  end
end
newopts = addfield(newopts,prfdata.name,ns);

setnewopts(prfdata.target, newopts);

% --------------------------------------------------------------------
function loadboolean(h, eventdata, handles, varargin)
%Boolean data from list selection.

prfdata = getappdata(h,'optinfo');
newopts = getappdata(prfdata.target,'newopts');
val = get(h,'Value')-1;

if isvalid(val,prfdata,newopts)
  newopts = addfield(newopts,prfdata.name,val);
else
  erdlgpls(['Option value for ''' prfdata.name ''' not valid. Check help for accepted range of values for this field.'],'Invalid Setting')
  set(h,'String',getsubstruct(newopts,prfdata.name))
  return
end

setnewopts(prfdata.target, newopts);

% --------------------------------------------------------------------
function loadsingle(h, eventdata, handles, varargin)
%Load single string or numeric value data into options struct.
%Add checking at end of load (from the valid field of optiondefs).
prfdata = getappdata(h,'optinfo');
newopts = getappdata(prfdata.target,'newopts');
strval = get(h,'String');

%Set datatype.
switch prfdata.datatype
  case 'double'
    strval = double(str2num(strval));
    if sum(size(strval))>2
      erdlgpls(['Option value must be a single value.'],'Invalid Setting')
      set(h,'String',num2str(getsubstruct(newopts,prfdata.name)))
      return
    end
end

if ~isvalid(strval,prfdata,newopts)
  erdlgpls(['Option value for ''' prfdata.name ''' not valid. Check help for accepted range of values for this field.'],'Invalid Setting')
  set(h,'String',num2str(getsubstruct(newopts,prfdata.name)))
  return
end
%TODO: Need utility to for setting sub sub fields with one string.
newopts = addfield(newopts,prfdata.name,strval);

setnewopts(prfdata.target, newopts);

% --------------------------------------------------------------------
function loadlist(h, eventdata, handles, varargin)
%Load list data into options struct.
prfdata = getappdata(h,'optinfo');
newopts = getappdata(prfdata.target,'newopts');
strval = get(h,'String');
strval = strval(get(h,'Value'));

%Set datatype.
switch prfdata.datatype
  case {'double'}
    strval = double(str2num(strval));
end

%Transform string back to number if using numeric list in 'valid' field. 
if isnumeric(prfdata.valid{1})
  strval = {str2num(strval{:})};
end

%TODO: Need utility to for setting sub sub fields with one string.

newopts = addfield(newopts,prfdata.name,strval{:});

setnewopts(prfdata.target, newopts);

% --------------------------------------------------------------------
function loadstructure(h, eventdata, handles, varargin)

prfdata = getappdata(h,'optinfo');
tabh = findobj(handles.optionsgui,'tag',['tab_' prfdata.name]);
optionsgui('togglebutton_Callback',tabh,[],handles);


% %Insert UI controls for a substructure with recursive call.
% prfdata = getappdata(h,'optinfo');
% newopts = getappdata(prfdata.target,'newopts');
% 
% %Get sub structure.
% subopts = getsubstruct(newopts,prfdata.name);
% 
% %Check to see if objects have already been created. If so, then collapse
% %the objects.
% 
% %Call 
% popts = prefobjplace('options');
% newfig = figure;
% popts.target = prfdata.target;
% popts.recursive = 'yes';
% 
% if isfield(subopts,'definitions')
%   %A named subfunction is being called (e.g function('options')). 
%   %Need to append parent name.
%   for i = 1:size(subopts.definitions,1);
%     subopts.definitions(i).name = [prfdata.name '.' subopts.definitions(i).name];
%   end
%   newopts.definitions = subopts.definitions;
%   prefobjplace(newfig,newopts,{subopts.definitions.name},popts);
% else
%   %Suboptions are defined within current function so can use existing defs.
%   nlst = fieldnames(subopts);
%   nlst = strcat(repmat([prfdata.name '.'], length(nlst),1), nlst);
%   prefobjplace(newfig,newopts,nlst,popts);
% end
% %If no defs, create.
% 
% %Move all controls down and make recursive call to preobjplace.
% 

% --------------------------------------------------------------------
function out = isvalid(invalue, defstruct, options)
%Test option input.
%
%Numeric: values have following conventions:
%  keyword(range) where keyword can be 'int' or 'float' and range is ML
%  notation including 'inf'.
%  E.G. int(1:5), float(0:1)
%
%Strings: can also be a cell of values against which invalue will be tested.
%
%Custom functions:
%  Two types of custom functions can be run wher the 'valid' string is:
%
%    'function=myfuntion' = 'myfunction' will be called with the name, the
%    new value of the option, and a copy of the current options stucture
%    (e.g., myfunciton(name,value,options)).
%
%    'function_cb=myfunction' = 'myfunction' will be called with a named
%    subfunction 'isvalidoption' along with name, new value, and a copy of
%    the current options structure (e.g., feval(myfunction,'isvalidfunction',name,value)).
%
%Keyword ODD or EVEN can be used as 'valid' string to check if value is odd
%or even.

valstr = defstruct.valid;

out = 1;  %assume OK unless we decide otherwise
if isempty(valstr)
  %Valid may be called by a load function without a 'valid' statement.
  return 
end

try
  if iscell(valstr)
    %Test against cell vaules.
    if isnumeric(invalue)
      %Test if invalue is memeber of number set.
      out = ismember(invalue,[valstr{:}]);
    else
      %Test if invalue is member of string set.
      out = ismember(invalue,valstr);
    end

  else
    %String description of valid settings

    out = 1; %Assume OK unless we find otherwise
    if ~isempty(strfind(valstr,'int(')) | ~isempty(strfind(valstr,'float('))
      %Parse numeric test string.
      [ntest,rem] = strtok(valstr,'(');
      ctest1 = strtok(rem,'()');
      [ctest1,rem] = strtok(ctest1,':');
      ctest2 = strtok(rem,':');
      ctest1 = str2num(ctest1);
      ctest2 = str2num(ctest2);

      switch ntest
        case 'int'
          if out & isnumeric(invalue) & invalue == round(invalue)
            out = (invalue >= ctest1 & invalue <= ctest2);
          else
            out = 0;
          end

        case 'float'
          if out & isnumeric(invalue)
            out = (invalue >= ctest1 & invalue <= ctest2);
          else
            out = 0;
          end
      end
    end
    %Key words ODD and EVEN
    if ~isempty(strfind(lower(valstr),'odd'))
      out = out & (mod(invalue,2)==1);
    end
    if ~isempty(strfind(lower(valstr),'even'))
      out = out & (mod(invalue,2)==0);
    end
    if ~isempty(strfind(lower(valstr),'function='))
      myfunc = valstr(strfind(valstr,'function=')+9:end);
      out = eval([myfunc '(defstruct.name,invalue,options)']);
    end
    if ~isempty(strfind(lower(valstr),'function_cb='))
      myfunc = valstr(strfind(valstr,'function_cb=')+12:end);
      out = feval(myfunc,'isvalidoption',defstruct.name,invalue,options);
    end
  end
catch
  out = 0;
end


% --------------------------------------------------------------------
function opts = addfield(opts,name,val)
%Add new value to options.
%If cell value, do parsing.

if regexp(name,'Mode\d*_Cell')
  oname = name(1:regexp(name,'_Mode\d*_Cell')-1); %Name
  omode = str2num(name(regexp(name,'_Mode\d*_Cell')+5:end-5)); %Integer
  opts = setsubstruct(opts,oname,{omode},{val});
else
  opts = setsubstruct(opts,name,{},val);
end
% --------------------------------------------------------------------
function out = findfield(opts,name)
%Get a value from options.
%If cell value, do parsing.
if regexp(name,'Mode\d*_Cell')
  oname = name(1:regexp(name,'_Mode\d*_Cell')-1); %Name
  omode = str2num(name(regexp(name,'_Mode\d*_Cell')+5:end-5)); %Integer
  out = getsubstruct(opts,oname,{omode});
  out = out{:};
else
  out = getsubstruct(opts,name);
end

% --------------------------------------------------------------------
function out = despace(in)
%Create string from vector. Avoid multiple spaces if values are elevated
%precision. 'in' is vector.

out = '';
for i = 1:length(in)
  out = [out num2str(in(i)) ' '];
end
out = out(1:end-1);

% --------------------------------------------------------------------
function setnewopts(target, newopts)

if ~ishandle(target)
  error('Controling figure for preferences/options GUI is not available.')
  return
end
obj = gcbo;
if ishandle(obj)
  %reenable save button for this row (if present)
  [junk,tag] = strtok(get(gcbo,'tag'),'_');
  if ~isempty(tag)
    svh = findobj(target,'tag',['save' tag]);
    if ishandle(svh)
      set(svh,'enable','on');
    end
  end
end
setappdata(target,'newopts',newopts);

% --------------------------------------------------------------------
function displayhelp(h, eventdata, handles, varargin)
%Display help in Description window.
hlpdsp = findobj(get(h,'parent'),'tag','display_help');
ud = getappdata(h,'optinfo');
dummyh = []; %Dummy uicontrol for text wrapping.
%Add name to help string.
if ~iscell(ud.help)
  str = [upper(ud.name) '  -  ' ud.help];
  %Get help window size and adjust size for wrapping.
  pos = get(hlpdsp,'position');
  pos(3) = pos(3)-148;
  pos(4) = pos(4)-1;

  %Create a dummy control so textwrap will space correctly.
  dummyh = uicontrol('visible','off','position',pos);
  str = textwrap(dummyh,{str});
else
  str = [{[upper(ud.name) ' :']} ud.help];
end

%set(hlpdsp,'value',[]);
set(hlpdsp,'string', str);
if ~isempty(dummyh)
  delete(dummyh);
end

% --------------------------------------------------------------------
function updategui(handles)
dh = findobj(handles.optionsgui, 'tag', 'display_help');
set(dh,'String', 'Description')

% --------------------------------------------------------------------
function sizestr(rawdata,prfdata)
%Make and display stirng for value cloumn.

sz = size(rawdata);
if isempty(rawdata)
  sizestr = '(empty)';
else
  sizestr = sprintf('%ix',sz);
  sizestr = [sizestr(1:end-1) ' ' class(rawdata)];
end
sizestr = ['Size: ' sizestr];
displayh = findobj(prfdata.target, 'tag',['disp_' prfdata.name]);%Find control.
set(displayh, 'String', sizestr);%Change string.

% -------------------------------------------------------------------
function savepref(h,eventdata,handles,varargin)

prfdata = getappdata(h,'optinfo');
newopts = getappdata(prfdata.target,'newopts');

if isfield(newopts,'functionname') & ~isempty(newopts.functionname)
  %   {newopts.functionname,prfdata.name,newopts.(prfdata.name)}
  %   ans{3}
  name = prfdata.name;
  if ~isempty(strfind(name,'.'))
    name = strtok(name,'.'); %grab first portion before .
  end
  setplspref(newopts.functionname,name,newopts.(name))
else
  evrierrordlg('Unable to save this as a persisent preference','Save Preference');
end
set(h,'enable','off')

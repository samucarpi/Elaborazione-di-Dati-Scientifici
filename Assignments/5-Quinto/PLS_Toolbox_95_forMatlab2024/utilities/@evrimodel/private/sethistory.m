function history = sethistory(history,feyld,val,notes)

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if isempty(history{1})
  ihis   = 1;
else
  ihis   = length(history)+1;
end

caller = '';
try
  [ST,I] = dbstack;
  if length(ST)>2;
    [a,b,c]=fileparts(ST(3).name);
    caller = ['   [' b c ']'];
  end
catch
end

if nargin>3 & ~isempty(notes)
  if ~isempty(feyld)
    notes  = [' % ' notes];
  end
else
  notes  = '';
end;

if nargin>2 & ~isempty(feyld)
  if ~ischar(val)
    if isnumeric(val) & size(val,1)==1 & size(val,2)<10
      val = encode(val,'');
    elseif isnumeric(val) & isempty(val)
      val = '[]';
    elseif iscell(val)
      val = '{...}';
    elseif isa(val,'double')
      val = '[...]';
    else
      val = [class(val) '(...)'];
    end
  else
    if size(val,1)>1 | size(val,2)>50
      val = '''...''';
    else
      val = ['''' val ''''];
    end
  end
  val = [' = ' val];
end
  

tstamp = datestr(now,'yyyy-mm-dd HH:MM:SS.FFF');
if isempty(feyld)
  history{ihis,1} = [tstamp ' ' notes ' ' caller ];
else
  history{ihis,1} = [tstamp ' - model.' feyld val notes ' ' caller ];
end

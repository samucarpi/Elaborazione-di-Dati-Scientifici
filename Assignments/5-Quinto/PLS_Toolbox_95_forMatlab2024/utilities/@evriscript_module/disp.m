function disp(A)
%EVRISCRIPT_MODULE/DISP displays class fields

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if A.lock
  lockstr = 'On/True (1)';
else
  lockstr = 'Off/False (0)';
end

disp(' EVRIScript_Module Object');

disp(['      keyword: ''', A.keyword '''']);
disp(['  description: ''', A.description '''']);
disp(['         lock: ', lockstr]);

if ~isempty(A.command);
  for f = fieldnames(A.command)';
    disp(sprintf('    + ''%s'' mode',f{:}));
    disp(sprintf('         command.%s= ''%s''',f{:},A.command.(f{:})));
    if ~isempty(A.required)
      disp(sprintf('        required.%s= %s',f{:},formatcell(A.required.(f{:}))));
    end
    if ~isempty(A.optional)
      disp(sprintf('        optional.%s= %s',f{:},formatcell(A.optional.(f{:}))));
    end
    if ~isempty(A.outputs)
      disp(sprintf('         outputs.%s= %s',f{:},formatcell(A.outputs.(f{:}))));
    end
  end
else
  disp(sprintf('    + No Modes Defined'));
  disp(sprintf('         command = (empty)'));
  disp(sprintf('        required = (empty)'));
  disp(sprintf('        optional = (empty)'));
  disp(sprintf('         outputs = (empty)'));
end


printstruct(A.default,  '    default')
printstruct(A.options,  '    options')

%--------------------------------------------------------
function sbuf = formatcell(aCell)

if ~isempty(aCell)
  sbuf = '{''';
  for ii=1:(length(aCell)-1)
    sbuf = [sbuf aCell{ii} ''' '''];
  end
  sbuf = [sbuf aCell{end} ];
  sbuf = [sbuf '''}'];
else
  %empty cell
  sbuf = '{ }';
end

%-----------------------------------------------------
function printstruct(aStruct, prefix)

if ~isempty(aStruct)
  if isstruct(aStruct)
    disp([prefix '=']);
  else
    disp([prefix '= (class ''' class(aStruct) ''')']);
  end
else
  disp([prefix '= (empty)']);
  return
end

disp(aStruct);

function outdef = adoptdefinitions(indef, func, posname, options)
%ADOPTDEFINITIONS Inserts definitions into an exsisting definitions list.
%  indef   = cell array of definitions. 
%  func    = function name  
%  posname = position name
%
% options remlist - remove options from display.
%
%I/O: outdef = adoptdefinitions(indef, func, posname, options)
%
%See also: GETSUBSTRUCT, OPTIONSGUI, SETSUBSTRUCT

%Copyright Eigenvector Research 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk 10/31/05

if nargin == 0; varargin{1} = 'io'; end
varargin{1} = indef;
if ischar(varargin{1});
  options = [];
  options.rmlist = '';
  if nargout==0; evriio(mfilename,varargin{1},options); else; outdef = evriio(mfilename,varargin{1},options); end
  return;
end
  
eval(['fopts = ' func '(''options'');']);

if isa(fopts.definitions,'function_handle')
  fdefs = feval(fopts.definitions);%preference definitions
else
  fdefs = fopts.definitions; %preference definitions
end

%Append parent name.
for i = 1:size(fdefs,1)
  fdefs(i).name = [posname '.' fdefs(i).name];
  fdefs(i).tab  = [posname '.' fdefs(i).tab];
  %Add change for 
end

%Create cell array.
fdefs = struct2cell(fdefs)';

%Remove fields.
if ~isempty(options.rmlist)
  for i = 1:length(options.rmlist)
    pos1 = find(ismember(fdefs(:,1),[posname '.' options.rmlist{i}]));
    if ~isempty(pos1)
      fdefs = [fdefs(1:pos1-1,:); fdefs(pos1+1:end,:)];
    end
  end 
end  

pos = find(ismember(indef(:,1),posname));

outdef = [indef(1:pos,:); fdefs; indef(pos+1:end,:)];

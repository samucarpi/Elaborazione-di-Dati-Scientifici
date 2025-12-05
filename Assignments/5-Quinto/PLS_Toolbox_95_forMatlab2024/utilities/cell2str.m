function parsed = cell2str(mycell,pad,addlf)
%CELL2STR convert cell array of strings to char array.
%  Input 'mycell' is nxm cell array of strings. Input 'pad' is padding
%  characters (usually spaces) to insert between columns. Input 'addlf' (0
%  or 1) adds a line feed character to end of each line.
%
%I/O: parsed = cell2str(mycell,pad);
%
%See also: STR2CELL

% Copyright © Eigenvector Research, Inc. 2008
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%rsk 12/2008

if nargin <2
  pad = '';
end

if nargin<3
  addlf = 0;
end

%Check for numeric but wrap in try/catch because using new cellfun
%functionality (new as of about 2008a). 
try
  numcells = cellfun(@isnumeric,mycell);
  mycell(numcells) = cellfun(@num2str,mycell(numcells),'UniformOutput', false);
  numcells = cellfun(@islogical,mycell);
  mycell(numcells) = cellfun(@num2str,mycell(numcells),'UniformOutput', false);
end

parsed = '';
rows = size(mycell,1);
cols = size(mycell,2);
if ~isempty(pad)
  pad = repmat(pad,[rows 1]);
end
for i = 1:cols
  %Replace empty cells with spaces so they vcat correctly.
  mycell(ismember(mycell,'')) = {' '};
  %Make a column.
  mycol = strvcat(mycell{:,i});
  %Add column.
  parsed = [parsed mycol];
  if ~isempty(pad) && i~=cols
    %Add pad column.
    parsed = [parsed pad];
  end
end

if addlf
  parsed = [parsed repmat(char(10),[rows 1])];
end




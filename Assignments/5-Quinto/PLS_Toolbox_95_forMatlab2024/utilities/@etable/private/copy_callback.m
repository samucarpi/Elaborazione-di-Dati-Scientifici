function varargout = copy_callback(hObj,ev,fh,mytag,target)
% ETABLE/COPY_CALLBACK Copy table data to clipboard.
%  target : {'data' 'column_labels' 'all'} What to copy.
%
% Copyright © Eigenvector Research, Inc. 2013
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.


%Get up-to-date copy of object since the object passed is from function
%handle.
obj = gettobj(fh,mytag);

%Get tables.
jt = obj.java_table;

if nargin<4
  target = {'data'};
end

if ~iscell(target)
  target = {target};
end

if length(target)==1 && strcmpi(target{1},'all')
  target = {'data' 'column_labels'};
end

%Column labels.
coldata = [];
if ismember('column_labels',target)
  coldata = striphtml(obj.column_labels);
end

%Table data.
tdata = [];
if ismember('data',target)
  tdata = obj.data;
  if ~iscell(tdata)
    tdata = num2cell(tdata);
  end
end

%Use java html parser to correct any mistakes. Fixes HTML tags that are in
%the column headers of SSQ table.
opts.make_pretty = 'on';

if nargout > 0
  varargout{1} = [coldata;tdata];
else
  ttbl = cell2str([coldata;tdata],char(9),1)';
  ttbl = [ttbl(:)]';
  clipboard('copy',ttbl);
end

%-------------------------------------
function colcell = striphtml(colcell)
%STRIPHTML Remove html tags.

for i = 1:length(colcell); 
  colcell{i} = regexprep(colcell{i},'<[^>]*>','');
end




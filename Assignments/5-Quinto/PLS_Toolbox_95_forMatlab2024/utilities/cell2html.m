function varargout = cell2html(table_cell_data,column_cell_names,options)
%CELL2HTML Export cell array to html character string and or table.
%
%
%I/O: dsohtml = cell2html(table_cell_data);
%I/O: dsohtml = cell2html(table_cell_data,column_cell_names);
%I/O: dsohtml = cell2html(table_cell_data,options);
%I/O: dsohtml = cell2html(table_cell_data,column_cell_names,options)
%
%See also: CELL2ARRAY

%Copyright © Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%NOTES:
%  
%  http://jsoup.org/
%  doc = org.jsoup.Jsoup.parse(sprintf('%s\n',mycell{:}))
%  pretty_html = char(doc.toString);

if nargin==0
  table_cell_data = 'io';
end

if ischar(table_cell_data) && ismember(table_cell_data,evriio([],'validtopics')) %Help, Demo, Options
  options = [];
  options.pathstr            = '';%Default path (folder) for exported files.
  options.table_only         = 'on';%Only return table tags, no HTML body tags.
  options.head_insert        = '';
  options.body_insert        = '';%Inser HTML into body before table. 
  options.filename           = '';%Save to file.
  options.replace_empty      = '&nbsp;';%Replace empty cells with this character/s, default is single space (HTML encoded) otherwise cells won't render in some browsers.
  %Formatting.
  options.numeric_column_format      = '%6.4g';%Handed directly to sprintf.
  options.make_pretty        = 'off';%Use Java parser to parse HTML.
  options.table_attributes   = 'border="1" cellspacing="0" cellpadding="2"';
  options.column_width       = 200;%In pixels

  if nargout==0;
    evriio(mfilename,table_cell_data,options);
  else
    varargout{1}= evriio(mfilename,table_cell_data,options);
  end
  return;
end

%Single input.
if nargin==1
  column_cell_names = {};
  options = [];
end

%Two inputs.
if nargin==2
  if isstruct(column_cell_names)
    options = column_cell_names;
    column_cell_names = {};
  else
    options = [];
  end
end

options = reconopts(options,'cell2html');

mycell = {};
mysz = size(table_cell_data);

if isdataset(table_cell_data)
  mydata = num2cell(table_cell_data.data);
end

%Make row format string.
myfrmt = '<tr>';
for i = 1:mysz(2)
  if ischar(table_cell_data{1,i})
    myfrmt = [myfrmt ['<td>%s</td>']];
    %Replace empty strings with html friendly string.
    myempties = cellfun('isempty',table_cell_data(:,i));
    if any(myempties(:))
      table_cell_data(myempties,i) = repmat({options.replace_empty},1,length(find(myempties)));
    end
  else
    myfrmt = [myfrmt ['<td>' options.numeric_column_format '</td>']];
  end
end
myfrmt = [myfrmt ['</tr>']];

%NOTE: Don't replace all empties, only string empties. Otherwise cause
%weird formatting.
% %Replace empty cells.
% if ~isempty(options.replace_empty)
%   myempties = cellfun('isempty',table_cell_data);
%   if any(myempties(:))
%     table_cell_data(find(myempties)) = repmat({options.replace_empty},1,length(find(myempties)));
%   end
% end

%Raw data parsing.
for i = 1:mysz(1)
  %Add data.
  mycell = [mycell; sprintf(myfrmt,table_cell_data{i,:})];
end

%Column headers.
if ~isempty(column_cell_names)
  mycell = [sprintf(strrep(myfrmt,options.numeric_column_format,'%s'),column_cell_names{:});mycell];
end

%Add column width attributes.

mycell{1,:} = strrep(mycell{1,:}, '<td>', ['<td width="' num2str(options.column_width) '">']);

%Add table tags.
mycell = ['<table ' options.table_attributes '>';mycell];
mycell = [mycell; '</table>'];

%Add html tags.
if strcmp(options.table_only,'off')
  if ~isempty(options.body_insert)
    mycell = [options.body_insert;mycell];
  end
  mycell = ['<body>';mycell];
  if ~isempty(options.head_insert)
    mycell = ['<head>'; options.head_insert;'</head>';mycell];
  end
  mycell = ['<html>';mycell];
  mycell = [mycell; '</body>'];
  mycell = [mycell; '</html>'];
end

if strcmp(options.make_pretty,'on')
  %Use java parser to make pretty string.
  doc = org.jsoup.Jsoup.parse(sprintf('%s\n',mycell{:}));
  table_html = char(doc.toString);
else
  table_html = sprintf('%s\n',mycell{:});
end

if ~isempty(options.filename)
  %Reopen discarding orginal contents and put new text in.
  fid = fopen(options.filename,'wt');
  if fid>0;
    fprintf(fid, '%s',table_html);
    fclose(fid);
  else
    disp('Could not write html data to file, check filename.');
  end
end

if nargout==1;
  varargout{1} = table_html;
end

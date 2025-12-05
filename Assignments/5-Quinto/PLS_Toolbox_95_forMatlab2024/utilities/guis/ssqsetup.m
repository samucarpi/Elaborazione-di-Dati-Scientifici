function mytbl = ssqsetup(mytbl,myheader,myrowheader,myformat,addcmc,options)
%SSQSETUP Adds default information and setup to ssqtable for Analysis gui.
%  Column header height will be 22px unless <br> detected in 'my header'
%  then will be set to 44px and centered. The 'addcmc' flag tells if to add
%  analysis calcmodel_Callback and ssqtable_Callback to table. Header
%  height can be adjusted with options.row_header_height.  
%
%  NOTE: All outside <html> tags are added in this function.
%
%  INPUTS:
%    myheader : cell array of strings with <br> tags.
% myrowheader : string for header of row column. (NOT USED CURRENTLY)
%    myformat : cell array of strings for row formats.
%
%
%
%I/O: mytbl = ssqsetup(mytbl,myheader,myrowheader,myformat,addcmc,options)
%
%See also: ANALYSIS

%Copyright © Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0
  mytbl = 'io';
end

if ~isempty(mytbl) && ischar(mytbl)
  options = [];
  options.columnheaderheight = 22;%Pixels
  if nargout==0; evriio(mfilename,mytbl,options);clear mytbl; else; mytbl = evriio(mfilename,mytbl,options); end
  return;
end

if nargin<6 || isempty(options)
  options = ssqsetup('options');
else
  options = reconopts(options,mfilename);
end

hto = '<html>';%html open%%
htc = '</html>';%html close%%
hht = options.columnheaderheight;

if nargin<5
  addcmc = 0;
end

%Check and add html.
addheight = 1;
for i = 1:length(myheader)
  if isempty(strfind(myheader{i},'<html>'))
    myheader{i} = [hto myheader{i} htc];
  end
  
  if ~isempty(strfind(myheader{i},'<br>'))
    %Double height of column header.
    addheight = 2;
  end
end

hht = hht*addheight;%Double height if necessary

%Add more height if high res screen.
[mpos,screenratiox,screenratioy] = getmouseposition(mytbl.parent_figure);
hht = hht/screenratioy;

%Check and add html.
if isempty(strfind(myrowheader,'<html>'))
  myrowheader = [hto myrowheader htc];
end

mytbl.data = repmat({' '},1,length(myheader));%Default is single empty row.
mytbl.column_labels = myheader;
mytbl.column_header_height = hht;
mytbl.column_format = myformat;
settablealignment(mytbl,'center',[]);%All columns center.
mytbl.row_header_width = 50;%
%%%% SHOULDN'T DO THIS, CAUSES TOO MANY PROBLEMS   %mytbl.row_header_text = myrowheader;%Add header text.
mytbl.replace_nan_with = '-';%Show "-" instead "NaN" 

ph = mytbl.parent_figure;
hh = guihandles(mytbl.parent_figure);
if addcmc
  mytbl.table_clicked_callback       = {'analysis','ssqtable_Callback',ph,[],hh};
  mytbl.row_clicked_callback         = {'analysis','ssqtable_Callback',ph,[],hh};
  mytbl.table_doubleclicked_callback = {'analysis','calcmodel_Callback',ph,[],hh};
  mytbl.row_doubleclicked_callback   = {'analysis','calcmodel_Callback',ph,[],hh};
else
  clear(mytbl,'callbacks');
end

drawnow

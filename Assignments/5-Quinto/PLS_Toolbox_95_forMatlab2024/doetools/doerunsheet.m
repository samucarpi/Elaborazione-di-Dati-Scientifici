function varargout = doerunsheet(doedso,responsevars)
%DOERUNSHEET Create a doe run sheet.
% Create DOE Run Sheet as HTML table and allow saving as html file.
%
% Input is (doedso) a DOE Dataset. The optional input (responsevars) is a
% cell-array of strings listing response variables to include as additional
% columns of the run sheet.
%
% The output (desgn) is an HTML representation of the run sheet. If no
% outputs are requested, the run sheet is displayed.
%
%I/O: doerunsheet(doedso,responsevars)   %display HTML table
%I/O: desgn = doerunsheet(doedso,responsevars)  %return HTML table
%
%See also: DOEGEN, DOEGUI

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


if isempty(doedso) | ~isfield(doedso.userdata,'DOE')
  return
end

if nargin<2
  responsevars = {};
end

if isempty(responsevars) & isfield(doedso.userdata.DOE,'options')
  %Get reponse variables from DOEDSO.
  responsevars = doedso.userdata.DOE.options.response_variables;
end

doedata = [];

%Loop throuch columns depending on data type (numeric vs categorical).
rsdata = {};
mydt = doedso.class{2,1};%Data type.
k = 1;%Category class index
for i = 1:size(doedso,2)
  switch mydt(i)
    case 2
      %Categorical.
      rsdata = [rsdata doedso.classid{1,k}'];
      k = k+1;
      use(i) = true;
    case 1
      %Numeric.
      rsdata = [rsdata num2cell(doedso.data(:,i))];
      use(i) = true;
      
    otherwise
      use(i) = false;
      
  end
end

%Column Header data.
rshead = str2cell(doedso.label{2,1}(use,:))';
%Sample names.
rshead = [{'Sample Name'} rshead];
rsdata = [str2cell(doedso.label{1,1}) rsdata];
%Design order.
rshead = [doedso.axisscalename(1,1) rshead];
rsdata = [num2cell(doedso.axisscale{1,1})' rsdata];
%Random order.
rshead = [doedso.axisscalename(1,2) rshead];
rsdata = [num2cell(doedso.axisscale{1,2})' rsdata];

%Response variables.
blkcol = repmat({''},size(doedso,1),1);
for i = 1:length(responsevars)
  rsdata = [rsdata blkcol];
  rshead = [rshead responsevars(i)];
end

%Don't want fatal error if java html renderer doesn't work so wrap in try
try
  t = cell2html(rsdata,rshead,struct('make_pretty','on'));
catch
  t = cell2html(rsdata,rshead);
end

if nargout>0
  varargout{1} = t;
else
  
  fig = figure(...
    'tag','runsheetgui',...
    'busyaction','cancel',...
    'integerhandle','off',...
    'handlevisibility','callback',...
    'Toolbar','none',...
    'Menubar','none',...
    'NumberTitle','off',...
    'Name', 'DOE Run Sheet');
  
  %Make java HTML redering area.
  je = evrijavaobjectedt('javax.swing.JEditorPane','text/html', t);
  jp = evrijavaobjectedt('javax.swing.JScrollPane',je);
  [hcomponent, hcontainer] = javacomponent(jp, [], fig);
  
  set(hcontainer, 'units', 'normalized', 'position', [0 .1 1 .89]);
  
  %Turn anti-aliasing on (R2006a, Java 5.0): Comment from Yair.
  java.lang.System.setProperty('awt.useSystemAAFontSettings', 'on');
  %Need larger font on most systems so use getdefaultfontsize('heading')
  je.setFont(java.awt.Font('Arial', java.awt.Font.PLAIN, getdefaultfontsize('heading')));
  je.putClientProperty(javax.swing.JEditorPane.HONOR_DISPLAY_PROPERTIES, true);
  
  okbtn = uicontrol(fig,'style','pushbutton','tag','savebutton','String','Save',...
    'units','normalized','position',[.71 .01 .14 .07],'Callback',@save_runsheet_callback);
  cnslbtn = uicontrol(fig,'style','pushbutton','tag','cancelbutton','String','Close',...
    'units','normalized','position',[.85 .01 .14 .07],'Callback','close(gcbf)');
  
  setappdata(fig,'runsheet',t)
  drawnow
end

%--------------------------------------------------------------------
function save_runsheet_callback(h,eventdata,handles,varargin)
%Save run sheet table to file.

fig = ancestor(h,'figure');
t = getappdata(fig,'runsheet');

%Save html file.
[filename, pathname, filterindex] = evriuiputfile(['DOE_RunSheet_' datestr(now,'mm_dd_yyyy') '.html'],'Save DOE as HTML file.');
if filename~=0
  [junk, junk, ext] = fileparts(filename);
  if isempty(ext)
    filename = fullfile(pathname,filename,'.html');
  else
    filename = fullfile(pathname,filename);
  end
  fid = fopen(filename,'w');
  fprintf(fid,'%s',t);
  fclose(fid);
end

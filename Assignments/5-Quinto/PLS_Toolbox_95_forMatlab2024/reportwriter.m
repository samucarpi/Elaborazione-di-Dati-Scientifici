function varargout = reportwriter(target, h, comments, options)
%REPORTWRITER Write a summary of the analysis including associated figures to html/word/powerpoint
% Report writer generates an analysis report in the requested target
% format. Typically, a report is generated based on a model and figures
% created within the Analysis window. However, instead of providing an
% Analysis window handle, the caller may instead provide a vector of figure
% handles, a model alone, or a cell array containing a model and figure
% handles. See input options below.
%
% INPUTS:
%  target    = The program to export figures to. can have the following values:
%              'html'       : HTML document
%              'powerpoint' : Microsoft PowerPoint
%              'word'       : Microsoft Word
%
%  Second input can be any of the following:
%  h         = Handle to existing analysis gui 
%  figs      = One or more handles of figures to include in a report
%               (without any model information)
%  model     = Model to report on (without figures)
%  modelcell = Cell array containing a model and handles of any figures to
%               include in the report. E.g.: {model fig1 fig2 fig3}
%
% OPTIONAL INPUTS:
%  comments = A comment string (user supplied comments). If empty, no
%              comment is included.
%   options = structure array with the following fields:
%    notificationdialog: [{'off'}| 'on' ]  Show a dialog at completion of report generation?
%       autocreateplots: [{'off'}| 'on' ]  Automatically create standard
%                         plots (if reporting on an Analysis figure)
%           autoopening: [ 'off' |{'on'}]  Open the report when it is generated?
%            autonaming: [ 'off' |{'on'}]  Determine how output files should be named. 
%                         If 'on', output files are given unique names.
%                         Otherwise, files are always given the same name
%                         so each new report overwrites the previous.
%                maxage: [10] Maximum age (in days) for old reports. Reports
%                        left in report folder longer than this will be
%                        automatically deleted. 
%                outdir: [{''}] Default folder to save reports to. If empty
%                        reports are saved to EVRIDIR folder in "analysisreports".
%            ignoretags: [{'gawindow'}] %Ignore figures with these tags.
%                        Default includes 'gawindow' because causes problems when
%                        variable selection is used (hidden GA window). To
%                        remove crossval gui add 'crossvalgui' to list.
%                        
%                        
%  OUTPUTS:
%  filename = name of the report file, including path.
%
%I/O: filename = reportwriter(target, h, comments, options);      %Report on the gui with handle h
%I/O: filename = reportwriter(target, figs, comments, options);   %Report including the figures listed 
%I/O: filename = reportwriter(target, model, comments, options);  %Report on the model supplied
%I/O: filename = reportwriter(target, modelcell, comments, options);  %Report on the model and figures supplied 
%
%See also: ANALYSIS, EXPORTFIGURE, MODLRDER

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


if nargin == 1 && ismember(target,evriio([],'validtopics')) %Help, Demo, Options
  options = [];
  options.name                = 'options';
  options.notificationdialog  = 'off';     %Show a dialog at completion of report generation?
  options.autocreateplots     = 'off';    %automatically create standard plots if reporting on an Analysis figure
  options.autoopening         = 'on';     %Open the report when it is generated?
  options.autonaming          = 'on';    %generate new name for each file?
  options.maxage              = 10;      %maximum age of old reports to keep (in days)
  options.outdir              = [];
  options.ignoretags          = {'gawindow'}; %Ignore figures with these tags.
  if nargout==0;
    evriio(mfilename,target,options);
  else
    varargout{1} = evriio(mfilename,target,options);
  end
  return;
end

if nargin<1       % have no target, no h, no comments
  target = 'html';
end

%test for valid target
target = lower(target);
if ~ismember(target,{'html' 'word' 'powerpoint'});
  error('Invalid target program');
end

% h is handle of analysis
if nargin<2      % have no handles
  h = [];
end
if nargin<3      % have no comments
  comments = [];
end
if nargin<4      % have no options
  options = [];
end

options = reconopts(options, mfilename);

model = [];
prediction = [];
fighandles = [];
addedfigs = [];
if isempty(h)
  %nothing passed? look for any analysis
  obj = evrigui('analysis', '-reuse');
  if isempty(obj)
    error('There is no available Analysis GUI to report on');
  end
  model      = obj.getModel;
  prediction = obj.getPrediction;
  addedfigs = generateplots(obj,options);
  fighandles = getplotsfromobject(obj,options);  % locate figures associated with this sharedobject
elseif length(h)==1 & ishandle(h) & strcmp(get(h,'tag'),'analysis')
  %scalar handle to analysis
  obj = evrigui(h);
  model      = obj.getModel;
  prediction = obj.getPrediction;  
  addedfigs = generateplots(obj,options);
  fighandles = getplotsfromobject(obj,options);  % locate figures associated with this sharedobject
elseif ismodel(h)
  %model passed (alone)
  model = h;
elseif iscell(h)
  %cell array of items
  for j=1:length(h);
    if ismodel(h{j})
      model = h{j};
    else
      fighandles(end+1) = h{j};
    end
  end  
elseif all(ishandle(h))
  %vector of handles, assume all are figures (with no model)
  fighandles = h;
else
  error('Input handle (h) is not recognized');
end

% Get the evri temp directory. Create it if it does not exist. Empty it if it does exist.
savedir    = getevritempdir(target, options);

% get model
modelDescription = getModelDescription(model);

% get SSQ Table
if ~isempty(model)
  ssqDescription = getModelSsqDescription(model);
end

% get validation
predDescription = getPredictionDescription(prediction);

% get user comments
userComments = getUserComments(comments);

%generate report name
basename = 'AnalysisReport';
if strcmp(options.autonaming,'on');
  basename = [basename '_'  datestr(now,30)];
end

waitbar(.5,'Generating Report');
try
  
  %delete files in savedir which are older than maxage
  files = dir(savedir);
  files(ismember({files.name},{'.' '..' '.svn'})) = []; %drop folders
  if ~isempty(files)
    if isfield(files,'datenum')
      age = now-[files.datenum];
    else  %for older Matlab where no datenum field exists (may not work in some localities)
      age = now-datenumplus({files.date});
    end
    todelete = files(age>options.maxage);
    for j=1:length(todelete)
      recursiveDelete(fullfile(savedir,todelete(j).name));
    end
  end
  
  %create description structure
  descStruct.modelDescription = modelDescription;
  if ~isempty(model)
    descStruct.ssqDescription = ssqDescription;
    descStruct.predDescription = predDescription;
  end
  if ~isempty(userComments)
    descStruct.userComments = userComments;
  end
  
  %create media folder for this report
  relative_mediafolder = basename;
  mediafolder = fullfile(savedir,relative_mediafolder);
  if ~exist(mediafolder,'dir')
    %if not there, create it
    mkdir(mediafolder);
  else
    %if already there, empty it
    recursiveDelete(mediafolder);
    mfobj = java.io.File(mediafolder);
    mfobj.mkdir;
  end
  
  %copy figures into the media folder
  createplots(mediafolder, fighandles);
  
  % Create the Analysis Report
  fileName = '';
  switch target
    case 'html'
      %add sub-folder for media and add some content there
      %get name and make sure it exists
      % copy the .css to the temp dir
      copyfile(which('reportwriter.css'), fullfile(mediafolder,'reportwriter.css'));
      
      fileName = fullfile(savedir, [basename '.html']);
      recursiveDelete(fileName);
      createReportHtml(descStruct, fighandles, fileName, relative_mediafolder);
      % open the created html report file
      if strcmp(options.autoopening, 'on')
        web(fileName, '-browser');
      end
      
    case 'word'
      fileName = fullfile(savedir, [basename '.doc']);
      recursiveDelete(fileName);
      createReportWord(descStruct, fighandles, fileName)
      if strcmp(options.autoopening, 'on')
        StartWord(fileName);
      end
      
    case 'powerpoint'
      fileName = fullfile(savedir, [basename '.ppt']);
      recursiveDelete(fileName);
      createReportPpt(descStruct, fighandles, fileName);
      if strcmp(options.autoopening, 'on')
        startPpt(fileName);
      end
      
  end
  if nargout>0
    varargout{1} = fileName;
  end
catch
  le = lasterror;
  delete(waitbar(1));
  delete(addedfigs(ishandle(addedfigs)));
  rethrow(le)
end
delete(waitbar(1));
delete(addedfigs(ishandle(addedfigs)));

%when done, notify user of the report file's location
if strcmp(options.notificationdialog, 'on')
  evrihelpdlg(sprintf('Report has been generated and saved to:\n  %s', fileName),'Report Created');
end

%---------------------------------------------------------------------------------------------------
function createReportPpt(descStruct, fighandles, filename)
%   fprintf('Document will be saved in %s\n',filename);

[actx_ppt, ppt_handle]=startPpt;

% write the model summary, ssq, and pred summary, and comments to file
writeTextToPpt(descStruct, ppt_handle, fighandles, actx_ppt);

if ~isempty(fighandles)
  exportfigure('powerpoint', fighandles);
end

ppt_handle.SaveAs(filename);
ppt_handle.Close;

%---------------------------------------------------------------------------------------------------
function createReportWord(descStruct, fighandles, filename)

[ActXWord,WordHandle]=StartWord(filename);

% write the model summary, ssq, and pred summary, and comments to file
writeTextToWord(descStruct, ActXWord, fighandles);

if ~isempty(fighandles)
  putFigureToWord(fighandles, ActXWord);
end

CloseWord(ActXWord,WordHandle,filename);

%---------------------------------------------------------------------------------------------------
function writeTextToPpt(descriptioncell, ppt_handle, fighandles, actx_ppt)
% Get current number of slides:
try
    slide_count = get(ppt_handle.Slides,'Count');
catch
    slide_count = get(actx_ppt.SlideShowWindows, 'Count');
end

% Insert text into the title object:
titletext = 'Analysis Report';
subtitle  = sprintf('Generated by %s on %s', userinfotag, datestr(now));

% write report text
textlinesperpage = 26;
pagelines = inf;  %triggers new page on first entry

if ~isempty(descriptioncell)
  for f = fieldnames(descriptioncell)';
    txt = descriptioncell.(f{:});
    
    if length(txt)+pagelines+2>textlinesperpage
      %too many lines, create a new page
      
      % Add a new slide (with title object):
      slide_count = slide_count+1;
      try
        new_slide = invoke(ppt_handle.Slides,'Add',slide_count,11);
      catch
        new_slide = invoke(actx_ppt.SlideShowWindows, 'Add', slide_count, 11);
      end
      new_slide.Shapes.Title.TextFrame.TextRange.Text=titletext;
      new_slide.Shapes.Title.TextFrame.TextRange.Font.Size=20;
      
      %add content textbox
      text_box  = invoke(new_slide.Shapes,'AddTextbox','msoTextOrientationHorizontal', 20, 100, 600, 20);
      textrange = text_box.TextFrame.TextRange;      
      textrange.ParagraphFormat.Alignment = 'ppAlignLeft'; %'ppAlignCenter';

      if slide_count==1
        %add subtitle
        t = textrange.InsertAfter([subtitle 13]);
        t.Font.Bold = 'msoTrue';
        t.Font.Size = 14;
        pagelines = 2;
      else
        t = textrange;
        pagelines = 0;
      end
    end
    
    if ~isempty(txt)
      %add first line
      t = t.InsertAfter([13 txt{1} 13]);
      t.Font.Bold = 'msoTrue';
      t.Font.Size = 16;
      
      %add subsequent lines
      t = t.InsertAfter(sprintf(['%s' 13],txt{2:end}));
      t.Font.Bold = 'msoFalse';
      t.Font.Size = 12;
    end
    pagelines = pagelines+length(txt)+2;
    
  end
  
  % write plot intro
  nplots = length(fighandles);
  switch nplots
    case 0
      text = '';
    case 1
      text = 'There is 1 figure associated with this analysis';
    otherwise
      text = sprintf('There are %i figures associated with this analysis',nplots);
  end
  if ~isempty(text)
    t = textrange.InsertAfter([13 text 13]);
    t.Font.Bold = 'msoTrue';
    t.Font.Size = 14;
  end
end


%---------------------------------------------------------------------------------------------------
function [actx_ppt, ppt_handle] = startPpt(ppt_file_p)
% Start an ActiveX session with Ppt:
actx_ppt = actxserver('PowerPoint.Application');
actx_ppt.Visible = true;

if nargin<1 | ~exist(ppt_file_p,'file');
  % Create new presentation:
  ppt_handle = invoke(actx_ppt.Presentations,'Add');
else
  % Open existing presentation:
  ppt_handle = invoke(actx_ppt.Presentations,'Open',ppt_file_p,[],[],1);
end


%---------------------------------------------------------------------------------------------------
function putFigureToWord(fighandles, ActXWord)
% based on function FigureIntoWord(actx_word_p)

for figind = 1:length(fighandles)
  %Copy name of figure to Word
  figname = get(fighandles(figind),'name');
    wasempty = false;
  if isempty(figname)
    figname = getShortFigName(fighandles(figind), figind);
    set(fighandles(figind),'name',figname);
    wasempty = true;
  end
  
  exportfigure('word', fighandles(figind), struct('activex',ActXWord));
  
  if wasempty
    set(fighandles(figind),'name','');
  end
  
  ActXWord.Selection.TypeParagraph; %enter
  
end

%---------------------------------------------------------------------------------------------------
function createReportHtml(desc, fighandles, filename, basename)
%CREATEREPORTHTML creates the html file which displays report with text and figures
% Create text file "filename"  containing "desc" text and "nplots" plots

nplots = length(fighandles);
fid = fopen(filename, 'w');
fprintf(fid, '<html>\n');
fprintf(fid, '<head>\n');

fprintf(fid, '<title>  Analysis Report   </title>\n');
fprintf(fid, '<link rel="stylesheet" href="%s" type="text/css">\n',fullfile(basename,'reportwriter.css'));
fprintf(fid, '</head>\n\n');

fprintf(fid, '<body>\n');

fprintf(fid, '<div class="report">\n');

fprintf(fid, '<h1 class="maintitle">Analysis Report</h1>\n');
fprintf(fid, '<h3 class="subtitle">Generated by %s on %s</h3>', userinfotag, datestr(now));
fprintf(fid, '\n');

fprintf(fid, '<div class="sectionbody">\n');
fprintf(fid, '<h2 class="sectiontitle">Analysis Details:</h2>\n');

fprintf(fid, '<p>\n');
% write the model summary, ssq, and pred summary, and comments to the html file
if isfield(desc, 'modelDescription') & ~isempty(desc.modelDescription)
  getDescriptionAsHtmlTable(desc.modelDescription, fid);
end
if isfield(desc, 'ssqDescription') & ~isempty(desc.ssqDescription)
  modelSsqAsTable(desc.ssqDescription, fid);
end
if isfield(desc, 'predDescription') & ~isempty(desc.predDescription)
  getDescriptionAsHtmlTable(desc.predDescription, fid);
end
if isfield(desc, 'userComments') & ~isempty(desc.userComments)
  getDescriptionAsHtmlTable(desc.userComments, fid);
end

% Separator before figures
fprintf(fid, '</div>\n');

if nplots>0
  fprintf(fid, '<span class="sectionbody">\n');
  fprintf(fid, '<h2 class="sectiontitle" id="figuresection">');
  fprintf(fid, 'Figures associated with the analysis:');
  fprintf(fid, '</h2>\n');
  
  for ip=1:nplots
    figname = get(fighandles(ip),'name');
    modifiedName = getShortFigName(fighandles(ip), ip);
    if isempty(figname)
      figname = modifiedName;
    end
    modifiedName = fullfile(basename,modifiedName);

    fprintf(fid, '<div class="pagebreak">&nbsp;</div>\n');
    fprintf(fid, '<table class="fig">\n');
    fprintf(fid, '<tr><th class="figcaption"><a href="%s.png">%s</a></th></tr>\n', modifiedName, figname);
    fprintf(fid, '<tr><td><a href="%s.png">', modifiedName);
    fprintf(fid, '<img title="Click to view image alone - %s" alt="Click to view image alone - %s" src="%s.png">', figname, figname, modifiedName);
    fprintf(fid, '<div class="otherformats">');
    fprintf(fid, '<img src="%s.eps"><a href="%s.eps">[View as .EPS]</a> ', modifiedName, modifiedName);
    fprintf(fid, '<img src="%s.fig"><a href="%s.fig">[View as .FIG]</a> ', modifiedName, modifiedName);
    fprintf(fid, '</div>');
    fprintf(fid, '</a></td></tr>\n</table>');
  end
  fprintf(fid, '</span>\n');  %end sectionbody
end

fprintf(fid, '</div>\n');  %end "report"

fprintf(fid, '</body>\n');
fprintf(fid, '</html>\n');
fclose(fid);

%---------------------------------------------------------------------------------------------------
function [actx_word,word_handle] = StartWord(word_file_p)
% Start an ActiveX session with Word:
actx_word = actxserver('Word.Application');
actx_word.Visible = true;
trace(actx_word.Visible);
if ~exist(word_file_p,'file');
  % Create new document:
  word_handle = invoke(actx_word.Documents,'Add');
else
  % Open existing document:
  word_handle = invoke(actx_word.Documents,'Open',word_file_p);
end


%---------------------------------------------------------------------------------------------------
function CloseWord(actx_word_p,word_handle_p,word_file_p)
if ~exist(word_file_p,'file')
  % Save file as new:
  invoke(word_handle_p,'SaveAs',word_file_p,1);
else
  % Save existing file:
  invoke(word_handle_p,'Save');
end
% Close the word window:
invoke(word_handle_p,'Close');
% Quit MS Word
invoke(actx_word_p,'Quit');
% Close Word and terminate ActiveX:
delete(actx_word_p);


%---------------------------------------------------------------------------------------------------
function description = getModelDescription(model)
%GETMODELDESCRIPTION returns a description of the model
%
modelline   = 'Model';

if ~isempty(model)
  description = [modelline; modlrder(model)'];
else
  description = [];
end

%---------------------------------------------------------------------------------------------------
function description = getModelSsqDescription(model)
%GETMODELSSQDESCRIPTION returns the SSQ table of the model as text
%
ssqline     = 'SSQ Table';

if ~isempty(model)
  if isfield(model, 'loads')
    description = [ssqline;ssqtable(model,size(model.loads{2,1},2))'];
  else
    description = [];
  end
else
  description = [];
end

%---------------------------------------------------------------------------------------------------
function description = getPredictionDescription(pred)
%GETPREDICTIONDESCRIPTION returns a description of the prediction
%
predline =  'Prediction';

if ~isempty(pred)
  description = [predline; modlrder(pred)'];
else
  description = [];
end

%---------------------------------------------------------------------------------------------------
function description = getUserComments(comments)
%GETUSERCOMMENTS returns the user comments with a header
%
description = [];
commentline =  'Comments';
if ~isempty(comments)
  % Convert comments to cell array, broken on newlines
  userComments = regexp(comments, '\\n', 'split');
  description = [commentline; userComments'];
end

%---------------------------------------------------------------------------------------------------
function  getDescriptionAsHtmlTable(desc, fid)
%GETDESCRIPTIONASHTMLTABLE converts the description to html representation

fprintf(fid, '<table class="model-table">\n');
fprintf(fid, '<tr><th>%s</th></tr>\n', desc{1});
fprintf(fid, '<tr><td>%s</td></tr>\n', desc{2:end});
fprintf(fid, '</table>');

%---------------------------------------------------------------------------------------------------
function modelSsqAsTable(desc, fid)
%MODELSSQASTABLE converts the SSQ table to html representation

fprintf(fid, '<table class="ssq-table"> \n');
fprintf(fid, '<tr><th>%s</th></tr>\n', desc{1});
fprintf(fid, '<tr><td><pre>');
fprintf(fid, '\n%s', desc{2:end});
fprintf(fid, '</pre></td></tr>\n');
fprintf(fid, '</table>');

%---------------------------------------------------------------------------------------------------
function added = generateplots(obj,options)

added = [];
if strcmpi(options.autocreateplots,'yes')
  existing = findobj(allchild(0),'type','figure');
  skip = {'plotxhat' 'plothalfnorm' 'doeeffects' 'splithalf' 'openimagegui' 'plotloadsurf'};
  
  btns = obj.getButtons;
  for j=max([1 strmatch('calcmodel',btns)+1]):length(btns);
    if ~ismember(btns{j},skip)
      obj.pressButton(btns{j});
      drawnow;
    end
  end
  
  pause(0.5);

  added = setdiff(findobj(allchild(0),'type','figure'),existing);
  
end

%---------------------------------------------------------------------------------------------------
function goodfighandles = getplotsfromobject(obj,options)
%GETPLOTS gets all plots associeated with current analysis gui
%
% loop over the objs,
% for each obj, loop over links looking for plotgui type

h = obj.handle;
sdo = getshareddata(h);
fighandles = [];
for i=1:size(sdo,1)
  xsdo = sdo{i};
  fighandles = getfigurehandles(xsdo, fighandles);
  sibs = [];
  if ~isempty(xsdo)
    sibs = xsdo.siblings;
  end
  for i=1:length(sibs)
    sib = sibs{i};
    if isshareddata(sib)
      fighandles = getfigurehandles(sib, fighandles);
    end
  end
end

% Get other related plots
handles = guihandles(h);  % use the analysis handle
children1 = double(getappdata(handles.analysis,'staticchildplot'));
children2 = double(getappdata(handles.analysis,'modelspecific'));
children3 = double(getappdata(handles.analysis,'methodspecific'));
fighandles = [double(fighandles) children1 children2 children3];
fighandles = unique(fighandles);

% check if any figures have been deleted.
goodfighandles = fighandles(ishandle(fighandles));

% Remove figures that aren't wanted.
glist = get(goodfighandles,'tag');
if ~isempty(glist)
  rmfigpos = ismember(glist,options.ignoretags);
  goodfighandles(rmfigpos) = [];
end

%---------------------------------------------------------------------------------------------------
function fighandles = getfigurehandles(sib, fighandles)
%GETFIGUREHANDLES gets array of figure handles for all figures associated with siblings

if(isempty(sib))
  links = [];
  %   disp(sprintf('SDO is empty'));
else
  links = sib.links;
  %   disp(sprintf('SDO has itemType %s', sib.properties.itemType));
end

for j=1:length(links)
  link = links(j);
  if strcmp(link.callback, 'plotgui')
    
    fighandles(end+1) = link.handle;
  end
end

%---------------------------------------------------------------------------------------------------
function createplots(savedir, fighandles)
%CREATEPLOTS saves each plot in the temp directory, as png, epsc and fig formats
nfigs = length(fighandles);
for j=1:nfigs
  fig = figure(fighandles(j)); 		% bring figure to front
  drawnow;
  
  modifiedName = getShortFigName(fig, j);
  
  clr = get(fig,'color');
  set(fig,'color',[1 1 1])
  
  filenamebase = fullfile(savedir,modifiedName);
  print(fig, '-dpng', filenamebase, '-r0');
  print(fig, '-depsc', filenamebase);
  hgsave(fig, filenamebase);
  
  set(fig,'color',clr);  %restore original color
end

%---------------------------------------------------------------------------------------------------
function modifiedName = getShortFigName(fig, counter)
%GETSHORTFIGNAME converts fig name to a sub-string suitable for a recognizable file name
% It converts non-alpha, non-numeric chars to underscores, then uses the leading 16 characters
%
fileNameMaxLength = 40; % Max length of created files' names, in characters

figureName = get(fig, 'Name');

% If fig has no name, then look for a plot axis title
if isempty(figureName)
  axis_h = findobj(fig,'type','axes'); % get handle on child axes
  for i=1:length(axis_h)
    figureName = get(get(axis_h(i),'title'),'String');
    if ~isempty(figureName)
      break
    end
  end
  if iscell(figureName)
    %Multi-line axes titles come back as cell arrays. Convert figure name to
    %single line string.
    figureName = sprintf('%s ',figureName{:});
  end
end

if isempty(figureName)
  figureName = 'Untitled_Fig';
end

%add figure # to end (always!)
figureName = ['fig_'  num2str(counter) '_' figureName];

% give figures meaningful names if possible
pat = '(\W*)';                                        % replace non-alpha, non-numeric chars
tempname = regexprep(figureName, pat, '_');

newlen = min(fileNameMaxLength, length(tempname));
modifiedName = tempname(1:newlen);

%---------------------------------------------------------------------------------------------------
function newdirname = getevritempdir(target, options)
%CREATE evri analysis reports directory for target format, or delete its contents if it exists
% The evri/<target> directories will be created in the EVRI home directory used to store PLS_Toolbox
% application data. This directory should be read/writeable by the current user.
% The default location is [user home directory]/EVRI.

try
  import java.io.*;
  import java.lang.*;
  
  if isfield(options, 'outdir') & isdir(options.outdir)
    tempDir = options.outdir;
  else
    tempDir = evridir; %Get current home directory.
  end
  newdirname = fullfile(tempDir,'analysisreports',target);
  
  evridirectory = java.io.File(newdirname);
  evridirectoryExists = evridirectory.exists;
  if ~evridirectoryExists
    %Create evri temp dir
    evridirectory.mkdirs;
  end
  
catch
  e1 =lasterror;
  errordlg(sprintf('%s.getevritempdir: \n%s \n%s \n', mfilename, e1.message, e1.identifier));
end

%---------------------------------------------------------------------------------------------------
function writeTextToWord(descStruct, ActXWord, fighandles)
%WRITETEXTTOWORD writes to word using activex

%create header in word
TextString = 'Analysis Report';
WordText(ActXWord,TextString,'Heading 1',[0,1]);
subtitle = sprintf('Generated by %s on %s', userinfotag, datestr(now));
WordText(ActXWord,subtitle,'Heading 3',[0,2]);

if ~isempty(descStruct)
  for f = fieldnames(descStruct)';
    intext = descStruct.(f{:});
    if ~isempty(intext) & iscell(intext)
      WordText(ActXWord, intext{1}, 'Heading 2', [0,1]);
      for i=2:length(intext)
        WordText(ActXWord, [intext{i} 10], 'Normal', [0,0]);
      end
    end
  end
  % write plot intro
  nplots = length(fighandles);
  Style = 'Heading 2';
  if nplots>0
    text1 = 'Figures associated with the analysis:';
    ActXWord.Selection.InsertBreak; %pagebreak
    WordText(ActXWord, text1, Style,[1,2]);
  end
  
end


%---------------------------------------------------------------------------------------------------
function WordText(actx_word_p,text_p,style_p,enters_p,color_p)
%WORDTEXT writes text to word document using activex

if(enters_p(1))
  actx_word_p.Selection.TypeParagraph; %enter
end
try
  actx_word_p.Selection.Style = style_p;
catch
end
if(nargin == 5)%check to see if color_p is defined
  actx_word_p.Selection.Font.Color=color_p;
end

% actx_word_p.Selection.ParagraphFormat.LineSpacing=8;
actx_word_p.Selection.ParagraphFormat.SpaceAfter = 0;
actx_word_p.Selection.TypeText(text_p);
for k=1:enters_p(2)
  actx_word_p.Selection.TypeParagraph; %enter
end

%------------------------------------------------------------------
function recursiveDelete(files,basefolder);
%delete recursively

if nargin<2
  basefolder = '';
end
if ~iscell(files)
  files = {files};
end

for j=1:length(files)
  file = fullfile(basefolder,files{j});
  if isdir(file)
    subfiles = dir(file);
    subfiles = {subfiles.name};
    subfiles(ismember(subfiles,{'.' '..' '.svn'})) = [];
    recursiveDelete(subfiles,file);
  end

  try
    fileobj = java.io.File(file);
    fileobj.delete;
  catch
    %do nothing...
  end
end

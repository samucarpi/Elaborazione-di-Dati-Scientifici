function varargout = evritip(tip_id,tipcontent,autosquelch)
%EVRITIP Show a tip for a specified feature.
% Show a user tip. A pre-defined user tip can be triggered by providing the
% tip_id alone as (tip_id). Otherwise, a unique tip_id, the text of the tip
% (tipcontent) and the "autosquelch" flag indicating:
%     0: This tip should be given every time it occurs during a session
%        (unless the user checks a box turning it off for good)
%     1: This tip should be given ONCE during a Matlab session (unless the
%        user checks a box turning it off for good)
%     2: This tip should be given ONCE ever
% A list of all predefined tip IDs and tip content can be obtained by
% calling with no inputs and one output.
%
% The record of which tips have been given and what the last time a tip was
% given are all stored in plspref for this function.
%
%I/O: evritip(tip_id)
%I/O: evritip(tip_id,tipcontent,autosquelch)

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

persistent tips

if isempty(tips)
  tips = gettips;
end

%no inputs? return tips
if nargin<1;
  varargout = {tips};
  return;
end

if nargin == 1 & ischar(tip_id) & ismember(tip_id,evriio([],'validtopics'))
  options         = [];
  options.delay      = 5; %delay in seconds between tips
  options.tips       = 1;
  options.lasttip    = 0;
  if nargout==0; evriio(mfilename,tip_id,options); else; varargout{1} = evriio(mfilename,tip_id,options); end
  return;
end

if nargin == 1 & strcmp(tip_id,'reset')
  setplspref(mfilename,'factory');
  if isappdata(0,'evritip_settings');
    rmappdata(0,'evritip_settings');
  end
end

%get settings and make sure we've got a valid structure to work with
options = reconopts([],mfilename,0);

%If they don't want these, exit now
if ~options.tips
  return
end

tip_id = safename(tip_id);
if nargin == 3;
  tips = {tip_id,tipcontent,autosquelch};
else
  %find out if this is a valid tip_id
  ind = find(ismember(tips(:,1),tip_id));
  if length(ind)==1
    %this is a a specific tip request
    tipcontent = tips{ind,2};
    autosquelch = tips{ind,3};
  else
    %found no tips matching the requested ID, just exit
    return
  end
end

%see if we're in automation mode
if inevriautomation
  %skip all tips
  return
end


%find out if we've shown this particular tip
if shown(tip_id,options)
  %already shown this tip? skip it
  return
end

%check last time we gave a tip - don't give another for some period of time
if (now-options.lasttip)<options.delay/60/60/24
  return
end
%record when we gave the last tip
setplspref('evritip','lasttip',now);

%record that we're showing this particular tip
switch autosquelch
  case 1
    %show only once per session ("soft" hide)
    settings = getappdata(0,'evritip_settings');
    settings = setfield(settings,tip_id,1);
    setappdata(0,'evritip_settings',settings);
  case 2
    %show only ONCE EVER
    setplspref('evritip',tip_id,1);
end

%add once-a-session notice 
if autosquelch==1;
  tipcontent = [tipcontent ' (This tip will be shown only once per session)'];
end

%create help figure
h = helpdlg(sprintf(tipcontent),'EVRI Tip');

%make some modifications...
set(findobj(h,'type','text'),'backgroundcolor',[1 1 1]);
if autosquelch~=2;
  %If we might show this note more than once (in a session or even multiple
  %sessions) allow the user to tell us to stop showing it
  uicontrol(h,'style','checkbox','string','Never show again.','position',[20 10 150 20],'callback',['setplspref(''evritip'',''' tip_id ''',get(gcbo,''value''))']);
else
  uicontrol(h,'style','text','string','(One-time notice)','position',[20 10 150 20]);
end
%move button to right side of figure
fpos = get(h,'position');
bh   = findobj(h,'style','pushbutton');
bpos = get(bh,'pos');
if bpos(1)<90;
  set(bh,'pos',[fpos(3)-bpos(3)-5 bpos(2:end)])
end

set(h,'windowstyle','modal');
drawnow;

%wait for close
uiwait(h);

%record when they last said "OK" to a tip (just in case it was a long time
%from when we popped it up) - NOTE: this keeps them from having to play
%"wack-a-mole" with our tip windows
setplspref('evritip','lasttip',now);

%-----------------------------------------------
function out = shown(tip_id,options)

%add session "don't show" flags to options passed
options = reconopts(getappdata(0,'evritip_settings'),options,0);

if isfield(options,tip_id);
  out = getfield(options,tip_id);
else
  out = 0;
end

%--------------------------------------------------
function out = gettips

%here are the actual tips, the cell array contains three columns:
%  column 1 = topic_code (to group various tips on a topic and cycle
%              through them using a single topic code)
%  column 2 = tip_id (a UNIQUE identifier for the tip - this MUST be
%              unique or the conflicting message may never be given)
%  column 3 = text of tip. Single cell - short and concise as possible.
%
%  The tip can be retrieved by using:  evritip tip_id
%   or  evritip topic_code

out = {

  'anslysis_mcr','MCR Constraints:  You can modify the MCR constraints and many other options using the Edit/Options menu item in the Analysis window.',2

  'automodelclear','Analysis Tip:  The action you just performed caused the model to be cleared. You must now recalculate the model by using the calculate button in the main Analysis window.',1

  'analysis_mpca','MPCA Analysis Tip:  To perform MPCA, the data is expected to be arranged such that rows are time points, columns are variables (measured at each time point), and "slabs" (the third dimension) are batches. Note that batches must already be equal in length. See the DataSet Editor (Edit/X-block data) or the browse interface (click on the Eigenvector logo on the toolbar) to arrange data into the correct size and order.',2

  'plotgui_exclude','Excluded Data:  To re-include excluded data, turn on "View/Excluded Data" (menu on the plot controls), select the excluded points, and then use "Edit/Include Selection". \n\nYou can also select Edit/Include All to re-include ALL excluded data at once.',1
  'plotgui_declutter','Decluttered Labels:  Labels and/or numbers have been decluttered on this figure as indicated by the "Decluttered" notice on the bottom left of the figure. Right-click this label to change declutter settings (e.g. to turn off decluttering altogether). \n\nYou can also change the declutter settings, including the default mode, through the View/Declutter menu on the Plot Controls.',1
  'plotgui_maxclassview','Maximum Classes Displayed: Too many unique classes to view as symbols. Modify the plotgui setting "maxclassview" to change.',1
  'mcrbadnonneg','Non-Negativity/Constraints Conflict: \n You can change the MCR constraints (e.g. disable non-negativity) using Edit/Options menu or the preprocessing settings using Preprocess/X-block menu.',1
  'plotgui_maxlabelmoveobj','Maximum Labels Displayed: Too many moveable labels can result in poor performance. Modity the plotgui setting "viewlabelmoveobjectthreshold" to change.',1
  'browseaugmentdata','Browse Tip: You can augment (combine) two data matrices in your workspace by dragging one on top of another. Depending on data sizes, you may be asked if the data should be augmented as new rows, columns, or even slabs (to make three-way data sets).',2
  'browserightclickdata','Browse Tip: A number of analysis functions can be performed by right-clicking a item in the Browse window.',2
  'browsedroponwindow','Browse Tip: You can drag a data item into another window from the Browse interface. If dragged into an analysis window, this will load the data; a plot window will plot the data; and a DataSet editor window will load the data for editing.',2
  'browsedroponshortcut','Browse Tip: In most cases, you can drag a data item onto an analysis method "shortcut" (white-backed items in the Browse window) to start up that method with the given data.',2
  'browsemovies','Browse Videos Unavailable: A list of current videos could not be obtained from Eigenvector website. Go to www.eigenvector.com to view videos.',2 
  
  'analysisstatusrightclick','Analysis Tip: You can load, import, save, and clear data or the current model by right-clicking on the Data or Model status boxes at the top of the Analysis window.',2
  'analysisstatuscolor','Analysis Tip: The color of the Data and Model status boxes indicates if the given model has been applied or built from the loaded data. If the color of the two boxes matches, then the model has already been applied to the data. If not, you need to click "Calculate" (when available for the selected Analysis method)',2
  'analysishelpbox','Analysis Tip: The help window at the bottom of the analysis interface will help guide you through the basic steps of an analysis. You can hide this window through the "help" menu.',2
  'analysisbrowselink','Analysis Tip: The Eigenvector logo button (lambda on the matrix) on the toolbar will take you to the workspace browser where you can manage data in your workspace and perform other analysis tasks.',2
  'analysisfigbrowserfind','Figure Browser Tip: If you ever find yourself wondering where a particular figure is, you can always use the "FigBrowser" menu in any window to get a list of the current figures or a thumbnail view of all figures.',2
  'browsefigbrowserfind','Figure Browser Tip: If you ever find yourself wondering where a particular figure is, you can always use the "FigBrowser" menu in any window to get a list of the current figures or a thumbnail view of all figures.',2
  'analysisclassification','Analysis Tip: The classification methods SIMCA and PLSDA can be used if you have set classes for the samples in your data. Set classes using the DataSet Editor (Edit/X-block Data)',2
  
  'closecache','Cache Viewer Tip: Once the Cache Viewer is closed you can reopen it using the Tools/View Cache menu.',1
  'cacheconnectionwarning',getcachewarn,1
  'tablecellrendererjava','Java Setup Tip: The table cell formatting component for the etable can''t be enabled. This indicates the java files have not been correctly added to your Matlab class path. Try manually adding the .jar files (file paths) located in PLS_Toolbox/extensions/javatools to your java class path file (>>edit classpath.txt).',1
  };

function out = getcachewarn
%Get cache connection warning text. Too long to do inline.

problem        =  {};
problem(end+1) =  {'* Warning: '};
problem(end+1) =  {'Cannot connect to Model Cache database.'};
problem(end+1) =  {''};
problem(end+1) =  {'Possible Solutions: '};
problem(end+1) =  {''};
problem(end+1) =  {'A) Reset the modelcache from Workspace Browser window View/Reset Model Cache or, use the command:  modelcache(''reset'') or, Restart Matlab'};
problem(end+1) =  {''};
problem(end+1) =  {'B) Turn off the modelcache from Workspace Browser window [Edit/Options/Model Cache Settings] or, use the command: setplspref(''modelcache'',''cache'',''off'')'};
problem(end+1) =  {''};
problem(end+1) =  {'C) Multiple instances of Matlab/Solo running. Only one instance of Matlab/Solo can access the Model Cache at one time. The Model Cache will be automatically turned off until connection can be re-established.'};
problem(end+1) =  {''};

out = sprintf('%s\n',problem{:});



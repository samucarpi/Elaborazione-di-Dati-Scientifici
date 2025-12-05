function varargout = exportfigure(target,sourcefigs,options)
%EXPORTFIGURE Automatically export figures to an external program.
%  Exports one or more open figures into a new blank document in an
%  external program. No inputs are required.
%
%  OPTIONAL INPUTS:
%   target     = The target program to export figures to. (target)
%                can have the following values:
%                 'powerpoint' : Microsoft PowerPoint {default}
%                 'word'       : Microsoft Word
%                 'png'        : Save as PNG in current directory
%                 'eps'        : Save as EPS in current directory
%                 'clipboard'  : System Clipboard based on platform.
%                 'clipboardbitmap'  : System Clipboard in bitmap format (legacy syntax).
%                 'clipboard_default' : Use default for given system.
%                 'clipboard_meta' : Use Windows meta.
%                 'clipboard_macscreencapture' : Mac OS screencapture utility.
%                 'clipboard_macold' : Builtin screen capture on older Mac/Matlab version. 
%                 'clipboard_bitmap' : Bitmap image. 
%                 'clipboard_getframe' : Use getframe function to capture movie frame to clipboard. 
%                 'clipboard_pdf' : PDF format to clipboard.
%                NOTE: Once a target has been used, that target will remain the
%                      default for later calls made without a target specified.
%   sourcefigs = A vector of figure numbers to export {default
%                is the current open figure (see GCF)}.
%                sourcefigs == 'all', exports all open figures.
%   options    = A structure containing one or more of the following
%                fields:
%      ppresizefontfactor : {[1.5]} The factor by which fonts should be
%                       resized prior to copying figure into PowerPoint.
%                       Default up-sizes all fonts by 50% (=1.5). A value
%                       of 1.0 will leave the font size alone.
%      wordresizsefontfactor : Same as above but for Microsoft Word.
%      resizemode     : [ 'none' | {'aspect'} | 'exact' ] Governs the
%                       figure resizing mode.
%                       'none' = no figure resizing is done
%                       'aspect' = figure is resized maintaining the
%                          aspect ratio (the figure is resized so that its
%                          larger dimension matches the corresponding
%                          target dimension).
%                       'exact' = figure is resized to exactly match the
%                          target size dimensions. The aspect ratio will
%                          change.
%      pptargetsize   : [885 591] [X Y] Specified size for the figure
%                       when copying. A value of [] will leave the
%                       figure size alone (same as setting 'none' for the
%                       resizemode option, but can be done specifically for
%                       powerpoint only)
%      wordtargetsize : Same as above but for Microsoft Word.
%  forcemacscreenshot : When using 'clipboard', force use of screencapture
%                       ('clipboard_macscreencapture') (shell command)
%                       rather than use Matlab command on Mac systems (legacy behavior).
%
% Notes: target = 'powerpoint' will export to current open document.
%                 If no document is open it will create a new document.
%        EXPORTFIGURE can be used to export multiple figures at a time.
%                 In contrast, "clipboard" export can only operate on one
%                 figure at a time.
%        Defaults for the options fields can be set using setplspref or the
%                 preferences expert interface (see prefexpert).
%
%I/O: exportfigure(target,sourcefigs,options)
%
%See also: REPORTWRITER

% Copyright © Eigenvector Research, Inc. 2005
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%JMS 8/05  - word export based on code submitted by Christopher Seaman at Alcoa
%  8/25/05 - PowerPoint added
% 9/12/05 -fixed no-inputs default (export current figure)
% 9/14/05 -copy ONLY integer handle figures
% 10/27/05 -export to clipboard option
% 10/28/05 -updated help
%    - added ability to append to existing documents (word requires that it
%       is a document we've already created or connected to)
%    - begun adding support for filename-specific export (not yet
%       implemented)
%RSK 04/04/06 -fix for missing Word obj.

persistent lasttarget wordapp

if nargin==1 & ischar(target) & ismember(target,evriio('','validtopics'))
  options = [];
  options.ppresizefontfactor = 1.5;
  options.wordresizefontfactor = 1.5;
  options.resizemode     = 'aspect';
  options.pptargetsize   = [885   591];
  options.wordtargetsize = [885   591];
  options.forcemacscreenshot = 0;
  options.activex  = [];
  
  if nargout==0; evriio(mfilename,target,options); else; varargout{1} = evriio(mfilename,target,options); end
  return;
end

filename = '';
if nargin<1
  % ()
  target = [];
end
if nargin<2;
  if ~isstr(target) | strcmp(target,'all')
    % ('all')  or  (fig_num)
    sourcefigs = target;
    target = [];
  else
    % ('word') (or other valid target)
    sourcefigs = [];
  end
end
if nargin<3;
  options = [];
end
options = reconopts(options,mfilename);

if strcmp(sourcefigs,'all');
  % ('zzz','all')
  sourcefigs = sort(findobj('type','figure','integerhandle','on'));
end
if isempty(sourcefigs);
  sourcefigs = get(0,'currentfigure');
end
if isempty(target);
  if isempty(lasttarget)
    target = 'powerpoint';
  else
    target = lasttarget;
  end
end
lasttarget = target;  %store as automatic default for next call

% Remove temporary informational messages from figures
for j=1:length(sourcefigs);
  delete(findobj(allchild(sourcefigs(j)),'userdata','tempnoticeaxes'));
end

%clear invalid figure handles
sourcefigs(~ishandle(sourcefigs)) = [];
if isempty(sourcefigs)
  warning('EVRI:ExportFigureNoFig','Figure(s) could not be located for export')
  return  %and exit if none exist
end

if length(target)>8 & strcmpi(target(1:9),'clipboard')
  if length(sourcefigs)>1
    error('Cannot export more than one figure to clipboard');
  end
end

try
  switch lower(target)
    %=======================================================
    case 'word'
      
      objexist = 1;
      if ~isempty(options.activex)
        wordapp = options.activex;
        %??Nominally add testing for this?
      else
        try
          %ML function exist() doesn't work on COM objects.
          %Try accessing and use error to imply object doesn't exist.
          junk = get(wordapp,'Activate');
        catch
          objexist = 0;
        end
      end
      
      if isempty(wordapp) | ~objexist
        wordapp = actxserver('word.application');
      end
      app = wordapp;
      
      if app.Windows.Count>0
        %Attach to current document
        fig_doc = app.ActiveDocument;
      else
        %Open a document
        app.Documents.Add;
        fig_doc = app.Documents.Item(wordapp.Documents.Count);
      end
      
      for figind = 1:length(sourcefigs)
        % Find end of document and make it the insertion point:
        end_of_doc = get(app.activedocument.content,'end');
        set(app.application.selection,'Start',end_of_doc);
        set(app.application.selection,'End',end_of_doc);
        
        %Copy name of figure to Word
        figname = get(sourcefigs(figind),'name');
        app.Selection.TypeParagraph;
        if ~isempty(figname)
          app.Selection.Style = 'Heading 2';
          app.Selection.ParagraphFormat.SpaceAfter = 1;
          app.Selection.TypeText(figname);
          app.Selection.TypeParagraph;
        end
        if strcmpi(getappdata(sourcefigs(figind),'figuretype'),'infobox')
          listobj = findobj(allchild(sourcefigs(figind)),'tag','listbox');
          st = get(listobj,'string');
          st(cellfun(@(s) ~isempty(strfind(s,'See Help menu')),st)) = [];  %drop "help link" comment line
          app.Selection.Style = 'Normal';
          fn = get(listobj,'fontname');
          if strcmpi(fn,'courier'); fn = 'Courier New'; end
          app.Selection.Style.Font.Name = fn;
          app.Selection.Style.Font.Size = get(listobj,'fontsize');
          app.Selection.ParagraphFormat.SpaceAfter = 0;
          app.Selection.TypeText(sprintf('%s\n',st{:}));
          flashlistobj(listobj);
        else
          %Copy the figure to the clipboard then paste into Word.
          printcheck(sourcefigs(figind),options)
          fig_doc.Paragraphs.Add.Next.Range.Paste;
        end
        
      end
      
      set(app, 'visible', 1);
      
      %=======================================================
    case 'powerpoint'
      
      app = actxserver('powerpoint.application');
      %this will connect to an existing powerpoint copy (if already running)
      %so no need to use persistant in this case.
      
      verNum = str2num(app.Version);
      %     2003 Office PowerPoint 2003 (version 11; Office 2003)
      %     2007 Office PowerPoint 2007 (version 12; Office 2007)
      %     2010 PowerPoint 2010 (version 14; Office 2010)
      %     2013 PowerPoint 2013 (version 15; Office 2013)
      
      
      if app.Windows.Count>0
        fig_doc = [];
        
        if ~isempty(filename)
          for j=1:app.Windows.Count;
            %look for file in current list of open files
            if strcmp(app.Windows.Item(j).Presentation.FullName,filename);
              fig_doc = app.Windows.Item(j).Parent;
            end
            if isempty(fig_doc);  %not currently open, try opening it
              fig_doc = app.Presentations.Open(filename);
            end
          end
        end
        
        if isempty(fig_doc);
          %Attach to current document
          fig_doc = app.ActivePresentation;
        end
        
      else
        %Open a document
        fig_doc = app.Presentations.Add;
      end
      
      if ~isempty(verNum) & verNum>11
        %Version 2007 and later? Determine correct custom layout to use
        layout = [];
        for lindex = 1:fig_doc.SlideMaster.CustomLayouts.Count
          if strcmpi(fig_doc.SlideMaster.CustomLayouts.Item(lindex).Name,'Blank')
            layout = lindex;
            break
          end
        end
        if isempty(layout)
          layout = fig_doc.SlideMaster.CustomLayouts.Count;
        end
        %get slide master corresponding to this layout
        layout = fig_doc.SlideMaster.CustomLayouts.Item(layout);
      end
      
      for figind = 1:length(sourcefigs)
        
        newslide = fig_doc.Slides.Count+1;
        
        %Add Figure
        if ismember('AddSlide',methods(fig_doc.slides))
          %Powerpoint 2007
          slide = fig_doc.Slides.AddSlide(newslide,layout);
        else
          %Older versions
          slide = fig_doc.slides.Add(newslide,'ppLayoutBlank');
        end
        
        %Copy the figure itself
        if strcmpi(getappdata(sourcefigs(figind),'figuretype'),'infobox')
          %Information box? copy CONTENTS as text
          listobj = findobj(allchild(sourcefigs(figind)),'tag','listbox');
          st = get(listobj,'string');
          st(cellfun(@(s) ~isempty(strfind(s,'See Help menu')),st)) = [];  %drop "help link" comment line
          text_box  = invoke(slide.Shapes,'AddTextbox','msoTextOrientationHorizontal', 20, 30, 600, 20);
          textrange = text_box.TextFrame.TextRange;
          textrange.ParagraphFormat.Alignment = 'ppAlignLeft'; %'ppAlignCenter';
          textrange = textrange.InsertAfter(sprintf(['%s' 13],st{:}));
          textrange.Font.Bold = 'msoFalse';
          fn = get(listobj,'fontname');
          if strcmpi(fn,'courier'); fn = 'Courier New'; end
          textrange.Font.Name = fn;
          textrange.Font.Size = get(listobj,'fontsize');
          flashlistobj(listobj)
        else
          %other figures - copy image using print
          printcheck(sourcefigs(figind),options)
          
          targ = slide.Shapes.Paste;  % Returns a ShapeRange object
          if ~isempty(verNum) & verNum<15   % Earlier than 2013
            targ.Align(1,1)
            targ.Align(4,1)
          end
        end
        
        if ~isempty(verNum) & verNum>12   % Version 2010 and later
          %Copy name of figure
          figname = get(sourcefigs(figind),'name');
          if ~isempty(figname);
%             clipboard('copy',figname);
%             targ = slide.Shapes.PasteSpecial(7);
%             targ.Align(3,1);
          text_box  = invoke(slide.Shapes,'AddTextbox','msoTextOrientationHorizontal', 20, 30, 600, 20);
          textrange = text_box.TextFrame.TextRange;
          textrange.ParagraphFormat.Alignment = 'ppAlignLeft';
          textrange = textrange.InsertAfter(figname);
          textrange.Font.Bold = 'msoTrue';
          end
        end
        
      end
      
      set(app, 'visible', 1);  %make visible
      
      %Delete the handles created for application.
      delete(app);
      
      %=======================================================
      
    case 'clipboard_infobox'
      if strcmpi(getappdata(sourcefigs,'figuretype'),'infobox')
        %any platform, infobox copy NOT as bitmap... copy CONTENTS as text
        listobj = findobj(allchild(sourcefigs),'tag','listbox');
        st = get(listobj,'string');
        st(cellfun(@(s) ~isempty(strfind(s,'See Help menu')),st)) = [];  %drop "help link" comment line
        clipboard('copy',sprintf('%s\n',st{:}));
      else
        warning('EVRI:ExportFigureNotInfobox','Figure type is not "infobox" and cannot be copied.')
      end
      
    case {'clipboard' 'clipboard_default'}
      
      if strcmpi(getappdata(sourcefigs,'figuretype'),'infobox')
        %Preserve old default behavior.
        exportfigure('clipboard_infobox',sourcefigs,options)
        return
      end
      
      if ~ispc
        mytarget = 'clipboard_bitmap';
        if ismac
          if options.forcemacscreenshot
            mytarget = 'clipboard_macscreencapture';
          elseif checkmlversion('>=','8.2')
            mytarget = 'clipboard_bitmap';
          else
            mytarget = 'clipboard_macold';
          end
        end
      else
        mytarget = 'clipboard_meta';
      end
      exportfigure(mytarget,sourcefigs,options)
      
    case 'clipboardbitmap'
      %This is old syntax.
      if ispc
        mytarget = 'clipboard_meta';
      else
        mytarget = 'clipboard_default';
      end
      exportfigure(mytarget,sourcefigs,options)
      
    case 'clipboard_meta'
      %Copy the figure itself
      printcheck(sourcefigs,[])
      
    case 'clipboard_macscreencapture'
      %Matlab copy may not work with alpha on newer macs. Can't use copy to
      %clipboard trick below because Java 7 is broken as of Jan 2014.
      %So take screen shot with shell command.
      
      ssize = get(0,'ScreenSize');
      mypos = get(sourcefigs(1),'position');
      newY = ssize(4) - mypos(2) - mypos(4);%Put y as upper left conrner.
      mypos(2) = newY;
      %Nudge sizing to get rid of 1px over size into border.
      mypos(1) = mypos(1)+1;
      mypos(3) = mypos(3)-2;
      mypos(4) = mypos(4)-1;
      mycmd = sprintf('screencapture -c -R%d,%d,%d,%d',mypos);
      figure(sourcefigs(1));
      drawnow;
      status = system(mycmd);
      
    case 'clipboard_macold'
      %This code does not work for images with alpha and possibly
      %other cases where renderer fails. Only works on older Mac
      %versions of Matlab.
      graphics.internal.copyFigureHelper(sourcefigs(1));
      
    case 'clipboard_getframe'
      %Try screen grab from getframe.
      myimg = getframe(sourcefigs);
      myimg = myimg.cdata;
      %NOTE: This is a bit of a hack but seems to work.
      %Take out default background color.
      myimg(myimg==204)=255;
      %Take out the resize tab in lower left corner of image.
      myimg(end-12:end,end-12:end,:)= 255;
      o.usescale = 'no';
      clipboard_image('copy',myimg,o);
      
    case 'clipboard_bitmap'
      print(sourcefigs,'-clipboard','-dbitmap')
      
    case 'clipboard_pdf'
      print(sourcefigs,'-clipboard','-dpdf')
      
      
      %=======================================================
    case 'png'
      
      for figind = 1:length(sourcefigs)
        print(sourcefigs(figind), '-dpng', getfigurename(sourcefigs(figind),'png'), '-r0');
      end
      %=======================================================
    case 'eps'
      
      for figind = 1:length(sourcefigs)
        print(sourcefigs(figind), '-depsc', getfigurename(sourcefigs(figind),'eps'), '-r0');
      end
      
    otherwise
      error('Unrecognized target program');
      
  end
  
catch
  warning('EVRI:ExportfigurePlatformInvalid',['Cannot export figure/s to ' upper(target) ' for this platform.'],lasterr);
  if isvarname('app')
    try
      delete(app);
    end
  end

end
%------------------------------------------
function flashlistobj(listobj)

prop = 'backgroundcolor';
clr = get(listobj,prop);
set(listobj,prop,[.3 .3 .3]);
drawnow; pause(.2);
set(listobj,prop,clr)
drawnow;


%------------------------------------------
function figureName = getfigurename(fig,ext)

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
end
if isempty(figureName)
  figureName = 'Untitled_Fig';
end

% give figures meaningful names if possible
pat = '(\W*)';                                        % replace non-alpha, non-numeric chars
figureName = regexprep(figureName, pat, '_');

fileNameMaxLength = 40; % Max length of created files' names, in characters
newlen = min(fileNameMaxLength, length(figureName));
figureName = figureName(1:newlen);

%if file extention given, look for unique name by modifying filename
if nargin>1 & ~isempty(ext)
  append = '';
  index = 0;
  while exist([figureName append '.' ext])
    index = index+1;
    append = ['_' num2str(index)];
  end
end

%--------------------------------------------------------
function old = setfontsize(fig,resizefactor)
%adjust font sizes by some scalar (or reset original font sizes)
%I/O: old = setfontsize(fig,resizefactor); %adjust by scale factor
%I/O: setfontsizse(fig,old);  %reset

if nargout==0
  old = resizefactor;
  for j=1:size(old,1)
    if ishandle(old{j,1});
      set(old{j,1},{'fontsize'},old{j,2});
    end
  end
  return
end

old = {};
targ = findobj(fig,'type','axes');
for j=1:length(targ);
  other = get(targ(j),{'ylabel','xlabel','zlabel','title'});
  h1 = unique([targ(j); findobj(allchild(targ(j)),'type','text'); cat(1,other{:})]);
  sz1 = get(h1,'fontsize');
  if ~iscell(sz1); sz1 = {sz1}; end
  old(end+1,1:2) = {h1 sz1};
  for k=1:length(sz1); sz1{k} = sz1{k}*resizefactor; end
  set(h1,{'fontsize'},sz1);
end
drawnow;
pause(.5);

%------------------------------------------------------
function pos = setfigsize(fig,targetsize,mode)
%adjust figure size to a given target size
% mode is one of:
%   'none' = no reszing
%   'aspect' = resize maintaining aspect ratio
%   'exact'  = resize giving a specific size
%I/O: oldpos = setfigsize(fig,[width height],mode)
%I/O: setfigsize(fig,oldpos)

if isempty(targetsize)
  if nargout>0
    pos = [];
  end
  return;
end

if nargout==0
  set(fig,'position',targetsize);
  return
end

pos = get(fig,'position');
switch mode
  case 'aspect'
    wh = round(pos(3:4)./max(pos(3:4)./targetsize));
    pos_new = [pos(1:2) wh];
  case 'exact'
    pos_new = [pos(1:2) targetsize];
  otherwise
    pos = [];  %don't need to resize back later
    return;
end
set(fig,'position',pos_new);

%------------------------------------------------------
function printcheck(fig,options)
%Call best print type for given figure. Need to test for java objects and
%only use bitmap otherwise error will occur on some systems.

if ~isempty(options)
  %Copy the figure to the clipboard then paste into Word.
  pos_old = setfigsize(fig,options.wordtargetsize,options.resizemode);
  sz = setfontsize(fig,options.wordresizefontfactor);
end
java_objs = findobj(allchild(fig),'type','hgjavacomponent');

try
  myerr = [];
  if isempty(java_objs)
    %Use windows meta for possible better resolution.
    print(fig, '-dmeta', '-painters')
  else
    print(fig, '-dbitmap', '-painters');
  end
catch
  myerr = lasterror;
end

if ~isempty(options)
  setfontsize(fig,sz);
  setfigsize(fig,pos_old);
end

if ~isempty(myerr)
  rethrow(myerr)
end

%------------------------------------------------------
function test
%Manual test.

f = figure;
plot(rand(10));

%Test clipboard.
for i = {'clipboard_default' 'clipboardbitmap' 'clipboard_meta' 'clipboard_macscreencapture' 'clipboard_macold' 'clipboard_bitmap' 'clipboard_getframe' 'clipboard_pdf'}
  exportfigure(i{:},f);
end



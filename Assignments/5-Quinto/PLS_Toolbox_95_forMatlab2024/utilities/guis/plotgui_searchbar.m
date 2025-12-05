function varargout = plotgui_searchbar(varargin)
%PLOTGUI_SEARCHBAR Add toolbar to bottom of plot figure for search/selection.
% Add a toolbar with search and selection controls.
%
%
%I/O: plotgui_searchbar(figure_handle)
%
%See also: PLOTGUI


%Copyright Eigenvector Research 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0 || ~ischar(varargin{1}) % LAUNCH GUI
  try
    %GUI init.
    gui_init(varargin{1})
  catch
    myerr = lasterr;
    erdlgpls({'Unable to create search bar: ' myerr},[upper(mfilename) ' Error']);
  end
else
  try
    switch lower(varargin{1})
      case evriio([],'validtopics')
        options.height = 30;
        options.fontsize = getdefaultfontsize;
        if nargout==0
          evriio(mfilename,varargin{1},options)
        else
          varargout{1} = evriio(mfilename,varargin{1},options);
        end
        return; 
      otherwise 
        if nargout == 0;
          feval(varargin{:}); % FEVAL switchyard
        else
          [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
        end
    end
  catch
    erdlgpls(lasterr,[upper(mfilename) ' Error']);
  end   
end

%----------------------------------------------------
function gui_init(fig)
%Add toolbar to figure (fig).

%See there's an existing toolbar. If so, just return.

htb = getappdata(fig,'PlotguiSearchBar');
if ~isempty(htb)
  if ~isempty(htb.getParent)
    return
  end
end

opts = plotgui_searchbar('options');
opts = reconopts(opts,mfilename);

frm = get(handle(fig),'JavaFrame');
fp = frm.getFigurePanelContainer;
jtb = evrijavaobjectedt('javax.swing.JToolBar');

%Some users reporting errors involving javacomponentdoc_helper orignating at
%call to javacomponent call below. Seems to be related to newer matlab
%16a+. Adding drawnow hoping it might be related to latency.

drawnow

%No container (jhh) unless we pass pixel position instead.
[htb, jhh] = javacomponent(jtb,java.awt.BorderLayout.SOUTH,fig);

jtb.setFloatable(false);%Floating can get weird sizing so just disable.

%Default height is low so up it to options height (default = 30).
psz = htb.getPreferredSize;
psz.height = opts.height;
htb.setPreferredSize(psz);

%Add controls to toolbar.
if ~isempty(htb)
  jButton  = evrijavaobjectedt('javax.swing.JButton','X');
  %Use matlab combo box because is resizes better in layout engine. Initial
  %size is based on width of list strings. No need to manually decide size.
  %Can resize figure to get more width and viewing.``
  jCombo   = evrijavaobjectedt('com.mathworks.mwswing.MJComboBox');
  jLabel   = evrijavaobjectedt('javax.swing.JLabel',' Source: ');
  jLabel2  = evrijavaobjectedt('javax.swing.JLabel',' Search For: ');
  jEdit    = evrijavaobjectedt('javax.swing.JTextField');
  
  %Bump font size on all controls.
  f = get(jLabel,'Font');
  f2 = f.deriveFont(opts.fontsize);
  set(jButton,'Font',f2);
  set(jLabel,'Font',f2);
  set(jLabel2,'Font',f2);
  set(jEdit,'Font',f2);
  
  %Set min size of edit box so it doesn't get lost.
  sz = get(jEdit,'preferredSize');
  sz.width = 150;
  set(jEdit,'PreferredSize',sz);%
  
  %Add callbacks.
  jCombo_h = handle(jCombo,'CallbackProperties');
  jButton_h = handle(jButton,'CallbackProperties');
  jEdit_h = handle(jEdit,'CallbackProperties');
  
  set(jCombo_h,'ItemStateChangedCallback', {@sourcechange fig htb jEdit_h});%Item changed.
  set(jButton_h,'ActionPerformedCallback',{@closetoolbar fig htb});
  set(jEdit_h,'KeyTypedCallback',{@keyupfcn fig htb jCombo});
  set(jEdit_h,'ToolTipText',['Case insensitive search. Surround term with double quotes "" for case sensitivity. '...
    'Use re:... for regular expression. If numeric field use relational expression (<) in first position. See: DATASET/SEARCH'])
  
  %Using fixed width font (courier) so indentation shows up in list. Need
  %to in increase fonts size to account for courier.
  set(jCombo,'Font',java.awt.Font('monospaced',java.awt.Font.PLAIN,opts.fontsize+2))
  
  %Add controls to toolbar.
  jtb(1).add(jButton); 
  jtb(1).add(jLabel);
  jtb(1).add(jCombo);
  jtb(1).add(jLabel2);
  jtb(1).add(jEdit);
  
  %Make sure everything gets painted and sized correctly.
  jtb(1).repaint;
  jtb(1).revalidate;
end

%Revalidate so the panel re calculates layout of controls to be sure
%toolbar is in right spot.
fp.validate
setappdata(fig,'PlotguiSearchBar',htb);

update_source_list(fig);

%------------------------
function varargout = update_source_list(varargin)
%Update source list.
% Use PlotguiSearchBarTableIndex to store information on selection
% information. Coluns are Index, Field, Mode, Set  (see listsets.m).

fig = varargin{1};
tb  = getappdata(fig,'PlotguiSearchBar');
cmp = tb.getComponents;
jcmb = cmp(3);%Combo box.
jedt = cmp(5);%Edit box.

%Get data.
mydataset = plotgui('getdataset',fig);

if isempty(mydataset)
  return
end

%Get mode to search on.
pv = plotvs(fig);

%Get list.
[liststr, tblidx] = listsets(mydataset,'',pv);

%Add index value.
liststr   = char('Index',liststr);
tblidx    = [{0 'index' pv 1}; tblidx];

tblidx(:,1) = num2cell(1:size(tblidx,1))';

oldtable = getappdata(fig,'PlotguiSearchBarTableIndex');

%Check to see if anything has changed.
sametbl = comparevars(tblidx,oldtable);

if ~sametbl
  %Update items.
  jcmb.removeAllItems;
  liststr = str2cell(liststr);
  for i = 1:length(liststr)
    mystr = liststr{i};
    mystr = strrep(mystr,' ','&nbsp;');
    jcmb.addItem(['<html><font color="black" id="' num2str(i) '">' mystr '</font></html>']);
  end

  setappdata(fig,'PlotguiSearchBarTableIndex',tblidx);
  
  %Update selection.
  keyupfcn(jedt,[],fig,[],jcmb);
end

%------------------------
function varargout = closetoolbar(varargin)
%Have to close by using remove.

jtb = varargin{4};
jpt = jtb.getParent;
jpt.remove(jtb);
jpt.repaint;
jpt.revalidate;
setappdata(varargin{3},'PlotguiSearchBar',[]);%Easiest way to know toolbar has been deleted.
setappdata(varargin{3},'PlotguiSearchBarTableIndex',[]);

%------------------------
function varargout = sourcechange(varargin)
%Change of source so run keyup to make new selections if needed.

keyupfcn(varargin{5}, [], varargin{3}, [], varargin{1});

%------------------------
function varargout = keyupfcn(varargin)
%Key up should trigger search and selection.

%Get inputs.
jedt  = varargin{1};
fig   = varargin{3};
combo = varargin{5};

%Get data info.
mydataset = plotgui('getdataset',fig);
tblidx = getappdata(fig,'PlotguiSearchBarTableIndex');

%Get set/mode.
myterm  = char(evrijavamethodedt('getText',jedt));
myidx   = evrijavamethodedt('getSelectedIndex',combo)+1;
if myidx==0
  return
end
myfield = tblidx{myidx,2};
mymode  = tblidx{myidx,3};
myset   = tblidx{myidx,4};

if mymode ==0 | myset==0
  %Set to first set then continue. Add two locations columns > 0 so first
  %item == 2 indicates a set with items.
  fsets = find(([tblidx{:,3}]'>0)+([tblidx{:,4}]'>0)==2);
  if isempty(fsets)
    return
  else
    fsets = fsets(1);
    evrijavamethodedt('setSelectedIndex',combo,fsets-1);
    mymode  = tblidx{fsets,3};
    myset   = tblidx{fsets,4};
    combo.repaint
  end
end

%Infer class or classID based on searchterm.
if strcmpi(myfield,'class') & ~isempty(myterm) &...
    ~ismember(myterm(1),{'<' '>' '=' '~' '['})
  myfield = 'classid';
end

%Search for items via dataset search method.
thissel = find(search(mydataset,myfield,mymode,myset,myterm));

myselection = {[] []};
pv = plotvs(fig);
myselection{pv} = thissel;

plotgui('setselection',myselection,fig);

%Line: 6427 in plotgui
%selectcell = insertselection(selection,targfig);
%setselection(selectcell,get(targfig,'selectiontype'),targfig);

%------------------------------------------------------
function out = plotvs(fig)
%returns the current mode being used for the x-axis and/or the selection basis for the indicated PlotGUI figure

opts = getappdata(fig);
plotby = opts.plotby;
if plotby==0
  ind = plotgui('GetMenuIndex',fig);
  out = ind{1}+1;
elseif plotby<3
  out = 3-plotby;
else
  out = 1;
end

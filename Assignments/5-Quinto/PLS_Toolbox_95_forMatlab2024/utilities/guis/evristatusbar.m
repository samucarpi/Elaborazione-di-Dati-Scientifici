function varargout = evristatusbar(varargin)
%EVRISTATUSBAR - Create status bar on a figure.
%  Based on a Yair tool.
%  Use 'settext' and 'setprogress' to updaste bar. Progress is between 0
%  and 1.
%
%  NOTE: Something about this code cases GCBO to always return the status
%  bar instead of normal GCBO. Needs fixing.
%
%I/O: varargout = evristatusbar(fig,text)
%I/O: varargout = evristatusbar('settext',fig,text)
%I/O: varargout = evristatusbar('setprogress',fig,.5)

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin>0;
  try
    switch lower(varargin{1})
      case evriio([],'validtopics')
        options = [];
        options.name = 'options';
        
        if nargout==0
          evriio(mfilename,varargin{1},options)
        else
          varargout{1} = evriio(mfilename,varargin{1},options);
        end
        return;
      otherwise
        if ishandle(varargin{1})
          settext(varargin{:})
        else
          if nargout == 0;
            feval(varargin{:}); % FEVAL switchyard
          else
            [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
          end
        end
    end
  catch
    erdlgpls(lasterr,[upper(mfilename) ' Error']);
  end
end

%--------------------------------------
function mybar = makebar(myfig)
%Make the actual bar.

%Get existing bar.
jRootPane = getroot(myfig);
mybar = evrijavaobjectedt('com.mathworks.mwswing.MJStatusBar');
jProgressBar = evrijavaobjectedt('javax.swing.JProgressBar');
jProgressBar.setVisible(true);
jProgressBar.setMinimum(0);
jProgressBar.setMaximum(100);
mybar.add(jProgressBar,'West');  % Beware: East also works but doesn't resize automatically
jRootPane.setStatusBar(mybar);

mybar = handle(mybar);
guidata(myfig,mybar);

if ~isempty(mybar)
  addOrUpdateProp(mybar,'CornerGrip',  mybar.getParent.getComponent(0));
  addOrUpdateProp(mybar,'TextPanel',   mybar.getComponent(0));
  addOrUpdateProp(mybar,'ProgressBar', mybar.getComponent(1).getComponent(0));
end
setappdata(myfig,'estatusbar',mybar);

%--------------------------------------
function settext(myfig,newtext)
%Set text on bar.

mybar = getbar(myfig);
mybar.setText(newtext)
mybar.setVisible(true);

%--------------------------------------
function mytxt = gettext(myfig)
%Get curent text.
mybar = getbar(myfig);
mytxt = mybar.getText;

%--------------------------------------
function setprogress(myfig,myprogress)
%Set progress on bar.

mybar = getbar(myfig);
pbar  = get(mybar,'ProgressBar');

myprogress = myprogress*100;
myprogress = max(myprogress,0);
myprogress = min(myprogress,100);

pbar.setValue(myprogress)
%--------------------------------------
function myprogress = getprogress(myfig)
%Set progress on bar.

mybar = getbar(myfig);
pbar  = get(mybar,'ProgressBar');
myprogress = pbar.getValue;

%--------------------------------------
function mybar = getbar(myfig)
%Get existing bar.
mybar = getappdata(myfig,'estatusbar');

if isempty(mybar)
  mybar = makebar(myfig);
else
  %Make sure visible.
  jRootPane = getroot(myfig);
  jRootPane.setStatusBarVisible(1);
end

%--------------------------------------
function remove(myfig)
%Get existing bar.
jRootPane = getroot(myfig);
jRootPane.setStatusBarVisible(0);
drawnow

%--------------------------------------
function jRootPane = getroot(myfig)
%Get the rootpane.

%Must be visible but test first because setting visible bring figure to
%front.
myvis = get(myfig,'visible');
if strcmpi(myvis,'off')
  set(myfig,'visible','on')
end
jFrame = get(handle(myfig),'JavaFrame');

jFigPanel = get(jFrame,'FigurePanelContainer');
pause(.01)
jRootPane = jFigPanel.getComponent(0).getRootPane;
pause(.01)
jRootPane = jRootPane.getTopLevelAncestor;

%--------------------------------------
function addOrUpdateProp(handle,propName,propValue)
try
  if ~isprop(handle,propName)
    schema.prop(handle,propName,'mxArray');
  end
  set(handle,propName,propValue);
catch
  % never mind... - maybe propName is already in use
  %lasterr
end

%--------------------------------------
function test
f = figure;
evristatusbar(f,'blah')
evristatusbar('setprogress',f,.5)

function evriuninstall(action,myproduct)
%EVRIUNINSTALL Uninstall an Eigenvector Research toolbox.
% Action can be set to 'pathonly' which will remove all evri products from
% the ML path or 'silent' which will remove evri products from preferences
% and the path without dialog boxes.
%
% Input 'myproduct' will constrain removal of particular product from the
% path. Input should be string of particular product (e.g., 'pls_toolbox'
% or 'mia_toolbox'). If emtpy or omitted then removes all products.
%
%I/O: evriuninstall(action,myproduct)
%I/O: evriuninstall('silent','mia_toolbox') %Uninstall MIA_Toolbox.
%
%See also: EVRIDEBUG, EVRIINSTALL, EVRIUPDATE, SETPATH

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms
% 6/28/05 switched to using pathsep instead of ';'

%Intialize quiet mode.
quiet = 0;

if nargin<1;
  action = '';
end

if nargin<2;
  myproduct = '';
end

switch action
  case 'pathonly'
    clensepath(myproduct);
    return
  case 'silent'
    quiet = 1;
end

%Get ml version, don't use getmlversion so don't need PLS_Toolbox.
mlver = version;
mlver = str2num(mlver(1:3));

[release,product,prodpath] = evrirelease('all');
if ~isempty(myproduct)
  uprod = unique(product);
  prodstr = '';
  for i = 1:length(uprod)
    prodstr = [prodstr uprod{i}];
  end
else
  prodstr = 'All EVRI Products';
end

if mlver>=6.5
  if ~quiet
    quest = questdlg(['This will uninstall ' prodstr '. Continue?'],[prodstr ' Uninstall'],['Uninstall ' prodstr],'Cancel',['Uninstall ' prodstr]);
  else
    quest = ['Uninstall ' prodstr];
  end
  if ~strcmp(quest,['Uninstall ' prodstr]);
    return
  end
else
  %Version 6.1
  %DO NOT USE QUESTDLG - a bug can cause the question dialog to show
  %up BEHIND the command window confusing the user, just assume they
  %really do want to install

  %intialize help window so it doesn't pop up in front of error dialogs
  helpwin({[' ** Uninstalling ' prodstr ' ** ']},prodstr,'Uninstallation');
  pause(3);
  drawnow;
end

h = waitbar(0,'Initializing...');
htitle = get(findobj(h,'type','axes'),'title');
set(h,'name',[prodstr ' Uninstallation'])

%=============================================
set(htitle,'string','Removing from Matlab Path...');
waitbar(.3);
try
  clensepath(myproduct);
  rehash toolboxcache;
catch
  delete(h);  %remove waitbar
  helpwin({['Problems encountered during ' prodstr ' Uninstallation - EVRIUninstall must be re-run after solving these problems'],...
    [{lasterr} {' '} {'Please contact Eigenvector Reasearch via e-mail at: helpdesk@eigenvector.com'}]}...
    ,prodstr,'Install Help');
  beep
  waitfor(errordlg([prodstr ' Uninstallation Failed - See Help Window'],[ prodstr ' Uninstallation'],'modal'));
  return
end

%=============================================
set(htitle,'string','Removing preferences and settings...');
waitbar(.6);

try
  if ispref('EVRI'); rmpref('EVRI'); end
  if ispref('EVRI_LM'); rmpref('EVRI_LM'); end
  evriprefreset(product);
  setappdata(0,'PLS_Prefs',[]);
  rmappdata(0,'PLS_Prefs');
catch
  delete(h);  %remove waitbar
  helpwin({['Problems encountered during ' prodstr ' Uninstallation - EVRIUninstall must be re-run after solving these problems'],...
    [{lasterr} {' '} {'Please contact Eigenvector Reasearch via e-mail at: helpdesk@eigenvector.com'}]}...
    ,prodstr,'Install Help');
  beep
  waitfor(errordlg(['' prodstr ' Uninstallation Failed - See Help Window'],['' prodstr ' Uninstallation'],'modal'));
  return
end

%=============================================
delete(h);  %remove waitbar
if mlver>=6.5;
  drawnow;
  if ~quiet
    h = helpdlg({['' prodstr ' Successfully Uninstalled!'],' ','Please Note: Some documentation features will not be updated until you restart Matlab'},['' prodstr ' Uninstallation']);
    set(h,'windowstyle','modal');
    uiwait(h)
  end
end

%-------------------------------------------------------------
function clensepath(myprod)
%Remove evri products from path. Input 'myprod' is string of particular
%product to move e.g., 'mia_toolbox'. If it's empty or not given then all
%products are removed. 

[release,product,prodpath] = evrirelease('all');

if ~isempty(myprod)
  idx = find(ismember(lower(product),myprod));
else
  idx = 1:length(product);
end

toremove = prodpath(idx);

%do the removal
mypath    = path;
for j=1:length(toremove);
  targetpth = toremove{j};
  newpath = [];
  [p,pth] = strtok(mypath,pathsep);
  while ~isempty(p);
    if isempty(findstr(p,targetpth));
      newpath = [newpath p pathsep];
    end;
    [p,pth] = strtok(pth,pathsep);
  end
  mypath    = newpath;
end
path(mypath);

%save path
mlver = version;
mlver = str2num(mlver(1:3));
if mlver<7  %release <14?
  f = path2rc;
else
  f = savepath;
end
switch f
  case 0
    %everything OK
  otherwise
    error(['Path could not be saved.'])
end

%-------------------------------------------------------------
function evriprefreset(prod)
%Remove prefs for 'prod', cell array of product names (e.g.,'pls_toolbox).
prod = unique(prod);
for i = 1:length(prod)
  if ispref(prod{i})
    rmpref(prod{i});
  end
end


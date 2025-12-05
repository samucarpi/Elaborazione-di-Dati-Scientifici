function outofdate = evriupdate(umode, product)
%EVRIUPDATE Check Eigenvector.com for available PLS_Toolbox updates.
% EVRIUPDATE checks the Eigenvector Research web site for the most current
% PLS_Toolbox release version number. This is compared to the currently
% installed version. A message reporting the availability of an update is
% given as necessary. The input (product) can be any standard Eigenvector
% Research product name (underscores included) or the keyword 'all' to
% check for all installed products. Product input only used with umodes
% 0-2.
%
% The optional input (umode) can be any of the following:
%   'auto'       : perform an automatic check based on Auto Check settings
%   'settings'   : Gives GUI to modify the automatic check settings
%   'prompt'     : prompt user before performing check - includes prompt to
%                  allow user to modify settings.
%   'autosilent' : performs an automatic check (as long as Auto Check
%                  settings are not "none"). Never prompts and does not
%                  display any dialogs (assumes caller will act on result)
% or (umode) one of the following levels of automatic reports:
%     0  : give dialog stating if new version is available or not
%     1  : give dialog ONLY if a new version is available
%     2  : gives no dialog messages - only returns output flag (see below)
%     3  : give dialog of outdated product(s) ONLY if a new version is available
%     4  : give dialog of all products from EVRI and versions (new or not)
%     5  : give dialog of all products but ONLY if a new version is available
% The default mode is 4.
%
% The output (outofdate) will be 0 (zero) if the installed products are
%  current, 1 (one) if the installed versions are out of date and -1 if
%  evriupdate could not retrieve the most current version number.
%
% All update checking options can be disabled by using the following:
%   setplspref('evriupdate','mode','disabled')
% Reset to factor settings using 'factory' in place of 'disabled'
%
%I/O: outofdate = evriupdate(umode,product)
%I/O: evriupdate settings  %manage evriupdate settings
%
%See also: EVRIDEBUG, EVRIINSTALL, EVRIRELEASE, EVRIUNINSTALL

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms
%jms 12/3/04 -modified to do true comparison of version #s
%jms 6/30/05 -added automatic check functionality and settings GUI
%rsk 9/02/05 -add multiple product check and display.
%rsk 3/23/06 -fix cell assignment for ML6.5.

if nargin==0;
  umode = 4;
end
if nargin < 2
  %assume product is PLS_Toolbox
  product = 'all';
end

if ischar(umode);
  switch umode
    case 'mode'
      opts = reconopts([],'evriupdate');
      outofdate = opts.mode;
      return
      
    case 'settings'
      opts = reconopts([],'evriupdate');
      if strcmp(opts.mode,'disabled');
        return
      end
      opts = evriupdatesettings(opts);
      setplspref('evriupdate','mode',opts.mode);
      setplspref('evriupdate','frequency',opts.frequency);
      
    case {'auto','prompt','autosilent'}
      opts = reconopts([],'evriupdate');
      if strcmp(umode,'prompt')
        %evriupdate prompt forces a prompted question
        opts.lastcheck = 0;
        opts.frequency = 0;
        opts.mode = 'prompt';
      end
      if strcmp(opts.mode,'never') | strcmp(opts.mode,'disabled');  %never check
        %return last found status
        outofdate = getfield(evriupdate('options'),'lastautostatus');
        if ~outofdate
          %UNLESS that status was "not of of date" - in which case, return
          %"I don't know" status (-1) since it may NOW be out of date, but
          %we can't tell.
          outofdate = -1;
        end
        return
      end
      if opts.lastcheck+opts.frequency < now
        if strcmp(umode,'autosilent')
          %don't display anything - caller will act
          outofdate = evriupdate(2);
        else
          switch lower(opts.mode)
            case 'prompt'
              ans = evriquestdlg({['Updates to Eigenvector software products may exist.'],'Do you want to check the Eigenvector Research web site for software updates?'},'Automatic Check For Updates','Check For Updates','Change Settings...','Skip','Check For Updates');
              if strcmp(ans,'Change Settings...')
                evriupdate settings;
                opts = reconopts([],'evriupdate');
                if strcmp(opts.mode,'never')
                  helpdlg({'Automatic Update Checks has been disabled','Use "evriupdate settings" to re-enable'},'Automatic Checks Disabled');
                end
                outofdate = evriupdate('auto');
                return
              end
              if strcmp(ans,'Check For Updates');
                outofdate = evriupdate(0);
              else
                outofdate = -1;
              end
            otherwise
              %automatic mode
              if exist('isdeployed') && isdeployed
                outofdate = evriupdate(3);
              else
                outofdate = evriupdate(5);
              end
          end
        end
        setplspref('evriupdate','lastcheck',now);
        setplspref('evriupdate','lastautostatus',outofdate); %store last status
      else
        %last check was recently - don't check again, just return last status
        outofdate = getplspref('evriupdate','lastautostatus');
      end
      return
      
    otherwise
      options = [];
      options.mode = 'prompt';
      options.frequency = 30;
      options.lastcheck = 0;
      options.lastautostatus = 0;
      if nargout==0; evriio(mfilename,umode,options); else; outofdate = evriio(mfilename,umode,options); end
      return;
  end
end

%Get list of all installed products and compare it to a list from EVRI then
%display requested information.

opts = reconopts([],'evriupdate');
if strcmp(opts.mode,'disabled')
  return
end

%get installed version
%myversion = getfield(getplspref('evriinstall'),'version');
[myversion,myproduct] = evrirelease('all');

if ~iscell(myproduct)
  myproduct = {myproduct};
  myversion = {myversion};
end

%Need to replace underscore so matches product name from website. 
namechange = {'Solo_MIA' 'Solo+MIA';
              'Solo_Model_Exporter' 'Solo+Model_Exporter'};
for i = 1:size(namechange,1)
  smia_loc = strfind(myproduct,namechange{i,1});
  smia_loc = [smia_loc{:}];
  if ~isempty(smia_loc)
    myproduct = strrep(myproduct,namechange{i,1},namechange{i,2});
  end
end

%Get SN.
sncode = evriio('test');
sncode = strtrim(strtok(sncode,'['));

%try to get newest version info
try
  newversion = urlread(['https://software.eigenvector.com/toolbox/versioninfo.php?product=all&rv=2&v=' getmlversion('string') '&p=' computer '&sn=' sncode]);
  [newversion,newproduct,mdate] = parseverinfo(newversion); %Get cell output to match evrirelease style.
catch
  if nargout>0
    outofdate = -1;
  end
  if umode<2;
    erdlgpls({'Unable to automatically verify currently available version.','Please check connection to Internet.'},'EVRI Update Error');
  end
  return
end

%Build product profile array.
%Column 1 = Product
%Column 2 = Available
%Column 3 = Installed.
%Fourth column consists of:
%   -1 = not installed.
%    0 = current.
%    1 = out of date.
%    2 = advanced copy (beta).

eprofile = [newproduct newversion repmat({''},[length(newproduct) 1]) repmat({-1},[length(newproduct) 1]) mdate repmat({-1},[length(newproduct) 1])];
priority = [-1 1 2 0];  %the hierachy of status flags (0 is best)
for i = 1:length(myproduct)
  ploc = find(ismember(lower(eprofile(:,1)),lower(myproduct{i}))); %product row location in profile.
  if ismember(lower(myproduct{i}),lower(newproduct))
    %Product is installed.
    if isnewversion(eprofile{ploc,2},myversion{i})
      %New version is greater than my version.
      status = 1;
    elseif isbetaversion(eprofile{ploc,2},myversion{i})
      %Version is advanced (beta).
      status = 2;
    else
      %Version is current.
      status = 0;
    end
    if find(priority==status) > find(priority==eprofile{ploc,4});
      %only record this if it is a more important discovery (i.e. have
      %current > beta > new version exists > not found)
      eprofile{ploc,3} = myversion{i};%installed version
      eprofile{ploc,4} = status;
    end
  else
    %Product not installed, default value already in place.
  end
end

for i = 1:size(eprofile,1)
  %Make maintenance code.
  %-1 = not availble, 0 = current, 1 = within month, 2 = expired
  if ~isempty(mdate{i})
    try
      mydiff = datenumplus(mdate{i})-now;
      if mydiff<-30
        %Expired
        eprofile{i,6}=2;
      elseif mydiff<30
        %Around Expired
        eprofile{i,6}=1;
      else
        %Not Expired
        eprofile{i,6}=0;
      end
    catch
      %some error - just ignore
      eprofile{i,6}=0;
    end
    
  end
end

if strcmp(product,'all')
  ploc = 1:size(eprofile,1);
else
  ploc = find(ismember(lower(eprofile(:,1)),lower(product))); %product row location in profile.
end
outdate = any([eprofile{ploc,4}]==1);
outmaintenance = any([eprofile{ploc,6}]==1);

if outdate || outmaintenance
  %out-of-date
  if outdate
    outofdate = 1;  %flag as out-of-date
  else
    outofdate = 2;  %flag as maintenance
  end
  if ismember(umode,[0 1 3 4 5]);
    if ismember(umode,[3 0])
      hh = buildgui(eprofile([eprofile{ploc,4}]>=0,:));
    elseif ismember(umode,[4 5]);
      hh = buildgui(eprofile);
    else
      hh = [];
    end
    if outdate
      if ~strcmp(product,'all')
        uiwait(warndlg({['Your version of ' eprofile{ploc,1} ' is out of date!'],' ',['Your version: ' eprofile{ploc,3}],['Current release: ' eprofile{ploc,2}],' ','Please check the Eigenvector Website for upgrade information'},'Eigenvector Product Out Of Date'));
      else
        uiwait(warndlg({'One or more of your Eigenvector Products are out of date!',' ','Please check the Eigenvector Website for upgrade information'},'Eigenvector Product Out Of Date'));
      end
    elseif outmaintenance
      if ~strcmp(product,'all')
        uiwait(warndlg({['Your maintenance for ' eprofile{ploc,1} ' is expired or is expiring soon!'],' ','Please check the Eigenvector Website for maintenance extension information'},'Eigenvector Maintenance Out Of Date'))
      else
        uiwait(warndlg({['One or more of your Eigenvector product maintenance agreemens is expired or expiring soon!'],' ','Please check the Eigenvector Website for upgrade information'},'Eigenvector Maintenance Out Of Date'))
      end
    end
    if ishandle(hh); uiwait(hh); end
  end
else
  %up-to-date
  outofdate = 0;
  if ismember(umode,[0 4]);
    if umode == 4
      hh = buildgui(eprofile);
    else
      hh = [];
    end
    if ~strcmp(product,'all')
      h = helpdlg({['Your ' eprofile{ploc,1} ' is the latest version available.'],'No update is necessary.'},'Eigenvector Product Current');
    else
      h = helpdlg({['Your Eigenvector Products are the latest version available.'],'No update is necessary.'},'Eigenvector Product Current');
    end

    uiwait(h);
    if ishandle(hh); 
      uiwait(hh); 
    end
  end
  
end
setplspref('evriupdate','lastautostatus',outofdate); %store last status
if nargout==0
  clear outofdate
end

%------------------------------------------
function out = isnewversion(newversion,myversion)

vnew = encodeversion(newversion);  %parse version #s for .'s
vmy  = encodeversion(myversion);

%make arrays equal in length
len  = max(length(vnew),length(vmy))+1;
vnew(len) = 0;
vmy(len)  = 0;

%compare element by element loking for first non-zero difference
vdiff = vnew-vmy;
firstdiff = vdiff(min(find(vdiff~=0)));

out = firstdiff>0;  %if first difference is >0 then new version > my version

%--------------------------------------
function out = encodeversion(str)

out = [];
rem = str;
% if strfind(rem,'Beta') | strfind(rem,'Beta')

while ~isempty(rem);
  [n,rem] = strtok(rem,'.');  %parse for periods
  nonnum = min(find(n>'9'));%any non-numeric characters?
  if ~isempty(nonnum) && ~strcmp(n,'beta');
    n = max([0 str2num(n(1:nonnum-1))])+sum(double(n(nonnum:end))/256);  %convert to decimal
  elseif strcmp(n,'beta')
    out(end) = out(end)-.01;
    continue
  else
    n = str2num(n);
  end
  out(end+1) = n;
end
if isempty(out);
  out = 0;
end

%--------------------------------------
function [pver,prd,mdate] = parseverinfo(vstr)
%Parse raw output what's returned by website.
%vstr = textscan(vstr,'%s');

linef = regexp(vstr,'\n');
vs = '';
loc = 1;
for i = 1:length(linef)
  vs = [vs; {vstr(loc:linef(i)-1)}];
  loc = linef(i)+1;
end

prd = {[]};
pver = {[]};
mdate = {[]};
for i = 1:size(vs,1)
  [prd{i,1}, rm] = strtok(vs{i,1},',');
  [pver{i,1},rm] = strtok(rm,',');
  [mdate{i,1},rm] = strtok(rm,',');
end

%------------------------------------------
function out = isbetaversion(newversion,myversion)

vnew = encodeversion(newversion);  %parse version #s for .'s
vmy  = encodeversion(myversion);

%make arrays equal in length
len  = max(length(vnew),length(vmy))+1;
vnew(len) = 0;
vmy(len)  = 0;

%compare element by element loking for first non-zero difference
vdiff = vnew-vmy;
firstdiff = vdiff(min(find(vdiff~=0)));

out = firstdiff<0;  %if first difference is >0 then new version > my version

%------------------------------------------
function ph = buildgui(displaycell)
%Build display for multiple products.

%Add headings to profile cell array.
displaycell = [{'Eigenvector Product' 'Available' 'Installed' [0] 'Maintenance' [0]}; displaycell];

%Add 'Not Installed' string for empty cells. Only displayed if umode = 4.
atbottom = [];
for i = 1:size(displaycell,1);
  if isempty(displaycell{i,3})
    displaycell{i,3} = 'n/a';
    atbottom(end+1) = i;
  end
end
%re-order putting "not installed" at bottom of list
displaycell = displaycell([setdiff(1:size(displaycell,1),atbottom) atbottom],:);

%Construct parent figure.
ph = figure('Name', 'Eigenvector Product Status',...
  'Units', 'Normalized',...
  'Position', [0.5-.2,0.5,.2,.1],... %Position near center of screen.
  'NumberTitle', 'off',...
  'Visible', 'on',...
  'Toolbar', 'none',...
  'MenuBar', 'none');

set(ph,'Units', 'Pixel');
pos = get(ph,'Position');

%Find number of rows and set figure height. [left bottom width height]
nrows = size(displaycell,1);
pos(3) = 512;
pos(4) = nrows*24 + 32;
set(ph,'Position', pos);

curpos = pos(4)-25;
clr = [0.88 0.88 .88]; %Starting background color = light grey

for i = 1:nrows
  dh1 = uicontrol(ph,...
    'Style', 'edit',...
    'Position', [4 curpos 200 23],...
    'horizontalalignment', 'left',...
    'BackgroundColor',clr,...
    'enable','inactive',...
    'String', displaycell{i,1});

  dh2 = uicontrol(ph,...
    'Style', 'edit',...
    'Position', [201 curpos 105 23],...
    'horizontalalignment', 'center',...
    'BackgroundColor',clr,...
    'enable','inactive',...
    'String', displaycell{i,3});
  
  dh3 = uicontrol(ph,...
    'Style', 'edit',...
    'Position', [305 curpos 105 23],...
    'horizontalalignment', 'center',...
    'BackgroundColor',clr,...
    'enable','inactive',...
    'String', displaycell{i,2});

  dh7 = uicontrol(ph,...
    'Style', 'edit',...
    'Position', [409 curpos 105 23],...
    'horizontalalignment', 'center',...
    'BackgroundColor',clr,...
    'enable','inactive',...
    'String', displaycell{i,5});
  
  %Mark background of out-of-date product versions with light red.
  if displaycell{i,4}==1
    set([dh2 dh3], 'BackgroundColor', [0.99 0.7 .7],'fontweight','bold')
  elseif  displaycell{i,4}==-1
    set([dh2], 'BackgroundColor', [0.99 0.99 .75])
  end
  
  if displaycell{i,6}==1
    set(dh7, 'BackgroundColor', [0.99 0.99 .75])
  elseif displaycell{i,6}==2
    set(dh7, 'BackgroundColor', [0.99 0.7 .7],'fontweight','bold','String','EXPIRED')
  end
  
  curpos = curpos - 24; %move down text box height + 1 pixels.

  if i == 1
    %Bold headings.
    set([dh1, dh2, dh3, dh7],'FontWeight','bold');
    clr = [1 1 1];%Change color to white
  end

end

%Add close and web buttons.
dh6 = uicontrol(ph,...
  'Style', 'PushButton',...
  'Position', [4 4 160 25],...
  'horizontalalignment', 'left',...
  'Callback','evriupdate settings',...
  'String', 'Auto-Check Settings' );
dh4 = uicontrol(ph,...
  'Style', 'PushButton',...
  'Position', [166 4 159 25],...
  'horizontalalignment', 'left',...
  'Callback','web(''http://software.eigenvector.com/toolbox/download'',''-browser'')',...
  'String', 'Go To Eigenvector Website' );
dh5 = uicontrol(ph,...
  'Style', 'PushButton',...
  'Position', [pos(3)-90 4 84 25],...
  'horizontalalignment', 'left',...
  'Callback',';close(gcf)',...
  'String', 'Close' );

set(ph,'Windowstyle','modal');  %make window modal (also avoids resize on docked error associated with next line)
set(ph,'Resize', 'off');


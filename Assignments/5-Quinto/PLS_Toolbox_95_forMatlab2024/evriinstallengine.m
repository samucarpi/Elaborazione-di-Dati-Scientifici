function out = evriinstallengine(action,varargin)
%EVRIINSTALLENGINE Install Eigenvector Research Product.
%
%See also: EVRICOMPATIBILITY, EVRIDEBUG, EVRIINSTALL, EVRIRELEASE, EVRIUNINSTALL, EVRIUPDATE, SETPATH

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB�, without
% written permission from Eigenvector Research, Inc.
%jms
%jms 5/4/04 -added additional information logging on install
%jms 6/11/04 -use waitbar for progress and helpwindow for errors
%jms 9/1/04 -fixed error message bug
%rsk 03/29/05 -improve waitbar handling and add quiet mode.
%rsk 03/23/06 -change to single interface GUI.
%rsk 04/26/07 -up last ML ver support to 6.5.

try
  %Outer try loop.
  if mlver<6.5
    %Don't even try to install PLS_Toolbox 4.0 or greater.
    errordlg({'Please Note: Matlab versions 6.1.x (R12) and earlier are no longer supported by Eigenvector Research Inc. products.' ' ' 'Please upgrade to a later version of Matlab.'},'Matlab Version Error');
    return
  end
  
  quiet = 0; %quiet = 0 implies a GUI exists.
  
  checkprerelease
  
  %Intialize quiet mode.
  curdir = pwd;
  if nargin>0;
    switch action
      case 'info'
        try
          out = getplspref('evriinstall');
          if isempty(out);
            out = [];
            out.version = evrirelease;
            out.type    = 'Not Installed';
            out.date    = 'n/a';
          end
          out.license = evriio('test');
        catch
          out = [];
          out.version = evrirelease;
          out.type    = 'Not Installed';
          out.license = 'unknown';
          out.date    = 'n/a';
        end
        return
      case 'silent'
        update_evriio
        quiet = 1;
      case 'install'
        update_evriio
        handles = varargin{1};
        setmsgboxcolor(handles,'ok')
      case 'callback'
        feval(varargin{:});
        return
        
      case 'licenseagree'
        web('text://');
        setappdata(0,'licenseagreement','yes');
        h = findobj(allchild(0),'tag','installfigure');
        if isempty(h);
          evriinstall
          return
        end
        handles = guihandles(h);
        figure(h);  %bring to front
        action = 'install';
      case 'cancel'
        web('text://');
        close all force
        errordlg(['Installation Canceled - For assistance please contact Eigenvector '...
          'Research via e-mail at: helpdesk@eigenvector.com'],...
          'User Cancel');
        return
    end
  else
    %Create installation figure.
    update_evriio
    createfig(curdir);
    return
  end
  
  if ~quiet
    installpref.removeold      = get(handles.cbox_removeold,'value');
    installpref.checkotherprod = get(handles.cbox_checkotherprod,'value');
    installpref.checkupdates   = get(handles.cbox_checkupdates,'value');
    updatebar(handles,0); drawnow;
  else
    installpref.removeold      = 1;
    installpref.checkotherprod = 1;
    installpref.checkupdates   = 0;
  end
  
  %----------------------------------------------
  %initial confirmation of installation
  
  [release,product] = evrirelease;
  
  %------------------------------------------
  %ask for license code (or verify that valid license code exists)
  thisfolder = fileparts(which(mfilename));
  notonpath = isempty(findstr(path,fullfile(thisfolder,'utilities')));
  if notonpath
    try
      cd(fullfile(thisfolder,'utilities'))  %get into utilities folder to run evriio
      addpath(pwd)
      cd ..
    catch
      uiwait(errordlg('Installation appears to be missing "utlities" sub-folder. Please re-install from the downloaded ZIP or EXE. If this problem persists, contact Eigenvector Research at helpdesk@eigenvector.com','Missing Utilities Folder'));
      set(handles.msgbox,'String','Aborting Installation: Missing "utilities" sub-folder.');
      setmsgboxcolor(handles,'error')
      return
    end
  end
  try
    invalid = ~isempty(findstr(evriio('test'),'expired'));
  catch
    if notonpath
      rmpath(fullfile(thisfolder,'utilities'));
    end
    uiwait(errordlg({'There appears to be a problem with the license test. Please re-install from the downloaded ZIP or EXE. If this problem persists, contact Eigenvector Research at helpdesk@eigenvector.com and report the following license manager error:',' ',lasterr},'Bad license test'));
    set(handles.msgbox,'String','Aborting Installation: Failed test of license.');
    setmsgboxcolor(handles,'error')
    return
  end
  if invalid
    %repeat test ONCE
    invalid = ~isempty(findstr(evriio('test'),'expired'));
  end
  if invalid
    if notonpath
      rmpath(fullfile(thisfolder,'utilities'));
    end
    msg = 'You have not entered a valid license code. Please verify you are entering the correct code for this product, click "install" and try again. If this problem persists, contact Eigenvector Research at helpdesk@eigenvector.com for more information.';
    set(handles.msgbox,'String','License Code Needed...');
    setmsgboxcolor(handles,'error')
    disp(msg)
    uiwait(errordlg(msg,'Invalid License Code'));
    uicontrol(handles.lic_edit);
    return
  end
  
  %---------------------------------------------
  %Show and confirm license
  if ~quiet
    if ~ishandle(handles.installfigure)
      errordlg([product ' Installation Canceled - For assistance please contact Eigenvector '...
        'Research via e-mail at: helpdesk@eigenvector.com'],...
        [product ' User Cancel']);
      return
    end
    set(handles.msgbox,'String','Confirming License Agreement...');
    setmsgboxcolor(handles,'ok')
    updatebar(handles); drawnow; pause(1);
  end
  
  if ~quiet & ~strcmp(getappdata(0,'licenseagreement'),'yes');
    setappdata(0,'licenseagreement','');
    res = questdlg('Installation of this product implies your full agreement with the Eigenvector Research software license. If you have not read this agreement, you must do so now before continuing. If you have read and agree to the license, click "Agree and Continue".','License Agreement','Show License','Agree and Continue','Cancel','Show License');
    switch res
      case 'Cancel'
        errordlg([product ' Installation Canceled - For assistance please contact Eigenvector '...
          'Research via e-mail at: helpdesk@eigenvector.com'],...
          [product ' User Cancel']);
        return
      case 'Show License'
        uiwait(helpdlg('After reading the license, click the "Agree and Continue" link at the bottom of the license to continue installation.','License Agreement Help'));
        web(which('license_evri.htm'));
        drawnow
        return
      case 'Agree and Continue'
        %OK... they agreed without looking at the license. Assumes agreement
        setappdata(0,'licenseagreement','yes');
    end
  end
  
  %-------------------------------------------------------------
  %Check for updates.
  if ~quiet & installpref.checkupdates
    if ~ishandle(handles.installfigure)
      errordlg([product ' Installation Canceled - For assistance please contact Eigenvector '...
        'Research via e-mail at: helpdesk@eigenvector.com'],...
        [product ' User Cancel']);
      return
    end
    set(handles.msgbox,'String','Checking for Updates...');
    setmsgboxcolor(handles,'ok')
    updatebar(handles); drawnow; pause(1);
  end
  
  if mlver>=6.5 & ~quiet
    if ~quiet & (installpref.checkupdates | exist('evriupdate.p','file'))
      setappdata(0,'PLS_Toolbox_installing',1)
      outdate = evriupdate(2,'PLS_Toolbox');
      rmappdata(0,'PLS_Toolbox_installing')
    else
      outdate = 0;
    end
    
    if installpref.checkupdates
      if outdate == 1
        if ~quiet
          helpwin(sprintf('%s\n',['Aborting Installation: a newer version of ' product ' has been released.'],'If you wish to use the latest version, you should download this now.','Otherwise, deselect the "Check for newer versions" option','in the Installation Guide window.',' ','EVRIInstall must be re-run after updating your version.'),...
            product,'Install Help');
          set(handles.msgbox,'String',['Aborting Installation: a newer version of ' product ' exists.']);
          set(handles.txtcheckupdates,'backgroundcolor',[.94 .5 .5])  %colorize the option which threw this error (so users better undstand what happened)
          setmsgboxcolor(handles,'error')
          return
        else
          error(['Aborting Installation: a newer version of ' product ' exists.']);
        end
      elseif outdate == -1
        if ~quiet
          set(handles.msgbox,'String',{['Unable to connect to internet, newer versions of ' product ' may exist.'] '*** Continuing Installation ***'});
          setmsgboxcolor(handles,'error')
          beep
          pause(2)
        end
      end
    end
  end
  
  %-------------------------------------------------------------
  %Get initial directory information.
  if nargout>0;
    out = logical(0); %assume we didn't install correctly
  end
  mypath = fileparts(which(mfilename));
  
  %Update Messages
  if ~quiet
    if ~ishandle(handles.installfigure)
      errordlg([product ' Installation Canceled - For assistance please contact Eigenvector '...
        'Research via e-mail at: helpdesk@eigenvector.com'],...
        [product ' User Cancel']);
      return
    end
    set(handles.msgbox,'String','Checking for old toolbox versions...');
    setmsgboxcolor(handles,'ok')
    updatebar(handles);drawnow;pause(1);
  end
  
  %-------------------------------------------------------------
  % Remove old versions.
  try
    
    %Use evrirelease to determine if any old versions are installed.
    my_release = evrirelease(product);
    
    if ~isempty(my_release)
      if installpref.removeold
        %Remove all products, they may (or may not) be added again below
        %depending on options selected by user.
        try
          evriuninstall('pathonly');
        catch
          %do NOT throw errors if this fails
          if ~isempty(findstr(lasterr,'Path could not be saved')) %#ok<*REMFF1>
            resp = questdlg('The path could not be saved. You need to modify permissions for the "pathdef.m" file. Please contact helpdesk@eigenvector.com for more information or click the "Help" button below.','Could Not Save Path','OK','Help','Help');
            if strcmpi(resp,'Help');
              web('http://software.eigenvector.com/faq/index.php?id=83','-browser');
              return
            else
              disp(lasterr);
            end
          end
        end
      end
    end
    
  catch
    if ~quiet
      helpwin(sprintf('%s\n',['Problems encountered during ' product ' Installation'],'EVRIInstall must be re-run after solving these problems',...
        lasterr,' ','Please contact Eigenvector Research via e-mail at: helpdesk@eigenvector.com')...
        ,product,'Install Help');
      set(handles.msgbox,'String',['' product ' Installation Failed - See Help Window']);
      setmsgboxcolor(handles,'error')
      return
    else
      error(['EVRIINSTALL error: ' lasterr]);
    end
  end
  
  %-------------------------------------------------------------
  %Add to path.
  if ~quiet
    if ~ishandle(handles.installfigure)
      errordlg([product ' Installation Canceled - For assistance please contact Eigenvector '...
        'Research via e-mail at: helpdesk@eigenvector.com'],...
        [product ' User Cancel']);
      return
    end
    set(handles.msgbox,'String','Adding toolbox to Matlab Path...');
    setmsgboxcolor(handles,'ok')
    updatebar(handles);drawnow;pause(1);
  end
  
  try
    cd(mypath);
    setpath(2);%Use flag input to setpath to move dems/uts/help folders to top of path.
    if installpref.checkotherprod;
      
      % Verify the prod(s) to install are compatible with the PLS_Toolbox
      % and remove any which are found to be incompatible
      pds = evricompatibility('install');
      
      try
        for jj = 1:length(pds)
          cd(pds(jj).folder);
          setpath(2);%Use flag input to setpath to move dems/uts/help folders to top of path.
        end
      end
      if ~isempty(pds)
        %now re-add PLS_Toolbox at top
        cd(mypath);
        setpath(2);%Use flag input to setpath to move dems/uts/help folders to top of path.
      end
    end
    rehash toolboxcache;
  catch
    if ~quiet
      helpwin(sprintf('%s\n',['Problems encountered during ' product ' Installation'],'EVRIInstall must be re-run after solving these problems',...
        lasterr,' ','Please contact Eigenvector Research via e-mail at: helpdesk@eigenvector.com')...
        ,product,'Install Help');
      set(handles.msgbox,'String',['' product ' Installation Failed - See Help Window']);
      setmsgboxcolor(handles,'error')
      return
    else
      error(['EVRIINSTALL error: ' lasterr]);
    end
  end
  
  %-------------------------------------------------------------
  %Squelch annoying warnings.
  %See evriwarningswitch
  
  %-------------------------------------------------------------
  %Set up jar files.
  setappdata(0,'PLS_Toolbox_installing',1)
  try
    evrijavasetup
  catch
    le = lasterror;
    rmappdata(0,'PLS_Toolbox_installing')
    rethrow(le);
  end
  rmappdata(0,'PLS_Toolbox_installing')
  
  %-------------------------------------------------------------
  %Test installation with EVRIDEBUG.
  if ~quiet
    if ~ishandle(handles.installfigure)
      errordlg([product ' Installation Canceled - For assistance please contact Eigenvector '...
        'Research via e-mail at: helpdesk@eigenvector.com'],...
        [product ' User Cancel']);
      return
    end
    set(handles.msgbox,'String','Testing Installation...');
    setmsgboxcolor(handles,'ok')
    updatebar(handles);drawnow;pause(1);
  end
  
  try
    [problems,problemcode] = evridebug('installing');
  catch
    if ~quiet
      helpwin(sprintf('%s\n',['Problems encountered during ' product ' Installation'],'EVRIInstall must be re-run after solving these problems',...
        lasterr,' ','Please contact Eigenvector Research via e-mail at: helpdesk@eigenvector.com')...
        ,product,'Install Help');
      set(handles.msgbox,'String',['' product ' Installation Failed - See Help Window']);
      setmsgboxcolor(handles,'error')
      return
    else
      error(['EVRIINSTALL error: ' lasterr]);
    end
  end
  
  if ~isempty(problems);
    if problemcode>1; %fatal error?
      if ~quiet
        helpwin(sprintf('%s\n',['Problems encountered during ' product ' Installation'],'EVRIInstall must be re-run after solving these problems',...
          problems{:},' ','Please contact Eigenvector Research via e-mail at: helpdesk@eigenvector.com')...
          ,product,'Install Help');
        set(handles.msgbox,'String',['' product ' Installation Failed - See Help Window']);
        setmsgboxcolor(handles,'error')
        return
      else
        error(['EVRIINSTALL error: ' lasterr]);
      end
    else
      if ~quiet
        set(handles.msgbox,'String',{'Non-Fatal Installation Problems Exist'...
          'Installation will continue, see Command Window for details.'});
        setmsgboxcolor(handles,'ok')
        pause(2)
      else
        warning('EVRIINSTALL:evridebug', ['Non-Fatal Installation Problems Exist. '...
          '\nSome functionality may not operate correctly but installation will continue. '])
      end
    end
  end
  
  %-------------------------------------------------------------
  %Set defaults.
  if ~quiet
    if ~ishandle(handles.installfigure)
      errordlg([product ' Installation Canceled - For assistance please contact Eigenvector '...
        'Research via e-mail at: helpdesk@eigenvector.com'],...
        [product ' User Cancel']);
      return
    end
    set(handles.msgbox,'String','Setting Default Preferences...');
    setmsgboxcolor(handles,'ok')
    updatebar(handles);drawnow;pause(1);
  end
  
  try
    setappdata(0,'PLS_Toolbox_installing',1)
    status = getplspref;
    if isfield(status,'evriinstall');
      status = status.evriinstall;
    else
      status = [];
    end
    if ~isfield(status,'version') | ~strcmp(status.version,evrirelease)
      setplspref('evriinstall','version',evrirelease);
      setplspref('evriinstall','date',datestr(now));
      [pth,file,ext] = fileparts(which(mfilename));
      if strcmp(ext,'.p');
        type = 'demo';
      else
        type = 'normal';
      end
      setplspref('evriinstall','type',type);
      
      %other first-time installation code here
    end
    rmappdata(0,'PLS_Toolbox_installing')
  catch
    rmappdata(0,'PLS_Toolbox_installing')
    if ~quiet
      helpwin(sprintf('%s\n',['Problems encountered during ' product ' Installation'],'EVRIInstall must be re-run after solving these problems',...
        lasterr,' ','Please contact Eigenvector Research via e-mail at: helpdesk@eigenvector.com')...
        ,product,'Install Help');
      set(handles.msgbox,'String',['' product ' Installation Failed - See Help Window']);
      setmsgboxcolor(handles,'error')
      return
    else
      error(['EVRIINSTALL error: ' lasterr]);
    end
  end
  
  %-------------------------------------------------------------
  %Configure Help
  %NOTE: EVRIHELPCONFIG should always be called after path has been set
  %becuase it uses EVRIRELEASE and needs to call the correct version when
  %configuring help.
  if ~quiet
    if ~ishandle(handles.installfigure)
      errordlg([product ' Installation Canceled - For assistance please contact Eigenvector '...
        'Research via e-mail at: helpdesk@eigenvector.com'],...
        [product ' User Cancel']);
      return
    end
    set(handles.msgbox,'String','Configuring Help...');
    setmsgboxcolor(handles,'ok')
    updatebar(handles);drawnow;pause(1);
  end
  
  %If using UNIX, edit xml help location to UNIX friendly relative path.
  try
    evrihelpconfig
  catch
    if ~quiet
      set(handles.msgbox,'String',['Unable to configure ' product ' Help. Please contact Eigenvector Research via e-mail at: helpdesk@eigenvector.com'],[product ' Installation']);
      setmsgboxcolor(handles,'error')
      drawnow;
    else
      error(['EVRIINSTALL error: ' lasterr]);
    end
  end
  
  %-------------------------------------------------------------
  %Final Steps
  if ~quiet
    try
      browse %bring up Workspace Browser
      uiwait(helpdlg({'We have automatically started the PLS_Workspace Browser so you can get started working with PLS_Toolbox. In the future, you can start this manually by using the command:',' ','>> browse',' ','at the Matlab command line.'},'Workspace Browser Started'));
    catch
      try
        helppls %bring up help pls screen
      catch
        warning('EVRI:InstallHelpFailure','Unable to start PLS_Toolbox help.') %#ok<*WNTAG>
      end
    end
  end
  
  drawnow;
  if ~quiet
    if ~ishandle(handles.installfigure)
      errordlg([product ' Installation Canceled - For assistance please contact Eigenvector '...
        'Research via e-mail at: helpdesk@eigenvector.com'],...
        [product ' User Cancel']);
      return
    end
    updatebar(handles,1);
    set(handles.msgbox,'String',{[product ' Successfully Installed! (License: ' evriio('test') ')'] 'Some documentation features will not be available until you restart Matlab.'})
    setmsgboxcolor(handles,'ok')
    mychild = get(handles.installfigure,'children');
    mychild = mychild(~ismember(mychild,handles.plslogo));
    set(mychild,'Enable','off')
    set([handles.msgbox handles.evrilogo handles.evriinfo],'Enable','on')
    set(handles.cancelbutton,'String','Done','Enable','on')
    figure(handles.installfigure)%Bring to front.
  end
  drawnow;
  
  cd(curdir);%Back to orginal calling directory.
  
  if nargout>0;
    out = logical(1); %#ok<*LOGL> %successful installation
  end
  
catch
  if ~quiet
    [release,product] = evrirelease;
    h = errordlg([product ' Installation Failed - Please contact Eigenvector Research via e-mail at: helpdesk@eigenvector.com  Last Error: ' lasterr],[product ' Installation Error']);
    %Delete waitbar fig if exists.
    if exist('handles','var') && isfield(handles,'installfigure')
      trydelete(handles.installfigure)
    end
  else
    error(['EVRIINSTALL error: ' lasterr]);
  end
end

%==================================================
function out = mlver
out  = version;
out  = str2num(out(1:3));

%==================================================
function trydelete(handle)
if ishandle(handle)
  delete(handle)
end

%==================================================
function waitbarh = stepwb(waitbarh,string,step_number)
%Manage waitbar. Need to handle situations where waitbar handle is not
%available.


%Current total number of steps.
steps=7;

if ishandle(waitbarh)
  htitle = get(findobj(waitbarh,'type','axes'),'title');
  set(htitle,'string',string);
  waitbar(step_number/steps);
  
else
  waitbarh = waitbar(0);
  htitle = get(findobj(waitbarh,'type','axes'),'title');
  set(htitle,'string',string);
  waitbar(step_number/steps);
  
end

%--------------------------------------
function out = encodeversion(str) %#ok<*DEFNU>

out = [];
rem = str;
while ~isempty(rem);
  [n,rem] = strtok(rem,'.');  %#ok<*STTOK> %parse for periods
  nonnum = min(find(n>'9'));%any non-numeric characters?
  if ~isempty(nonnum);
    n = str2num(n(1:nonnum-1))+double(n(nonnum:end))/256;  %#ok<*ST2NM> %convert to decimal
  else
    n = str2num(n);
  end
  out(end+1) = n;
end
if isempty(out);
  out = 0;
end

%--------------------------------------
function out = createfig(str)
%Create installation dialog figure. Replaces multiple dialog boxes of
%existing installation process.

fwidth  = 630;
fheight = 290;

%Change font size to smaller for Mac so longer messages fit in message box.

[v,p] = evrirelease;

dfp = get(0,'defaultfigureposition');
fig = figure('tag','installfigure','visible','off',...
  'units','pixel','position',[dfp(1) dfp(2) fwidth fheight],...
  'toolbar','none','menubar','none',...
  'color',[.8 .8 .8],...
  'name',[p ' ' v ' Installation Guide'],...
  'IntegerHandle','off','numbertitle','off','resize','off');
centerfigure(fig);
set(fig,'visible','on')
fpos = get(fig,'position'); %figure postion [left bottom width height]
fcolor = get(fig,'color');

%Add initial path as appdata so gui can know where it's suppose to call from.
mypath = fileparts(which(mfilename));
setappdata(fig,'mypath',mypath)

%---- Create Logo Area
%Create Eigenvector logo.
[logoimg logomap] = imread(['help' filesep 'smallevri.gif']);
logocdata = ind2rgb(logoimg,logomap);
logoh = uicontrol(fig,'tag','evrilogo','style','pushbutton','position',[fpos(3)-190 fpos(4)-36 187 35],...
  'cdata',logocdata,'enable','on','callback','web(''http://www.eigenvector.com'',''-browser'');');

%Create text box below logo with additional information.
texth = uicontrol(fig,'tag','evriinfo','style','text','position',[fpos(3)-190 fpos(4)-90 187 88-35],...
  'enable','inactive','string',msgstr('adinfo'),...
  'FontSize',10,'HorizontalAlignment','left',...
  'backgroundcolor',fcolor,'fontweight','bold');
makelogo(fig);

%---- Create License Input area.
lic_frame = uicontrol(fig,'style','frame','tag','lic_frame','units','pixels',...
  'position',[4 fpos(4)-62 fpos(3)-200 60],'BackgroundColor',fcolor);

lic_text = uicontrol(fig,'tag','lic_text',...
  'units','pixels',...
  'style','text','position',[8 fpos(4)-34 fpos(3)-206 28],...
  'HorizontalAlignment','left',...
  'backgroundcolor',fcolor,...
  'FontWeight','bold',...
  'string',{'1) Paste license code below and verify.'});

lic_edit = uicontrol(fig,'tag','lic_edit',...
  'units','pixels',...
  'style','edit','position',[8 fpos(4)-54 fpos(3)-306 24],...
  'HorizontalAlignment','left',...
  'backgroundcolor','white',...
  'buttondownfcn','cd(getappdata(gcf,''mypath''));evriinstall(''callback'',''lictext_Callback'',gcbo,[],guihandles(gcbo),[])',...
  'string',{'<paste license code here>'});

lic_btn = uicontrol(fig,'tag','lic_btn',...
  'units','pixels',...
  'style','pushbutton','position',[fpos(3)-298 fpos(4)-54 100 24],...
  'HorizontalAlignment','left',...
  'backgroundcolor','white',...
  'Callback','cd(getappdata(gcf,''mypath''));evriinstall(''callback'',''checklicense_Callback'',gcbo,[],guihandles(gcbo),[]);',...
  'string',{'Check'});


%---- Create Option CheckBox Area
opts_frame = uicontrol(fig,'style','frame','tag','opts_frame','units','pixels',...
  'position',[4 fpos(4)-200 fpos(3)-200 134],'BackgroundColor',fcolor);

opts_text = uicontrol(fig,'tag','opts_text',...
  'units','pixels',...
  'style','text','position',[8 fpos(4)-100 fpos(3)-206 30],...
  'HorizontalAlignment','left',...
  'backgroundcolor',fcolor,...
  'FontWeight','bold',...
  'string',{'2) Select options for installation by checking the box next to each option.'}); %#ok<*NASGU>

%Add 3 text/radio button controls for setup options.
%Two controls per row, text explanation, button accept, button cancel.
ctrlist = {'removeold' 'checkotherprod' 'checkupdates'};

botpos  = fpos(4) - 130; %bottom box minus 2 pixel border and 29 pixel box height.
leftpos = 8; %left side width of logo plus 2x2 pixel border.
wdth    = fwidth-240; %width - 30 for checkbox.
hght    = 28;

for i = 1:length(ctrlist)
  callback = ['set(findobj(gcbf,''tag'',[''cbox_' ctrlist{i} ''']),''value'',~get(findobj(gcbf,''tag'',[''cbox_' ctrlist{i} ''']),''value''))'];
  tb1 = uicontrol(fig,'tag',['txt' ctrlist{i}],...
    'style','text','position',[leftpos botpos wdth hght],...
    'HorizontalAlignment','left',...
    'backgroundcolor',[.94 .94 .94],...
    'enable','inactive',...
    'buttondownfcn',callback,...
    'string',msgstr(ctrlist{i}));
  pb1 = uicontrol(fig,'tag',['cbox_' ctrlist{i}],...
    'style','checkbox','position',[leftpos+wdth+2 botpos 18 hght],...
    'backgroundcolor',[0 0 0],...
    'value',1,...
    'HorizontalAlignment','left');
  botpos = botpos - 30;
end


%---- Bottom Message/Button Area
install_frame = uicontrol(fig,'style','frame','tag','install_frame','units','pixels',...
  'position',[4 28 fpos(3)-8 58],'BackgroundColor',get(fig,'color'));

install_text = uicontrol(fig,'tag','install_text',...
  'units','pixels',...
  'style','text','position',[8 50 fpos(3)-206 30],...
  'HorizontalAlignment','left',...
  'backgroundcolor',fcolor,...
  'FontWeight','bold',...
  'string',{'3) Click Install to begin the installation.'});

%Create 2 buttons for install and cancel.
instbtn = uicontrol(fig,'tag','installbutton',...
  'style','pushbutton','position',[fpos(3)-206 32 100 30],...
  'HorizontalAlignment','left',...
  'Callback','cd(getappdata(gcf,''mypath''));evriinstall(''callback'',''install_Callback'',gcbo,[],guihandles(gcbo),[])',...
  'string','Install');
cnclbtn = uicontrol(fig,'tag','cancelbutton',...
  'style','pushbutton','position',[fpos(3)-106 32 100 30],...
  'HorizontalAlignment','left',...
  'Callback','cd(getappdata(gcf,''mypath''));evriinstall(''callback'',''cancel_Callback'',gcbo,[],guihandles(gcbo),[])',...
  'string','Cancel');

%Set to size 8 so longest message will fit in box. Little small on Mac but looks fine on Windows.
if ispc
  txtsize = 8;
else
  txtsize = 10;
end

% %Create output message area.
msgbox = uicontrol(fig,'tag','msgbox',...
  'style','text','position',[8 32 fpos(3)-218 28],...
  'HorizontalAlignment','left',...
  'FontSize',txtsize,...
  'backgroundcolor',[1 1 1],...
  'string',{'Installation setup.'});

%Create mimicked wait bar.
nbar = uicontrol(fig,'tag','fullbar','style','frame','position',[4 3 fpos(3)-6 20]);
ibar = uicontrol(fig,'tag','incbar','style','frame','position',[4 3 .01 20],'backgroundcolor',[1 0 0]);

handles = guihandles(fig);
checklicense_Callback(fig,[],handles);

out = fig;
%--------------------------------------
function updatebar(handles,fill)
%Increment bar by 1/n, fill = 1 will fill out bar fill = 0 will reset to start

full = get(handles.fullbar,'position');
ibar = get(handles.incbar,'position');

inc = full(3)/7;
ibar(3) = ibar(3)+inc;

if nargin>1 & fill == 0;
  ibar(3) = 0.01;
end

if full(3)>ibar(3) | (nargin>1 & ~fill)
  set(handles.incbar,'position',ibar);
else
  set(handles.incbar,'position',full);
end

%--------------------------------------
function setmsgboxcolor(handles,mode)

if ~isfield(handles,'msgbox')
  return
end

switch mode
  case 'error'
    clr = [1 .4 .4];
  otherwise
    clr = [1 1 1];
end
set(handles.msgbox,'backgroundcolor',clr)

%--------------------------------------
function out = msgstr(str)
% Returns string for text box or display.
[release,product] = evrirelease;
switch str
  case 'removeold'
    out = 'Remove older versions of Eigenvector software from path [Recommended].';
  case 'checkotherprod'
    out = 'Install additional Eigenvector products found in this folder.';
  case 'checkupdates'
    out = 'Check for newer versions of software [requires Internet connection]. Installation is aborted if newer version is found.';
  case 'adinfo'
    out = {'> Consulting' '> Short Courses' '> Additional Software Tools'};
end

%--------------------------------------
function install_Callback(h, eventdata, handles, varargin)
handles = guihandles(h);

out = checklicense_Callback(h, eventdata, handles, varargin);
if out ==0
  %Bad license code.
  warndlg('License code entered is not valid for this version of PLS_Toolbox. Please check your code and try again.','Check License')
  return
end


set([handles.installbutton handles.cancelbutton],'enable','off');
evriinstall('install',handles);
if ishandle(handles.cancelbutton) & strcmp(get(handles.cancelbutton,'enable'),'off');
  %if cancel is disabled, we didn't get to end without error
  set([handles.installbutton handles.cancelbutton],'enable','on');
end
%--------------------------------------
function cancel_Callback(h, eventdata, handles, varargin)
close(handles.installfigure);

%--------------------------------------
function lictext_Callback(h, eventdata, handles, varargin)

%--------------------------------------
function out = checklicense_Callback(h, eventdata, handles, varargin)
%Check for existing license and if it's valid, if so disable check box.
% Output 'out' indicates license is good.

out = 0;

%Check for valid license file.
base_folder = fileparts(which(mfilename));
util_folder = fullfile(base_folder,'utilities');
lic_file = fullfile(util_folder,'evrilicense.lic');

if exist(lic_file,'file')
  %Check file.
  msg = evriio_test(util_folder,lic_file,'validatelicense');
  if ~isempty(msg)
    %Invalid license file, rename file so user can continue with manual (pasted) code if needed.
    try
      movefile(lic_file,fullfile(base_folder,'utilities','evrilicense_invalid.lic'));
      set(handles.msgbox,'String','An invalid license file has been detected in PLS_Toolbox/utilties folder. The file has been renamed to "evrilicense.lic.notvalid" please enter a new license code.');
      setmsgboxcolor(handles,'error')
      %Need to clear pref and appdata(0) too since the file code will exist
      %in both [use code from evriclearlicense].
      setpref('EVRI','license',[]);
      setappdata(0,'EVRI_license',[]);
      clear evriio
      %TODO: Check with Jeremy about LM commands in evriclearlicense.
    catch
      msg = 'An invalid license file has been detected in PLS_Toolbox/utilties folder but we were unable to rename it. Please delete this file and re-run evriinstall.';
      set(handles.msgbox,'String',msg);
      setmsgboxcolor(handles,'error')
      set(handles.lic_edit,'String','<INVALID License File Found - cannot continue>','enable','off');
      errordlg(msg,'Invalid License File');
      return
    end
  else
    set(handles.lic_edit,'String','<Valid License File Found>','enable','off');
    set(handles.msgbox,'String','Existing license file is valid, proceed to step 2.');
    setmsgboxcolor(handles,'ok')
    out = 1;
    return
  end
end

%Get existing code.
if ispref('EVRI','license')
  ecode = getpref('EVRI','license');
else
  ecode = [];
end

ncode = get(handles.lic_edit,'String');
if iscell(ncode)
  ncode = ncode{1};
end
%Trim spaces out of code.
ncode = strtrim(ncode);

%Always let manually entered code take precedence.
if isempty(ncode) || strcmpi(ncode,'<paste license code here>')
  if ~isempty(ecode)
    msg = evriio_test(util_folder,ecode,'validatelicense');
    if isempty(msg)
      %Existing code is good.
      set(handles.lic_edit,'String',ecode);
      set(handles.msgbox,'String',{'Existing license code is valid, proceed to step 2.'});
      setmsgboxcolor(handles,'ok')
      out = 1;
    end
  end
else
  msg = evriio_test(util_folder,ncode,'validatelicense');
  if isempty(msg)
    %Good code, move on.
    %set(handles.lic_edit,'enable','off');
    set(handles.msgbox,'String',{'New license code is valid, proceed to step 2.'});
    setmsgboxcolor(handles,'ok')
    setpref('EVRI','license',ncode);
    setappdata(0,'EVRI_license',ncode);
    clear evriio
    z=evriio_test(util_folder,'test');%Utilities folder should be on the path but will ask for new code if not. 
    out = 1;
  else
    set(handles.msgbox,'String',msg);
    if size(msg,1)>1
      uiwait(errordlg(msg,'License Code Error'));
      set(handles.msgbox,'buttondownfcn','errordlg(get(gcbo,''string''),''License Code Error'')')
    end
    setmsgboxcolor(handles,'error')
    uicontrol(handles.lic_edit);
  end
end

%--------------------------------------
function varargout = evriio_test(util_folder,varargin)
%allows calls to evriio before we've added anything to the path

%not current folder and set working folder to utilties folder name passed
pcd = pwd;
cd(util_folder);

le = [];
try
  %try call to evriio as instructed
  if nargout>0
    [varargout{1:nargout}] = evriio(varargin{:});
  else
    evriio(varargin{:});
  end
catch
  %got error? note it for rethrow after we reset working directory
  le = lasterror;
end

cd(pcd);  %restore working directory
if ~isempty(le)
  %rethrow any errors we got from evriio
  rethrow(le)
end

%--------------------------------------
function makelogo(fh)
%Make logo.
fpos = get(fh,'position');
nmap = []; p = [];  %replaced by plslogo.mat contents (assigned here to squelch errors)

thisfolder = fileparts(which(mfilename));
logofile = fullfile(thisfolder,'dems','plslogo.mat');

try
  %If dems folder is missing this will fail. Don't make fatal error in case
  %dems folder is around but has different name. User will see error later
  %in installation process indicating missing folder.
  load(logofile);
end

ax = axes('parent',fh,...
  'tag','plslogo',...
  'CameraPosition', [45 20 22],...
  'CameraTarget',[21 7 7], ...
  'CameraUpVector',[0 0 1], ...
  'CameraViewAngle',57, ...
  'DataAspectRatio', [1 .5 .9],...
  'units','pixels',...
  'position',[fpos(3)-180 fpos(4)-196 150 120], ...
  'color',get(fh,'color'),...
  'Visible','on', ...
  'XLim',[1 42], ...
  'YLim',[1 15], ...
  'ZLim',[0 20], ...
  'Xtick',[1 21 41], ...
  'Xticklabel',['MLR';'PLS';'PCR'],...
  'fontname','times', ...
  'fontsize',8);
%	'Zscale','log');
s = surface(p', ...
  'parent',ax,...
  'EdgeColor',[.4 0 0], ...
  'FaceColor',[0.8 0.2 0.2], ...
  'FaceLighting','phong', ...
  'AmbientStrength',0.3, ...
  'DiffuseStrength',0.6, ...
  'Clipping','off',...
  'BackFaceLighting','lit', ...
  'SpecularStrength',1, ...
  'SpecularColorReflectance',1, ...
  'SpecularExponent',7);
l1 = light('Position',[21 7 13], ...
  'style','local', ...
  'Color',[0.8 0.7 0]);
l2 = light('Position',[25 11 25], ...
  'Color',[1 1 0]);
% xl = xlabel('Parameter','fontname','arial', ...
% 'fontsize',9,'fontweight','bold','position',[30 20 0]);
% yl = ylabel('LVs','fontname','arial', ...
% 'fontsize',9,'fontweight','bold','position',[36 0 -8.9]);
% zl = zlabel('PRESS','fontname','arial', ...
% 'fontsize',9,'fontweight','bold');
shading interp
set(s,'Edgecolor',[.2 .2 .2])
colormap(nmap)
set(s,'buttondownfcn','web(''http://www.eigenvector.com'',''-browser'')');

%--------------------------------------
function update_evriio(fh)
%Make sure correct version of evriio.p is enabled.
%If installing on olderversion, rename older version of "evriio_2007b.p" to
%"evriio.m" AND "evriio.p" to "evriio_new.p". 


%MATLAB can retain old files in memory between restarts so need to rehash
%here. 2011a pre release showed this behavior when installing full version
%over a demo (pls 6.2). 
try
  rehash toolboxcache
end

thisfolder = fileparts(which(mfilename));

if checkmlversion('<','7.5')
  if exist(fullfile(thisfolder,'utilities','evriio_new.p'),'file')
    %We've already run through this code.
    return
  end
  %Need to change to older version for p-code format for Matlab 2007b and older.
  try
    %Rename new evriio
    movefile(fullfile(thisfolder,'utilities','evriio.p'),fullfile(thisfolder,'utilities','evriio_new.p'));
    %Rename old evriio
    movefile(fullfile(thisfolder,'utilities','evriio_2007b.p'),fullfile(thisfolder,'utilities','evriio.p'));
  catch
    errordlg('For versions of Matlab 2007b and older, the evriio_2007b.p must be renamed to evriio.p. Rename the existing evriio.p file to evriio_new.p. If file is missing re-download the application.','EVRIIO.P File Error');
  end
end

%--------------------------------------
function checkprerelease
%Check release info for prerelease of Matlab and warn. Only do this once
%per startup.

myver    = ver('Matlab');
% verNames = {myver.Name};
% ind      = ~cellfun(@(x)isempty(x), regexpi(verNames, '^matlab$'));
% myver    = myver(ind);
% the above code will work for the general case if Matlab is not the first
% output from the call to ver('Matlab') above
myver    = myver(1);
if ~isempty(strfind(myver.Release,'Prerelease')) & isempty(getappdata(0,'PLS_Toolbox_prereleasewarn'))
  resp = questdlg('Installing Eigenvector products with a Matlab Prerelease is not supported. Product may not install or opperate correctly. Eigenvector Research may refuse support in this version.','Matlab Prerelease Unsupported','Cancel','Continue','Cancel');
  if ~strcmpi(resp,'continue');
    error('Installation Aborted - Prerelease Not Supported');
  end
  setappdata(0,'PLS_Toolbox_prereleasewarn',1)
  return;
end

[junk,junk,mltest] = evricompatibility('matlab');
if ~isempty(mltest)& isempty(getappdata(0,'PLS_Toolbox_mlverwarn')) & isempty(getappdata(0,'PLS_Toolbox_prereleasewarn'))
  resp = questdlg(['This ' mltest{1} ', is not supported and may not install or work correctly. Eigenvector Research may refuse support in this version.'],'Matlab Version Unsupported','Cancel','Continue','Cancel');
  if ~strcmpi(resp,'continue');
    error(['Installation Aborted - ' mltest{1}]);
  end
  setappdata(0,'PLS_Toolbox_mlverwarn',1)
end


function [password, username] = evripassworddialog(varargin)
%EVRIPASSWORDDIALOG - Password verfication dialog box.
%
% INPUTS (optional name/value pairs):
%  showusername     : [{true}| false] - Show username field.
%  defaultusername  : {''} - Default user name.
%  validatepassword : [true|{false} - Show second password field to verfiy.
%  windowname       : {'Login'} - Name of window.
%  minlength        : {6} - minimum length of password.
%
%I/O: [password, username] = evripassworddialog();
%I/O: [password] = evripassworddialog('showusername',false);
%I/O: [password] = evripassworddialog('defaultusername','Bob','windowname','Password Login');
%
%See also: ERDLGPLS, EVRIWARNDLG, EVRIQUESTDLG, QUESTDLG

%Copyright Eigenvector Research, Inc. 2020
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 1 && ismember(varargin{1},evriio([],'validtopics'))
  options = [];
  options.showusername = true;
  options.validatepassword = false;
  options.defaultusername = '';
  options.windowname = 'Login';
  options.minlength = 6;
  
  if nargout==0;
    evriio(mfilename,varargin{1},options);
  else
    password = evriio(mfilename,varargin{1},options);
  end
  return;
end


if inevriautomation
  %in automation, skip message
  if nargout>0
    password = '';
  end
  return
end

%Get defaults and use in parser.
options = evripassworddialog('options');

%Parse inputs.
myparser = inputParser;
myparser.KeepUnmatched = true;
myparser.addParamValue('showusername', options.showusername, @(x) islogical(x) || isnumeric(x));
myparser.addParamValue('validatepassword', options.validatepassword, @(x) islogical(x) || isnumeric(x));
myparser.addParamValue('defaultusername', options.defaultusername, @ischar);
myparser.addParamValue('windowname', options.windowname, @ischar);
myparser.addParamValue('minlength', options.minlength, @(x) isnumeric(x) && isscalar(x) && (x > 0));

% Parse Input Arguments
try
  myparser.parse(varargin{:});
catch Error
  myparser.parse;
  if strcmpi(Error.identifier, 'MATLAB:InputParser:ArgumentFailedValidation')
    error(Error.identifier, Error.message);
  end
end

myoptions = myparser.Results;

windowsize = [0 0 330 85];
if myoptions.showusername
  windowsize = windowsize + [0 0 0 30];
end
if myoptions.validatepassword
  windowsize = windowsize + [0 0 0 60];
end;

handles.fig = figure('Menubar','none', ...
  'Visible','off',...
  'Units','pixels', ...
  'Resize','off', ...
  'NumberTitle','off', ...
  'Name',myoptions.windowname, ...
  'Position',windowsize, ...
  'CloseRequestFcn', @closeFcn, ...
  'WindowStyle', 'modal', ...
  'KeyPressFcn',[]);

movegui(handles.fig,'center')

%Get fig color so can decorate text boxes, this is needed for older
%versions of Matlab.
figcolor = get(handles.fig,'Color');

%Starting password.
password = '';

%User cancel.
canceled = false;

mybottom = 45;
if myoptions.validatepassword
  %Add password verification controls.
  handles.text_MatchPassword = uicontrol('Parent',handles.fig, ...
    'Tag', 'text_LabelPassword', ...
    'Style','Text', ...
    'Units','Pixels',...
    'BackgroundColor',figcolor,...
    'Position',[10 mybottom 130 20], ...
    'FontSize',10, ...
    'String','Password Match:',...
    'HorizontalAlignment', 'Left');
  
  handles.text_MatchYesNo = uicontrol('Parent',handles.fig, ...
    'Tag', 'text_LabelPassword', ...
    'Style','Text', ...
    'Units','Pixels',...
    'BackgroundColor',figcolor,...
    'Position',[140 mybottom 80 20], ...
    'FontSize',10, ...
    'FontWeight','Bold',...
    'String','No',...
    'ForegroundColor','red',...
    'HorizontalAlignment', 'Left');
  
  mybottom = mybottom+30;
  
  %Have to use java text field because Matlab edit box won't issue callback
  %after character is typed.
  handles.java_Password2 = javax.swing.JPasswordField();
  [handles.java_Password2, handles.edit_Password2] = javacomponent(handles.java_Password2, [140 mybottom 180 25], handles.fig);
  handles.java_Password2.setFocusable(true);
  set(handles.edit_Password2, ...
    'Parent', handles.fig, ...
    'Tag', 'edit_Password2', ...
    'BackgroundColor',[1 1 1],...
    'Units', 'Pixels', ...
    'Position',[140 mybottom 180 25]);
  
  %Use this to capture typeing AND pasting to dynamically check if passwords
  %match.
  set(handles.java_Password2,'KeyReleasedCallback',@passwordKeyFcn)
  
  handles.text_LabelPassword = uicontrol('Parent',handles.fig, ...
    'Tag', 'text_LabelPassword2', ...
    'Style','Text', ...
    'Units','Pixels',...
    'BackgroundColor',figcolor,...
    'Position',[10 mybottom+2 130 20], ...
    'FontSize',10, ...
    'String','Verify Password:',...
    'HorizontalAlignment', 'Left');
  
  mybottom = mybottom+30;
  
end


%Have to use java text field because Matlab edit box won't issue callback
%after character is typed.
handles.java_Password = javax.swing.JPasswordField();
[handles.java_Password, handles.edit_Password] = javacomponent(handles.java_Password, [140 mybottom 180 25], handles.fig);
handles.java_Password.setFocusable(true);
set(handles.edit_Password, ...
  'Parent', handles.fig, ...
  'Tag', 'edit_Password', ...
  'BackgroundColor',[1 1 1],...
  'Units', 'Pixels', ...
  'Position',[140 mybottom 180 25]);

%Use this to capture typeing AND pasting to dynamically check if passwords
%match.
set(handles.java_Password,'KeyReleasedCallback',@passwordKeyFcn)

handles.text_LabelPassword = uicontrol('Parent',handles.fig, ...
  'Tag', 'text_LabelPassword', ...
  'Style','Text', ...
  'Units','Pixels',...
  'BackgroundColor',figcolor,...
  'Position',[10 mybottom+2 130 20], ...
  'FontSize',10, ...
  'String','Enter Password:',...
  'HorizontalAlignment', 'Left');


handles.pushbutton_OK = uicontrol('Parent',handles.fig, ...
  'Tag', 'pushbutton_OK', ...
  'Style','Pushbutton', ...
  'Units','Pixels',...
  'Position',[155 5 80 30], ...
  'FontSize',10, ...
  'String','OK',...
  'Callback',@buttonPressFcn,...
  'HorizontalAlignment', 'Center');

handles.pushbutton_Cancel = uicontrol('Parent',handles.fig, ...
  'Tag', 'pushbutton_Cancel', ...
  'Style','Pushbutton', ...
  'Units','Pixels',...
  'Position',[240 5 80 30], ...
  'FontSize',10, ...
  'String','Cancel',...
  'Callback',@buttonPressFcn,...
  'HorizontalAlignment', 'Center');

%Add user name if needed.
if myoptions.showusername
  mybottom = mybottom + 40;
  handles.edit_username = uicontrol('Parent',handles.fig, ...
    'Tag', 'edit_username', ...
    'Style','Edit', ...
    'Units','Pixels',...
    'Position',[140 mybottom 180 25], ...
    'FontSize',10, ...
    'String','',...
    'KeyPressFcn',[],...
    'HorizontalAlignment', 'Left');
  
  handles.text_username  = uicontrol('Parent',handles.fig, ...
    'Tag', 'text_username', ...
    'Style','Text', ...
    'Units','Pixels',...
    'Position',[10 mybottom+2 130 20], ...
    'BackgroundColor',figcolor,...
    'FontSize',10, ...
    'String','Enter Username:',...
    'HorizontalAlignment', 'Left');
  if ~isempty(myoptions.defaultusername)
    set(handles.edit_username,'String',myoptions.defaultusername)
    %TODO: Maybe set editable 'off' here to force username.
  end
  
end

%Bump font.
chld = findall(allchild(handles.fig),'-property','Fontsize');
set(chld,'Fontsize',getdefaultfontsize);
set(handles.fig,'visible','on');

uiwait(handles.fig);
username = '';
if canceled
  password = '';
end

if myoptions.showusername && ishandle(handles.edit_username)
  username = get(handles.edit_username,'String');
end

if ishandle(handles.fig)
  delete(handles.fig);
end

%% Nested Functions

%--------------------------------------------------------------------------
  function closeFcn(obj, edata) %#ok<INUSD>
    canceled = true;
    delete(obj);
  end

%--------------------------------------------------------------------------
  function buttonPressFcn(obj, edata) %#ok<INUSD>
    switch get(obj,'Tag')
      case 'pushbutton_Cancel'
        canceled = true;
      case 'pushbutton_OK'
        password = handles.java_Password.Password';
        %Check info.
        if myoptions.showusername
          username = strtrim(get(handles.edit_username,'String'));
          if isempty(username)
            evriwarndlg('Username is blank.','Warning');
            return
          end
        end
        
        %Final check for match.
        if ~passwordCheckMatch
          evriwarndlg(['Password does not match validation password.'],'Warning');
          return
        end
        
        %Check for min length.
        if length(password)<myoptions.minlength
          evriwarndlg(['Password must be minimum of ' num2str(myoptions.minlength) ' characters long.'],'Warning');
          return
        end
        
        %Check for invalid characters.
        for i = 1:length(password)
          mychar = password(i);
          if mychar >= '!' && mychar <= '}'
            %Do nothing.
          else
            evriwarndlg(['Invalid password character (' mychar ').'],'Warning');
            return
          end
        end
        
        
    end
    uiresume(handles.fig);
  end
%--------------------------------------------------------------------------
  function mymatch = passwordCheckMatch()
    %Check to see if validation is on and if passwords match. Adjust match
    %indicator.
    
    mymatch = [];
    if myoptions.validatepassword
      p1 = handles.java_Password.Password';
      p2 = handles.java_Password2.Password';
      if length(p1)==length(p2) && all(p1==p2)
        mymatch = true;
        set(handles.text_MatchYesNo,'String','Yes','ForegroundColor','green');
      else
        mymatch = false;
        set(handles.text_MatchYesNo,'String','No','ForegroundColor','red');
      end
    end
    
  end
%--------------------------------------------------------------------------
  function passwordKeyFcn(obj, edata)
    %Dynamically check if passwords match and update . This function call
    %after anything happens in pw field including paste action. It was
    %difficult to get a paste recognized so this function was added to the
    %keyup callback.
    passwordCheckMatch;
  end

end



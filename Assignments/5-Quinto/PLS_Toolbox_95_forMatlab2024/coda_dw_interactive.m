function varargout = coda_dw_interactive(varargin);
%CODA_DW_INTERACTIVE Interactive version of CODA_DW.
%The function calculates values for the Durbin_Watson criterion of columns of data set.
%The better the quality, the lower the Durbin-Watson value.
%The function is normally used for LC/MS data. Plotting variables with a
%low Durbion_Watson value eliminates solvent peaks.
%This interactive program provides interactive loading of data, setting of
%the parameters and interactive plotting options.
%I/O: coda_dw_interactive
%
%See also: CODA_DW

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%ww
%rsk 07/20/04 Add code for cancel loaddlg, returns to commandline.
%rsk 07/27/04 Major revisions for test release in 3.5.
%ww 06/27/04 changed limit from (ncols-1) to ncols in line 875

%functions used:
%CODA_DW

if nargin>0 & ischar(varargin{1}) & ismember(varargin{1},evriio([],'validtopics'));
  %options=define_options;
  options=[];
  if nargout==0; 
    evriio(mfilename,varargin{1},options); 
  else;
    varargout{1} = evriio(mfilename,varargin{1},options); 
  end;
  return 
elseif nargin==2;
  if strcmp(varargin{1},'close_cb')
    close_cb(varargin{2});
    return;
  end
  if strcmp(varargin{1},'delete_spec')
    delete_spec(varargin{2});
    return;
  end
  coda_dw_callback(varargin{:});
  return;
elseif nargin==3;
  if strcmp(varargin{1},'load_cb')
    load_cb(varargin{2},varargin{3});
  return;
  end
end;

%USED FOR PROGRAMMING ONLY

test=0;

%READ FILE

if test==1;
  userdata.data=read_dso('C:\data\Windig_toolbox\eigenvector\dems\lcms.mat');
  
else;
  %     [filename,pathname]=uigetfile('*.mat','Read File');
  %     userdata.data=read_dso([pathname,filename]);
  %   userdata.data = lddlgpls('doubdataset');
  %   if isempty(userdata.data)
  %     return;
  %   end
  %   if ~isa(userdata.data,'dataset');
  %     userdata.data = dataset(userdata.data);
  %   end
  if nargin==1 & (isnumeric(varargin{1}) || isdataset(varargin{1}))
    userdata.data = varargin{1};
  else
    userdata = load_cb([],0);
    if isempty(userdata.data)
      return
    end
  end
  if ~isdataset(userdata.data);
    userdata.data = dataset(userdata.data);
  end

end

% Return to command line if no data loaded.
if isempty(userdata.data)
  return;
end

%INITIALIZATIONS

[nrows,ncols]=size(userdata.data.data);
if isempty(userdata.data.axisscale{1});userdata.data.axisscale{1}=[1:nrows];end;
if isempty(userdata.data.axisscale{2});userdata.data.axisscale{2}=[1:ncols];end;

%CREATE FIGURE FOR MENU

userdata.arg.handle_fig_menu_main=create_fig('handle_fig_menu_main');
set(gcf,'backingstore','off');
set(userdata.arg.handle_fig_menu_main,'menubar','none','units','normalize','CloseRequestFcn'...
  ,'coda_dw_interactive(''close_cb'',gcf)','name','Coda DW Menu','NumberTitle','off');

%CREATE MENU

userdata=create_menu(userdata);

%CREATE FIGURE FOR PLOT

userdata.arg.handle_fig_plot_main=create_fig('handle_fig_plot_main');
set(gcf,'backingstore','off');
set(userdata.arg.handle_fig_plot_main,'CloseRequestFcn','coda_dw_interactive(''close_cb'',gcf)'...
  ,'name','Coda DW Analysis','NumberTitle','off');

%Don't have figbroser menu show up before file menu.
delete(findobj(userdata.arg.handle_fig_menu_main,'tag','figbrowsermenu'));
  
%CREATE MENU
menuh = uimenu(userdata.arg.handle_fig_menu_main,'label','File');
uimenu(menuh,'label','Load Data','callback','coda_dw_interactive(''load_cb'',gcf,1)');
uimenu(menuh,'label','Close','callback','coda_dw_interactive(''close_cb'',gcf)','separator','on');

%Uncomment if we want figbrowser on Coda menu window.
%figbrowser('addmenu',userdata.arg.handle_fig_menu_main)

%PLOT DATA ANALYSIS RESULTS

userdata=plot_results(userdata);

%SET HANDLESVISIBILITY TO CALLBACK

set(userdata.arg.handle_fig_menu_main,'handlevisibility','callback');
set(userdata.arg.handle_fig_plot_main,'handlevisibility','callback');

%STORE INFO IN USERDATA

set(userdata.arg.handle_fig_menu_main,'userdata',userdata);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [values, root_name]=read_dso(fn);

values=load(fn);
root_name=fieldnames(values);
values=getfield(values,root_name{1});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function handle=create_fig(tag);

handle = findobj('tag',tag);
if isempty(handle)
  handle = figure('tag',tag);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function userdata=create_menu(userdata);

%INITIALIZATIONS

[nrows,ncols]=size(userdata.data.data);

%CREATE UICONTROL BUTTON

cb{1}='Display Spectrum';
cb{2}='Display Time';
cb{3}='Close Plot';
length_cb=length(cb);

tt{1} = 'Display Mass Spectrum at Scan';
tt{2} = 'Display Spectrum at Mass';
tt{3} = 'Close Spectrum at Scan Plot';

p2=.95;
for i=1:length_cb;
  %callbackstring=['coda_dw_callback(''',cb{i},''');'];
  callbackstring=['coda_dw_interactive(''',cb{i},''',gcbf);'];
  userdata.arg.handle_pushbutton_main(i)=uicontrol(userdata.arg.handle_fig_menu_main,...
    'style','pushbutton',...
    'FontSize',getdefaultfontsize,...
    'string',cb{i},'callback',callbackstring,'tooltip',tt{i});
  set(userdata.arg.handle_pushbutton_main(i),...
    'units','normalize','position',[0.0    p2    1    0.055]);
  p2=p2-.05;
end;
%DISABLE DISPLAY TIME AND CLOSE
set(userdata.arg.handle_pushbutton_main(2),'enable','off')
set(userdata.arg.handle_pushbutton_main(3),'enable','off')

%n_handles=i;

%CREATE UICONTROL SLIDERS

% min_slider{1}=1;
% max_slider{1}=min(ncols-1,500);
% sliderstep{1}=[1/max_slider{1} .1];

%value{1}=1;
string{1}='#var';
tts{1}='Number of Variables';

% min_slider{2}=0;
% max_slider{2}=1;
% sliderstep{2}=[.01 .1];
% value{2}=.3;
% string{2}='noise';

% min_slider{2}=0;
% max_slider{2}=1;
% sliderstep{2}=[.01 .1];
%value{2}=.65;
string{2}='corr';
tts{2}='Correlation Threshold';

%_handles=n_handles+1;
%l=.05;b=.3;w=.3;h=.4;
l=.16;b=.1;w=.33;h=.7;
for i=1:2;
  %callbackstring=['coda_dw_callback(''',string{i},''');'];
  callbackstring=['coda_dw_interactive(''',string{i},''',gcbf);'];
  userdata.arg.handle_slider_main(i)=...
    uicontrol(userdata.arg.handle_fig_menu_main,...
    'style','slider','Units','Normalized','Position',[l+(i-1)*w+.09,b,w/2.9,h],...
    'callback',callbackstring,'BusyAction','cancel','tooltip',tts{i},...
    'FontSize',getdefaultfontsize);
end;
setsliderstep(userdata)

b=b+h;
h=.04;

for i=1:2;
  userdata.arg.handle_text_main(i)=...
    uicontrol(userdata.arg.handle_fig_menu_main,...
    'style','text','String',string{i},'Units','Normalized',...
    'HorizontalAlignment','Center',...
    'Position',[l+(i-1)*w,b,w,h],... 
    'FontSize',getdefaultfontsize);
end;

%REPOSITION WINDOW

set(userdata.arg.handle_fig_menu_main,'position',[0.02    0.2    0.12    0.5]);

set(userdata.arg.handle_fig_menu_main,'HandleVisibility','Callback');

%set(userdata.arg.handle_fig_menu_main,'userdata',userdata);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function userdata=plot_results(userdata);

%INITIALIZE

[nrows,ncols]=size(userdata.data.data);

slider_value=get_slider_values(userdata);
%MAKE CORRECT FIGURE CURRENT.
figure(userdata.arg.handle_fig_plot_main)


%PLOT ORIGINAL RESULTS

userdata.arg.handle_data_axes = subplot(412);
plot(userdata.data.axisscale{1},userdata.data.data);
title(['original data: ',num2str(ncols),' variables']);
set(gca,'xTicklabel',[],'Tickdir','out');

%CALCULATE REDUCED 

[userdata.arg.q_value,userdata.arg.q_index]=coda_dw(userdata.data.data);%,slider_value(2));

%INITIALIZE PLOT SO IT CAN BE UPDATED WITHOUT REDRAWING ALL PLOTS

userdata.arg.handle_reduced_axes = subplot(413);
userdata.arg.handle_reduced_plot=plot(NaN,NaN(1,500));
userdata.arg.handle_title(1)=title(['reduced data: ',num2str(slider_value(1)),...
    ' variables, level ',...
    num2str(userdata.arg.q_value(userdata.arg.q_index(slider_value(1))),2)]);
%,...
%   ', noise ',num2str(slider_value(2))]);
set(gca,'xTicklabel',[],'Tickdir','out');

%ACTUAL PLOTTING OF REDUCED DATA

data_reduced=userdata.data.data(:,userdata.arg.q_index(1:slider_value(1)));
for i=1:slider_value(1);
  set(userdata.arg.handle_reduced_plot(i),'xdata',userdata.data.axisscale{1},...
    'ydata',data_reduced(:,i));
end;

%CALCULATE SUPER_REDUCED 

% [userdata.arg.q_index2,userdata.arg.corr_values]=...
%     super_reduce(userdata.data.data,userdata.arg.q_value,...
%     slider_value(1));
%userdata.arg.corr_values=super_reduce3(userdata.data.data,slider_value(1));
%data2plot=userdata.data.data(:,userdata.arg.q_index2(userdata.arg.corr_values<slider_value(2)));
%nvar=size(data2plot,2);
userdata.arg.corr_values=super_reduce3(data_reduced);
%set(userdata.arg.handle_super_reduced_plot,'xdata',[],'ydata',[]);
data_super_reduced=data_reduced(:,userdata.arg.corr_values<slider_value(2));
nvar=size(data_super_reduced,2);
%INITIALIZE PLOT SO IT CAN BE UPDATED WITHOUT REDRAWING ALL PLOTS

userdata.arg.handle_super_reduced_axes = subplot(414);
userdata.arg.handle_super_reduced_plot=plot(NaN,NaN(1,500));
userdata.arg.handle_title(2)=...
  title(['super reduced data: ',num2str(nvar), ' variables, corr ',num2str(slider_value(2))]);
set(gca,'Tickdir','out');

%ACTUAL PLOTTING OF DATA

for i=1:nvar;
  set(userdata.arg.handle_super_reduced_plot(i),'xdata',userdata.data.axisscale{1},...
    'ydata',data_super_reduced(:,i));
end;

%PLOT YY for Total Ion Current
TIC=[sum(userdata.data.data,2) sum(data_reduced,2) sum(data_super_reduced,2)];

subplot(411);userdata.arg.handle_TIC_plot=plotyy(userdata.data.axisscale{1},TIC(:,1),userdata.data.axisscale{1},TIC(:,2:3));
set(userdata.arg.handle_TIC_plot,'xlim',userdata.data.axisscale{1}([1 end]));
set(userdata.arg.handle_TIC_plot(1),'ylim',[0 1.1*max(TIC(:,1))]);
set(userdata.arg.handle_TIC_plot(2),'ylim',[0 1.1*max(TIC(:,2))]);
legend('Data','Reduced','Super Reduced');

drawnow

%GET LIMITS FOR LATER

userdata.synchronize.arg.xlim=zeros(3,2);
userdata.synchronize.arg.ylim=zeros(3,2);
for i=1:3;
  subplot(4,1,i+1);
  userdata.synchronize.arg.xlim(i,:)=get(gca,'xlim');
  userdata.synchronize.arg.ylim(i,:)=get(gca,'ylim');
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function slider_value=get_slider_values(userdata);

iend=length(userdata.arg.handle_slider_main);

for i=1:iend;
  slider_value(i)=get(userdata.arg.handle_slider_main(i),'Value');
end;
slider_value(1)=round(slider_value(1));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function coda_dw_callback(option,h);

% set(0,'showhiddenhandles','on');
try;
%   h=findobj('tag','handle_fig_menu_main');
  userdata=get(h,'userdata');
%   set(0,'showhiddenhandles','on');
catch;
  disp('problems in coda_db_callback')
%   set(0,'showhiddenhandles','on');
end;

%DISABLE SLIDERS IF SECOND PLOT DISPLAYED
if isfield(userdata.arg,'handle_fig_plot_spec');
  if ~ishandle(userdata.arg.handle_fig_plot_spec);
    set(userdata.arg.handle_slider_main,'enable','on');
  end;
end;

data_reduced = [];
data_super_reduced = [];

%INITIALIZATIONS

slider_value=get_slider_values(userdata);
[nrows,ncols]=size(userdata.data.data);

%OPTION #VAR AND NOISE

if strcmp(option,'#var')|strcmp(option,'noise');
%   if strcmp(option,'noise');
%     [userdata.arg.q_value,userdata.arg.q_index]=...
%       coda_fft(userdata.data.data)
%   end;
  
  %UPDATE REDUCED PLOT
  
  set(userdata.arg.handle_reduced_plot,'xdata',[],'ydata',[]);
  data_reduced=userdata.data.data(:,userdata.arg.q_index(1:slider_value(1)));
  for i=1:slider_value(1);
    set(userdata.arg.handle_reduced_plot(i),'xdata',userdata.data.axisscale{1},...
      'ydata',data_reduced(:,i));
  end;
  set(userdata.arg.handle_title(1),'string',...
    ['reduced data: ',num2str(slider_value(1))    ,' variables, level ',...
      num2str(userdata.arg.q_value(userdata.arg.q_index(slider_value(1))),2)]);
  %,...
  %       ', noise ',num2str(slider_value(2))]);
end;

if strcmp(option,'#var')|strcmp(option,'noise')|strcmp(option,'corr');
  try
  set(gcf,'Pointer','watch')
  data_super_reduced=userdata.data.data(:,userdata.arg.q_index(1:slider_value(1)));
  
  %UPDATE SUPER REDUCED PLOT
  
  set(userdata.arg.handle_super_reduced_plot,'xdata',[],'ydata',[]);
  userdata.arg.corr_values=super_reduce3(data_super_reduced);
  data_super_reduced=data_super_reduced(:,userdata.arg.corr_values<slider_value(2));
  nvar=size(data_super_reduced,2);
  
  
  for i=1:nvar;
    set(userdata.arg.handle_super_reduced_plot(i),'xdata',userdata.data.axisscale{1},...
      'ydata',data_super_reduced(:,i));
  end;
  set(userdata.arg.handle_title(2),'string',...
    ['super reduced data: ',num2str(nvar), ' variables, corr ',num2str(slider_value(2))]);
  set(gcf,'Pointer','arrow')
  catch
    set(gcf,'Pointer','arrow')
  end
  
end;


h = userdata.arg.handle_TIC_plot;

% Raw data shouldn't change between callbacks so comment out for now.
%  set(findobj(h(1),'type','line'),'xdata',userdata.data.axisscale{1},'ydata',TIC(:,1))
%  set(h(1),'ylim',[0 1.1*max(TIC(:,1))]);
if ~isempty(data_reduced)
  set(findobj(h(2),'type','line','DisplayName','Reduced'),'xdata',userdata.data.axisscale{1},'ydata',sum(data_reduced,2))
  set(h(2),'ylim',[0 1.1*max(sum(data_reduced,2))]);
end

if ~isempty(data_super_reduced)
  set(findobj(h(2),'type','line','DisplayName','Super Reduced'),'xdata',userdata.data.axisscale{1},'ydata',sum(data_super_reduced,2))
  %data_reduced = get(findobj(h(2),'type','line','DisplayName','Reduced'),'ydata'); %May not be calculated every time (corr callback)
  set(h,'xlim',userdata.data.axisscale{1}([1 end]));
end

%OPTION CURSOR

if strcmp(option,'Display Spectrum')
  userdata=plot_cursor_stuff(userdata);
elseif strcmp(option,'Display Time')
  userdata=plot_cursor_stuff(userdata);
end;

%OPTION CLOSE SPEC PLOT

%if strcmp(option,'close spec plot');
if strcmp(option,'Close Plot');
  set(userdata.arg.handle_pushbutton_main(1),'enable','on')
  set(userdata.arg.handle_pushbutton_main(2),'enable','off')
  set(userdata.arg.handle_pushbutton_main(3),'enable','off')
  
  try 
    set(userdata.arg.handle_slider_main,'enable','on');
    delete (userdata.arg.handle_fig_plot_spec);
    figure(findobj('tag','handle_fig_plot_main'));
    userdata=de_synchronize_zoom(userdata);
  catch;
  end;
end; 


set(userdata.arg.handle_fig_menu_main,'userdata',userdata);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function plotms (varlist,spec,c);
%function plotms (varlist,spec,c);
%plots a mass spectrum.
if nargin==2;c='b';end;
lengthspec=length(spec);
y0=zeros(1,lengthspec);
plot(reshape([varlist;varlist;varlist],1,3*lengthspec),...
  reshape([y0;spec;y0],1,3*lengthspec),c);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [index,dif2]=findindx(array,r);
%function index=findindx(array,r);
%%finds the index of the array element that is closest to r;

lengthr=length(r);
index=zeros(1,lengthr);
for i=1:lengthr;
  dif=abs(array-r(i));index2=find(dif==min(dif));index(i)=index2(1);
  dif2(i)=dif(index2(1));
end;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function zero (x);
%function zero (x);
%draws a line at y=0 in a plot. x is the x array of a plot;
%No argument needed

if ~nargin;a=axis;x=a(1:2);end;
hold on; plot([min(x), max(x)], [0, 0], 'k'); hold off

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function userdata=plot_cursor_stuff(userdata);

%INITIALIZATIONS

[nrows,ncols]=size(userdata.data.data);
slider_value=get_slider_values(userdata);

%IF SPECPLOT, CURSOR ACTION FOR SPECPLOT

if isfield(userdata.arg,'handle_fig_plot_spec');
  if ishandle(userdata.arg.handle_fig_plot_spec);
      %h=gcf;
      %set(h,'visible','off');
    figure(userdata.arg.handle_fig_plot_spec);
    userdata=label_plot(userdata);
    %set(h,'visible','on');
    return
  end;
end;

%IF NOT SPECPLOT, CREATE SPECPLOT

figure(userdata.arg.handle_fig_plot_main);
userdata=plot_ms_cursor(userdata);
%userdata=plot_results(userdata);


%INACTIVATE UICONTROLS FOR MAIN FIG

set(userdata.arg.handle_slider_main,'enable','off');
set(userdata.arg.handle_pushbutton_main(1),'enable','off')
set(userdata.arg.handle_pushbutton_main(2),'enable','on')
set(userdata.arg.handle_pushbutton_main(3),'enable','on')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function userdata=plot_ms_cursor(userdata);

%INITIALIZATIONS

[nrows,ncols]=size(userdata.data.data);
slider_value=get_slider_values(userdata);

userdata=synchronize_zoom(userdata);

%GET CURSOR INDEX
%set(userdata.arg.handle_fig_plot_main, 'WindowStyle','modal');%old
figure(userdata.arg.handle_fig_plot_main);%nes
[x,y]=ginput(1);
%[x,y]=gselect('x');
%set(userdata.arg.handle_fig_plot_main, 'WindowStyle','normal')%old

userdata.arg.cursorx_index=findindx(userdata.data.axisscale{1},x);
scan_position=userdata.data.axisscale{1}(userdata.arg.cursorx_index);

%CREATE NEW FIGURE



userdata.arg.handle_fig_plot_spec=create_fig('handle_fig_plot_spec');
%uimenu(gcf,'label','return','callback','close');
set(userdata.arg.handle_fig_plot_spec, 'CloseRequestFcn','coda_dw_interactive(''delete_spec'',gcf)'...
  ,'name','Spec Plot','NumberTitle','off')
%PLOT MS

subplot(211);
plotms(userdata.data.axisscale{2},userdata.data.data(userdata.arg.cursorx_index,:),'k');
title(['scan position: ',num2str(scan_position)]);
hold on;

%PLOT SELECTED VARIABLES IN RED

index1=1;index2=slider_value(1);
select=userdata.arg.q_index(index1:index2);
plotms(userdata.data.axisscale{2}(select),...
  userdata.data.data(userdata.arg.cursorx_index,select),'r');

%PLOT NEXT HIGHEST SERIES OF VARIABLES IN GREEN

index1=index2+1;
index2=min(2*slider_value(1),ncols);
select=userdata.arg.q_index(index1:index2);
plotms(userdata.data.axisscale{2}(select),...
  userdata.data.data(userdata.arg.cursorx_index,select),'g');


%INDICATE SUPER SELECTED VARIABLES

select=userdata.arg.q_index(1:slider_value(1));
data2plot=userdata.data.data(:,select);%NEWWWWWWWW
v_select=userdata.data.axisscale{2}(select);
y2plot=data2plot(userdata.arg.cursorx_index,userdata.arg.corr_values<slider_value(2));
nvar=size(y2plot,2);
x2plot=v_select(userdata.arg.corr_values<slider_value(2));
c=get(userdata.arg.handle_super_reduced_plot(1:nvar),'color');
if nvar==1;
  temp=c;
  clear c
  c{1}=temp;
end;

for i=1:nvar;
  h=plot(x2plot(i),y2plot(i),'*');
    set(h,'color',c{i});
end;

zero
hold off;
userdata.arg.handle_axis_plot_spec=gca;

%INITIALIZE PLOT SO IT CAN BE UPDATED WITHOUT REDRAWING ALL PLOTS

subplot(212);
userdata.arg.handle_chromatogram_plot=plot(NaN);
userdata.arg.handle_chromatogram_axis=gca;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function userdata=label_plot(userdata);

%SET TO PROPER AXIS FOR GINPUT

%INITIALIZE
axes(userdata.arg.handle_axis_plot_spec);
set(gca,'units','normalized');
v=axis;

set(gcf,'backingstore','off');

%LOOP FOR LABELING AND CHROMATOGRAM PLOTTING;
%while 1;
%axes(userdata.arg.handle_axis_plot_spec);%old
%try;%old
  %set(userdata.arg.handle_fig_plot_spec, 'WindowStyle','modal')%old
  %[x1,y1,button]=ginput(1);%avoid problems when fig closed%old
  %set(userdata.arg.handle_fig_plot_spec, 'WindowStyle','normal')%old
try;%new
  figure(userdata.arg.handle_fig_plot_spec);%new
  [x1,y1,button]=ginput(1);%avoid problems when fig closed%old
   
  
catch
  set(userdata.arg.handle_slider_main,'enable','on');
  figure(userdata.arg.handle_fig_plot_main);
  userdata=plot_ms_cursor(userdata);
  
  return;
end;

b=get(gca,'currentpoint');
x1=b(1,1);y1=b(1,2);

index=findindx(userdata.data.axisscale{2},x1);
var_current=userdata.data.axisscale{2}(index);
label_string=num2str(var_current);
if x1<v(1)|x1>v(2)|y1<v(3)|y1>v(4)|button~=1;return;end;
dragrect([0 0 0 0]); 
b=get(gca,'currentpoint');
x2=b(1,1);y2=b(1,2);
h=findobj('tag',label_string);
if ~isempty(h);delete(h); end;
h=text(x2,y2,label_string);
set(h,'tag',label_string);
p=get(h,'position');
if p(1)<v(1)|p(1)>v(2)|p(2)<v(3)|p(2)>v(4);delete(h);end;
set(userdata.arg.handle_chromatogram_plot,'xdata',userdata.data.axisscale{1},...
  'ydata',userdata.data.data(:,index));
axes(userdata.arg.handle_chromatogram_axis);
title(var_current);
refresh
%end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function corr_values=super_reduce3(data,level_corr);
%SUPER_REDUCE eliminates highly correlated variables.
%When several variables have a high correlation, the variable(s) with the lower
%intensity will be deleted, leaving the most intense variable.
%Generally used in combination with CODA and COMPARLCMS applications
%[corr_values=super_reduce3(data,level_corr);
%
%INPUTS:
%           data: matrix to be analyzed
%           level_corr: (optional) correlation level. Variables with a
%           correlation above this level will be eliminated. A plot will
%           be made when this value is given.
%
%OUTPUTS:
%           corr_values: the correlation values used for elimination
%
%  I/O: [corr_values=super_reduce3(data,level_corr);
%  I/O: super_reduce demo
%
%Also see CODA_FFT   

%EVRI INITIALIZATIONS

corr_values=[];
if nargin == 0; data = 'io'; end
if ischar(data);
  options=[];
  if nargout==0; 
    evriio(mfilename,data,options); 
  else;
    q_index2=evriio(mfilename,data,options); 
  end;
  return 
end;

%INITIALIZATONS

[nrows,ncols]=size(data );
max_values=max(data);
index_array=1:ncols;

%CALCULATE CORRELATION MATRIX

c=corrcoef(data);
c=c-eye(ncols);

%FIND MAX CORRELATION

thrownout=[];
for i=1:ncols;
  maxmaxc=max(c(:));
  [i,j]=find(c==maxmaxc);
  i=i(1);j=j(1);
  varindex=[i j];%variable index of vars with highest correlation
  [m,index]=sort(max_values(varindex));
  varindex=varindex(index(1));
  thrownout=[thrownout index_array(varindex)];
  corr_values(index_array(varindex))=maxmaxc;
  
  %UPDATE 
  
  max_values(varindex)=[];
  index_array(varindex)=[];
  c(varindex,:)=[];
  c(:,varindex)=[];
end;

q_index2=[1:ncols];
if nargin==3;return;end;

%PLOT

if nargin==2;
  subplot(211);plot(data);title(['original reduced data, ',num2str(ncols),' variables']);
  select2=q_index2(corr_values<level_corr);
  nvar2=length(select2);
  subplot(212);plot(data(:,select2));
  title(['super reduced data, ',num2str(nvar2),' variables']);
  shg;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function userdata=synchronize_zoom(userdata);

h=[userdata.arg.handle_data_axes userdata.arg.handle_reduced_axes userdata.arg.handle_super_reduced_axes];
h2=get(h,'xlim');
h3=get(h,'ylim');
xlim1=zeros(3,1);
xlim2=xlim1;
ylim2=xlim1;
%for i=1:3;
%  xlim1(i)=h2{i}(1);
%  xlim2(i)=h2{i}(2);
%  ylim2(i)=h3{i}(2);
%end;
index=0;
for i=1:length(h);
    if strcmp(get(h(i),'type'),'axes');
    index=index+1;
     xlim1(index)=h2{i}(1);
     xlim2(index)=h2{i}(2);
     ylim2(index)=h3{i}(2);
    end;
end;

    
    

%IF NO ZOOMING APPLIED RETURN

if (std(xlim1)==0)&(std(xlim2)==0);return;end;
xlim=[max(xlim1) min(xlim2)];
ylim=[0 min(ylim2)];
% userdata.synchronize.arg.xlim=[min(xlim1) max(xlim2)];
% userdata.synchronize.arg.ylim=[0 max(ylim2)];
%userdata.synchronize.arg.xlim=[xlim1;xlim2]
%userdata.synchronize.arg.ylim=[[0 0 0]; ylim2];


for i=1:3;
  subplot(4,1,i+1);axis([xlim ylim]);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function userdata=de_synchronize_zoom(userdata);

for i=1:3;
  subplot(4,1,i+1);
  axis([userdata.synchronize.arg.xlim(i,:) userdata.synchronize.arg.ylim(i,:)]);
  %axis([userdata.synchronize.arg.xlim userdata.synchronize.arg.ylim]);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function userdata = load_cb(handle, reload);

userdata = get(handle,'userdata');

%IF RELOADING DATA, DELETE SPEC PLOT.
if reload & ~isempty(userdata) & isfield(userdata.arg,'handle_fig_plot_spec');
  if ishandle(userdata.arg.handle_fig_plot_spec);
    delete_spec(userdata)
  end;
end;
userdata.data = lddlgpls('doubdataset','Choose Data to Process');

% No data loaded, return to main function.
if isempty(userdata.data)
  return;
end

if ~isa(userdata.data,'dataset');
  userdata.data = dataset(userdata.data);
end

%HARD DELETE EXCLUDED DATA
userdata.data = userdata.data(userdata.data.includ{1},userdata.data.includ{2});

%IF RELOADING DATA, RECALCULATE MAIN PLOT.
if reload
  setsliderstep(userdata);
  delete(userdata.arg.handle_fig_plot_main)

  %Reset axis scales.
  [nrows,ncols]=size(userdata.data.data);
  if isempty(userdata.data.axisscale{1});userdata.data.axisscale{1}=[1:nrows];end;
  if isempty(userdata.data.axisscale{2});userdata.data.axisscale{2}=[1:ncols];end;  
  %CREATE FIGURE FOR PLOT

  userdata.arg.handle_fig_plot_main=create_fig('handle_fig_plot_main');
  set(userdata.arg.handle_fig_plot_main,'CloseRequestFcn','coda_dw_interactive(''close_cb'',gcf)'...
    ,'name','Coda DW Analysis','NumberTitle','off');

  %PLOT DATA ANALYSIS RESULTS

  userdata=plot_results(userdata);

  %SET HANDLESVISIBILITY TO CALLBACK

  set(userdata.arg.handle_fig_menu_main,'handlevisibility','callback');
  set(userdata.arg.handle_fig_plot_main,'handlevisibility','callback');

  %STORE INFO IN USERDATA

  set(userdata.arg.handle_fig_menu_main,'userdata',userdata);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function setsliderstep(userdata);
[nrows,ncols]=size(userdata.data.data);

min_slider{1}=1;
max_slider{1}=min(ncols,500);
sliderstep{1}=[1/max_slider{1} .1];

if max_slider{1}<50
  value{1} = 1;
else
value{1}=50;
end

min_slider{2}=0;
max_slider{2}=1;
sliderstep{2}=[.01 .1];
value{2}=.65;

for i=1:2;
    set(userdata.arg.handle_slider_main(i),...
    'min',min_slider{i},'max',max_slider{i},'sliderstep',sliderstep{i},'Value',value{i});
end;
userdata.data.axisscale{1}=[1:nrows];
userdata.data.axisscale{2}=[1:ncols];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function close_cb(handle);
 
h = findobj('tag','handle_fig_menu_main');
userdata = get(h,'userdata');

if isfield(userdata.arg,'handle_fig_plot_spec');
  if ishandle(userdata.arg.handle_fig_plot_spec);
    delete(userdata.arg.handle_fig_plot_spec);
  end;
end;
if isfield(userdata.arg,'handle_fig_plot_main');
  if ishandle(userdata.arg.handle_fig_plot_main);
    delete(userdata.arg.handle_fig_plot_main);
  end;
end;
if isfield(userdata.arg,'handle_fig_menu_main');
  if ishandle(userdata.arg.handle_fig_menu_main);
    delete(userdata.arg.handle_fig_menu_main);
  end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function delete_spec(userdata);
if ishandle(userdata)
  h = findobj('tag','handle_fig_menu_main');
  userdata = get(h,'userdata');
end

delete(userdata.arg.handle_fig_plot_spec);
figure(findobj('tag','handle_fig_plot_main'));
userdata=de_synchronize_zoom(userdata);
userdata.arg = rmfield(userdata.arg,'handle_fig_plot_spec');
set(userdata.arg.handle_pushbutton_main(1),'enable','on')
set(userdata.arg.handle_pushbutton_main(2),'enable','off')
set(userdata.arg.handle_pushbutton_main(3),'enable','off')
set(userdata.arg.handle_slider_main,'enable','on');
    
    
    
    

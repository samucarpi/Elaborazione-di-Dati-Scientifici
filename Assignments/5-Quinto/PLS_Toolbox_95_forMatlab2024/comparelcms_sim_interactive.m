function varargout = comparelcms_sim_interactive(varargin);
%COMPARELCMS_SIM_INTERACTIVE Interactive interface for COMPARELCMS.
%The function calculates similarity values of variables of several
%different data sets. Plotting variables with a low similarity value 
%shows the variables that are different across the samples. A typical
%example is the analysis of data sets of different batches of the same
%material with the goal to extract the minor differences between the
%samples. This interactive version loads the data interactively, with
%options to interactively set the parameters and explore the output through
%interactive plots
%
%I/O: comparelcms_sim_interactive
%
%See also: COMPARELCMS_SIMENGINE

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%ww
%rsk 07/29/04 Major revisions for test release in 3.5.

%SEE IF CALLBACK IS NEEDED

if nargin>0 & ischar(varargin{1}) & ismember(varargin{1},evriio([],'validtopics'));
  %options=define_options;
  options=[];
  if nargout==0; 
    evriio(mfilename,varargin{1},options); 
  else;
    varargout{1} = evriio(mfilename,varargin{1},options); 
  end;
  return 
  % elseif nargin==1;
  %   comparelcms_sim_callback(varargin{1});
  %   return;
elseif nargin==2;
  if strcmp(varargin{1},'close_cb')
    close_cb(varargin{2});
    return;
  elseif strcmp(varargin{1},'close_cb_spec')
    close_cb_spec(varargin{2});
    return;
  end
  comparelcms_sim_callback(varargin{1},varargin{2});
  return
end;

%ONLY USED FOR PROGRAMMING PURPOSES

test=0;

%INITIALIZATIONS

userdata.coda_level=2.25;
userdata.noise_level=20;
userdata.window_smooth=7;
userdata.sim_level=0.57;
userdata.corr_level=0.65;

%READ FILES

if test==1;
  data{1}=read_dso('c:\data\windig_toolbox\eigenvector\dems\lcms_compare1');
  data{2}=read_dso('c:\data\windig_toolbox\eigenvector\dems\lcms_compare2');
  data{3}=read_dso('c:\data\windig_toolbox\eigenvector\dems\lcms_compare3');
else;
  try  
    data=getfiles_dso;
    if length(data)<2
      return
    end
  catch
    return
  end
end;

%CHECK IF AXISSCALE IS NOT EMPTY

for i=1:length(data);
  if isempty(data{i}.axisscale{1})|isempty(data{i}.axisscale{2});
    error('axisscale is empty');
  end;
end;

%CALCULATE 1 COUNT

count2intensity=sort(data{1}.data(:));
count2intensity=count2intensity(count2intensity>0);
userdata.count2intensity=count2intensity(1);

%PUT EVERYTHING IN ONE CUBE

[userdata.data_combined,userdata.masses_combined,userdata.rows_combined]=combine(data);
[nslabs,nrows,ncols]=size(userdata.data_combined);

%CALCULATE MAXIMA

userdata.max_int=squeeze(max(max(userdata.data_combined,[],2)))';

%APPLY CODA_DW

dw_matrix=zeros(nslabs,ncols);
for i=1:nslabs;
  dw_matrix(i,:)=coda_dw(reshape(userdata.data_combined(i,:,:),nrows,ncols));
end;
userdata.dw_combined=min(dw_matrix);

%APPLY COMPARELCMS

h = waitbar(0,'Got to do some algebra ....');
userdata.sim=comparelcms_simengine(userdata.data_combined,userdata.window_smooth,h);
close(h);



%CREATE FIGURE FOR MENU

userdata.arg.handle_fig_menu_main=create_fig('handle_fig_menu_main');
set(userdata.arg.handle_fig_menu_main,'menubar','none','units','normalize',...
  'CloseRequestFcn','comparelcms_sim_interactive(''close_cb'',gcf)',...
  'name','Main Menu','NumberTitle','off');

%CREATE MENU

userdata=create_menu(userdata);

%APPLY COMPARELCMS_SIM WITH THE DEFINED WINDOW_WIDTH

%slider_value=get_slider_values(userdata);
%nvar=slider_value(1);
%noise=slider_value(2);
%slider_value(3);
%slider_value(4);

%CREATE FIGURE FOR PLOT

userdata.arg.handle_fig_plot_main=create_fig('handle_fig_plot_main');
set(userdata.arg.handle_fig_plot_main,'CloseRequestFcn',...
  'comparelcms_sim_interactive(''close_cb'',gcf)','name','Main Plot','NumberTitle','off');
setappdata(userdata.arg.handle_fig_plot_main,'parent',userdata.arg.handle_fig_menu_main)
%PLOT DATA ANALYSIS RESULTS;

userdata=plot_results2(userdata);



%SET HANDLESVISIBILITY TO CALLBACK

set(userdata.arg.handle_fig_menu_main,'handlevisibility','callback');
set(userdata.arg.handle_fig_plot_main,'handlevisibility','callback');

%STORE INFO IN USERDATA

set(userdata.arg.handle_fig_menu_main,'userdata',userdata);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function data=getfiles_dso;
%get files and put in structure

%INITIALIZATIONS
 qdata = {};
nfile=0;
min_size=inf;
while 1
  [value,name,location] = lddlgpls('dataset','Select Data to Analyze, Finish by Using "Cancel"');
  if isempty(value)
    break
  end
  %HARD DELETE EXCLUDED DATA
  %value.data = value.data(value.includ{1},value.includ{2});
  value = value(value.includ{1},value.includ{2});
  nfile=nfile+1;
  data{nfile}=value;
  
  size_data=size(data{nfile},1);
  if size_data<min_size;
    min_size=size_data;
  end;
end

if nfile == 0
  return
end

if nfile == 1
  erdlgpls('Must load more than one spectrum.');
  return
end

%LINE UP DATA

for i=1:nfile;
  data{i}=data{i}(1:min_size,:);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [data_combined,masses_combined,rows_combined]=combine(data);

%INITIALIZATIONS

n_files=length(data);

%GET MINIMUM NUMBER OF ROWS AND ALL MASSES

nrows=inf;
masses_combined=[];
for i=1:n_files;
  nrows2=length(data{i}.axisscale{1});
  if nrows2<nrows;nrows=nrows2;end;
  masses_combined=[masses_combined data{i}.axisscale{2}];
end;
rows_combined=data{1}.axisscale{1}(1:nrows);

%GET UNION OF MASSES

masses_combined=unique(masses_combined);
ncols=length(masses_combined);

%CREATE MATRICES WITH ALL SELECTED DATA

data_combined=zeros(n_files,nrows,ncols);
for i=1:n_files;
  [dummy,indexa,indexb]=intersect(masses_combined,data{i}.axisscale{2});
  data_combined(i,:,indexa)=data{i}.data([1:nrows],indexb);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function handle=create_fig(tag)

handle = findobj('tag',tag);
if isempty(handle)
  handle = figure('tag',tag);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function userdata=create_menu(userdata);

%INITIALIZATIONS

[n_files,nrows,ncols]=size(userdata.data_combined);

%CREATE UICONTROL BUTTON

cb{1}='Select';
cb{2}='Close Plot';
length_cb=length(cb);
%comparelcms_sim_callback
p2=.06;
for i=1:length_cb;
  %callbackstring=['comparelcms_sim_callback(''',cb{i},''');'];
  callbackstring=['comparelcms_sim_interactive(''',cb{i},''',gcf);'];
  userdata.arg.handle_pushbutton_main(i)=uicontrol(userdata.arg.handle_fig_menu_main,...
    'style','pushbutton','FontSize',getdefaultfontsize,...    
    'string',cb{i},'tag',cb{i},'callback',callbackstring);
  set(userdata.arg.handle_pushbutton_main(i),...
    'units','normalize','position',[0.0    p2    1    0.0476]);
  p2=p2-.05;
end;
set(userdata.arg.handle_pushbutton_main(2),'enable','off')
%n_handles=i;

%CREATE UICONTROL SLIDERS

% nslider=1;
% min_slider{nslider}=1;
% max_slider{nslider}=min(ncols,500);
% sliderstep{nslider}=[1/max_slider{nslider} .1];
% dummy=sort(userdata.dw_combined);
% index=find(dummy>userdata.coda_level);
% value{nslider}=index(1);
% string{nslider}=str2mat('coda','level');

nslider=1;
min_slider{nslider}=0;
max_slider{nslider}=10;
sliderstep{nslider}=[.001 .01];
value{nslider}=userdata.coda_level;
string{nslider}=str2mat('Coda','Level');

nslider=nslider+1;
min_slider{nslider}=0;
max_slider{nslider}=500;
sliderstep{nslider}=[1/500 .1];
value{nslider}=userdata.noise_level;
string{nslider}=str2mat('Noise','Level');

nslider=nslider+1;
min_slider{nslider}=1;
max_slider{nslider}=10;
sliderstep{nslider}=[.1 .1];
value{nslider}=userdata.window_smooth;
string{nslider}=str2mat('Window','Smooth');
%string{nslider}=str2mat('sim','level');

nslider=nslider+1;
min_slider{nslider}=0;
max_slider{nslider}=1;
sliderstep{nslider}=[.001 .01];
value{nslider}=userdata.sim_level;
string{nslider}=str2mat('Sim','Level');

nslider=nslider+1;
min_slider{nslider}=0;
max_slider{nslider}=1;
sliderstep{nslider}=[.01 .1];
value{nslider}=.65;
string{nslider}=str2mat('Correlation','Level');


%l=.01;b=.3;w=.33;h=.4;
l=.01;b=.63;w=.33;h=.3;
for i=1:3;
  %callbackstring=['comparelcms_sim_callback(''',string{i}(1,:),''');'];
  callbackstring=['comparelcms_sim_interactive(''',string{i}(1,:),''',gcf);'];
  userdata.arg.handle_slider_main(i)=...
    uicontrol(userdata.arg.handle_fig_menu_main,...
    'style','slider','Units','Normalized','Position',[l+(i-1)*w+.09,b,w/2.9,h],...
    'min',min_slider{i},'max',max_slider{i},'sliderstep',sliderstep{i},...
    'Value',value{i},'callback',callbackstring,'Interruptible','off');
end;

b=b+h;
h=.06;

for i=1:3;
  userdata.arg.handle_text_main(i)=...
    uicontrol(userdata.arg.handle_fig_menu_main,...
    'style','text','String',string{i},'Units','Normalized','HorizontalAlignment','Center',...
    'Position',[l+(i-1)*w,b,w,h],'FontSize',getdefaultfontsize);
  if logical(~rem(i,2));
    set(userdata.arg.handle_text_main(i),'backgroundcolor',[.75 .75 .75]);
  end;
end;

%%%%%%%%%%

l=.17;b=.24;w=.33;h=.3;
for i=4:nslider;
  %callbackstring=['comparelcms_sim_callback(''',string{i}(1,:),''');'];
  callbackstring=['comparelcms_sim_interactive(''',string{i}(1,:),''',gcf);'];
  userdata.arg.handle_slider_main(i)=...
    uicontrol(userdata.arg.handle_fig_menu_main,...
    'style','slider','Units','Normalized','Position',[l+(i-4)*w+.09,b,w/2.9,h],...
    'min',min_slider{i},'max',max_slider{i},'sliderstep',sliderstep{i},...
    'Value',value{i},'callback',callbackstring);
end;

b=b+h;
h=.06;

for i=4:nslider;
  userdata.arg.handle_text_main(i)=...
    uicontrol(userdata.arg.handle_fig_menu_main,...
    'style','text','String',string{i},'Units','Normalized','HorizontalAlignment','Center',...
    'Position',[l+(i-4)*w,b,w,h],'FontSize',getdefaultfontsize);
  if logical(~rem(i,2));
    set(userdata.arg.handle_text_main(i),'backgroundcolor',[.75 .75 .75]);
  end;
end;


%REPOSITION WINDOW

set(userdata.arg.handle_fig_menu_main,'position',[0.0    0.1467    0.1500    0.7000]);

%set(userdata.arg.handle_fig_menu_main,'HandleVisibility','Callback');

%set(userdata.arg.handle_fig_menu_main,'userdata',userdata);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% function userdata=plot_results(userdata);
% 
% %INITIALIZE
% 
% [nfiles,nrows,ncols]=size(userdata.data_combined);
% 
% %GET SLIDER VALUES;
% 
% slider_value=get_slider_values(userdata);
% %50.0000   20.0000    7.0000    0.5600    0.6500
% 
% %SELECT VARIABLES;
% %^%^%^%^
% %SMOOTH THE DATA TO COMPENSATE FOR SLIGHT RETENTION TIME SHIFTS
% 
% data_combined_filtered=userdata.data_combined;
% for i=1:nfiles;
%   b=reshape(data_all(i,:,:),nrows,ncols);
%   data_combined_filtered(i,:,:)=filter2(ones(filter_width,1)/filter_width,b,'same');
% end;
% 
% %DETERMINE MAX IN ALL ROWS
% %keyboard
% 
% max_rows=max(data_all,[],2);%for noise stuff
% max_rows=max(reshape(max_rows,n_files,n_masses_selected));
% 
% %CALCULATE DIFFERENCE INDEX
% 
% mean_spec=mean(data_all_filtered);
% mean_spec=reshape(mean_spec,nrows2,n_masses_selected);
% min_spec=min(data_all_filtered);
% min_spec=reshape(min_spec,nrows2,n_masses_selected);
% 
% array1=all(mean_spec==0);%take out all zero arrays
% array2=all(min_spec==0);
% array=((array1==1)|(array2==1));
% masses_selected(array)=[];
% mean_spec(:,array)=[];
% min_spec(:,array)=[];
% data_all(:,:,array)=[];
% max_rows(array)=[];
% 
% %calculate CORELATION BETWEEN MEANSPEC AND MINSPEC
% 
% m=mean(mean_spec);m=repmat(m,nrows2,1);
% s=std(mean_spec);s=repmat(s,nrows2,1);
% a1=(mean_spec-m)./s;
% m=mean(min_spec);m=repmat(m,nrows2,1);
% s=std(min_spec);s=repmat(s,nrows2,1);
% a2=(min_spec-m)./s;
% %a2=(min_spec-m)
% 
% s=sum(a1.*a2)/nrows2;%correlation coefficiant
% %s=1;
% s=s.*sum(sqrt(min_spec.^2))./sum(sqrt(mean_spec.^2));
% %s=s.*sum((min_spec))./sum((mean_spec));
% 
% %APPLY LIMITS BASED ON NOISE_LEVEL AND s_level
% 
% array=max_rows<noise_level2;
% s(array)=s_level+1;%avoids selection
% %array4=find(s<s_level);
% %m=max(max_rows(array4));
% [dummy,array4]=sort(s);
% %array4=array4(1:26);
% array4=s<s_level;
% m=max(max_rows(array4));
% %PLOT
% %^%^%^^%
% 
% 
% %PLOT ORIGINAL RESULTS
% 
% subplot(311);plot(userdata.data.axisscale{1},userdata.data.data);
% title(['original data: ',num2str(ncols),' variables']);
% set(gca,'xTicklabel',[],'Tickdir','out');
% 
% %CALCULATE REDUCED 
% 
% [userdata.arg.q_value,userdata.arg.q_index]=coda_dw(userdata.data.data);%,slider_value(2));
% 
% %INITIALIZE PLOT SO IT CAN BE UPDATED WITHOUT REDRAWING ALL PLOTS
% 
% subplot(312);
% userdata.arg.handle_reduced_plot=plot(NaN,repmat(NaN,1,500));
% userdata.arg.handle_title(1)=title(['reduced data: ',num2str(slider_value(1)),...
%     ' variables, level ',...
%     num2str(userdata.arg.q_value(userdata.arg.q_index(slider_value(1))),2),...
%     ', noise ',num2str(slider_value(2))]);
% set(gca,'xTicklabel',[],'Tickdir','out');
% 
% %ACTUAL PLOTTING OF REDUCED DATA
% 
% data2plot=userdata.data.data(:,userdata.arg.q_index(1:slider_value(1)));
% for i=1:slider_value(1);
%   set(userdata.arg.handle_reduced_plot(i),'xdata',userdata.data.axisscale{1},...
%     'ydata',data2plot(:,i));
% end;
% 
% %CALCULATE SUPER_REDUCED 
% 
% % [userdata.arg.q_index2,userdata.arg.corr_values]=...
% %     super_reduce(userdata.data.data,userdata.arg.q_value,...
% %     slider_value(1));
% %userdata.arg.corr_values=super_reduce3(userdata.data.data,slider_value(1));
% %data2plot=userdata.data.data(:,userdata.arg.q_index2(userdata.arg.corr_values<slider_value(2)));
% %nvar=size(data2plot,2);
% userdata.arg.corr_values=super_reduce3(data2plot);
% %set(userdata.arg.handle_super_reduced_plot,'xdata',[],'ydata',[]);
% data2plot=data2plot(:,userdata.arg.corr_values<slider_value(2));
% nvar=size(data2plot,2);
% %INITIALIZE PLOT SO IT CAN BE UPDATED WITHOUT REDRAWING ALL PLOTS
% 
% subplot(313);
% userdata.arg.handle_super_reduced_plot=plot(NaN,repmat(NaN,1,500));
% userdata.arg.handle_title(2)=...
%   title(['super reduced data: ',num2str(nvar), ' variables, corr ',num2str(slider_value(2))]);
% set(gca,'Tickdir','out');
% 
% %ACTUAL PLOTTING OF DATA
% 
% for i=1:nvar;
%   set(userdata.arg.handle_super_reduced_plot(i),'xdata',userdata.data.axisscale{1},...
%     'ydata',data2plot(:,i));
% end;
% 
% 
% 
% 
%PLOT


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function slider_value=get_slider_values(userdata);

iend=length(userdata.arg.handle_slider_main);

for i=1:iend;
  slider_value(i)=get(userdata.arg.handle_slider_main(i),'Value');
end;
slider_value(3)=round(slider_value(3));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function userdata=plot_results2(userdata);

%INITIALIZATIONS

[nslabs,nrows,ncols]=size(userdata.data_combined);
slider_value=get_slider_values(userdata);
userdata.coda_level=slider_value(1);
userdata.noise_level=slider_value(2);
userdata.window_smooth=slider_value(3);
userdata.sim_level=slider_value(4);
userdata.corr_level=slider_value(5);
%'handle_fig_plot_main'
h=findobj('tag','handle_fig_plot_main');
figure(h);

array=get_reduced(userdata);
userdata.select_reduced=array;
%array=(userdata.sim<userdata.sim_level)&(userdata.dw_combined<userdata.coda_level)&...
%(userdata.max_int>(userdata.noise_level*userdata.count2intensity));

big_matrix=zeros(nslabs*nrows,sum(array));
for i=1:nslabs;
  index1=(i-1)*nrows+1;
  index2=i*nrows;
  big_matrix(index1:index2,:,:)=squeeze(userdata.data_combined(i,:,array));
end;
%if isempty(bigmatrix);
%corrvalues=[]
corr_values=super_reduce3(big_matrix);
array_corr_values_all=ones(1,ncols);
array_corr_values_all(array)=corr_values;
array=array&(array_corr_values_all<userdata.corr_level);
userdata.select_super_reduced=array;
clear big_matrix;

max2plot=0;
for i=1:nslabs;
  subplot(nslabs,1,i);
  if sum(array)>1;
    y2plot=squeeze(userdata.data_combined(i,:,array));
    plot(userdata.rows_combined,y2plot);
    m=max(y2plot);
    m2=max(m);
    for k=1:length(m);
      f=find(y2plot(:,k)==m(k));
      mp(k)=f(1);
    end;
    hold on;
    m=diag(m);
    m(m==0)=NaN;
    plot(userdata.rows_combined(mp),m,'*');
  
    hold off;
    if max2plot<m2;max2plot=m2;end;
    %hold on;
    
  else;
    plot(NaN);
  end;
  
  if i==1;
    titlestring=['LEVELS: coda: ',num2str(userdata.coda_level,3), ...
        ', noise: ',num2str(userdata.noise_level),...
        '(',num2str(userdata.noise_level*userdata.count2intensity,3),' i.u.)',...
        ', sim: ',num2str(userdata.sim_level),...
        ', corr: ',num2str(userdata.corr_level),...
        '; smth wind.: ',num2str(userdata.window_smooth),...
        ', nvar: ',num2str(sum(array))];
    
    
    title(titlestring);
  end;
  
  set(gca,'tickdir','out');
end;
if max2plot==0;max2plot=1;end;

%SET PROPER SCALE;

for i=1:nslabs;
  subplot(nslabs,1,i);
  axis([userdata.rows_combined([1 end]),0,1.1*max2plot]);
end;
h=findobj('tag','handle_fig_plot_main');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function array=get_reduced(userdata);
array=(userdata.sim<userdata.sim_level)&(userdata.dw_combined<userdata.coda_level)&...
  (userdata.max_int>(userdata.noise_level*userdata.count2intensity));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function comparelcms_sim_callback(option,handle);



%set(0,'showhiddenhandles','on');
try;
  
  h = findobj('tag','handle_fig_menu_main');
  
  %Deal with multible instances of camparelcms.
  if ismember(handle,h)
    userdata = get(handle,'userdata');
  else
    h = getappdata(handle,'parent');
    userdata = get(h,'userdata');
  end
  
  %     h=findobj('tag','handle_fig_menu_main');
  %     userdata=get(h,'userdata');
  %set(0,'showhiddenhandles','on');
catch;
  disp('problems in comparelcms_sim_callback')
  %set(0,'showhiddenhandles','on');
end;

%if isfield(userdata.arg,'handle_fig_plot_spec');
%    if ~ishandle(userdata.arg.handle_fig_plot_spec);
%        set(userdata.arg.handle_slider_main,'enable','on');
%    end;
%end;


%INITIALIZATIONS

%slider_value=get_slider_values(userdata);
[nslabs,nrows,ncols]=size(userdata.data_combined);
option=deblank(option);

%OPTION CODA

if strcmpi(option,'window');
  h = waitbar(0,'Got to do some algebra ....','windowstyle','modal');
  slider_value=get_slider_values(userdata);
  userdata.window_smooth=slider_value(3);
  userdata.sim=comparelcms_simengine(userdata.data_combined,userdata.window_smooth,h);
  close(h);
end;

%OPTION CURSOR

if strcmpi(option,'select');
  userdata=plot_cursor_stuff(userdata);
  set(userdata.arg.handle_fig_menu_main,'userdata',userdata);
  set(userdata.arg.handle_pushbutton_main(2),'enable','on')
  return
end;

%OPTION CLOSE PLOT

if strcmpi(option,'close plot');
  
  if isfield(userdata.arg,'handle_fig_plot_mass_chromatograms');
    if ishandle(userdata.arg.handle_fig_plot_mass_chromatograms);
      delete(userdata.arg.handle_fig_plot_mass_chromatograms);
      return;
    end;
  end;
  if isfield(userdata.arg,'handle_fig_plot_spec');
    if ishandle(userdata.arg.handle_fig_plot_spec);
      delete (userdata.arg.handle_fig_plot_spec);
      %set(userdata.arg.handle_slider_main,'enable','on');
      userdata=plot_results2(userdata);
      %return;
    end;
  end;
  set(userdata.arg.handle_slider_main,'enable','on');
  set(userdata.arg.handle_pushbutton_main(2),'enable','off')
  set(userdata.arg.handle_fig_menu_main,'userdata',userdata);
  return
end; 

userdata=plot_results2(userdata);

set(userdata.arg.handle_fig_menu_main,'userdata',userdata);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [index,dif2]=findindx(array,r);
%function index=findindx(array,r);
%%finds the index of the array element that is closest to r;

%
lengthr=length(r);
index=zeros(1,lengthr);
for i=1:lengthr;
  dif=abs(array-r(i));index2=find(dif==min(dif));index(i)=index2(1);
  dif2(i)=dif(index2(1));
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function userdata=plot_cursor_stuff(userdata);

%INITIALIZATIONS

[nslabs,nrows,ncols]=size(userdata.data_combined);
slider_value=get_slider_values(userdata);

%IF SPECPLOT, CURSOR ACTION FOR SPECPLOT

if isfield(userdata.arg,'handle_fig_plot_spec');
  if ishandle(userdata.arg.handle_fig_plot_spec);
    figure(userdata.arg.handle_fig_plot_spec);
    %TURN ZOOM OFF BEFORE PLOTTING, CAUSES PROBLEMS OTHERWISE
    zoom off
    userdata=plot_mass_chromatograms(userdata);
    return
  end;
end;

%IF NOT SPECPLOT, CREATE SPECPLOT

figure(userdata.arg.handle_fig_plot_main);

%TURN ZOOM OFF BEFORE PLOTTING, CAUSES PROBLEMS OTHERWISE
zoom off

userdata=plot_ms_cursor(userdata);

%INACTIVATE UICONTROLS FOR MAIN FIG

set(userdata.arg.handle_slider_main,'enable','off');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function userdata=plot_ms_cursor(userdata);

%INITIALIZATIONS

[nslabs,nrows,ncols]=size(userdata.data_combined);
slider_value=get_slider_values(userdata);

%ZOOM PLOT IF NECESSARY

synchronize_zoom(userdata);

%GET CURSOR INDEX
set(userdata.arg.handle_fig_plot_main, 'WindowStyle','modal')
[x,y]=ginput(1);
set(userdata.arg.handle_fig_plot_main, 'WindowStyle','normal')

userdata.arg.cursorx_index=findindx(userdata.rows_combined,x);
scan_position=userdata.rows_combined(userdata.arg.cursorx_index);

%CREATE NEW FIGURE

userdata.arg.handle_fig_plot_spec=create_fig('handle_fig_plot_spec');
setappdata(userdata.arg.handle_fig_plot_spec,'parent',userdata.arg.handle_fig_menu_main)
set(userdata.arg.handle_fig_plot_spec,'CloseRequestFcn','comparelcms_sim_interactive(''close_cb_spec'',gcf)',...
  'name','Spec Plot','NumberTitle','off')
%uimenu(gcf,'label','return','callback','close');

%PLOT MS

max_y=-inf;
for i=1:nslabs;
  subplot(nslabs,1,i);
  x=userdata.masses_combined;
  y=squeeze(userdata.data_combined(i,userdata.arg.cursorx_index,:))';
  if max_y<max(y);max_y=max(y);end;
  plotms(x,y,'k');%original data
  if i==1;title(['scan position: ',num2str(scan_position)]);end;
  %array=get_reduced(userdata);
  %array=userdata.select_super_reduced
  hold on
  
  x2=x(userdata.select_reduced);
  y2=y(userdata.select_reduced);
  plotms(x2,y2,'r');%selected variables in red;
  
  a=axis;b=a(1:2);
  plot([min(b), max(b)], [0, 0], 'k');%draw black line to cover read
  
  x2=x(userdata.select_super_reduced);
  y2=y(userdata.select_super_reduced);
  dx=diag(x2);
  m=eye(size(dx));
  dx(m==0)=NaN;
  plot(dx,y2,'v');%plot marker in appropriate color
end;

%SCALE

v=axis;
for i=1:nslabs;
  subplot(nslabs,1,i);
  axis([v(1) v(2) 0 1.1*max_y]);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function userdata=plot_mass_chromatograms(userdata);

%INITIALIZATIONS

[nslabs,nrows,ncols]=size(userdata.data_combined);
slider_value=get_slider_values(userdata);

%ZOOM PLOT IF NECESSARY

synchronize_zoom(userdata);

%GET CURSOR INDEX
set(userdata.arg.handle_fig_plot_spec, 'WindowStyle','modal')
[x,y]=ginput(1);
set(userdata.arg.handle_fig_plot_spec, 'WindowStyle','normal')

userdata.arg.cursorx_index=findindx(userdata.masses_combined,x);
mass_selected=userdata.masses_combined(userdata.arg.cursorx_index);

%CREATE NEW FIGURE

userdata.arg.handle_fig_plot_mass_chromatograms=create_fig('handle_fig_plot_mass_chromatograms');
set(userdata.arg.handle_fig_plot_spec,'name','Mass Chromatograms','NumberTitle','off')
%uimenu(gcf,'label','return','callback','close');

%PLOT MASS CHROMATOGRAMS

max_y=-inf;
for i=1:nslabs;
  subplot(nslabs,1,i);
  x=userdata.rows_combined;
  y=squeeze(userdata.data_combined(i,:,userdata.arg.cursorx_index))';
  if max_y<max(y);max_y=max(y);end;
  plot(x,y);
  if i==1;title(['mass: ',num2str(mass_selected)]);end;
end;

%SCALE

v=axis;
for i=1:nslabs;
  subplot(nslabs,1,i);
  axis([v(1) v(2) 0 1.1*max_y]);
end;

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

function y=string_x(string);
%takes care of _ (underbar) problem in strings for title. etc.
%y=string_x(string);


a=blanks(length(string));
index=find(string=='_');
a(index)='\';
string=[a;string];
string=string(:);
a=string==' ';
%a=(string(1:2:end)==' ')
a=[a ones(length(a),1)];
%a=[a' ;ones(1,length(a))];
a=a(:);

y=string(~a)';

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

function synchronize_zoom(userdata);

[nslabs,nrows,ncols]=size(userdata.data_combined);

h=get(gcf,'children');
h2=get(h,'xlim');
h3=get(h,'ylim');
xlim1=zeros(nslabs,1);
xlim2=xlim1;
ylim2=xlim1;
% for i=1:nslabs;
%     xlim1(i)=h2{i}(1);
%     xlim2(i)=h2{i}(2);
%     ylim2(i)=h3{i}(2);
% end;
index=0;
for i=1:length(h);
  if strcmp(get(h(i),'type'),'axes');
    index=index+1;
    xlim1(index)=h2{i}(1);
    xlim2(index)=h2{i}(2);
    ylim2(index)=h3{i}(2);
  end;
end;


xlim=[max(xlim1) min(xlim2)];
ylim=[0 min(ylim2)];
for i=1:nslabs;
  subplot(nslabs,1,i);axis([xlim ylim]);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
waitbar_limit=100;
if ncols>waitbar_limit
    h_waitbar=waitbar(0,'got to do some algebra .... ');
    set(h_waitbar,'WindowStyle','modal');%keep on foreground
end;
for i=1:ncols;
  if ncols>waitbar_limit;waitbar(i/ncols,h_waitbar);end;
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
if ncols>waitbar_limit;close(h_waitbar);end;

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

function [values,root_name]=read_dso(fn);
%READ_DSO reads dataset object;
%INPUT:
%   filename
%OUTPUT:
%   values is the dso
%   root_name contains the name
values=load(fn);
root_name=fieldnames(values);
values=getfield(values,root_name{1});
%HARD DELETE EXCLUDED DATA
values.data = values.data(values.includ{1},values.includ{2});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function close_cb(handle);

h = findobj('tag','handle_fig_menu_main');

%Deal with multible instances of camparelcms.
if ismember(handle,h)
  userdata = get(handle,'userdata');
else
  h = getappdata(handle,'parent');
  userdata = get(h,'userdata');
end

if isfield(userdata.arg,'handle_fig_plot_mass_chromatograms');
  if ishandle(userdata.arg.handle_fig_plot_mass_chromatograms);
    delete(userdata.arg.handle_fig_plot_mass_chromatograms);
  end;
end;
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

function close_cb_spec(handle);
%SPECIAL CALLBACK FOR CLOSE REQUEST ON SPEC PLOT.

h = findobj('tag','handle_fig_menu_main');

%Deal with multible instances of camparelcms.
if ismember(handle,h)
  userdata = get(handle,'userdata');
else
  h = getappdata(handle,'parent');
  userdata = get(h,'userdata');
end

if isfield(userdata.arg,'handle_fig_plot_mass_chromatograms');
  if ishandle(userdata.arg.handle_fig_plot_mass_chromatograms);
    delete(userdata.arg.handle_fig_plot_mass_chromatograms);
  end;
end;
if isfield(userdata.arg,'handle_fig_plot_spec');
  if ishandle(userdata.arg.handle_fig_plot_spec);
    delete (userdata.arg.handle_fig_plot_spec);
    %set(userdata.arg.handle_slider_main,'enable','on');
    userdata=plot_results2(userdata);
    %return;
  end;
end;
set(userdata.arg.handle_slider_main,'enable','on');
set(userdata.arg.handle_pushbutton_main(2),'enable','off')
set(userdata.arg.handle_fig_menu_main,'userdata',userdata);
return



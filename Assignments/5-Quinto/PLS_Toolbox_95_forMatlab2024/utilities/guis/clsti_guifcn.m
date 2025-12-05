function varargout = clsti_guifcn(varargin)
%CLSTI_GUIFCN Analysis-specific methods for Analysis GUI.
% This is a set of utility functions used by the Analysis GUI only.
%See also: ANALYSIS

%Copyright © Eigenvector Research, Inc. 2023
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%If function not found here then call from pca_guifcn.
if nargin>0;
  try
    switch lower(varargin{1})
      case evriio([],'validtopics')
        options = analysis('options');
        %add guifcn specific options here
        if nargout==0
          evriio(mfilename,varargin{1},options)
        else
          varargout{1} = evriio(mfilename,varargin{1},options);
        end
        return; 
      otherwise
        usepca = {'biplot_Callback','loadsdatabuttoncall','loadsincludchange','loadsinfobuttoncall',...
          'loadsinfobuttoncall_add','plotloads_Callback','scoresclasschange','scoresdatabuttoncall',...
          'scoresincludchange','scoresqconbuttoncall','scorestconbuttoncall','varcapbuttoncall'};
        if ~ismember(char(varargin{1}),usepca) 
          if nargout == 0;
            feval(varargin{:}); % FEVAL switchyard
          else
            [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
          end
        else
          if nargout == 0;
            pca_guifcn(varargin{:}); % FEVAL switchyard
          else
            [varargout{1:nargout}] = pca_guifcn(varargin{:}); % FEVAL switchyard
          end
        end
    end
  catch
    erdlgpls(lasterr,[upper(mfilename) ' Error']);
  end   
end

%----------------------------------------------------
function gui_init(h,eventdata,handles,varargin);
%create toolbar
[atb abtns] = toolbar(handles.analysis, 'clsti','');
handles  = guidata(handles.analysis);

%Enable correct buttons.
analysis('toolbarupdate',handles)  %set buttons

analysis('ssqvisible',handles,'off')

%turn off crossvalidation
setappdata(handles.analysis,'enable_crossvalgui','off');

set(handles.preprocess,'enable','off');
set(handles.refine,'enable','off');
set(handles.tools,'enable','off');

%general updating
myObj = evrigui(handles.analysis);
if ~isempty(myObj.getXblock)
  myObj.clearBothCal;
end
analysis('updatestatusboxes',handles)
updatefigures(handles.analysis)

%----------------------------------------------------
function gui_deselect(h,eventdata,handles,varargin)
closefigures(handles);
panelmanager('delete',panelmanager('getpanels',handles.ssqframe),handles.ssqframe)
setappdata(handles.analysis,'enable_crossvalgui','on');
%Clear table.
% mytbl = getappdata(handles.analysis,'ssqtable');
% clear(mytbl,'all');

%----------------------------------------------------
function gui_updatetoolbar(h,eventdata,handles,varargin)
pca_guifcn('gui_updatetoolbar',h,eventdata,handles,varargin);

statmodl = getappdata(handles.analysis,'statmodl');
%obj = evrigui('analysis','-reuse');
obj = evrigui(handles.analysis);
myPred = obj.getPrediction;
if isempty(myPred)
  %set(handles.calcmodel,'enable','off');
  set(handles.plotloads,'enable','off');
  set(handles.plotscores,'enable','off');
else
  set(handles.plotloads,'enable','on');
  set(handles.plotscores,'enable','on');
end


%----------------------------------------------------
function out = isdatavalid(xprofile,yprofile,fig)
%two-way x
out = xprofile.data & xprofile.ndims==2;

%multi-way x
% out = xprofile.data & xprofile.ndims>2;

%discrim: two-way x with classes OR y
% out = xprofile.data & xprofile.ndims==2 & (xprofile.class | (yprofile.data & yprofile.ndims==2) );

%two-way x and y
% out = xprofile.data & xprofile.ndims==2 & yprofile.data & yprofile.ndims==2;

%multi-way x and y
% out = xprofile.data & xprofile.ndims>2 & yprofile.data;

%--------------------------------------------------------------------
function out = isyused(handles)

out = true;

%----------------------------------------------------
function calcmodel_Callback(h,eventdata,handles,varargin);

% statmodltest = lower(getappdata(handles.analysis,'statmodl'));
% 
% switch statmodltest
%   case {'none', 'calnew'}
%     %prepare X-block for analysis
%     x = analysis('getobjdata','xblock',handles);
%     y = analysis('getobjdata','yblock',handles);
% 
%     if isempty(x.includ{1});
%       erdlgpls('All samples excluded. Can not calibrate','Calibrate Error');
%       return
%     end
%     
%     preprocessing = {getappdata(handles.preprocessmain,'preprocessing') getappdata(handles.preproyblkmain,'preprocessing')};    
%     
%     ppdesc = {};
%     if ~isempty(preprocessing{1})
%       ppdesc = {preprocessing{1}.description};
%     end
%     if ~isempty(preprocessing{2}) & ~isempty(y)
%       ppdesc = {ppdesc{:} preprocessing{2}.description};
%     end
%     if ~isempty(ppdesc) & any(ismember(ppdesc,{ 'Autoscale' 'Center' 'Mean Center' 'Median Center' 'SNV' 'Detrend' }));
%       switch evriquestdlg({'One or more of your selected preprocessing methods includes a centering step (e.g. Autoscale, Mean Centering, Detrend) and is likely to produce a poor CLS model.',...
%           ' ','Are you sure you want to calculate the model now?'},'Preprocessing Warning','Yes','No','Yes');
%         case 'No'
%           return
%       end
%     end
%     
%     opts = getappdata(handles.analysis,'analysisoptions');
%     if isempty(opts)
%       opts = cls('options');
%     end
%     
%     opts.display       = 'off';
%     opts.plots         = 'none';
%     opts.preprocessing = preprocessing;
%     
%     if isempty(y) || (isdataset(y) && isempty(y.data))
%       %y-block is empty, do special tests for diagy mode
%       if getappdata(handles.analysis,'clsxaspure');
%         answer = 'Yes';
%       else
%         answer = evriquestdlg('No y-block is currently loaded. CLS will use the X-block as a set of pure component spectra. Continue?','No Y-block','Yes','Yes, always','Cancel','Yes');
%       end
%       switch answer
%         case 'Cancel'
%           return
%         case 'Yes, always'
%           setappdata(handles.analysis,'clsxaspure',1);
%       end
%       
%       if length(x.include{2})<length(x.include{1})
%         erdlgpls({'You have more components than you do variables. A CLS model will not work in these conditions. Suggestions:' 'a) Verify that all samples in your X-block are pure component samples or' 'b) Remove some components or' 'c) Collect additional variables' },'Too few variables')
%         return
%       end
%       
%       %remove preprocessing (doesn't really work with empty y-block)
%       opts.preprocessing{2} = [];
%       
%     else
%       %y-block isn't empty...
%       %check if number of components>number of VARIABLES
%       if length(x.include{2})<length(y.include{2})
%         erdlgpls({'You have more components than you do variables. A CLS model will not work in these conditions. Suggestions:' 'a) Remove some y-block columns (i.e. components) or' 'b) Add additional x-block variables'},'Too few variables')
%         return
%       end
% 
%       %check if number of components>number of SAMPLES
%       if length(x.include{1})<length(y.include{2})
%         erdlgpls({'You have more components than you do samples. A CLS model will not work in these conditions. Suggestions:' 'a) Remove some y-block columns (i.e. components) or' 'b) Add additional samples.'},'Too few samples')
%         return
%       end
%     end
%     
%     %calculate model
%     modl    = cls(x,y,opts);
%     pc      = size(modl.loads{2},2);   %may have been reduced from what we asked for
%       
%     if ~isempty(y) || (isdataset(y) && ~isempty(y.data));
%       cvmode = crossvalgui('getsettings',getappdata(handles.analysis,'crossvalgui'));
%       if ~strcmp(cvmode,'none');
%         modl = crossvalidate(handles.analysis,modl);
%       end
%     end
% 
%     %UPDATE GUI STATUS
%     %set status windows
%     setappdata(handles.analysis,'statmodl','calold');
%     analysis('setobjdata','model',handles,modl);
%     
%     updatessqtable(handles,pc);
%     
% end
% 
if analysis('isloaded','validation_xblock',handles)
  %apply model to new data
  [x,y,modl] = analysis('getreconciledvalidation',handles);
    if isempty(x); return; end  %some cancel action
  
  opts = getappdata(handles.analysis,'analysisoptions');
  if isempty(opts)
    opts               = clsti('options');
  end
  opts.display       = 'off';
  opts.plots         = 'none';
  try
    test = modl.apply(x,y,opts);
  catch
    erdlgpls({'Error applying CLSTI model to validation data.',lasterr,'Model not applied.'},'Apply Model Error');
    test = [];
  end

  analysis('setobjdata','prediction',handles,test)

else
  %no test data? clear prediction
  analysis('setobjdata','prediction',handles,[]);  
end

analysis('updatestatusboxes',handles);
analysis('toolbarupdate',handles)  %set buttons

%delete model-specific plots we might have had open
h = getappdata(handles.analysis,'modelspecific');
close(h(ishandle(h)));
setappdata(handles.analysis,'modelspecific',[]);

%update plots
updatefigures(handles.analysis);     %update any open figures
figure(handles.analysis)

%--------------------------------------------------------------------
function updatefigures(h)
%update any open figures

pca_guifcn('updatefigures',h);

%-------------------------------------------------
function updatessqtable(handles,pc)

%----------------------------------------
function closefigures(handles)
%close the analysis specific figures

pca_guifcn('closefigures',handles);

%----------------------------------------
function clstiModelBuilder_callback(hObject,eventdata,handles)
modl = analysis('getobjdata','model',handles);
if isempty(modl)
  clsti_gui(handles);
else
  clsti_gui(modl,handles);
end


%------------------------------------------------
function ind = locateincache(cache,lookfor)

ncomp = [];
for j=1:length(cache);
  ncomp(j) = size(cache{j}.loads{2,1},2);
end

ind = find(ncomp==lookfor);


%----------------------------------------------------
function  optionschange(h)

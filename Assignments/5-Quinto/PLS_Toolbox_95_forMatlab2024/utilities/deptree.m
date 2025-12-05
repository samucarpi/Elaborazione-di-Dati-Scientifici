function deptree(varargin)
%DEPTREE Interactive m-file dependency tree
% Optional keywords:
%    *evri  - include EVRI folders in tree
%    *subfolders - include subfolders of current in tree
%    *php   - do for PHP files
%    <filename> - give tree relative to given filename
%
%I/O: deptree filename evri subfolders

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

fig = findobj('tag','deptree');
if isempty(fig);
  fig = figure('tag','deptree','color',[1 1 1],'menubar','none','numbertitle','off','integerhandle','off','name','M-File Dependency Tree');
  
  mh1 = uimenu(gcf,'label','File');
  mh2 = uimenu(mh1,'label','Open Folder...','callback','deptree *openfolder');
  mh2 = uimenu(mh1,'label','Close','callback','close(gcbf)','separator','on');
  mh1 = uimenu(gcf,'label','View','callback','deptree *view');
  mh2 = uimenu(mh1,'label','Maximum Levels','callback','deptree *checklevel','tag','maxlevel');
  for j = [2:10 15 20];
    uimenu(mh2,'label',num2str(j),'callback',['deptree *update *maxlevel ' num2str(j) ])
  end
  mh2 = uimenu(mh1,'label','Show Hidden Branches','callback','deptree *showall','tag','showall');
  
end
itemcontext = findobj(fig,'tag','itemcontext');
if isempty(itemcontext)
  figure(fig);
  itemcontext = uicontextmenu('tag','itemcontext');
  set(itemcontext,'callback','deptree *contextmenu');
  uimenu(itemcontext,'label','Hide Branch','callback','deptree *trim','tag','itemtrim');
  uimenu(itemcontext,'label','Open M-File','callback','deptree *edit','tag','itemedit');
end

if nargin==0;
  varargin = {'new'};
end

%handle command-line options
options.folders        = {pwd};
options.warningfolders = [];
options.notrace        = {};
options.target         = [];
options.maxlevel       = 20;
options.ignoremissing  = false;
options.fileformat     = '.m';
files                  = [];
for ind = 1:nargin;
  if isa(varargin{ind},'cell');
    options.folders = varargin{ind};
  else
    switch varargin{ind}
      case '*reload';
        options = getappdata(fig,'options');
      case '*update';
        options = getappdata(fig,'options');
        data    = getappdata(fig,'data');
        if isstruct(data);
          files     = data.files;
          xref      = data.xref;
          nlinks    = data.nlinks;
        end
      case '*php'
        options.fileformat = '.php';
      case '*subfolders'
        options.folders = dirtree(options.folders);
      case '*warningsub'
        options.warningfolders = dirtree(options.folders);
      case '*top'
        options.target  = [];
        options.notrace = {};      
      case '*ignoremissing'
        options.ignoremissing = true;
      case '*evri'
        options.warningfolders = which('evrirelease','-all');
        for k=1:length(options.warningfolders);
          options.warningfolders{k} = fileparts(options.warningfolders{k});
        end
        options.warningfolders = dirtree(options.warningfolders);

        %---------------------------------------------------
        %  Figure Menu commands (File, View, etc)

      case '*openfolder'
        folder = uigetdir(pwd,'Trace dependency on folder:');
        if ~isstr(folder)
          return
        end
        cd(folder)
        deptree
        return        

      case '*view'
        options = getappdata(fig,'options');
        if ~isempty(options.notrace)
          enb = 'on';
        else
          enb = 'off';
        end
        set(findobj(gcbo,'tag','showall'),'enable',enb);
        return        
        
      case '*checklevel'
        options = getappdata(fig,'options');
        set(allchild(gcbo),'checked','off');
        set(findobj(gcbo,'label',num2str(options.maxlevel)),'checked','on');
        return
        
      case '*maxlevel';
        options.maxlevel = str2num(varargin{ind+1});
        varargin{ind+1} = '*';
        
      case '*';
        %ignore this (set by maxlevel)

      case '*showall'
        options = getappdata(fig,'options');
        options.notrace = {};
        setappdata(fig,'options',options);
        deptree *update
        return

        %---------------------------------------------------
        %  Right- and left-click commands
      case '*click';
        options = getappdata(fig,'options');
        if ~strcmp(get(gcf,'selectiontype'),'normal');
          setappdata(fig,'lastclick',varargin{ind+1});
          if ismember(varargin{ind+1},options.notrace)
            lbl = 'Show Branch';
          else
            lbl = 'Hide Branch';
          end           
          set(findobj(itemcontext,'tag','itemtrim'),'label',lbl)
          return
        end
        options.notrace = setdiff(options.notrace,varargin{ind+1});
        setappdata(fig,'options',options);
        deptree('*update',varargin{ind+1});
        return;

      case '*contextmenu'
        fn = getappdata(fig,'lastclick');
        options = getappdata(fig,'options');
        if ismember(fn,options.notrace)
          trim = 'Show';
        else
          trim = 'Hide';
        end
        set(findobj(gcbo,'tag','itemedit'),'label',['Edit "' fn options.fileformat '"']);
        set(findobj(gcbo,'tag','itemtrim'),'label',[trim ' Branch Below "' fn '"']);
        return;
        
      case '*trim'
        fn = getappdata(fig,'lastclick');
        options = getappdata(fig,'options');
        if ismember(fn,options.notrace)
          options.notrace = setdiff(options.notrace,{fn});
        else
          options.notrace = union(options.notrace,{fn});
        end
        setappdata(fig,'options',options);
        deptree *update
        return
      
      case '*edit'
        fn = getappdata(fig,'lastclick');
        options = getappdata(fig,'options');
        if strcmp(options.fileformat,'.m')
          options.fileformat = '';
        end
        edit([fn options.fileformat]);
        return

      otherwise
        options.target = varargin{ind};
    end
  end
end
matchfolders = lower([options.folders; options.warningfolders]);

%get list of files and depenencies
if isempty(files)
  for mypath=options.folders(:)';
    [junk,top] = fileparts(mypath{1});
    if top(1)=='@'; continue; end  %skip object folders
    onedir = dir(fullfile(mypath{1},['*' options.fileformat]));
    temp = {};
    for j=1:length(onedir);
      [pth,fn,ext] = fileparts(onedir(j).name);
      temp{j} = fn;
    end
    files = union(files,temp);
  end

  xref   = cell(length(files),4);
  nlinks = zeros(length(files),2);
  if length(files)>10;
    wbh = waitbar(0,'Getting Dependencies');
  else
    wbh = [];
  end
  for k = 1:length(files);

    if strcmp(options.fileformat,'.m');
      ispresent = exist(files{k});
    else
      ispresent = exist([files{k} options.fileformat]);
    end

    if ispresent;
      %locate files this function uses
      if strcmp(options.fileformat,'.m');
        if checkmlversion('>=','8.3')
          uses = matlab.codetools.requiredFilesAndProducts(files{k},'toponly');
        else
          [uses, builtins, classes, prob_files] = depfun(files{k},'-toponly','-quiet','-nosort');
        end
      else
        uses = phpuses(files{k});
      end

      %only keep the ones which are in the matchfolders list (source or
      % other special folder)
      keep = [];
      for findx=1:length(matchfolders);
        keep = union(keep,strmatch(matchfolders{findx},lower(uses)));
      end
      uses = uses(keep);

      %check for items which are in warning folder
      inwarning = 0;
      for findx=1:length(options.warningfolders);
        if ~inwarning;
          inwarning = ~isempty(strmatch(options.warningfolders{findx},lower(uses)));
        else
          break
        end
      end

      %remove the path and extension from those filenames
      for j=1:length(uses);
        [pth,fn,ext] = fileparts(uses{j});
        uses{j}=[fn];
      end

      %check for ones missing from list
      missing = find(~ismember(uses,files));  %match up with file list index
      if ~isempty(missing) & ~options.ignoremissing
        newitems = length(files)+[1:length(missing)];
        [files{newitems}] = uses{missing};
        [xref{newitems,1}] = uses{missing};
        [xref{newitems,4}] = deal(1);
      end

      %locate them in the file list
      uses = find(ismember(files,uses));  %match up with file list index
      uses = setdiff(uses,k);  %remove self
      uses = uses(:)';
    else
      uses = [];
      inwarning = 1;
    end

    uses = uses(:)';  %row-vectorize
    %assemble into results
    xref{k,1}   = files{k};
    xref{k,2}   = uses;
    xref{k,4}   = inwarning;
    nlinks(k,1) = length(uses);

    %add this fn to the "called by" list of those functions
    for j = uses;
      xref{j,3} = union(xref{j,3},k);
      nlinks(j,2) = length(xref{j,3});
    end

    if ishandle(wbh);
      waitbar(k/length(files));
    end
  end
  if ishandle(wbh);
    delete(wbh);
  end

  data.files = files;
  data.xref = xref;
  data.nlinks = nlinks;
  setappdata(fig,'data',data);
end
setappdata(fig,'options',options);

%- - - - - - - - - - - - - - - - - - - -
%prep figure

invert = getappdata(gcf,'invert');
if isempty(invert); invert = 0; end
set(gcf,'resizefcn',['deptree *update']);

%- - - - - - - - - - - - - - - - - - - -
%decide who is in level 1
levels = zeros(size(xref,1),1);
if ~isempty(options.target)
  %user requested a given function - try it as level2
  level2 = min(find(ismember(files,options.target)));
  if ~isempty(level2);
    level1 = xref{level2,3};
    if ~isempty(level1);
      %put parents of that fn as level1
      levels(level1) = 1;
    else
      %no parents? use fn named as level1
      levels(level2) = 1;
      level2 = [];
    end
  end
end
if ~any(levels==1);
  % level1 is those with no parental calls
  levels(nlinks(:,2)==0) = 1;
  level2 = [];  %undefined level2 (not pre-specified)
  invert = false;
end


%- - - - - - - - - - - - - - - - - - - -
%trace levels
lev = 0;
traced = zeros(1,size(xref,1));
traced(find(ismember(xref(:,1),options.notrace))) = 1;
if invert;
  linkcolumn = 3;
else
  linkcolumn = 2;
end
nextlevel = inf;  %start loop
while ~isempty(nextlevel)
  lev       = lev+1;
  nextlevel = [];
  for item = find(levels(:,lev))';
    if ~traced(item);
      links = xref{item,linkcolumn};
      if lev==1 & ~isempty(level2);
        links = intersect(level2,links);
      else
        traced(item) = 1;
      end
      nextlevel = [nextlevel links];
    end
  end
  levels(nextlevel,lev+1) = 1;
end
nlevels = min(lev,options.maxlevel);


%- - - - - - - - - - - - - - - - - - - -
%rowmap allows us to remove unlisted functions and thus compress map
rowmap = ones(1,size(xref,1));
use    = find(sum(levels,2)>0);
nused  = length(use);
rowmap(use) = 1:nused;  %remap used to first n rows of image

%prep axes
cla
set(gca,'units','normalized','position',[0.02642857142857   0.04095238095238   0.84642857142857   0.93642857142857]);
axis ij;
axis([1 max(2,nlevels) 0 max(2,nused+1)])
axis off
shg

if ~isempty(options.target)
  h = text(1,0,'[ <-Top Level Tree ]');
  set(h,'buttondownfcn','deptree *update *top','color',[0 0 1]);
end
h = text(1,max(2,nused+1),'[ Reload ]');
set(h,'buttondownfcn','deptree *reload','color',[0 0 1]);

%do plot
clrs = get(gca,'colororder');
traced = zeros(1,size(xref,1));
traced(find(ismember(xref(:,1),options.notrace))) = 2;
for lev = 1:nlevels;
  for item = find(levels(:,lev))';
    if xref{item,4}
      clr = [1 0 0];
      weight = 'bold';
      edgecolor = [1 0 0];
    else
      clr = clrs(mod(rowmap(item)-1,size(clrs,1))+1,:);
      weight = 'normal';
      edgecolor = 'none';
    end

    lbl = xref{item,1};
    if lev==options.maxlevel;  %if user has requested a limited number of levels
      traced(item) = 2;  %show as "blocked"
    end
    if traced(item)==2;
      lbl = [lbl '>>'];
    end
    h = text(lev,rowmap(item),lbl);
    set(h,'color',clr,'fontweight',weight,'edgeColor',edgecolor,'interpreter','none');

    if ~traced(item);
      ext = get(h,'extent');

      links = xref{item,linkcolumn};
      if lev==1 & ~isempty(level2);
        links = intersect(level2,links);
      else
        traced(item) = 1;
      end
      for j = links;
        lh = line([ext(1)+ext(3) (ext(1)+1)],[rowmap(item) rowmap(j)],'color',clr);
        if xref{j,4}
          set(lh,'linestyle','--');
        end
      end;
    end
    set(h,'buttondownfcn',['deptree *click ' xref{item,1}])
    set(h,'uicontextmenu',itemcontext);

  end
end

%--------------------------------------------
function folders = dirtree(folders)

for k=1:length(folders);
  new = dir(folders{k});
  new = {new([new.isdir]).name};
  new(strmatch('.',new)) = [];
  if ~isempty(new);
    for j=1:length(new);
      new{j}  = fullfile(folders{k},new{j});
      folders = union(folders,dirtree(new(j)));
    end
  end
end
folders = folders(:);

%-------------------------------------------
function uses = phpuses(filename)

uses = {};
fid = fopen([filename '.php'],'r');
while ~feof(fid);
  line = fgetl(fid);

  %drop everything after comment marks
  comment = findstr(line,'//');
  if ~isempty(comment);
    line = line(1:min(comment)-1);
  end

  %locate includes/requires
  incl = [findstr(line,'include') findstr(line,'require')];
  for ind = 1:length(incl);
    %parse line for included or required file
    open = min(findstr(line(incl(ind):end),'(')+incl(ind));
    close = min(findstr(line(open:end),')')+open);

    fnname = line(open+1:close-3);
    if ~isempty(fnname)
      uses = [uses {fullfile(pwd,[fnname])}];
    end
  end
  incl = [findstr(lower(line),' href') findstr(lower(line),' action')];
  for ind = 1:length(incl);
    %parse line for linked
    line = strrep(line,'''','"');
    open = min(findstr(line(incl(ind):end),'"')+incl(ind));
    close = min(findstr(line(open:end),'"')+open);

    fnname = line(open:close-2);
    if ~isempty(fnname)
      [pth,fnname,ext]=fileparts(fnname);
      if ~isempty(fnname) & ~any(fnname=='@') & exist([fnname ext])
        uses = [uses {fullfile(pwd,[fnname])}];
      end
    end
  end

end
fclose(fid);
uses = unique(uses);

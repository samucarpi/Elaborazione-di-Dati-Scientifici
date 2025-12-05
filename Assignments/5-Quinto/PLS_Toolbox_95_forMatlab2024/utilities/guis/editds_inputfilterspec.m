function [ffilter,fmethod] = editds_inputfilterspec
%EDITDS_INPUTFILTERSPEC returns filter spec string for use in load dialogs.
% Filter spec contains all possible file types that can be read based on
% import list

%Copyright Eigenvector Research, Inc. 2015
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

ft = editds_defaultimportmethods;
isfile = ~cellfun('isempty',ft(:,4));
issep = cellfun(@(s) s(1)=='-', ft(:,1));
fmethod = ft(:,2);
ffilter = [cellfun(@(c) sprintf('*.%s;',c{:}),ft(:,4),'uniformOutput',0) ft(:,1) ];
[ffilter{issep,1}] = deal('.');
ffilter(~isfile&~issep,:) = [];
fmethod(~isfile&~issep) = [];
issep(~isfile&~issep) = [];
while issep(end)
  ffilter(end,:) = [];
  fmethod(end) = [];
  issep(end) = [];
end
ffilter = [{'*.*' 'All Files'; '.' '--------------------------------------'};ffilter];
fmethod = [{''}; {''}; fmethod];

if length(fmethod)>24 & ispc & checkmlversion('<','7.14')
  %fix for bug which crashes some Matlab versions on PC
  %identify which filters we HAVE to include because they have file types we
  %can't identify by unique extension
  
  force = {'*.*'; '*.0'; '*.xml'; '*.bif'; '*.hdr' };  %FORCE these extensions to be included
  donotshow = {'*.mat'; '*.tiff'; '*.mtf'};  %HIDE these always
  
  list = cellfun(@(l) str2cell(regexprep(l,';','\n')),ffilter(:,1),'uniformoutput',0);  %expand file types into cell
  alist = lower(cat(1,list{:}));  %get ALL file types
  [ualist,ui,uj] = unique(alist);  %get unique extension list
  nu = setdiff(1:length(uj),ui);  %identifies items dropped for being non-unique
  nulist = alist(nu);  %which extensions appear in more than one filter
  nulist = [force; nulist];  %add in forced extensions
  nuext = cellfun(@(l) any(ismember(l,nulist)),list);  %boolean: which filters list these extensions
  hide  = cellfun(@(l) any(ismember(l,donotshow)),list);  %boolean: which must be hidden
  nuext(hide) = 0;  %always hide these ones

  if sum(nuext)<24
    %add back methods until we reach 24 items (the approx. threshold for the
    %problem we've seen)
    issep = cellfun(@(s) s(1)=='-', ffilter(:,2));
    sepind = find(issep);
    inst = sepind(2);
    nuext(inst:end) = ~hide(inst:end) & (nuext(inst:end) | cumsum((~hide(inst:end) & ~nuext(inst:end)))<=(24-sum(nuext)));
  end
  
  ffilter = ffilter(nuext,:);
  fmethod = fmethod(nuext,:);
  
elseif checkmlversion('>=','7.14')
  %late enough version of Matlab? add in "readable" item
  use = isfile;
  use(isfile) = cellfun(@(c) ~ismember('*',c),ft(isfile,4));
  alltypes = cellfun(@(c) sprintf('*.%s;',c{:}),ft(use,4),'uniformoutput',0);
  alltypes = [alltypes{:}];
  ffilter = [{alltypes 'Readable Files'};ffilter];
  fmethod = [{''}; fmethod]; 
end

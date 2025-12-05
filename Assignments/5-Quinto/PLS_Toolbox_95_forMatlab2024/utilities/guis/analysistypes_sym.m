function out = analysistypes_sym
%ANALYSISTYPES_SYM Support method for analysistypes adding symbolic links.
%I/O: list = analysistypes_sym;
%
%See also: ANALYSISTYPES

%Copyright Eigenvector Research 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

persistent list

%This list includes items which should SHOW in the Analysis menu of
%Analysis window, but which aren't methods supported directly by Analysis.
%They can't be added to the main analysistypes list because drag/drop
%methods require that list to indicate ONLY methods which Analysis handles
%directly.

if isempty(list)
  %NOTE: although newer versions of Matlab will NOT use the "separator"
  %column (because separators are determined by the Category changes), it
  %is still required to allow separating the methods in the list 
  %for older versions of Matlab. It CANNOT be removed from this list.

  options = analysistypes('options');

  %Order of columns:
  %    tag                Label                          Function        separator  Category      order
  list = {
    'multiblocktool'    'Multiblock Modeling'            'multiblocktool'     'off'  'Data Fusion'     7;
    'modelselector'     'Hierarchical Modeling'          'modelselector'     'off'  'Data Fusion'     7;
    };

  if ~isempty(options.show)
    if ~iscell(options.show)
      options.show = {options.show};
    end
    if length(options.show)~=1 | ~strcmpi(options.show{1},'all')
      %if some items are listed in option "show", ONLY give those options
      list = list(ismember(list(:,1),options.show),:);
    end
  end

end

out = list;

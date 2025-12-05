function editdefaultcolormap
%EDITDEFAULTCOLORMAP - Select and save default colormap.
%
%I/O: editdefaultcolormap
%
%See also: PCOLOR, RWB

% Copyright © Eigenvector Research, Inc. 2024
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

% TODO: Maybe add reset to "factory" option. 

%Get list of current colormaps that are available in older versions of MATLAB. 
base_maps = { 'autumn' ; 'bone' ; 'colorcube' ; 'cool' ;
  'copper' ; 'flag' ; 'gray' ; 'hot' ;
  'hsv' ; 'jet' ; 'lines' ; 'parula' ;
  'pink' ; 'prism' ; 'spring' ; 'summer' ;
  'turbo' ; 'vga' ; 'white' ; 'winter' };

try %Don't make this fatal, just use default base maps if fail.
  if checkmlversion('>=','9.14')
    %Look for newer maps that were added after 22b, e.g., sky and abyss
    mymaps = dir([fileparts(which('hot.m')) filesep '*.m']);
    mymaps = {mymaps.name}';
    mymaps = setdiff(mymaps,{'linestyleorder.m' 'colororder.m' 'orderedcolors.m' 'validatecolor.m'});
    if length(mymaps)>length(base_maps)
      mymaps = replace(mymaps,'.m','');
      base_maps = mymaps;
    end
  end
end

%Add PLS_Toolbox map
base_maps{end+1} = 'rwb';

[indx,tf] = listdlg('PromptString','Select a colormap to set as default:',...
    'SelectionMode','single','ListString',base_maps);

if tf
  set(0,'DefaultFigureColormap',feval(base_maps{indx}));
end

end
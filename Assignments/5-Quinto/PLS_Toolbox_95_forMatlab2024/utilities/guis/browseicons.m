function icon = browseicons(name,icon,force);
%BROWSEICONS retrieve icons for the EVRI Workspace Browser
%
%I/O: browseicons(name)        %retrieve icon
%I/O: browseicons(name,icon)   %add icon to icon file
%I/O: browseicons(name,[])     %clear icon from icon file
%I/O: browseicons(name,[],1)   %clear icon from icon file without warning
%
%See also: BROWSE

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

persistent icons

if isempty(icons)
  icons = load('browseicons');
end

if nargin==0
  icon = icons;
  return
end

if strcmp(name,'icons')
  showicons('browseicons.mat')
  return
end

if nargin==1
  if isfield(icons,name);
    icon = getfield(icons,name);
  else
    icon = icons.shortcut;
  end
  return
end

%more than one input, create new icon

%write icon to file
if isempty(icon)
  %remove icon
  if ~isfield(icons,name)
    %don't bother, it isn't there
    clear icons
    return
  end
  icons = rmfield(icons,name);
  if  nargin<3
    warning('EVRI:BrowseiconsIconRemoved','icon "%s" removed from icon file',name)
  end

else
  %add icon

  %check icon size and type
  if ~isa(icon,'uint8')
    error('Icon must be uint8 format')
  end
  if ndims(icon)~=3
    error('Icon must be RGB (3 slabs)')
  end
  if isfield(icons,name) & nargin<3
    error('Icon already exists')
  end
  icons.(name) = icon;

end
save(which('browseicons.mat'),'-struct','icons','-V6')

clear icon icons

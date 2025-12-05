function tbicons = gettbicons(iconname,icon,force)
%GETTBICONS Return structure with all toolbox toolbar icons.
% Utility for adding, retrieving, and deleting icons from the icon store.
%  
% Use toolbar('icons'); to see all icons.
%
%I/O: icons = gettbicons
%I/O: cdata = gettbicons('blank');%Return cdata for named icon.
%I/O: gettbicons('blank','remove_icon');%Remove named icon.
%I/O: gettbicons(iconname,icon_cdata)   %add icon to icon file
%I/O: gettbicons('','C:\path\to\icons')   %Load all png, jpg, gif files in directory. 
%
%See also: TOOLBAR TOOLBAR_BUTTONSETS

%Copyright Eigenvector Research 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk 02/04/04 initial coding
%rsk 05/01/06 remove <R14 legacy icons for more consistent look.

%SEE https://thenounproject.com/ for icon ideas.

tbicons = load('tbimg7');
if nargin==0
  return
end

if nargin==1 
  %Return cdata for named icon.
  tbicons = getfield(tbicons,iconname);
  return
end

if ischar(icon)
  if strcmp(icon,'remove_icon')
    %Remove icon from file if it's there.
    if ~isfield(tbicons,iconname)
      %don't bother, it isn't there
      clear tbicons
      return
    end
    tbicons = rmfield(tbicons,iconname);
    if  nargin<3
      warning('EVRI:GettbiconsIconRemoved','icon "%s" removed from icon file',iconname)
    end
  elseif exist(icon)==7
    %Load all image files in directory.
    img_files = [dir(fullfile(icon,'*.png')); dir(fullfile(icon,'*.jpg')); dir(fullfile(icon,'*.gif'))];
    for i = 1:length(img_files)
      thisicon_cdata = imread(fullfile(icon,img_files(i).name));
      thisname = img_files(i).name(1:end-4);
      checkicon(tbicons,thisname,thisicon_cdata)
      tbicons.(thisname) = thisicon_cdata;
    end
  end
else
  %add single icon
  checkicon(tbicons,iconname,icon)
  tbicons.(iconname) = icon;
end

save(which('tbimg7.mat'),'-struct','tbicons','-V6')

clear tbicons

%-----------------------------------------------
function checkicon(tbicons,iconname,icon)
  %check icon size and type
  if ~isa(icon,'uint8')
    error('Icon must be uint8 format')
  end
  if ndims(icon)~=3
    error('Icon must be RGB (3 slabs)')
  end
  if isfield(tbicons,iconname) & nargin<3
    error('Icon "%s" already exists',iconname)
  end

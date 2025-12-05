function updateicon(obj,mystruct, jleaf)
%EVRITREE/UPDATEICON Updaste "checked" icons for sibling leaf nodes.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if ~isfield(mystruct,'icn')
  return
end

persistent jIcons

jt = obj.java_tree;

[junk,myicn] = fileparts(mystruct.icn);

if strcmp(myicn,'evri_uncheck') & ~isempty(jIcons)
  %Save icons so don't have to read them in every time. 
  jImage_off = jIcons.joff;
  jImage_on  = jIcons.jon;
else
  [I_off,map_off] = imread(mystruct.icn);
  [I_on,map_on] = imread(mystruct.chk);

  jImage_off = im2java(I_off,map_off);
  jImage_on = im2java(I_on,map_on);
  
  if strcmp(myicn,'evri_uncheck')
    jIcons.joff = jImage_off
    jIcons.jon  = jImage_on
  end
  
end

set(jleaf,'Icon',jImage_on)

if isfield(mystruct,'chk')
  
  %Step through siblings down.
  mysib = jleaf;
  while true
    mysib = mysib.getNextSibling;
    if isempty(mysib)
      break
    else
      set(mysib,'Icon',jImage_off);
    end
  end
  
  %Step through siblings up.
  mysib = jleaf;
  while true
    mysib = mysib.getPreviousSibling;
    if isempty(mysib)
      break
    else
      set(mysib,'Icon',jImage_off);
    end
  end
  jt.repaint
end

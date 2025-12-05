function out = evriwhich(varargin)
%EVRIWHICH Which to search additional stand-alone application folders.
% This version of which searches the PWD and other Solo-specific folders
% which wouldn't otherwise get searched in a stand-alone application.
% The input and output are identical to the built-in which call. Note
% that special folders are ONLY searched if the file requested has an
% extension associated with it. When no extension is given, the search is
% for an m- or p-file and, when stand-alone, these files should NEVER take
% precidence over the CTF-extracted files. Thus, which('name') where name
% has no extension always returns a result identical to the built-in call.
%
%I/O: list = evriwhich

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin>1 & strcmp(varargin{end},'-all');
  findall = true;
else
  findall = false;
end

fn = varargin{1};
found = {};

[p,f,e] = fileparts(fn);
if ~isempty(e) & nargin<3
  %extension given - we can search several "special" folders for Solo
  dllfolder = char(getappdata(0,'dllfolder'));
  topfolder = fileparts(fileparts(fileparts(dllfolder)));
  
  toSearch = {pwd dllfolder topfolder};
  
  %look through those folders
  for totest = toSearch;
    if isempty(totest{:}) | strcmp(totest{:},'/')
      %Make sure not just NIX root "/" doesn't generate false positive in
      %exist e.g., 
      %>>  exist('/pca.m','file')
      %  ans =
      %        2
      % Even though /pca.m doesn't exist in root folder.
      continue; 
    end
    item = fullfile(totest{:},fn);
    if exist(item,'file')
      %found one in this folder
      switch findall
        case true
          %wanted -all, add and keep looking
          found{end+1} = item;
        otherwise
          %only needed one, return this
          out = item;
          return;
      end
    end
  end
end

switch findall
  case true
    % -all flag used - need ALL possible items
    others = builtin('which',fn,'-all');
    others(ismember(others,found)) = [];  %drop duplicates
    out = [found(:); others(:)];
    
  otherwise
    %no -all flag - only need first one found
    if isempty(found);
      %none found, use builtin which call
      out = builtin('which',fn);
    else
      %found one in our special paths, use that (don't call built in
      out = found{1};
    end
    
end

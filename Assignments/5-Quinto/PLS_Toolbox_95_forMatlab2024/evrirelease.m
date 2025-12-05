function [release,product,epath,rdate] = evrirelease(srchprod)
%EVRIRELEASE Returns Eigenvector product release number.
% If no input then returns product and release for current folder
% (location). If input given then searches for particular product (e.g.
% 'PLS_Toolbox', 'MIA_Toolbox') or, give the key word 'all', function will
% return cell arrays of all products and releases. 
%
%I/O: [release,product, path, rdate] = evrirelease
%I/O: [release,product, path, rdate] = evrirelease('PLS_Toolbox')
%I/O: [release,product, path, rdate] = evrirelease('all')
%
%See also: EVRIDEBUG, EVRIINSTALL, EVRIUPDATE

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk 08/25/05 change to contents.m as source.
%rsk 08/26/05 add product lookup.
%rsk 09/22/05 add path output.

release = '';
product = '';
epath   = '';
rdate   = '';

mypath = fileparts(which(mfilename));
startpath = pwd;

if nargin == 1
%Look up release info.
  try
    vrs = which('evrirelease.m','-all');
    for i = 1:length(vrs)
      cd(fileparts(vrs{i}));
      [rls, prds] = evrirelease;
      release = [release {rls}];
      product = [product {prds}];
      epath   = [epath {fileparts(vrs{i})}];
    end
    cd(startpath)
  catch
    cd(startpath)
    return
  end
  
  if ~strcmp(lower(srchprod), 'all')
  %Search for particular product.
    ploc = find(ismember(lower(product), lower(srchprod)));
    if ~isempty(ploc)
    release = release(ploc);
    product = product(ploc);
    epath   = epath(ploc);
    else
      release = '';
      product = '';
      epath   = '';
    end
  end
  
else
%Current folder release info.
  if exist(fullfile(mypath,'Contents.m'),'file')
    cfile = fullfile(mypath,'Contents.m');
  elseif exist(fullfile(mypath,'contents.m'),'file')
    cfile = fullfile(mypath,'contents.m');
  else
    error(['Can''t locate Contents file for (' mypath ') Toolbox.'])
  end

  fid = fopen(cfile);

  %Get first non empty line should be toolbox name.
  while ~feof(fid)
    line = fgetl(fid);
    if ~isempty(line)
      product = line(2:end);
      product = deblank(product);
      product = fliplr(deblank(fliplr(product)));
      if strcmp(product(end),'.')
        product(end) = [];
      end
      break
    end
  end

  %Next line should be toolbox version.
  while ~feof(fid)
    line = fgetl(fid);
    if ~isempty(line)
      vstr = deblank(line(2:end));
      vloc = findstr(lower(vstr),'version ');
      %Version number should be first continuous string after 'version'.
      if ~isempty(vloc)
        vstr = vstr(vloc+length('version '):end);
        vstr = fliplr(deblank(fliplr(vstr)));
        sloc = findstr(vstr,' ');
        release = vstr(1:sloc(1)-1);
        rdate = char(regexp(vstr,'\d*-\w*-\d{4}','match'));
        break
      end
    end
  end
  epath = mypath;
  fclose(fid);
end

  

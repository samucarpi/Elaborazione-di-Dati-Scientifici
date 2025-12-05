function [out] = areadr(file,nline,nvar,flag)
%AREADR Reads ascii data and strips header.
%  INPUTS:
%    file = an ascii string containing the file name to be read,
%   nline = the number of rows to skip before reading (class "double"), or
%           a string containing the last few characters before the first
%           number to be read (used to skip header information) (class "char"),
%    nvar = the number of rows or columns in the matrix, and
%    flag = which tells AREADR if (nvar) is rows or columns
%             flag==1 (rows), flag==2 (columns).
%
%  OUTPUT:
%     out = is the data matrix.
%
%Warning: conversion may not be successful for files from other platforms.
%
%I/O: out = areadr(file,nline,nvar,flag);   %reads text files
%I/O: areadr demo
%
%See also: DLMREAD, MTFREADR, PARSEMIXED, SPCREADR, TEXTREADR, XCLGETDATA, XCLPUTDATA, XLSREADR

%Copyright Eigenvector Research, Inc. 1996
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
%nbg 4/1/04 added DLMREAD to the See also

if nargin == 0; file = 'io'; end
if ismember(file,evriio([],'validtopics'));
  varargin{1} = file;
  options = [];
  if nargout==0; clear out; evriio(mfilename,varargin{1},options); else; out = evriio(mfilename,varargin{1},options); end
  return;
end

if ~isa(file,'char')
  error('Input (file) must be a character string.')
end
if nargin<4
  error('AREADR requires 4 inputs.')
end

[fid,message] = fopen(file,'r');
if fid<0
  disp(['Couldn''t open file: ',file])
  error(message)
end

try
  switch class(nline)
    case 'double'
      for i=1:nline
        line    = fgets(fid);
      end
      [a,count] = fscanf(fid,'%g',[inf]);
      na        = length(a);
      no        = na/nvar;
      if (no-floor(no))~=0
        error(['Number of rows/columns (nvar) does not appear correct for file: ',file])
      elseif count<1
        disp('Conversion does not appear to be successful')
      else
        switch flag
          case 1      %nvar = rows;
            for i=1:nvar
              jj       = (i-1)*no;
              j        = [jj+1:jj+no];
              out(i,:) = a(j,1)';
            end
          case 2      %nar = columns;
            for i=1:no
              jj       = (i-1)*nvar;
              j        = [jj+1:jj+nvar];
              out(i,:) = a(j,1)';
            end
          otherwise
            error('Input (flag) not recognized (It should be 1 or 2.)')
        end
      end
    case 'char'
      j           = [];
      while isempty(j)
        line      = fgets(fid);
        k         = findstr(nline,line);
        if ~isempty(k)
          j       = ftell(fid) - length(line) + length(nline) + k - 1;
        end
      end
      status      = fseek(fid,j,'bof');
      if status<0
        [message,errnum] = ferror(fid);
        error(message)
      end
      [a,count]   = fscanf(fid,'%g',[inf]);
      [na,ma]     = size(a);
      no          = na/nvar;
      if (no-floor(no))~=0
        error(['Number of rows/columns (nvar) does not appear correct for file: ',file])
      elseif count<1
        disp('Conversion does not appear to be successful')
      else
        switch flag
          case 1      %nvar = rows;
            for i=1:nvar
              jj       = (i-1)*no;
              j        = [jj+1:jj+no];
              out(i,:) = a(j,1)';
            end
          case 2      %nar = columns;
            for i=1:no
              jj       = (i-1)*nvar;
              j        = [jj+1:jj+nvar];
              out(i,:) = a(j,1)';
            end
          otherwise
            error('Input (flag) not recognized (It should be 1 or 2.)')
        end
      end
    otherwise
      error('Input (nline) must be class "double" or "char".')
  end
catch
  %if an error is thrown while reading, close file then rethrow error
  le = lasterror;
  try
    fclose(fid);
  catch
  end
  rethrow(le)
end

fclose(fid);

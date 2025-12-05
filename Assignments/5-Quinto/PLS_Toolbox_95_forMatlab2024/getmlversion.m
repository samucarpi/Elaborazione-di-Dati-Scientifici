function out = getmlversion(vreturn)
%GETMLVERSION Returns current Matlab version as an integer.
%  Input:
%     vreturn: ['release' | {'version'} | 'string'] dictates style of version to
%              return. 'release' uses "R" format (e.g. 12, 13, 14, or 15).
%              'version' uses "ver" format (e.g. 6.5, 7.0, 7.2).
%              'string' returns string to second dot, e.g., '7.10'
%
%I/O: version = getmlversion
%I/O: version = getmlversion('release')

%Copyright © Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
%rsk 02/15/06 -change version to match code used in evriinstall and evriupdate
%rsk 02/15/06 -added input for return style.
%
%See also: CHECKMLVERSION

if nargin == 0
  vreturn = 'version';
end

%As of PLS V3.5 matlabversion of appdata 0 is only used here.
switch vreturn
  
  case {'version' 'long'}
    out  = version;
    vernum = sscanf(out,'%d.%d');
    minorv = vernum(2);
    if minorv>9
      %minor version is 10 not 01 so need to deal with it here. We know
      %there was no official 7.9x release (only 7.9) so this should work by
      %incrementing >10 as a hundredth added to 7.9. E.g., 7.10 becoms 7.91 and
      %7.12 becomes 7.93.
      minorv = 0.9 + minorv/1000;
      out = vernum(1) + minorv;
    else
      out = vernum(1)+vernum(2)/10;
    end
  case 'string'
    %Gets sting of version to second dot, e.g., '7.10'
    out  = version;
    dot_pos = findstr(out,'.');
    out =  out(1:dot_pos(2)-1);
  case 'release'
    %get RELEASE number
    out = getappdata(0,'matlabversion');
    
    if isempty(out);
      str = version('-release');
      out = str2num(strtok(str,'.'));
      if isempty(out)
        switch getmlversion('version')
          case 7.3
            out = 15.1;
          otherwise  %7.2
            out = 15;        %TODO: add permanent fix for 2006a.
        end
      end
      setappdata(0,'matlabversion',out);
    end
end

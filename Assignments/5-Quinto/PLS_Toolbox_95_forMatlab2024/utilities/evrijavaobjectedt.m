function out = evrijavaobjectedt(varargin)
%EVRIJAVAOBJECTEDT Overload for javaObjectEDT that's backwards compatible.
%  If older than 2008a awtcreate is used but will only work when creating
%  with string:
%               javaObj = evrijavaobjedt('javax.swing.JButton')
%
%I/O: out = evrijavaobjectedt(varargin)
%I/O: javaObj = evrijavaobjectedt('javax.swing.JButton')
%I/O: javaObj = evrijavaobjectedt(javaObj);%Only works on 2008b+
%
%See also: EVRIJAVAMETHODEDT, EVRIJAVASETUP

% Copyright © Eigenvector Research, Inc. 2011
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%

try
  out = varargin{1};
catch
  out = [];
end

if checkmlversion('>','7.6')
  out = javaObjectEDT(varargin{:});
else
  if exist('awtcreate.m','file')==2 && ischar(varargin{1})%Must be char, javaObj = evrijavaobjectedt(javaObj);%Only works on 2008b+
    %Test for second input. Give warning if second input can't be tolerated
    %by awtcreate (for backward compatibility).
    if nargin>1
      if nargin==2
        if ~ischar(varargin{2}) && ~iscell(varargin{2})
          %Comment out this warning and just use try/catch below. The
          %.Object creation seems to work most of the time with graphical
          %objects.
          %warning('Backward Compatibility Warning: The second input to this function is not a String or Cell and is not compatible with awtcreate used in this function. Try using single input or create directly.');
        end
      else
        warning('EVRI:JavaobjectBackwardsCompat','More than 2 inputs is not backwards compatible with awtcreate used in this function. Try using single input or create directly.');
      end
    end
    switch nargin
      case 1
        out = awtcreate(varargin{:});
      case 2
        %Passing two arguments, and second argument is a char or cell then
        %pass to awtcreate w/ correct signature.
        switch class(varargin{2})
          case 'char'
            out = awtcreate(varargin{1},'Ljava.lang.String;',varargin{2});
          case 'cell'
            out = awtcreate(varargin{1},'[Ljava.lang.Object;',varargin{2});
          otherwise
            %Run it on the main thread and hope for the best.
            try
              out = awtcreate(varargin{1},'[Ljava.lang.Object;',varargin{2});
              if isempty(out)
                out = feval(varargin{:});
              end
            catch
              out = feval(varargin{:});
            end
        end
      otherwise
        %Run it on the main thread and hope for the best.
        out = feval(varargin{:});
    end
  else
    if ischar(varargin{1})
      %Only option is to run on main thread.
      out = feval(varargin{:});
    end
  end
end

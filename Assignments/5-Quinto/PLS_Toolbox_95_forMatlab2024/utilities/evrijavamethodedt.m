function out = evrijavamethodedt(mymethod,myobj,varargin)
%EVRIJAVAMETHODEDT Overload for javaMethodEDT that's backwards compatible.
%  If older than 2008a awtinvoke is used but this can be problemmatic
%  because of "signature in JNI notation" (see awtinvoke.m) so code makes
%  direct calls on tree methods (these should be safe because they're
%  already on EDT) then tries awtinvoke. If that fails it tries a direct
%  call.
%
%I/O: out = evrijavamethodedt(mymethod,myobj,varargin)
%I/O: out = evrijavamethodedt('getModifiers',mymouseevent)
%
%See also: EVRIJAVAOBJECTEDT, EVRIJAVASETUP

% Copyright © Eigenvector Research, Inc. 2011
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%

try
  out = [];
  if checkmlversion('>','7.6')
    if nargout>0
      if nargin>2
        out = javaMethodEDT(mymethod,myobj,varargin{:});
      else
        out = javaMethodEDT(mymethod,myobj);
      end
    else
      if nargin>2
        javaMethodEDT(mymethod,myobj,varargin{:});
      else
        javaMethodEDT(mymethod,myobj);
      end
    end
  else
    if exist('awtinvoke.m','file')==2 && checkmlversion('>','7.2')
      try
        %In some cases awtinvoke needs "signature in JNI notation" (see
        %awtinvoke.m). In this case we should give up and try on main thread I
        %think.
        if nargout>0
          if nargin>2
            out = awtinvoke(myobj,mymethod,varargin{:});
          else
            out = awtinvoke(myobj,mymethod);
          end
        else
          %As is done in browse, use direct call on these tree methods if
          %they come to this function. This should go out on EDT. Do this
          %because, as stated above, awtinvoke needs JNI.
          switch mymethod
            case 'expandRow'
              myobj.expandRow(varargin{1});
            case 'setSelectionRow'
              myobj.setSelectionRow(varargin{1});
            case 'setSelectionPath'
              myobj.setSelectionPath(varargin{1});
            case 'setRoot'
              myobj.setRoot(varargin{1});
            otherwise
              if nargin>2
                awtinvoke(myobj,mymethod,varargin{:});
              else
                awtinvoke(myobj,mymethod);
              end
          end
        end
      catch
        %Use same code as below to make direct call on main thread.
        if nargout>0
          if nargin>2
            %Not sure this will work.
            out = myobj.(mymethod)(varargin{:});
          else
            out = myobj.(mymethod);
          end
        else
          if nargin>2
            %Not sure this will work in every case but has worked for jtree
            %method calls.
            myobj.(mymethod)(varargin{:});
          else
            myobj.(mymethod);
          end
        end
      end
    else
      if nargout>0
        if nargin>2
          %Not sure this will work.
          out = myobj.(mymethod)(varargin{:});
        else
          out = myobj.(mymethod);
        end
      else
        if nargin>2
          %Not sure this will work in every case but has worked for jtree
          %method calls.
          myobj.(mymethod)(varargin{:});
        else
          myobj.(mymethod);
        end
      end
    end
  end
catch
  %No fatal error.
end

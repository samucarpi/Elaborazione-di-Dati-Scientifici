function varargout = goldensecsearchd(varargin)
%GOLDENSECSEARCHD Discrete Golden Section Search.
%  GOLDENSECSEARCHD finds the minimum of an objective function (fun)
%  that is a function of a single discrete variable (x) using a
%  Golden Section algorithm.
%
%  INPUTS:
%    fun = objective function name (char string or inline object) that
%          has a scalar output (fval). It is called using the following:
%          fval = feval(fun,x,P1,P2,...);
%      x = N by 1 vector of independent variables to be searched.
%    P1, P2, ... = additional parameters used by (fun).
%
%  OUTPUTS:
%     ix = index of the optimimum: x(ix) is the value of the independent
%          value at the optimum.
%   fval = corresponding value of the objective function at the minimum.
%
%Example: find minimimum for inline function g
%  x      = [-10:10];
%  g      = inline('x.^2');
%  [d,fv] = goldensecsearchd(g,x);
%  plot(x,g(x),'b'), vline(x(d))
%
%I/O: [ix,fval] = goldensecsearchd(fun,x,P1,P2, ...);
%I/O: goldensecsearchd demo
%
%See also: CALIBSEL, CROSSVAL, FULLSEARCH, GENALG

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 9/06 (modified FULLSEARCH)

if nargin == 0; varargin{1} = 'io'; end

%Check I/O:
if ischar(varargin{1}) | isobject(varargin{1})
  if ischar(varargin{1})
    if nargout==0 %Help, Demo
      evriio(mfilename,varargin{1},[]);
      return
    end
    if nargout>0
      switch lower(varargin{1})
      case evriio([],'validtopics');
        options  = [];
        varargout{1} = evriio(mfilename,varargin{1},options);
        return
      end
    end
  end
  if nargin<2
    error('GOLDENSECSEARCHD requires 2 inputs.')
  end
  fun      = varargin{1};
  x        = varargin{2};
  if nargin>2
    varargin = varargin(3:end);
  else
    varargin = {};
  end

  if all(size(x))>1
    error('Input (x) must be a vector.')
  end
  %End check I/O.

  %Initialization
  nx       = length(x);
  x        = x(:);
  varargout{1} = 0;
  varargout{2} = inf;
  il       = 1;
  ir       = nx;
  ix       = il:ir;
  sc       = 0.382;  %Section Size
  sd       = 1-sc;
  ia       = findindx(ix,sc*nx);
  ib       = findindx(ix,sd*nx);
  fr       = feval(fun,x(nx),varargin{:});
  fl       = feval(fun,x(1), varargin{:});
  fa       = feval(fun,x(ia),varargin{:});
  fb       = feval(fun,x(ib),varargin{:});

  %Check boundaries
  if fa>fl | fa>fr | fb>fl | fb>fr
    if fl<fr
      varargout{1} = il;
      varargout{2} = fl;
    else
      varargout{1} = ir;
      varargout{2} = fr;
    end
    warning('EVRI:GoldenNonConvex','Function does not appear to be convex.')
  else
%     hwait    = waitbar(0,'GoldenSecSearchD working.'); 
    its      = 0;
    while its<nx & ia~=ib
      if fa<=fb %then throw away right side
        ir   = ib;
        ix   = il:ir;
        ib   = ia;
        fb   = fa;
        ia   = ix(findindx(il:ir,sc*(ir-il)+il));
        fa   = feval(fun,x(ia),varargin{:});
      else      %then throw away left side
        il   = ia;
        ix   = il:ir;
        ia   = ib;
        fa   = fb;
        ib   = ix(findindx(il:ir,sd*(ir-il)+il));
        fb   = feval(fun,x(ib),varargin{:});
      end
      its    = its+1;
      if abs(diff([ib;ia]))<2
        if fa<fb
          varargout{1} = ia;
          varargout{2} = fa;
          ib = ia; %forces termination
        else
          varargout{1} = ib;
          varargout{2} = fb;
          ia = ib; %forces termination
        end
      end
    end
%     close(hwait)
  end
else
  error('Input (fun) must be an inline function of text string function name.')
end

function [result,list] = coreanal(core,action,param)
%COREANAL Analysis of the core array of a Tucker model.
%  Performs an analysis of the input core array of a Tucker model (core).
%  Results are returned in the output (result).
%
%  The optional input (action) is a text string used to customize the analysis.
%  action = 'list'   {default} Output (result) contains text describing
%             the main properties of the core. If COREANAL is called without
%             outputs, the text is printed to the command window. If optional
%             input (param) is included the number of core entries shown can
%             be controlled. An optional second output will provide a structure
%             containing the indices and values of the largest elements
%  action = 'plot'   Plots the core array and output (result) is not assigned.
%  action = 'maxvar' Rotates the core to maximum variance. This is the same as 
%             maximum simplicity as defined by Andersson & Henrion, Chemometrics &
%             Intelligent Laboratory Systems, 1999,47,189-204. The output (result)
%             is a structure array containing the rotated core in the field
%             "core" and the rotation matrices to achieve this rotation in the
%             field "transformation".
%             The loadings of the Tucker model should also be rotated correspondingly.
%             This rotation is applied by using the following:
%               >> rotatedmodel = coreanal(oldmodel,coreanalresult);
%             where the input (oldmodel) is the original Tucker model structure
%             and (coreanalresult) is the output from
%               >> coreanalresult = coreanal(oldmodel,'maxvar');
%            The rotation can be achieved in one step using:
%               >> rotatedmodel = coreanal(oldmodel,coreanal(oldmodel,'maxvar'));
%            where the output (rotatedmodel) is a Tucker model structure.
%
%I/O: result = coreanal(core,action,param);
%I/O: coreanal demo
%
%See also: CORECALC, TUCKER

%Copyright Eigenvector Research 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rb 10/01
%rb 10/01 added nargin=0 help
%nbg 11/19/01 added nargin<2,action, ...
%rb 11/01 added optional extra parameter that shrinks the size of the core and skips the text on each core elements (it's not documented but used in mwaplotter)
%rb 20/09/04 fixed error in plots when zero core entries
%rb mar 2005 and fixed the thereby added error that negative numbers are not plotted
%rb Jan 2007 use color to indicate sign 


varargout = [];
if nargin == 0; core = 'io'; end
varargin{1} = core;
if ischar(varargin{1});
  options = [];
  if nargout==0; 
    clear varargout; 
    evriio(mfilename,varargin{1},options); 
  else; 
    result = evriio(mfilename,varargin{1},options); 
  end
  return; 
end


if nargin<2
  options = 'list';
  action  = 'list';  %nbg 11/19/01
elseif nargin>4
  error(' Too many inputs in COREANAL')
end

RotateOldModel = 0;

if ismodel(core)
  if strcmp(lower(core.modeltype),'tucker')
    % Then it's either a core that must be extracted or a rotation of an old model
    if isstruct(action)
      if length(size(action.core)) == length(size(core.loads{end}))
        RotateOldModel = 1;
      else
        error(' Input not correctly given in COREANAL')
      end
    else
      core = core.loads{end};
    end
  else
    error(' First input to COREANAL should be either a core array or a model structure')
  end
end


if ~RotateOldModel
  if strcmp(lower(action),'list')
      list.position=[];
      list.corevalue=[];
    if nargin<3
      param = min(10,prod(size(core)));
    else
      if isstr(param)
        if strcmp(lower(param),'all')
          param = prod(size(core));
        else
          param = min(param,prod(size(core)));
        end
      end
    end
    sumg2 = sum(core(:).^2);
    g = [core(:) core(:).^2 100*(core(:).^2)/sumg2];
    [a,b]=sort(g(:,2));
    b = flipud(b);
    
    t=[];
    for ii=1:length(size(core))-1
      t = [t sprintf('%2i x',size(core,ii))];
    end;
    t = [t sprintf('%2i',size(core,length(size(core))))];
    s = sprintf(['\n']);
    s = [s sprintf(['          ANALYSIS OF ',t,' CORE ARRAY \n'])];
    s = [s sprintf('          (Comp /Value /Squared /FractionVar /SummedFraction) \n \n')];
    s = [s sprintf('          IMPORTANT. Percentages are relative to the model. \n')];
    s = [s sprintf('          They describe how much of the model (not the data), that  \n')];
    s = [s sprintf('          an element is describing. Hence all elements add to 100 \n \n')];
    
    for i=1:param
      index = num2ind(b(i),size(core));
      s = [s sprintf('[')];
      for ii=1:length(size(core))-1
        s = [s sprintf('%2i,',index(ii))];
      end;
      s = [s sprintf('%2i] %14.2f %14.2f  %14.2f%%  %14.2f%%\n',index(end),g(b(i),:),sum(g(b(1:i),end)))];
      %         s = [s sprintf('\n')];
      list.position(i,:)=index;
      list.corevalue(i,1)=g(b(i));
    end
    result = s;
    if nargout==0
      disp(result)
    end
    
  elseif strcmp(lower(action),'plot')
    
    if nargin>2
      scaler = param(1);
      textoff = 1;
    else
      textoff = 0;
      scaler = 1;
    end
    
    origcoresize = size(core);
    if length(size(core))>3
      % Make it into a 3D core
      core = reshape(core,origcoresize(1),origcoresize(2),prod(origcoresize(3:end)));
    end
    
    G = core;
    G = .7*(G/max(abs(G(:))));
    for i=1:prod(size(core))
      ind = num2ind(i,size(core));
      j=ind(1);k=ind(2);try, l=ind(3);catch,l=1;end
      if abs(G(i))>0
        if G(i)>0
          p=plot3(j,k,l,'o','markersize',scaler*abs(150*G(i)),'MarkerFaceColor','red', 'MarkerEdgeColor', 'none');hold on
        else
          p=plot3(j,k,l,'o','markersize',scaler*abs(150*G(i)),'MarkerFaceColor','blue', 'MarkerEdgeColor', 'none');hold on
        end
        if ~textoff
          text(j,k,l,num2str(num2ind(i,origcoresize)),'fontsize',10,'fontname','verdana')
        end
        set(p,'userdata',num2str(num2ind(i,origcoresize)));
        hold on
      end
    end
    if ~textoff
      set(gca,'Xtick',[1:size(core,1)],'fontweight','bold')
      set(gca,'Ytick',[1:size(core,2)],'fontweight','bold')
      set(gca,'Ztick',[1:size(core,3)],'fontweight','bold')
      grid on
      xlabel('Factors mode 1')
      ylabel('Factors mode 2')
      zlabel('Factors mode 3')
      hold off
      title('Core elements (area~%var,red positive/blue negative)','fontsize',10,'fontweight','bold')
    end
    result = [];
    
  elseif strcmp(lower(action),'maxvar')
    [rotcore,rot]=maxvar(core);
    result.core = rotcore;
    result.transformation = rot;
  else
    error(' Input action incorrectly given in COREANAL')
  end
  
else % Rotate a model
  
  oldmodel = core;
  rotcore = action.core;
  rotloads = action.transformation;
  model = oldmodel;
  result = model;
  result.detail.core = rotcore;
  for i=1:length(size(rotcore))
    result.loads{i} = result.loads{i}*rotloads{i}';
  end
  
end



function [rotcore,rot]=maxvar(core);

% gg=RotMats{1}*g*kron(RotMats{3},RotMats{2})';corevarn(gg)


ConvCrit = 1e-8;
MaxIt    = 100;
it       = 0;
coresize = size(core);
order = length(size(core));
rot = cell(1,order);
for i = 1:order
  rot{i} = eye(size(core,i));
end
var = std(core(:).^2).^2;
oldvar = 2*var;


while abs(var-oldvar)/oldvar>ConvCrit & it<MaxIt
  oldvar = var;
  it = it+1;
  for i = 1:order
    G = permute(core,[i [1:i-1 i+1:order]]);
    
    G = reshape(G,coresize(i),prod(coresize([1:i-1 i+1:order])));
    [Gnew,R] = orthomax(G',0);
    rot{i} = R'*rot{i};
    %      Gnew'-R'*G,pause
    Gnew = reshape(Gnew',coresize([i 1:i-1 i+1:order]));
    core = ipermute(Gnew,[i 1:i-1 i+1:order]);
  end
  var = std(core(:).^2).^2;
end
rotcore = core;

function [Arot,T,f]=orthomax(A,gamma);
% Orthomax rotation of A - originally written by H.A.L. Kie rs
% according to Clarkson % Jennrich (1988), psychometrika, 53(2), 251-259
% Remedy of ten Berge (1995), psychometrika, 60, 437-446 not built in
%
% input 
% A      loading-matrix to rotate
% gamma  orthomax parameter
%
% output
% Arot   rotated A
% T      rotation matrix


ConvCrit=1e-6;
[I,F]=size(A);
Arot = A;

f= sum(Arot(:).^4) - gamma/I*sum((sum(Arot.^2)).^2);
fold=2*f;
it=0;
k3 = -gamma/I;
k4 = 1;

while abs(f-fold)/abs(f)>ConvCrit
  fold=f;
  it=it+1;
  for f1=1:F-1
    for f2=f1+1:F
      x=Arot(:,f1);
      y=Arot(:,f2);
      
      a3 = .25*(x'*x -y'*y)^2-(x'*y)^2;
      a4 = .25*(x.^2'*x.^2 +y.^2'*y.^2)-1.5*(x.^2'*y.^2);
      b3 = x'*y*(x'*x-y'*y);
      b4 = x.^3'*y-x'*y.^3;
      
      a = k3*a3+k4*a4;
      b = k3*b3+k4*b4;
      theta = .25*atan2(b,a);
      
      xnew = x*cos(theta)+y*sin(theta);
      ynew = -x*sin(theta)+y*cos(theta);
      
      u = x.*x-y.*y;
      v = 2*x.*y;
      u = u-mean(u);
      v = v-mean(v); 
      a = 2*I*u'*y;
      b = I*u'*u-I*y'*y;      
      c = (a^2+b^2)^(.5);
      v = -sign(a)*( (b+c)/2*c  )^(.5);
      
      Arot(:,f1) = xnew;
      Arot(:,f2) = ynew;
    end
  end
  
  f= sum(Arot(:).^4) - gamma/I*sum((sum(Arot.^2)).^2);
end;

T = pinv(A)*Arot;

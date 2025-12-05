function a = plotloads_parafac2(modl,options)
%PLOTLOADS_PARAFAC Plotloads helper function used to extract info from model.
% Called by PLOTLOADS.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%a = plotloads_mcr(varargin{:});
a = [];
mode = options.mode;

if mode==1
%   %Special plotting for mode 1. May need to add more labels in future with
%   %copydsfields.
%   for k=1:modl.datasource{1}.include_size(3)
%     a(:,:,k)=modl.loads{1}.P{k}*modl.loads{1}.H;
%   end
%   a = dataset(a);
%   a.class{2,1} = str2cell(sprintf('Class %d\n',[1:modl.ncomp]));
% elseif mode==-1
  P = modl.loads{1}.P;
  H = modl.loads{1}.H;
  NumFact = size(P{1},2);
  NumSamps = length(P);
  A=[];
  for i=1:NumSamps
    A(:,:,i)=P{i}*H;
  end
  a = dataset(A(:,:));
  cnum = repmat([1:NumFact],[1 NumSamps]);
  a.class{2,1} = cnum;
  a.classname{2,1} = 'Component Number';
  lutbl = a.classlookup{2,1};
  lutbl(:,2) = strrep(lutbl(:,2),'Class','Comp');
  a.classlookup{2,1} = lutbl;
  
  a.classname{2,2} = 'Sample Number';
  sampnum = repmat([1:NumSamps],[NumFact 1]);
  sampnum = sampnum(:);
  a.class{2,2} = sampnum;

  lutbl = a.classlookup{2,2};
  lutbl(:,2) = strrep(lutbl(:,2),'Class','Sample');
  a.classlookup{2,2} = lutbl;
  
  lbl = str2cell(sprintf('Component %d / Sample %d\n',[cnum' sampnum]'));
  a.label{2,1} = lbl;
  
else
  a = plotloads_mcr(modl,options);
end

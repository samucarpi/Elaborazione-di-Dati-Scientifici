function a = plotscores_mdf(modl,test,options)
%PLOTSCORES_MDF Plotscores helper function used to extract info from model.
% Called by PLOTSCORES.
% model.detail.options.mdfdir = [ {'mean'} | 'col' | 'row' ]
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg

if all(size(modl.wts)==size(modl.detail.ploads{2}))
  %This version was used in the original maxautofactors in 2003
  modl.loads{1} = squeeze(modl.loads{1}(:,:,1)) + ...
                  squeeze(modl.loads{1}(:,:,2));

  a             = plotscores_pca(modl,test,options); %really should only work in cal
else
  if isempty(modl.detail.options.mdfdir)
    flag        = 'mean';
  else
    flag        = modl.detail.options.mdfdir;
  end
  if strcmpi(modl.datasource{1}.type,'image')
    modl          = trimmodel(modl,flag);  
    if ismodel(test)
      test        = trimmodel(test,flag);
    end
  end
  a             = plotscores_pca(modl,test,options);
end
end % PLOTSCORES_MDF function end

function modl = trimmodel(modl,flag)
  m             = modl.datasource{1}.size(1);
  i1            =   1:m;
  i2            = m+1:m*2;
  ic            = modl.detail.include{1}(modl.detail.include{1}<=m);
  ih            = modl.detail.include{1}(modl.detail.include{1}> m) - m; 
  switch lower(flag)
  case 'mean'
    modl.loads{1}           = (modl.loads{1}(i1,:)+modl.loads{1}(i2,:))/2;
    modl.tsqs{1}            = (modl.tsqs{1}(i1,1) +modl.tsqs{1}(i2,1))/2;
    modl.ssqresiduals{1}    = (modl.ssqresiduals{1}(i1,1)+modl.ssqresiduals{1}(i2,1))/2;
    modl.detail.includ{1}   = intersect(ic,ih);
  case {'c', 'v', 'col', 'column', 'vertical'}
    modl.loads{1}           = squeeze(modl.loads{1}(i1,:));
    modl.tsqs{1}            = modl.tsqs{1}(i1,1);
    modl.ssqresiduals{1}    = modl.ssqresiduals{1}(i1,1);
    modl.detail.includ{1}   = ic;      
  case {'h', 'r', 'row', 'horizontal'}
    modl.loads{1}           = squeeze(modl.loads{1}(i2,:));
    modl.tsqs{1}            = modl.tsqs{1}(i2,1);
    modl.ssqresiduals{1}    = modl.ssqresiduals{1}(i2,1);
    modl.detail.includ{1}   = ih;
  end
  for ii=1:length(modl.detail.label(1,:))
    if ~isempty(modl.detail.label{1,ii})
      modl.detail.label{1,ii}  = modl.detail.label{1,ii}(i1,:);
    end
  end
  for ii=1:length(modl.detail.axisscale(1,:))
    if ~isempty(modl.detail.axisscale{1,ii})
      modl.detail.axisscale{1,ii}  = modl.detail.axisscale{1,ii}(i1,:);
    end
  end 
  for ii=1:length(modl.detail.class(1,:))
    if ~isempty(modl.detail.class{1,ii})
      modl.detail.class{1,ii}  = modl.detail.class{1,ii}(i1);
    end
  end 
  if ~isempty(modl.detail.imageaxisscale{1})
% %     modl.detail.imageaxisscale{1} = 1:modl.datasource{1}.imagesize(1);
%   else
    modl.detail.imageaxisscale{1} = modl.detail.imageaxisscale{1}(1:modl.datasource{1}.imagesize(1));
  end

end
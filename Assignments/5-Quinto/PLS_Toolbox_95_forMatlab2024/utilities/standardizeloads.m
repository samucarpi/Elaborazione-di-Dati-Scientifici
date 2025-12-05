function [loads,ScaleMode] = standardizeloads(loads,constraints,samplemodex,modeltype,scaletype);
%STANDARDIZELOADS Utility for standardizing loadings.
%
% [loads,ScaleMode] = standardizeloads(loads,constraints,samplemodex);

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% rb, 20/9/04, removed scaling of tucker loads when core is constrained
% rb, 20/3/05, reversed the scaling in parafac so first is largest

if strcmp(lower(modeltype),'parafac')
  condef = regresconstr(constraints(1:length(constraints))); % Checks which modes can be scaled
  constrainedmodes     = condef.constrainedmodes;
  freetoscalemodes     = condef.freetoscalemodes;
  freetonormalizemodes = condef.freetonormalizemodes;
  fixedmodes           = condef.fixedmodes;
  
  if length(constrainedmodes)<length(loads)  % Can happen when you fit one sample to an existing model
    constrainedmodes     = [constrainedmodes 1];
    freetoscalemodes     = [freetoscalemodes 0];
    freetonormalizemodes = [freetonormalizemodes 0];
  end
  
  ScaleMode = samplemodex;
  if freetonormalizemodes(ScaleMode)==0,
    ScaleMode = find(freetonormalizemodes'==1);
  end
 
  if length(find(freetonormalizemodes))>1 % Else no scaling
    ScaleMode = ScaleMode(1);
    for i=1:length(loads)
      if (i ~=ScaleMode) & freetonormalizemodes(i)
        if strcmp(lower(scaletype.value),'norm')
          SS = sum(loads{i}.^2,1);
          SS(find(SS==0))=1;% If a zero value is encountered
          Scal = 1./sqrt(SS);
          Scal = sign(sum(loads{i}.^3,1)).*Scal;
          loads{i} = loads{i}*diag(Scal); % normalization leads to wrong model but that's corrected in the next update of the next mode, and for the last mode no normalization is performed, so that's ok, unless last mode is fixed.
          loads{ScaleMode} = loads{ScaleMode}*diag(Scal.^(-1));%ii = i+1;
        elseif strcmp(lower(scaletype.value),'max')
          [SS,out] = max(abs(loads{i}));
          for i2=1:size(loads{i},2) % chk sign
            if loads{i}(out(i2),i2)<0
              SS(i2)=-SS(i2);
            end
          end
          SS(find(SS==0))=1;% If a zero value is encountered
          Scal = 1./(SS);
          loads{i} = loads{i}*diag(Scal); % normalization leads to wrong model but that's corrected in the next update of the next mode, and for the last mode no normalization is performed, so that's ok, unless last mode is fixed.
          loads{ScaleMode} = loads{ScaleMode}*diag(Scal.^(-1));%ii = i+1;
        else
          error(['The option field scaletype value must be set to ''norm'' or ''max''.'])
        end
      end
    end
  else % Check if there are fixed elements in some modes so that some columns are fixed and other not and equalize the columns then
    if ~isempty(ScaleMode) % If there is a mode that can be scaled
      ScaleMode = ScaleMode(1);
      for i=1:length(loads)
        if (i ~=ScaleMode)
          fxmodes(i,1:size(loads{i},2)) = (sum(constraints{i}.fixed.position)>0); % Modes that are fixed
          nonfxmodes(i,1:size(loads{i},2)) = (sum(constraints{i}.fixed.position)==0); % Modes that are not fixed
        else
          fxmodes(i,:) = repmat(0,1,size(loads{i},2));
          nonfxmodes(i,:) = repmat(1,1,size(loads{i},2));
        end
        if constraints{i}.fixed.weight==-1 % Then completely fixed
          fxmodes(i,1:size(loads{i},2))=1;
        end
      end
      % Now chk the average scale of fxmodes columns and make that the scale
      % of the nonfixed columns (put the scale in ScaleMode)
      fxcol = find(sum(fxmodes([1:ScaleMode-1 ScaleMode+1:end],:)));
      nonfxcol = find(sum(fxmodes([1:ScaleMode-1 ScaleMode+1:end],:))==0);
      for i=1:length(loads)
        if (i ~=ScaleMode)
          SS = sum(loads{i}.^2,1);
          SS(find(SS==0))=1;% If a zero value is encountered
          Scal = 1./sqrt(SS);
          TargetScal = mean(Scal(fxcol)).^(-1);
          loads{i}(:,nonfxcol) = loads{i}(:,nonfxcol)*diag(Scal(nonfxcol)*TargetScal); % normalization leads to wrong model but that's corrected in the next update of the next mode, and for the last mode no normalization is performed, so that's ok, unless last mode is fixed.
          loads{ScaleMode}(:,nonfxcol) = loads{ScaleMode}(:,nonfxcol)*diag(Scal(nonfxcol).^(-1))*TargetScal;%ii = i+1;
        end
      end
      
    end
  end

  % Order the components
  if ~fixedmodes & ScaleMode
    SS = sum(loads{ScaleMode}.^2,1);
    [a,b]=sort(SS);
    for i=1:length(loads)
      loads{i} = loads{i}(:,flipud(b(:)));
    end
  end

  
elseif strcmp(lower(modeltype),'parafac2')
  condef = regresconstr(constraints(1:length(constraints))); % Checks which modes can be scaled
  constrainedmodes     = condef.constrainedmodes;
  freetoscalemodes     = condef.freetoscalemodes;
  freetonormalizemodes = condef.freetonormalizemodes;
  fixedmodes           = condef.fixedmodes;
  
  if length(constrainedmodes)<length(loads)  % Can happen when you fit one sample to an existing model
    constrainedmodes     = [constrainedmodes 1];
    freetoscalemodes     = [freetoscalemodes 0];
    freetonormalizemodes = [freetonormalizemodes 0];
  end

  % Make sure parafac2 variable-length mode is set correct
  freetonormalizemodes(1) = 0;
  constrainedmodes(1)     = 1;
  freetonormalizemodes(length(loads)) = 0;
  constrainedmodes(length(loads))     = 1;

  ScaleMode = samplemodex;
  if freetonormalizemodes(ScaleMode)==0,
    ScaleMode = find(freetonormalizemodes'==1);
  end  

  if length(find(freetonormalizemodes))>1 % Else no scaling
    ScaleMode = ScaleMode(1);
    for i=2:length(loads)
      if (i ~=ScaleMode) & freetonormalizemodes(i)
        SS = sum(loads{i}.^2,1);
        SS(find(SS==0))=1;% If a zero value is encountered
        Scal = 1./sqrt(SS);
        Scal = sign(sum(loads{i}.^3,1)).*Scal;
        loads{i} = loads{i}*diag(Scal); % normalization leads to wrong model but that's corrected in the next update of the next mode, and for the last mode no normalization is performed, so that's ok, unless last mode is fixed.
        loads{ScaleMode} = loads{ScaleMode}*diag(Scal.^(-1));%ii = i+1;
      end
    end
  end

 
  % Order the components
  if ~fixedmodes&~isempty(ScaleMode)
    SS = sum(loads{ScaleMode}.^2,1);
    [a,b]=sort(SS);
    for i=2:length(loads)
      loads{i} = loads{i}(:,b);
    end
    loads{1}.H = loads{1}.H(b,b);
    for k = 1:length(loads{1}.P)
      loads{1}.P{k} = loads{1}.P{k}(:,b);
    end
  end
  
  
elseif strcmp(lower(modeltype),'tucker')

  condef = regresconstr(constraints(1:length(constraints)-1)); % Checks which modes can be scaled
  constrainedmodes     = condef.constrainedmodes;
  freetoscalemodes     = condef.freetoscalemodes;
  freetonormalizemodes = condef.freetonormalizemodes;
  corecon = regresconstr(constraints(end));
  
  
  if length(constrainedmodes)<length(loads)-1  % Can happen when you fit one sample to an existing model
    constrainedmodes     = [constrainedmodes 1];
    freetoscalemodes     = [freetoscalemodes 0];
    freetonormalizemodes = [freetonormalizemodes 0];
  end

  
  % Don't counterscale the loadings in other modes (not possible if different # comp). Instead, the core will absorb the scale
  if ~(corecon.fixedmodes|corecon.constrainedmodes) % Don't scale if core is fixed
    if length(find(freetonormalizemodes))>1 % Else no scaling
      for i=1:length(loads)-1
        if freetonormalizemodes(i)
          SS = sum(loads{i}.^2,1);
          SS(find(SS==0))=1;% If a zero value is encountered
          Scal = 1./sqrt(SS);
          Scal = sign(sum(loads{i}.^3,1)).*Scal;
          Scal(find(~Scal))=1;  % If a zero value is encountered
          loads{i} = loads{i}*diag(Scal); % normalization leads to wrong model but that's corrected in the next update of the core.
        end
      end
    end
  end

else
 error('Modeltype not known in STANDARDIZELOADS')
end

function [dA,DeltaMin] = linesrch(x,A,Ao,DoWeight,weights,alllae,Missing,MissId,Delta);

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

dbg=0;

if nargin<8
  Delta=5;
else
  Delta=max(2,Delta);
end

Fit1 = fithis(A,x,DoWeight,weights,alllae,Missing,MissId);
regx=[1 0 0 Fit1];
dA = extrapol(A,Ao,Delta);
Fit2 = fithis(dA,x,DoWeight,weights,alllae,Missing,MissId);

regx=[regx;1 Delta Delta.^2 Fit2];

while Fit2>Fit1
  Delta=Delta*.6;
  dA = extrapol(A,Ao,Delta);
  Fit2 = fithis(dA,x,DoWeight,weights,alllae,Missing,MissId);
  regx=[regx;1 Delta Delta.^2 Fit2];
end

dA = extrapol(A,Ao,2*Delta);
Fit3 = fithis(dA,x,DoWeight,weights,alllae,Missing,MissId);
regx=[regx;1 2*Delta (2*Delta).^2 Fit3];

while Fit3<Fit2
  Delta=1.8*Delta;
  Fit2=Fit3;
  dA = extrapol(A,Ao,Delta);
  Fit3 = fithis(dA,x,DoWeight,weights,alllae,Missing,MissId);
  regx=[regx;1 2*Delta (2*Delta).^2 Fit2];
end

% Add one point between the two smallest fits
[a,b]=sort(regx(:,4));
regx=regx(b,:);
Delta4=(regx(1,2)+regx(2,2))/2;
dA = extrapol(A,Ao,Delta4);
Fit4 = fithis(dA,x,DoWeight,weights,alllae,Missing,MissId);
regx=[regx;1 Delta4 Delta4.^2 Fit4];

reg=pinv(regx(:,1:3))*regx(:,4);
%DeltaMin=2*reg(3);

DeltaMin=-reg(2)/(2*reg(3));

dA = extrapol(A,Ao,DeltaMin);
Fit = fithis(dA,x,DoWeight,weights,alllae,Missing,MissId);

if dbg
  plot(regx(:,2),regx(:,4),'o'),
  hold on
  x=linspace(0,max(regx(:,2))*1.2);
  plot(x',[ones(100,1) x' x'.^2]*reg),
  hold off
  drawnow
  pause
end

% If Fit has not improved just pick the original
if Fit>Fit1
  dA = A;
end


function dA = extrapol(A,Ao,delta);

dA = A;
for i=1:length(A)
  if isstruct(A{i}) % Assuming that it's then parafac2
    dA{i}.H = A{i}.H+delta*(A{i}.H-Ao{i}.H);
    for j = 1:length(A{i}.P);
      dA{i}.P{j} = A{i}.P{j}+delta*(A{i}.P{j}-Ao{i}.P{j});
    end
  else
    dA{i} = A{i}+delta*(A{i}-Ao{i});
  end
end


function fit = fithis(param,x,DoWeight,weights,alllae,Missing,MissId);

xest = datahat(param);
%Iterative preproc
if DoWeight
  if alllae
    xsq = abs((x-datahat(param)).*weights);
  else
    xsq = ((x-datahat(param)).*weights).^2;
  end
else
  if alllae
    xsq = abs(x-datahat(param));
  else
    xsq = (x-datahat(param)).^2;
  end
end
if Missing
  xsq(MissId)=0;
end
fit = sum(xsq(:));

echo on
%PARAFAC2DEMO Demo of the PARAFAC2 function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% PARAFAC2 is capable of handling deviations from trilinearity in a 
% simple manner.
%
% We will generate a small dataset that is PARAFAC-like but has
% the problem that the loadings in the first mode differ from 
% sample to sample. Note that the samples are typically held in the
% last mode in PARAFAC2 while the 'varying' mode is held in the first one
 
F=3;    % Number of components
n=1:30; % For mode 2 (B)
 
% Second mode loads ("spectra")
B=[exp(-((n-15)/5).^2);exp(-((n-1)/10).^2);exp(-((n-21)/7).^2)]';
subplot(2,2,1)
plot(B),title(' Second mode loadings')
 
% Third mode loadings ("concentrations")
C=rand(5,3)+.2;
subplot(2,2,2)
plot(C),title(' Third mode loadings')
 
 
 
% Now generate first mode data (e.g. elution profiles)
% One set of profiles is defined for each sample (k)
%
% Press key to continue
pause
%
 
H=orth(orth(rand(F))');
P=[];X=[];
for k=1:size(C,1),
  subplot(2,5,5+k)
  P(:,:,k)=orth(rand(7,F));
  plot(P(:,:,k)*H)
  eval(['title([''Ak (1. mode, k = '',num2str(k),'')''])'])
  axis tight
end,
 
%
% Note that the second mode loadings change from slab to slab
% hence the ordinary PARAFAC model is not valid.
%
% Press key to continue
pause
%-------------------------------------------------
% Generate data    
for k=1:size(C,1),
  Ak = P(:,:,k)*H; % Different A for each k
  X(:,:,k)=Ak*diag(C(k,:))*B';
end,
 
% Add noise
X = X + randn(size(X))*.02;
 
 
% First fit a PARAFAC model to see if PARAFAC can estimate the parameters
%
% Press key to continue
pause
%-------------------------------------------------
myopt = parafac('options');
myopt.plots = 'off'; % turn off plotting
 
% Fit the model
model = parafac(X,F,myopt);
 
 
% Extract parameters
A = model.loads{1};
b = model.loads{2};
c = model.loads{3};
 
% Now plot the estimated and true parameters with sign and norm of 
% components adjusted according to the true parameters problems fixed
 
subplot(2,2,1)
plot(B*diag(sum(B.^2).^(-.5)),'b','linewidth',3),
hold on,
plot(b*diag(sum(b.^2).^(-.5)),'r','linewidth',2),title(' First mode (Blue:true, red:estimated)')
hold off
subplot(2,2,2)
plot(abs(C)*diag(sum(abs(C).^2).^(-.5)),'b','linewidth',3)
hold on,
plot(abs(c)*diag(sum(abs(c).^2).^(-.5)),'r','linewidth',2),title(' Third mode (Blue:true,red:estimated)')
hold off
for i=1:size(C,1),
  subplot(2,5,5+i)
  ph=P(:,:,i)*H;
  ph = ph*diag(sum(ph.^2).^(-.5));
  ph = ph*diag(sign(ph(1,:)));
  plot(ph,'b','linewidth',3),
  hold on
  ph=A;
  ph = ph*diag(sum(ph.^2).^(-.5));
  ph = ph*diag(sign(ph(1,:)));
  plot(ph,'r','linewidth',2),
  eval(['title([''2. mode, k = '',num2str(i)])'])
  hold off
  axis tight
end
 
%
% As can be seen, PARAFAC is not doing a very good job at recovering the
% underlying parameters. In the lower part of the plot, note that PARAFAC
% is suggesting the same set of profiles (red) to be adequate for all five
% samples, but as the actual profiles (blue) differ, the model is not
% adequate. This is also reflected in the second and third mode loadings.
%
% Instead, we will try a PARAFAC2 model.
%
% Press key to continue
pause
%-------------------------------------------------
 
myopt = parafac2('options');
myopt.plots = 'off'; % turn off plotting
 
% Fit the model
model = parafac2(X,F,myopt);
 
 
% Extract parameters
p = model.loads{1}.P;
h = model.loads{1}.H;
b = model.loads{2};
c = model.loads{3};
 
% Now plot the estimated and true parameters with parameters optimally
% adjusted according to the true parameters
%
subplot(2,2,1)
plot(B*diag(sum(B.^2).^(-.5)),'b','linewidth',3),
hold on,
plot(b*diag(sum(b.^2).^(-.5)),'r','linewidth',2),title(' First mode (Blue:true, red:estimated)')
hold off
subplot(2,2,2)
plot(C*diag(sum(C.^2).^(-.5)),'b','linewidth',3)
hold on,
cest = c;
clear ph
for k = 1:size(C,1) % check scale of each score using scale of first mode loads
  ph(:,:,k)=p{k}*h;
  PH=P(:,:,k)*H;
  for f = 1:F
    cor = corrcoef([ph(:,f,k) PH]);
    [a1,a2]=max(abs(cor(1,2:end)));
    s = sign(cor(1,a2+1));
    ph(:,f,k) = ph(:,f,k)*s;
    cest(k,f)=cest(k,f)*s;
  end
end
cest = cest*diag(sum(cest.^2).^(-.5));
plot(cest,'r','linewidth',2),title(' Third mode (Blue:true,red:estimated)')
hold off
for i=1:size(C,1),
  subplot(2,5,5+i)
  PH=P(:,:,i)*H;
  PH = PH*diag(sum(PH.^2).^(-.5));
  plot(PH,'b','linewidth',3),
  hold on
  plot(ph(:,:,i)*diag(sum(ph(:,:,k).^2).^(-.5)),'r','linewidth',2),
  eval(['title([''2. mode, k = '',num2str(i)])'])
  hold off
  axis tight
end
%
%
% PARAFAC2, correctly estimates the parameters, even though
% the first mode profiles differ from sample to sample
%
% Press key to continue
pause
%-------------------------------------------------
%
%
%
% As in any bi- or multilinear model, there is a sign-interminacy. For
% example, one spectrum may have an incorrect sign. This can be corrected
% by simply multiplying the vector with -1. To maintain the model, another
% vector of that component (e.g. its elution profile or its score vector)
% must also be multiplied by -1.
%
% This is usually not a problem in itself because non-sense signs are
% easily spotted and corrected. And these may even be corrected within the
% algorithm. However, for PARAFAC2, the situation is a bit more
% complicated, because there is a sign indeterminacy WITHIN each sample's 
% parameters. In PARAFAC2, for each sample the scores AND the first mode
% profiles are estimated. Therefore, for each sample there is a scaling
% indeterminacy for the scores (because each profile can flip). Thus, not
% only can the score vectors as such flip, but the individual elements can.
% 
% Plot the parameters without adjusting the signs and see how the scores 
% (third mode) now look wrong because individual elements change sign. 
% Imposing nonnegativity (if applicable) in the third mode can help
% avoiding the problem
%
% Press key to continue
pause
%-------------------------------------------------
 
% Now plot the estimated and true parameters (only scale them to 
% length one)
 
subplot(2,2,1)
plot(B*diag(sum(B.^2).^(-.5)),'b','linewidth',3),
hold on,
plot(b*diag(sum(b.^2).^(-.5)),'r','linewidth',2),title(' First mode (Blue:true, red:estimated)')
hold off
subplot(2,2,2)
plot(C*diag(sum(C.^2).^(-.5)),'b','linewidth',3)
hold on,
plot(c*diag(sum(c.^2).^(-.5)),'r','linewidth',2),title(' Third mode (Blue:true,red:estimated)')
hold off
for i=1:size(C,1),
  subplot(2,5,5+i)
  ph=P(:,:,i)*H;
  ph = ph*diag(sum(ph.^2).^(-.5));
  plot(ph,'b','linewidth',3),
  hold on
  ph=p{i}*h;
  ph = ph*diag(sum(ph.^2).^(-.5));
  plot(ph,'r','linewidth',2),
  eval(['title([''2. mode, k = '',num2str(i)])'])
  hold off
  axis tight
end
%
%
% Note that this is the same solution as shown before with the only
% difference being that signs are not adjusted. Obviously, care has to be
% exercised in interpreting the signs in PARAFAC2
%
%
 
%End of PARAFAC2DEMO
 
 
echo off

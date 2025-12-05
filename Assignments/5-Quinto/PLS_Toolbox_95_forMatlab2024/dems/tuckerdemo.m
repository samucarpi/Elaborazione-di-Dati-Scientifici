%tuckdemo.m
%
%
 
%
% Rasmus Bro, rb@kvl.dk
% REQUIRES THE DATA SETS !!!!!
%
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
 
echo off
home
load aminoacids;
 
% Reduce data set in case, memory is low
X = delsamps(X,[1:2:size(X,2)],2,2);
X = delsamps(X,[1:2:size(X,2)],2,2);
X = delsamps(X,[1:2:size(X,3)],3,2);
 
% Extract variables scales from dataset
EmAx = X.axisscale{2};
ExAx = X.axisscale{3};
 
disp(' DATA ')
disp(' Fluorescence measurements ideally follow the trilinear parafac')
disp(' model but we will use a TUCKER model now. We will use a simple ')
disp(' data set of 5 mixtures of three amino-acids (trp, phe & tyr) to ')
disp(' how Tucker modeling can proceed. Note that these data are probably')
disp(' better modeled with parafac')
disp(' ')
disp(' The data loaded can be seen seen by typing <whos>')
disp(' ')
whos
disp(' ')
disp(' First lets look at the raw data:')
disp(' ')
disp(' Press any key to continue')
disp(' ')
disp(' ')
pause
%-------------------------------------------------
figure(1);
for i=1:5,
   subplot(3,2,i)
   sample = squeeze(X.data(i,:,:));
   mesh(ExAx,EmAx,sample);
   title(['Sample ',num2str(i)]);
   xlabel('Exc [nm]')
   ylabel('Emi [nm]')
   axis([ExAx(1) ExAx(end) EmAx(1) EmAx(end) 0 1000]);
   grid on
   drawnow
end;
 
disp(' ')
disp(' ')
disp(' Press any key to continue')
pause
%-------------------------------------------------
close
home
 
 
disp(' FITTING A MODEL')
disp(' To investigate how many components are needed, a model with')
disp(' more than enough components is fitted. In this case we know that ')
disp(' the rank is probably 3, but we will use five components. It is ')
disp(' possible to use a different number of components in each mode in')
disp(' Tucker but we will only use five in each mode')
disp(' ') 
disp(' After fitting take a look at the produced plots')
disp(' and close the plots afterwards. Notice, in the loading plots')
disp(' that later components become spiky due to noise and note')
disp(' also the high residual of one particular excitation wave-')
disp(' length (which is faulty). This is also reflected in the')
disp(' influence plot')
disp(' ')
disp(' If you have forgotten how to fit the model, simply type')
disp(' tucker (no input arguments) at the command line, and ') 
disp(' the I/O will show up')
disp(' ')
disp(' ')
disp(' ')
disp(' model = tucker(X,[5 5 5]);')
disp(' ') 
disp(' Press any key fit the model')
disp(' ')
pause
%-------------------------------------------------
 
model = tucker(X,[5 5 5]);
disp(' ') 
disp(' Press any key to continue')
pause
%-------------------------------------------------
close
home
 
disp(' EVALUATING THE CORE')
disp(' Note that the plots which are shown by default are not')
disp(' an exhaustive number of plots, but merely a few major')
disp(' ones to force the analyst to explore the adequacy')
disp(' of the model. The special nature of the specific data')
disp(' will mostly need further plotting of the model.')
disp(' ') 
disp(' If you want to turn off the plots, you can use the fourth')
disp(' input to tucker (options) to turn them off. For more help')
disp(' on this, at the command line, type: help tucker. ')
disp(' ')
disp(' ') 
disp(' Press any key to continue')
pause
%-------------------------------------------------
home
 
 
disp(' THE MODEL STRUCTURE')
disp(' The output of the fitting is a so-called structure')
disp(' which we here named model. By typing model at the ')
disp(' command line, we can see the content of it:')
disp(' ')
disp(' model')
disp(' ')
model
disp(' ') 
disp(' Press any key to continue')
pause
%-------------------------------------------------
home
disp(' And we can access individual parts such as the first')
disp(' mode loadings (scores):')
disp(' ')
disp(' model.loads{1}')
disp(' ')
model.loads{1}
disp(' ') 
disp(' Press any key to continue')
pause
%-------------------------------------------------
home
 
disp(' Next we will investigate the core array in a bit more ')
disp(' detail')
disp(' ')
disp(' ')
disp(' Press any key to continue')
pause
%-------------------------------------------------
home
 
disp(' LOOKING AT THE CORE') 
disp(' In the core list:')
disp(' ') 
disp(' ') 
disp(' coreanal(model,''list'',12)') 
figure
coreanal(model,'list',12);
disp(' ') 
disp(' ') 
disp(' it is seen how much of the variance is explained by different ')
disp(' components. Note that the variance explained is in terms of the')
disp(' model. So all core elements together add up to 100% even if')
disp(' the model only explains a fraction of the data.')
disp(' ')
disp(' In PARAFAC there would only be factor combination 1,1,1; 2,2,2; ')
disp(' etc., but in Tucker models, there are interactions. To intepret')
disp(' the different loading matrices together, we therefore have')
disp(' to take this into account.')
disp(' ')
disp(' Knowing that a three-component PARAFAC model is adequate, it')
disp(' is noteworthy that the ten most important combinations, ')
disp(' responsible for almost 98% of the fit, only use two loadings')
disp(' in the third mode. Looking at the list of important factors')
disp(' it is suggested that a 3x3x2 Tucker3 model would be adequate')
disp(' ')
 
disp(' ')
disp(' Press any key to continue')
pause
%-------------------------------------------------
close
home
 
 
disp(' LOOKING AT THE CORE II') 
disp(' The core can also be visualized using the command ')
disp(' ') 
disp(' coreanal(model,''plot'');') 
coreanal(model,'plot');
disp(' ') 
disp(' from which plot it is clearly seen that one component')
disp(' (1,1,1) carries the majority of the information which')
disp(' is not uncommon for non-centered spectroscopic data')
disp(' ')
disp(' ')
disp(' Press any key to continue')
pause
%-------------------------------------------------
home
 
 
disp(' LOOKING AT THE CORE III') 
disp(' Before deciding too much based on the core we will ')
disp(' use the fact that the Tucker3 model has rotational ')
disp(' freedom. We will try to simplify the core, to see if ')
disp(' we can explain more of the variation with fewer factor ')
disp(' combinations by simply rotating the core to maximal')
disp(' ''simplicity''. For such a rotated core, the loadings ')
disp(' can be counter-rotated (with COREANAL.M) so that the ')
disp(' model of the data is still the same.')
disp(' ') 
disp(' rotated = coreanal(model,''maxvar'');') 
rotated = coreanal(model,'maxvar'); 
disp(' ') 
disp(' This model can be viewed similar to above as')
disp(' ')
disp(' coreanal(rotated.core,''list'',8);') 
disp(' ')
disp(' ')
disp(' Press any key to rotate the core')
pause
%-------------------------------------------------
coreanal(rotated.core,'list',8); 
disp(' ')
disp(' ')
disp(' ')
disp(' As can be seen, now we only need to look at 8 combinations rather ')
disp(' than ten, to take the 98% into account.')
disp(' ')
disp(' ')
 
 
disp(' ')
disp(' END OF  TUCKDEMO')

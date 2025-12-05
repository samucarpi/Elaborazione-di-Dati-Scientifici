echo off
% PARAFAC Demo
 
%Copyright Eigenvector Research, Inc. 1998
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%bmw
 
 
disp(' PARAFAC DEMOS')
disp(' ')
disp(' 1) Simple demo showing the concept of PARAFAC uniqueness on simulated data')
disp(' 2) More complicated fluorescence data showing the use of constraints and weights')
disp(' ')
choice = input(' Choose 1 or 2: ');
 
if choice==2
  
  echo on
  
  
  % This script demonstrates the PARAFAC routine for
  % modeling multiway fluorescence excitation-
  % emission data. 
  
  % Let us first look at one of the samples of 
  % the data which consists of 23 samples 
  % containing different amounts of four
  % fluorescing analytes: Hydroquinone, Tryptophan,
  % Phenylalanine and Dopa measured at excitation
  % 230 to 315 nm and emission 250 to 482 nm
  
  pause
%-------------------------------------------------
  load dorrit
  figure
  mesh(EEM.axisscale{3}(EEM.includ{3}),EEM.axisscale{2}(EEM.includ{2}),squeeze(EEM.data(1,EEM.includ{2},EEM.includ{3})))
  axis tight
  xlabel('Emission /nm'),ylabel('Excitation /nm'),zlabel('Intensity'),title('Sample 1')
  
  % FITTING PARAFAC 
  %
  % Since we already know that four components should 
  % be appropriate, we will fit a four-component PARAFAC
  % model. After the model has been fitted, a window will
  % pop up showing the model. Take you time to look at the plot
  % Most plots will change mode when the white background
  % is hit. You can also spawn a figure by right-clicking
  % the white background of that figure.
  
  % Note also the text appearing in the command-window.
  % This information is useful for checking that data 
  % and algorithmic settings are as expected.
  
  pause
%-------------------------------------------------
  close
  model1 = parafac(EEM,4);
  
  pause
%-------------------------------------------------
  % CHANGING SETTINGS OF THE ALGORITHM
  %
  % We will close the figure and a have a look at how 
  % the settings of the algorithm can be changed.
  
  close
  
  % Default settings for PARAFAC can be generated
  % by typing
  
  myoptions = parafac('options');
  myoptions
  
  pause
%-------------------------------------------------
  % As can be seen, several aspects of the algorithm
  % can be controlled from the options. For example, we
  % can turn of plotting
  
  myoptions.plots = 'off';
  myoptions
  
  
  % By inputting the options to PARAFAC, we then avoid 
  % the plot of the model
  
  pause
%-------------------------------------------------
  model1 = parafac(EEM,4,myoptions);
  
  % OUTPUT FROM PARAFAC
  %
  % It is also instructive to look at the output from
  % PARAFAC in the structure model1.
  
  model1
  
  % The structure contains important information such as 
  % loadings, sum-squared residuals etc. For example, the 
  % second-mode loadings, B, are in model1.loads{2} and 
  % can be extracted as
  
  B = model1.loads{2};
  

  pause
%-------------------------------------------------
  % CHANGING THE ALGORITHM
  %
  % Looking at the loadings in the second (emission)
  % mode, it is seen that one of the components has
  % a very sharp peak, which is not consistent with 
  % the expected lineshape in this case.
  
  EmissionAxis = EEM.axisscale{2}(EEM.includ{2});
  plot(EmissionAxis,B)
  
  pause
%-------------------------------------------------
  % Note that this plot can be accessed more 
  % conveniently from the model plot output
  % from PARAFAC by left-clicking the upper 
  % left loading plot window once to reach
  % the second (and possibly right-clicking
  % to spawn). This overall model plot can
  % also be generated as
  
  modelviewer(model1,EEM);
  
  
  % By looking at the residual and data landscapes
  % in the modelviewer plot, it is observed that
  % the cause of the narrow peak in the emission
  % loading may be due to the diagonal scatter peaks
  % that appear in the landscapes. These do not follow
  % the PARAFAC model and hence disturb the model.
  
  % There are several ways of dealing with this problem,
  % two of which will be discussed here
  
  pause
%-------------------------------------------------
  % USING CONSTRAINTS
  % 
  % It is possible to constrain the PARAFAC solution
  % e.g. so that the parameters do not turn negative.
  % Constraints are defined for each mode separately.
  % The definition is given in the options to PARAFAC
  % in the field .constraints. This is a cell with 
  % three elements (in case of a three-way array).
  %
  % In order to define constraints in mode two, type
  
  myoptions.constraints{2}
  
  % As can be seen, a number of constraints are possible
  % to set for the emission mode loadings (and likewise 
  % for the other modes). In this case, we could try to
  % force the emission-mode loadings to be non-negative.
  % Although, only minor negative areas occur, this 
  % constraint may be sufficient for avoiding the 
  % spurious peak.
  
  myoptions.constraints{2}.type = 'nonnegativity';
  myoptions.plots = 'on';
  pause
%-------------------------------------------------
  % Note, when the model is fitted, that the display on
  % the screen now states 'non-negativity' for mode two
  % indicating that we set the constraint correctly.
  
  model2 = parafac(EEM,4,myoptions);
  
  pause
%-------------------------------------------------
  % USING WEIGHTED LEAST SQUARES FITTING
  % 
  % Although, the emission mode loadings are now positive
  % the use of non-negativity in this case, did not help
  % in changing the spurious peak. Instead, we will weigh
  % down the area where the scattering appears. In order
  % to do so, we define a weight matrix of the same size
  % as the data. For each data-element, the weight is one
  % except in areas of scatter, where the weight is set 
  % to 0.01;
  
  % First we define the weights for one sample
  
  EmissionAxis = EEM.axisscale{2}(EEM.includ{2});
  ExcitationAxis = EEM.axisscale{3}(EEM.includ{3});
  Wonesample = ones(model2.datasource{1}.include_size(2:3));
  for i = 1:length(ExcitationAxis)
    j = find(EmissionAxis<(ExcitationAxis(i)+5)&EmissionAxis>(ExcitationAxis(i)-5));
    Wonesample(j,i)=.01;
  end
  
  subplot(2,1,1)
  mesh(EEM.axisscale{3}(EEM.includ{3}),EEM.axisscale{2}(EEM.includ{2}),squeeze(EEM.data(1,EEM.includ{2},EEM.includ{3})))
  axis tight
  xlabel('Emission /nm'),ylabel('Excitation /nm'),zlabel('Intensity'),title('Sample 1')
  subplot(2,1,2)
  mesh(EEM.axisscale{3}(EEM.includ{3}),EEM.axisscale{2}(EEM.includ{2}),Wonesample)
  axis tight
  xlabel('Emission /nm'),ylabel('Excitation /nm'),zlabel('Weight'),title('Weights')
  
  pause
%-------------------------------------------------
  % Then we define the weights to use by generating 
  % an array of the same size as X with each 
  % sample-slab being equal to Wonesample
  
  W = zeros(model2.datasource{1}.include_size);
  for i=1:size(W,1);
    W(i,:,:) = Wonesample;
  end
   
  pause
%-------------------------------------------------
  % In order to introduce the weights, these are put
  % in the field .weights in the options. We redefine
  % the options, to be sure not to include prior
  % settings such as the non-negavity constraint.
  % Note the command display stating the weights
  % will be used in fitting the model.
 
  close
  myoptions = parafac('options');
  myoptions.weights = W;
  model3 = parafac(EEM,4,myoptions);
   
  pause
%-------------------------------------------------
  % Use the modelviewer loading plot to see how
  % the use of weights removed the problematic
  % emission mode loadings. Also, toggle between
  % model and data in the data view part to see
  % how the model avoids fitting the scatter part
  % of the data.
  
  % Much more can be done in treating scatter
  % in fluorescence data, but the above exemplifies
  % how some of the more advanced aspects of 
  % PARAFAC modeling can be made useful.
  
  echo off
  
  
elseif choice == 1
  
  echo on
  % This script demonstrates the PARAFAC routine for
  % modeling multiway data. 
  
  % An interesting aspect of PARAFAC is that, under
  % fairly general conditions, it is possible to recover
  % the "true" underlying factors in a data set. This is
  % in contrast to two-way techniques like PCA, where this
  % cannot, in general, be done without some additional
  % information, such as constraints used in curve resolution
  % like non-negativity and unimodality.
  pause
%-------------------------------------------------
  % 
  
  a = [1:10]';
  b = [1:6]';
  c = [1:3]';
  d = [1:2]';
  
  % Now we'll use OUTERM to multiply them together to form a
  % 4-D array:
  pause
%-------------------------------------------------
  mwa = outerm({a,b,c,d})
  
  % Of course, a data set with only one factor isn't all that
  % interesting, so lets create another one
  
  a = [1 10 2 9 3 8 4 7 5 6]';
  b = [1 6 2 5 3 4]';
  c = [1 3 2]';
  d = [2 1]';
  pause
%-------------------------------------------------
  mwa = mwa + outerm({a,b,c,d});
  
  % So now we have a 4-way array that should be modelable
  % as the sum of the outer product of 2 sets of vectors.
  % Lets turn PARAFAC loose on this and see what we get.
  % Note that we have to tell the routine how many factors
  % to estimate. 
  pause
%-------------------------------------------------
  opt = parafac('options');
  opt.init = 3;
  mod = parafac(mwa,2,opt);
  
  % From looking at the loadings plots, it looks like we have
  % captured the right factors, except for the scale of the 
  % factors. Note that the PARAFAC routine puts all the variance
  % information into the last set of loadings, all the other
  % loadings are unit vectors. So, just to be sure, lets take
  % each of the factors and normalize it so that the first element
  % is 1, just like all our input factors, then print them out.
  pause
%-------------------------------------------------
  echo off
  
  dimension1 = mod.loads{1}*inv(diag(mod.loads{1}(1,:)))
  dimension2 = mod.loads{2}*inv(diag(mod.loads{2}(1,:)))
  dimension3 = mod.loads{3}*inv(diag(mod.loads{3}(1,:)))
  fac = mod.loads{1}(1,:).*mod.loads{2}(1,:).*mod.loads{3}(1,:);
  dimension4 = mod.loads{4}*diag(fac)
  echo on
  pause
%-------------------------------------------------
  % Thus, we can see that, to 5 digits at least, we have
  % recovered our original data. Now lets see what happens
  % when we have some noise in the data.
  
  mwa = mwa + randn(size(mwa));
  
  % Now we'll make a new PARAFAC model on this data.
  pause
%-------------------------------------------------
  
  mod = parafac(mwa,2);
  pause
%-------------------------------------------------
  % Once again, lets compare our factors to the one
  % we started with.
  pause
%-------------------------------------------------
  echo off
  dimension1 = mod.loads{1}*inv(diag(mod.loads{1}(1,:)))
  dimension2 = mod.loads{2}*inv(diag(mod.loads{2}(1,:)))
  dimension3 = mod.loads{3}*inv(diag(mod.loads{3}(1,:)))
  fac = mod.loads{1}(1,:).*mod.loads{2}(1,:).*mod.loads{3}(1,:);
  dimension4 = mod.loads{4}*diag(fac)
  echo on
  pause
%-------------------------------------------------
  % So we see that we still reasonably well, even in the
  % presence of noise.
  
  echo off
  
else
  error(' You must type either 1 or 2. Please restart the demo')
end
 
 

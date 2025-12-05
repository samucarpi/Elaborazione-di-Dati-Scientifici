classdef Classif
  % Collection of static helper functions used by classification methods

  %Copyright © Eigenvector Research, Inc. 2004
  %Licensee shall not re-compile, translate or convert "M-files" contained
  % in PLS_Toolbox for use with any software other than MATLAB®, without
  % written permission from Eigenvector Research, Inc.

  methods(Static)
    %--------------------------------------------------------------------------
    function [model] = setpredprobability(model)
      %Convert prediction into probability scale
      % Same function is used in other classification methods
      
      % check that model is an allowable model type
      modtype = lower(model.modeltype);
      if ~ismember(modtype, {'plsda', 'annda', 'anndlda', 'plsda_pred', 'annda_pred', 'anndlda_pred'})
        error( 'Model type (%s) is not supported by method setpredprobability', modtype);
      end
      model.detail.predprobability = [];  %start with empty prob matrix
      % Use Gaussian params and priorprob to calculate class probability
      if strcmp(model.detail.options.usegaussianparams,'yes') & ~isempty(model.detail.distprob)
        [predprobability, thresh]    = Classif.getProbsFromGauss(model.pred{2}, model.detail.distprob);
        model.detail.predprobability = predprobability;
        model.detail.threshold       = thresh;
      else
        % Use lookup-table to calculate class probability
        for j = 1:size(model.pred{2},2)
          temp = max(min(model.pred{2}(:,j),max(model.detail.probability{j}(:,1))),min(model.detail.probability{j}(:,1)));
          model.detail.predprobability(:,j) = interp1(model.detail.probability{j}(:,1),model.detail.probability{j}(:,3),temp);
        end
      end
    end

    %--------------------------------------------------------------------------
    function [prob1, thresh, prob0, py1, py0] = getProbsFromGauss(y, distprob)
      %Get class probability for input y, Gaussian params, and priors.
      %
      % Use Gaussian params and priors to calculate class probability directly
      % for the input value(s) of y (instead of using PLSDA-style lookup table).
      % Input distprob contains s, c, and prior entries for each of 2 modeled
      % classes (element in distprob cell array). These each have have 2 values.
      % The first is for class=0 and second is for class=1.
      % Samples with class=1 are samples with y=1, the class of interest.
      % Samples with class=0 are the "others", not-the-class-of-interest classes.
      % Thus, py1 is P(y|A), prob distribution as fn(y) of the class of interest,
      % The "prob" calculated below is P(A|y), or the probability that a sample
      % with the input value of y belongs to the class-of-interest.
      %
      % INPUTS:
      %        y = matrix of size(nsamples, nclasses) of y values
      % distprob = cell array containing a struct of Gaussian params and priors
      %            for each class. Length = nclasses
      % OUTPUTS:
      %    prob1 = Probability of class-of-interest for the input y, P(class1|y)
      %   thresh = Threshold value in y for separating class1 from class 0
      %    prob0 = Probability of ~class-of-interest for the input y, P(class0|y)
      %      py1 = Probability distribution of class2, P(y|class1), times prior1
      %      py0 = Probability distribution of class2, P(y|class0), times prior0
      %
      %See also: DISCRIMPROB, PLSDTHRES, PLSDA

      py1   = [];
      py0   = [];
      nclasses = length(distprob);

      prob0  = nan(size(y,1), nclasses);
      prob1  = nan(size(y,1), nclasses);
      thresh = nan(1, nclasses);
      for ic=1:nclasses
        scp = distprob{ic};
        s = scp.s;          % std of [class0, class1]
        c = scp.c;          % mu of [class0, class1]
        prior = scp.prior;  % prior of [class0, class1]

        py0 = 1/(s(1)*sqrt(2*pi)) *prior(1) *exp( -(y(:, ic) - c(1)).^2/(2*s(1)^2) );  % P(y|class0)*prior(0)
        py1 = 1/(s(2)*sqrt(2*pi)) *prior(2) *exp( -(y(:, ic) - c(2)).^2/(2*s(2)^2) );  % P(y|class1)*prior(1)
        % add eps to ednominator to avoide it ever becoming zero, causing NaN result
        prob0(:,ic) = py0./(py1+py0 + eps);                                            % P(class0|y)
        prob1(:,ic) = py1./(py1+py0 + eps);                                            % P(class1|y)

        thresh(ic)  = getroots(s, c, prior);
      end

      %--------------------------------------------------------------------------
      function [y1, y2] = getroots(s, c, prior)
        % Find where the two class prob distributions, adjusted by prior
        % probabilities, overlap between their peaks, each = 0.5
        aa = s(2)^2 - s(1)^2;
        bb = 2*(s(1)^2*c(2) - s(2)^2*c(1));
        cc = (s(2)*c(1))^2 - (s(1)*c(2))^2 + 2*(s(1)*s(2))^2*log( (prior(2)*s(1))/(prior(1)*s(2)));

        y1 = nan;
        y2 = nan;
        if abs(aa)<eps & abs(bb)<eps
          % Class distribribution is same as the not-class distribution
        elseif abs(aa)>10*eps
          y1 = (-bb + sqrt(bb*bb-4*aa*cc)) / (2*aa);
          y2 = (-bb - sqrt(bb*bb-4*aa*cc)) / (2*aa);
        else
          y1 = 0;
          y2 = -cc/bb;
        end

        % Ensure first returned root is the root between the centers, c(1), c(2)
        if ~isnan(y1*y2) & y2>c(1) & y2<c(2)
          % Swithching root order
          tmp = y1;
          y1 = y2;
          y2 = tmp;
        end
      end

    end
    %--------------------------------------------------------------------------

  end  % methods

end
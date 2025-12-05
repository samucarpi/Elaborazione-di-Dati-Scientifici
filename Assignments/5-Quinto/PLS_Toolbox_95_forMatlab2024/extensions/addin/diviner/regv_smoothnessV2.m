
% regv_smoothness: The regression vector smoothness
% It takes the regression vector from a model and smooth it and take the
% residuals between the smooth vector and the original regression vector
% It also returns the Standard Deviation of the normalized Regression Vector
% V2 treats separately the different sections of the regression vector.
% INPUTS:
%        model  = calibrated PLS, PCR or MLR EVRI model object.
%        w      = SavGol smoothing window
% OUTPUT:
%       regv_smoothness = The regression vector smoothness
%       std_regv        = Standard Deviation of the normalized regression vector
%       full_smth_regv  = Smooth regression vector
%
% Manuel Palacios, Eigenvector Research Inc. 10/19/2023

% Check if w is provided. If not, set to 11.




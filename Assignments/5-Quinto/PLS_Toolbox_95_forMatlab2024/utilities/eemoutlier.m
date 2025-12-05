function result = eemoutlier(X,F,options);
%EEMOUTLIER automatically remove outliers in PARAFAC models of EEM data
%
% Provides an automated outlier selection procedure for a given dataset and
% given number of components. Samples with a high leverage or high
% sum-squared residual are removed one by one until no samples are assessed
% as outliers. The settings for making decisions are given in the top of
% the m-file. Outliers can only be removed until there are 8 samples left.
% Then the algorithm will stop.
%
% The output has the following fields
%   result.model % 
%   result.SMPS  % cell of sample sets
%
% R. Bro and M. Vidal, EEMizer: Automated modeling of fluorescence EEM data, 
% Chemometrics and Intelligent Laboratory Systems 106 (2011) 86–92
%
%I/O: result = eemoutlier(X,factors);
%
%See also: PARAFAC

%Copyright Eigenvector Research, Inc. 2016
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

options.plots = 'off';
options.waitbar = 'off';
origdisplay = options.display;
options.display = 'off';

samples = size(X,1); % Number of sample

% CRITERIA
critlevel = options.auto_outlier.critlevel; % if any sample has a leverage or Q more than critlevel higher than the median, the sample is removed (one sample is removed at a time)
samplenumberfactor = options.auto_outlier.samplenumberfactor ;
samplefraction  = options.auto_outlier.samplefraction; % If more than samplefraction of the samples are removed, increase the critical level
if samples/20<1
    samplenumberfactor = 30/samples;
end; %If less than 20 samples increase the critical level of leverage and Q by this factor in order not to remove too many samples on small datasets

smps = [1:samples];

continu = 1;
cou = 0;
R = [];
if strcmpi(origdisplay,'on')
    disp(['Testing for outliers'])
end
while continu
    cou = cou+1;
    res = parafac(X(smps,:,:),F,options);
    tsqsmax = max(res.tsqs{1})/median(res.tsqs{1});
    ssqmax = max(res.ssqresiduals{1})/median(res.ssqresiduals{1});
    numsam = length(res.detail.includ{1});
      
    if length(smps)<9
        fracfactor = 1e10;
    elseif (1-(length(smps)/samples))>samplefraction
        fracfactor = ((1-(length(smps)/samples))/samplefraction).^2;
    else
        fracfactor = 1;
    end
        
    if max(tsqsmax,ssqmax)>critlevel*samplenumberfactor*fracfactor
        continu = 1;
        if tsqsmax>ssqmax
            [a,b]=max(res.tsqs{1});
        else
            [a,b]=max(res.ssqresiduals{1});
        end
        if strcmpi(origdisplay,'on')
            disp([' Removing sample ',num2str(smps(b)),' ...'])
        end
        smps(b) = [];
    else
        continu = 0;
    end
end
result.model = res;
result.SMPS = smps;

function [nhid1] = getanndlnhidone(varargin)
%GETANNDLNHIDONE Gets size of first hidden layer in ANNDL/ANNDLDA model
%object.
%   Helper script was made to get the first hidden layer since it used in
%   many various places. Gets the first hidden layer depending on the type
%   of algorithm used.



if nargin==1
  if isa(varargin{1},'evrimodel')
    % input is model
    % model is a ANNDL or ANNDLDA modeltype
    model = varargin{1};
    if ~ismember(model.modeltype, {'ANNDL' 'ANNDLDA' 'ANNDL_PRED' 'ANNDLDA_PRED'})
      error(['Model is not of type ANNDL, ANNDLDA, ANNDL_PRED, ANNDLDA_PRED. Instead got modeltype ' model.modeltype])
    end

    switch model.detail.options.algorithm
      case 'sklearn'
        nhid1 = model.detail.options.sk.hidden_layer_sizes{1};
      case 'tensorflow'
        if ~ismember(model.detail.options.tf.hidden_layer{1}.type,{'Dense','Conv1D','Conv2D','Conv3D'})
          %these layers don't have units, hard code to 1
          nhid1 = 1;
        else
          nhid1 = model.detail.options.tf.hidden_layer{1}.units;
        end
      otherwise
        error(['Unsupported algorithm type ' model.detail.options.algorithm]);
    end
  elseif isa(varargin{1},'struct')
    %options structure passed
    options = varargin{1};
    switch options.algorithm
      case 'sklearn'
        nhid1 = options.sk.hidden_layer_sizes{1};
      case 'tensorflow'
        if ~ismember(options.tf.hidden_layer{1}.type, {'Dense','Conv1D','Conv2D','Conv3D'})
          %these layers don't have units, hard code to 1
          nhid1 = 1;
        else
          nhid1 = options.tf.hidden_layer{1}.units;
        end
    end
  end
end


end


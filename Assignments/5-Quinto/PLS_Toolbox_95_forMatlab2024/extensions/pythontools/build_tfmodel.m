function [model] = build_tfmodel(opts, input_shape, output_shape,xblock_size)
%BUILD_TFMODEL Wrapper for Python help build_tfmodel.py
%   Detailed explanation goes here
orig_dir = pwd;
filepath = fileparts(mfilename('fullpath'));
cd(filepath);
try
  model = py.build_tfmodel.main(opts,input_shape,output_shape,xblock_size);
  cd(orig_dir);
catch E
  cd(orig_dir);
  error(['Error in building Tensorflow model.' E.message]);
end
end


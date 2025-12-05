#######################################################################

# Imports

import array
import numpy as np
import tensorflow.keras as tf
from tensorflow.random import set_seed
from tensorflow.keras.optimizers import Adam, Adamax, SGD, RMSprop

#######################################################################

# Globals

SUPPORTED_FIELD_NAMES = ('type', 'units','size')
NEEDED_FIELDS         = {'Dense':['type','units'],
                         'Dropout':['type','units'],
                         'Flatten':['type'],
                         'BatchNormalization': ['type'],
                         'Conv1D':['type','units','size'],
                         'Conv2D':['type','units','size'],
                         'Conv3D':['type','units','size'],
                         'MaxPooling1D':['type','size'],
                         'MaxPooling2D':['type','size'],
                         'MaxPooling3D':['type','size'],
                         'AveragePooling1D':['type','size'],
                         'AveragePooling2D':['type','size'],
                         'AveragePooling3D':['type','size']
                        }
INPUT_SHAPES          = {'Dense':1,
                         'Conv1D':2,
                         'Conv2D':3,
                         'Conv3D':4,
                         'MaxPooling1D':2,
                         'MaxPooling2D':3,
                         'MaxPooling3D':4,
                         'AveragePooling1D':2,
                         'AveragePooling2D':3,
                         'AveragePooling3D':4
                        }

#######################################################################

def check_hidfields(hid):
    '''
    Make sure that the keys of this layer are supported.

    hid : Hidden layer of type dict. 
    '''

    if hid.get('type')==None:
        raise ValueError('Error in hidden layer: ', hid, '. Need to declare "type" for this layer.')
    layer = hid['type']
    for key in hid.keys():
        if key not in SUPPORTED_FIELD_NAMES:
            raise ValueError('Unsupported field name for hidden layer. Got: ',key)
    
    '''
    Now make sure that each layer type has all the fields it needs.
    Take a set difference between what is needed versus what is supplied. If the needed fields are not in what is supplied,
    then the difference will be at least one. 
    To make sure all that is needed is there, the set difference must be 0.
    '''

    if len(set(NEEDED_FIELDS[layer]).difference(set(hid.keys())))!=0:
        raise ValueError('Error in ', layer, ' layer. This layer needs values for these fields: ', NEEDED_FIELDS[layer])

#######################################################################

def get_optimizer(options):
    '''
    Set up optimizer with learning rate.

    options: options.tf from MATLAB
    '''

    opt = str(options['optimizer']).lower()
    if opt == 'rmsprop':
        optimizer = RMSprop(learning_rate=options['learning_rate'])
    elif opt == 'adam':
        optimizer = Adam(learning_rate=options['learning_rate'])
    elif opt == 'adamax':
        optimizer = Adamax(learning_rate=options['learning_rate'])
    elif opt == 'sgd':
        optimizer = SGD(learning_rate=options['learning_rate'])
    else:
        raise ValueError('Unsupported optimizer: ', opt, 'Please choose from rmsprop, adam, adamax, and sgd.')
    return optimizer

########################################################################

def check_input_shape(first_layer,xblock_size,input_shape):
    '''
    Need to check the dimensionality of xblock and the type of layer selected.
    
    first_layer: string of layer type for the first layer
    x_block_size: value returned from MATLAB when calling size(x)
    input_shape: input dimensions for first layer of Tensorflow model
    '''

    #input_shape is a padded container, a tuple of a numpy array
    #if this numpy array is array(one_element), len(array(one_element)) will give error
    #use .shape on input_shape[0] instead

    #this is what will be returned if the input shape is 1-dimensional
    if input_shape[0].shape==():
        ndim_ip = 1
    else:
        ndim_ip = len(input_shape[0])
    ndim_xb = len(xblock_size)
    if first_layer in INPUT_SHAPES.keys():
        if (INPUT_SHAPES[first_layer] != ndim_ip) or (INPUT_SHAPES[first_layer]+1 != ndim_xb):
            raise ValueError('Error in dimensionality. Layer type ', first_layer, ' needs an XBlock dimensionality of ', INPUT_SHAPES[first_layer]+1, ' and an input shape dimensionality of ', INPUT_SHAPES[first_layer],
                             '. Provided Xblock was of dimensionality ',ndim_xb,' and an input shape of dimensionality ', ndim_ip,'.' ) 

########################################################################

def add_first_layer(model, options, input_shape,xblock_size):
    '''
    Function made for this since input_shape is a need parameter, not for other additional hidden layers
    
    model: Tensorflow Sequential model
    options: options.tf from MATLAB
    input_shape: input dimensions for first layer of Tensorflow model
    xblock_size: dimensions of xblock
    '''

    act = options['activation']
    hid = options['hidden_layer'][0]
    
    if type(hid)!=dict:
        raise TypeError('Wrong type for hidden layer. Each hidden layer provided should be in the form of a struct.')
    
    check_hidfields(hid)
    
    layer = hid['type']

    # Make sure the size of the data and the layer specified agrees.
    check_input_shape(layer, xblock_size, input_shape)

    # Create first layer, condition by the type of layer
    if layer=='Dense':
        model.add(tf.layers.Dense(hid['units'], activation=act, input_shape=input_shape))
    elif layer=='Dropout':
        model.add(tf.layers.Dropout(hid['units']))
    elif layer=='Flatten':
        model.add(tf.layers.Flatten())
    elif layer=='BatchNormalization':
        model.add(tf.layers.BatchNormalization())
    elif layer=='Conv1D':
        input_shape = (input_shape[0][0],input_shape[0][1]) 
        model.add(tf.layers.Conv1D(hid['units'],kernel_size=int(hid['size']),activation=act, input_shape=input_shape))
    elif layer=='Conv2D':
        if type(hid['size'])==array.array:
            hid['size'] = (int(hid['size'][0]),int(hid['size'][1]))
            input_shape = (input_shape[0][0],input_shape[0][1],input_shape[0][2]) 
            model.add(tf.layers.Conv2D(hid['units'], kernel_size=hid['size'], activation=act, input_shape=input_shape))
        else:
            raise ValueError('Please provide length and width for Conv2D kernel: [x y].')
    elif layer=='Conv3D':
        if type(hid['size'])==array.array:
            input_shape = (input_shape[0][0],input_shape[0][1],input_shape[0][2],input_shape[0][3])      
            hid['size'] = (int(hid['size'][0]),int(hid['size'][1]), int(hid['size'][2]))
            model.add(tf.layers.Conv3D(hid['units'], kernel_size=hid['size'],activation=act, input_shape=input_shape))
        else:
            raise ValueError('Please provide length, width, and depth for Conv3D kernel: [x y z].')
    elif layer=='MaxPooling1D':
        input_shape = (input_shape[0][0],input_shape[0][1])
        model.add(tf.layers.MaxPooling1D(int(hid['size']), input_shape=input_shape))                                 
    elif layer=='MaxPooling2D':
        input_shape = (input_shape[0][0],input_shape[0][1],input_shape[0][2])
        model.add(tf.layers.MaxPooling2D(hid['size'], input_shape=input_shape))                                                               
    elif layer=='MaxPooling3D':
        input_shape = (input_shape[0][0],input_shape[0][1],input_shape[0][2],input_shape[0][3])
        model.add(tf.layers.MaxPooling3D(hid['size'], input_shape=input_shape))
    elif layer=='AveragePooling1D':
        input_shape = (input_shape[0][0],input_shape[0][1])
        model.add(tf.layers.AveragePooling1D(int(hid['size']), input_shape=input_shape))
    elif layer=='AveragePooling2D':
        input_shape = (input_shape[0][0],input_shape[0][1],input_shape[0][2])
        model.add(tf.layers.AveragePooling2D(hid['size'], input_shape=input_shape))
    elif layer=='AveragePooling3D':
        input_shape = (input_shape[0][0],input_shape[0][1],input_shape[0][2],input_shape[0][3])
        model.add(tf.layers.AveragePooling3D(hid['size'], input_shape=input_shape))
    else:
        raise ValueError('Unsupported layer type: ', layer)

    return model

#######################################################################

def add_remaining_hidden_layers(model, options):
    act = options['activation']

    for hid in options['hidden_layer']:
        if type(hid)!=dict:
            raise TypeError('Wrong type for hidden layer. Each hidden layer provided should be in the form of a struct.')
        check_hidfields(hid)
        layer = hid['type']

        if layer=='Dense':
            model.add(tf.layers.Dense(hid['units'],activation=act))
        elif layer=='Dropout':
            model.add(tf.layers.Dropout(hid['units']))
        elif layer=='Flatten':
            model.add(tf.layers.Flatten())
        elif layer=='BatchNormalization':
            model.add(tf.layers.BatchNormalization())
        elif layer=='Conv1D':
            model.add(tf.layers.Conv1D(hid['units'],kernel_size=int(hid['size']),activation=act))
        elif layer=='Conv2D':
            if type(hid['size'])==array.array:
                hid['size'] = (int(hid['size'][0]),int(hid['size'][1]))
                model.add(tf.layers.Conv2D(hid['units'], kernel_size=hid['size'], activation=act))
            else:
                raise ValueError('Please provide length and width for Conv2D kernel: [x y].')
        elif layer=='Conv3D':
            if type(hid['size'])==array.array:  
                hid['size'] = (int(hid['size'][0]),int(hid['size'][1]), int(hid['size'][2]))
                model.add(tf.layers.Conv3D(hid['units'], kernel_size=hid['size'],activation=act))
            else:
                raise ValueError('Please provide length, width, and depth for Conv3D kernel: [x y z].')
        elif layer=='MaxPooling1D':
            model.add(tf.layers.MaxPooling1D(int(hid['size'])))                                
        elif layer=='MaxPooling2D':
            model.add(tf.layers.MaxPooling2D(hid['size']))
        elif layer=='MaxPooling3D':
            model.add(tf.layers.MaxPooling3D(hid['size'])) 
        elif layer=='AveragePooling1D':
            model.add(tf.layers.AveragePooling1D(int(hid['size'])))
        elif layer=='AveragePooling2D':
            model.add(tf.layers.AveragePooling2D(hid['size']))
        elif layer=='AveragePooling3D':
            model.add(tf.layers.AveragePooling3D(hid['size'])) 
        else:
            raise ValueError('Unsupported layer type: ', layer)                            

    return model

#######################################################################

def main(options, input_shape, output_shape,xblock_size):

    '''
    options: tf struct to help guide build of model
    input_shape : shape of input layer
    output_shape: shape of output layer
    xblock_size: dimensions of xblock
    '''

    # set random seed from options
    set_seed(int(options['random_state']))
    
    # cast options to list to make it mutable
    options['hidden_layer'] = list(options['hidden_layer'])

    # build model
    engine = tf.Sequential()

    # add first layer
    engine = add_first_layer(engine,options,input_shape,xblock_size)

    if len(options['hidden_layer'])>1:
        # pop first layer, since it has been taken care of
        options['hidden_layer'].pop(0)
        engine = add_remaining_hidden_layers(engine, options)

    # output layer
    engine.add(tf.layers.Dense(output_shape))

    # get optimizer object configured with learning rate from options structure
    optimizer = get_optimizer(options)

    # compile and return to MATLAB for fitting
    engine.compile(optimizer=optimizer,loss=options['loss'])
    
    return engine

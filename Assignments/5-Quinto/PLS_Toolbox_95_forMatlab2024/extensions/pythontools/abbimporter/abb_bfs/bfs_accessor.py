'''
Created on Jan 16, 2019

@author: jslarochelle
'''

from abb_bfs.byte_buffer import ByteBuffer
from zlib import decompress
import csv

try:
    # Used only for static type checking (optional)
    from typing import Tuple, Union, List, Any, Optional, Dict
except Exception as e:
    #print("Not loading types for PEP 484 checking")
    pass

class BfsAccessException(Exception):
    '''
    This is the type for exceptions in the module. 
    It includes a message and sometimes the exception that is the original source of the error. 
    '''

    BFS_ERROR = 2
    BFS_WARNING = 1
    
    def __init__(self, message, exception=None, error=BFS_ERROR):
        # type: (str, Optional[Exception], int) -> None
        super(BfsAccessException, self).__init__(message)
        self._message = message
        self._exception = exception # type: Optional[Exception]
        self._error = error  # type: int

    @property
    def message(self):
        # type: () -> str
        if isinstance(self._exception, Exception):
            return self._message + ", cause: {}".format(str(self._exception))
        else:
            return self._message

    def get_error_level(self):
        # type: () -> int
        '''
        Return an int representing the severity of the exception
        2 means a severe error and the current operation could not be completed
        1 means a warning and the result of the current operation might not be what's expected
        '''
        return self._error

    @property
    def exception(self):
        # type: () -> Optional[Exception]
        return self._exception


_PLACE_HOLDER = ["&1", "&2","&3","&4","&5","&6","&7","&8","&9"]

def expect(condition, message, *values):
    # type: (bool, str, List) -> None
    '''
    Test a condition and throws a :BfsAccessException if False 
    '''
    if not condition:
        for index in range(len(values)):
            message = message.replace(_PLACE_HOLDER[index], str(values[index]))
        raise BfsAccessException(message)              

class DataDescriptor:
    '''
    Fully describes one item in the BFS. It provides all the information required to access the data associated with
    a name. This includes information about the specific type and position of the data in the :DataBlock 
    '''

    # There is no type associated with this field.
    NO_TYPE = 0

    # <code>byte</code> data which may be used for Ascii character
    TYPE_BYTE = 1

    # <code>boolean</code> data stored as <code>byte</code>
    TYPE_BOOLEAN = 2

    # Unicode <code>char</code> data type
    TYPE_CHAR = 3

    # <code>short</code> data
    TYPE_SHORT = 4
    
    # <code>int</code> data
    TYPE_INT = 5

    # <code>long</code> data
    TYPE_LONG = 6

    # <code>float</code> data
    TYPE_FLOAT = 7

    # <code>double</code> data
    TYPE_DOUBLE = 8

    # <code>complex float</code> data
    TYPE_COMPLEX = 9

    # <code>complex double</code> data
    TYPE_DCOMPLEX = 10

    # RGB
    TYPE_RGB = 11

    # Color 4
    TYPE_COLOR4 = 12

    # <code>String</code> data type
    TYPE_STRING = 50

    # ascii string data type
    TYPE_ASCII_STRING = 51

    # Block floating point where the first element is a <code>float</code>
    # scale factor m, the second element <code>float</code> b and the remaining
    # elements are <code>short</code> data.  The data value may be computed
    # with the equation: y = m*x + b
    TYPE_SHORT_BFP = 52

    # Block floating point where the first element is a <code>double</code>
    # scale factor m, the second element <code>double</code> b and the
    # remaining elements are <code>int</code> data.  The data value may be
    # computed with the equation: y = m*x + b
    TYPE_INT_BFP = 53

    NO_COMPRESSION = 0

    # Maximum number of dimensions of a data item
    MAX_NBR_DIM = 4

    DATA_SIZE = [0, 1, 1, 2, 2, 4, 8, 4, 8, 8, 16, 3, 4]
    
    DATA_TYPE_SIZE_INFO = {TYPE_STRING: (2, 4), TYPE_ASCII_STRING: (1, 1), TYPE_SHORT_BFP: (2, 8), TYPE_INT_BFP: (4, 6)}

    def __init__(self, name, number_of_dim, byte_buffer):
        # type: (str, int, ByteBuffer) -> None
        '''
        Constructor
        '''
        # Parameter name
        self._name = name
        
        # Number of dimensions of the parameter:  1 for scalar, 2 for vector, ...
        self._number_of_dim = number_of_dim

        self._compression_scheme = byte_buffer.get_short ();

        # Axis name i.e. Radiance (String [])
        self._axis_name = [] # type: List[str]
    
        # Units code
        self._axis_unit = [] # type: List[str]
    
        # Scale type of this axis.
        # NO_TYPE
        # TYPE_FLOAT
        # TYPE_DOUBLE
        self._axis_type = [] # type: List[int]
    
        # Number of elements in this dimension (int [])
        self._axis_npts = [] # type: List[int]
    
        # Value of the first element of the axis (double [])
        self._axis_min_value = [] # type: List[int]
    
        # Value of the last element of the axis (double [])
        self._axis_max_value = [] # type: List[int]

        for dimdex in range(number_of_dim):
            self._axis_name.append(byte_buffer.get_pascal_string())
            self._axis_unit.append(byte_buffer.get_pascal_string())
            self._axis_type.append(byte_buffer.get_short ())
            npts = byte_buffer.get_int () # print("{} :: dim={} -> npts={}".format(name, dimdex, npts))
            self._axis_npts.append(npts)
            self._axis_min_value.append(byte_buffer.get_double ())
            self._axis_max_value.append(byte_buffer.get_double ())
    
    @property
    def name(self):
        return self._name
        
    @property
    def compression_scheme(self):
        return self._compression_scheme
        
    @property
    def number_of_dim(self):
        # type: () -> int
        return self._number_of_dim
         
    def get_axis_type(self, index=0):
        # type: (int) -> int
        return self._axis_type[index] 
        
    def get_axis_npts(self, axis=0):
        # type: (int) -> int
        return self._axis_npts[axis] 
    
    def get_axis_size(self, axis=0):
        # type: (int) -> int
        '''
        Returns the size of the data axis described by this <code>DataDescriptor
        If the axis is not present (NO_TYPE), 0 is returned.
        Where axis is
        1    X
        2    Y
        3    Z
        return    size in bytes
        '''
        return self.get_type_size(self._axis_type[axis], self._axis_npts[axis])

    def get_data_size(self):
        # type: () -> int
        '''
        Returns the size of the data described by this <code>DataDescriptor
        This is the uncompressed size.
        return    size in bytes
        '''
        size = 1
        for i in range(0, self._number_of_dim):
            size *= self._axis_npts[i]
        return self.get_type_size (self._axis_type[0], size);

    def get_type_size (self, typeid, npts):
        # type: (int, int) -> int
        '''
        Returns the size of a given <code>type</code> for a given number of
        elements <code>nPts</code>.
        param type        see TYPE_xxx
        param nPts        number of elements
        return            size in <code>bytes</code>
        '''
        size = 0;
        extra = 0;
        if typeid <= DataDescriptor.TYPE_COLOR4:
            size  = DataDescriptor.DATA_SIZE[typeid]
            extra = 0
        elif typeid <= DataDescriptor.TYPE_INT_BFP:
            size, extra = DataDescriptor.DATA_TYPE_SIZE_INFO[typeid]
        return size * npts + extra;
    

class DataDirectory:
    '''
    This is used to define the data stored in the BFS. It gives access to the list of items
    stored in the BFS including their name and and their :DataDescriptor 
    '''  
    # Marker used to verify file integrity and help data retrieval.
    # Version of the <code>DataDirectory</code> is the last digit of "Dir0".
    DIR_MAGIC_NUMBER = 0x30726940  # Dir0  

    def __init__(self, byte_buffer):
        # type: (ByteBuffer) -> None
        '''
        Constructor
        '''
        self._number_of_entries = byte_buffer.get_int()
        self._entries = [] # type: List[DataDescriptor]
        self._lookup = {} # type: Dict[str, int]
        
        for index in range(0, self._number_of_entries):
            name = byte_buffer.get_pascal_string()
            number_of_dim = byte_buffer.get_short()           
            desc = DataDescriptor (name, number_of_dim, byte_buffer)
            self._entries.append(desc)
            self._lookup[name] = index

    @staticmethod
    def get_instance (byte_buffer, size, header_compressed=False):
        # type: (ByteBuffer, int, bool) -> DataDirectory
        '''
        Factory method to build instance of this from ByteBuffer data
        '''
        if header_compressed:
            unziped_size = byte_buffer.get_int()
            
            start = byte_buffer.position()
            end = start + size - 4
            zipped_data = byte_buffer._get_byte_array_at(start, end) # Skip the first int (-4)
            
            unzipped_data = decompress(zipped_data, bufsize=unziped_size) 
            
            byte_buffer = ByteBuffer(unzipped_data)
            
        magic = byte_buffer.get_int()
    
        assert(magic == DataDirectory.DIR_MAGIC_NUMBER)
        
        return DataDirectory(byte_buffer)
    
    @property
    def number_of_entries(self):
        # type: () -> int
        '''
        Return the number of entries in this
        '''
        return self._number_of_entries
    
    def descriptor(self, key):
        # type: (Union[int, str]) -> DataDescriptor
        '''
        Return the descriptor matching the key where the key can be:
        an index between 0 and :number_of_entries - 1
        or simply the name of the item.         
        '''
        if isinstance(key, int):
            return self._entries[key]
        else:
            index = self.index_of(key)
            if index >= 0:
                return self._entries[index]
            else:
                raise BfsAccessException("The key '{}' does not match any entry".format(key))
    
    def index_of(self, name):
        # type: (str) -> int
        '''
        Returns the 0 based index of the <code>DataDescriptor</code> entry which
        holds the <code>parameterName</code> or -1 if entry does not exist.
        parameterName case sensitive <code>String</code> name of the
                                requested entry
        
        returns >=0    index of the requested entry which can be used to index in the
                           <code>DataDescriptor</code> array.
                 -1    parameterName does not match any entry in the
                        <code>DataDescriptor</code> array.
        '''
        index = self._lookup.get(name)
        if isinstance(index, int):
            return index
        else:
            return -1

    
class DataBlock:
    '''
    This provides access to the actual data associated with a :DataDirectory
    '''

    def __init__(self, data_directory, byte_buffer):
        # type: (DataDirectory, ByteBuffer) -> None
        '''
        Constructor
        '''
        self._descriptor = data_directory
        self._data       = byte_buffer # this is a section of the top level ByteBuffer 
                                        # and the next byte in it is at index 0 here
        self._relative_offset = [] # type: List[int]

        offset = 0
        for i in range(0, data_directory.number_of_entries):
            self._relative_offset.append(offset)
            offset += self.get_data_size (i)
            
        self._relative_offset.append(offset)
        self.total_size = offset

    def get_data_size(self, entry):
        # type: (int) -> int
        desc = self._descriptor.descriptor (entry) # type: DataDescriptor
        
        size = 0
        if desc.compression_scheme == DataDescriptor.NO_COMPRESSION:
            if desc.get_axis_type(0) == DataDescriptor.TYPE_STRING:
                if desc.get_axis_npts(0) != 0:
                    return 2 * desc.get_axis_npts(0)
                else:
                    return 4 + 2 * self._data.get_int_at (self._relative_offset[entry])
            elif desc.get_axis_type(0) == DataDescriptor.TYPE_ASCII_STRING:
                if desc.get_axis_npts(0) != 0:
                    size = desc.get_axis_npts(0) + 1 # An extra character
                else:
                    size = 0
                    c = self._data.get_byte_at (self._relative_offset[entry] + size)
                    size += 1
                    while c != 0:
                        c = self._data.get_byte_at (self._relative_offset[entry] + size)
                        size += 1
 
                    return size + 1 # An extra character
            else:
                size = desc.get_data_size ()
        else:
            # If data is compressed, length followed by data
            size = 4 + self._data.get_int_at(self._relative_offset[entry])

            
        for j in range(1, desc.number_of_dim):
            size += desc.get_axis_size(j) # Was getAxisSize()
            
        return size
    
    @property
    def directory(self):        
        return self._descriptor

    @property
    def data(self):
        return self._data
    
    def get_relative_offset(self, entry):
        # type: (int) -> int
        return self._relative_offset[entry]
    
    def get_value(self, name, descriptor):
        # type: (str, DataDescriptor) -> Tuple[int, Any]
        '''
        This is the method that gets the data matching a given name
        '''
        index = self._descriptor.index_of(name)
        offset = self._relative_offset[index]
        axis_type = descriptor.get_axis_type()
        value = None # type: Any
        if axis_type == DataDescriptor.TYPE_BYTE:
            value = self._data.get_byte_at(offset)
        elif axis_type == DataDescriptor.TYPE_SHORT:
            value = self._data.get_short_at(offset)
        elif axis_type == DataDescriptor.TYPE_INT:
            value = self._data.get_int_at(offset)
        elif axis_type == DataDescriptor.TYPE_LONG:
            value = self._data.get_long_at(offset)
        elif axis_type == DataDescriptor.TYPE_FLOAT:
            dim = descriptor.number_of_dim
            if dim == 1:
                value = self._data.get_float_at(offset)
            else:
                # Here we assume an array (dim >= 2) remark: dimensions are not really dimensions
                npts = descriptor.get_axis_npts(1)
                value = self._data.get_float_array_at(offset, npts)
        elif axis_type == DataDescriptor.TYPE_DOUBLE:
            value = self._data.get_double_at(offset)
        elif axis_type == DataDescriptor.TYPE_STRING:
            try:
                value = self._data.get_pascal_string_at(offset)
            except UnicodeDecodeError as unicode_error:
                raise BfsAccessException(str(unicode_error), unicode_error)
        elif axis_type == DataDescriptor.TYPE_ASCII_STRING:
            try:
                strlen = descriptor.get_axis_npts(0)
                value = self._data.get_ascii_string_at(offset, strlen-1) # Strip the 0 at the end
            except UnicodeDecodeError as unicode_error:
                raise BfsAccessException(str(unicode_error), unicode_error)
            
        return (axis_type, value)

    
class BomemFile:
    '''
    This is a class to access ABB Bomem BFS files
    '''
    
    # Version 1.0
    VERSION_1_0 = "Bomem File v1.0"  # type: str

    # Version 1.1 supporting header directory compression
    VERSION_1_1 = "Bomem File v1.1"  # type: str

    #------------------------------------------------------------------------
    #    File description flags
    #------------------------------------------------------------------------
    
    # Set if tValue cross index is present
    FLAGS_INDEX_T_VALUE = 1
    
    # Set if offset cross index is present
    FLAGS_INDEX_OFFSET = 2
    
    # Set if 8 bytes Adler CRC32 is present at the beginning of each subfile
    FLAGS_SUBFILE_CRC = 4
    
    # Set if magic number is present at the beginning of each subfile
    FLAGS_SUBFILE_MAGIC = 8
    
    # Set if varSize is present at the beginning of each subfile
    FLAGS_SUBFILE_SIZE = 16
    
    # Set if tValue is present at the beginning of each subfile
    FLAGS_SUBFILE_T_VALUE = 32
    
    # Set if the size of subfile data is not constant
    FLAGS_SUBFILE_VARSIZE = 64
    
    # Set if the header directory is compressed
    FLAGS_HEADER_DIR_COMPRESSED = 128
  
    HEADER_SIZE = 504
    
    MACHINE_CODE_OFFSET = 422    

    SKIP_SIZE = 2

    SIGNATURE_SIZE = 16

    DATA_ORIGIN_SIZE = 32

    APPLICATION_ID_SIZE = 32
    
    FILE_DESCRIPTION_SIZE = 127

    def __init__(self, data_source):
        # type: (str) -> None
        '''
        Constructor
        '''
        self._byte_buffer = ByteBuffer(data_source)
        
        self._signature = self._byte_buffer.get_fix_string(self.SIGNATURE_SIZE)
        self._byte_buffer.skip(2)  
        self._origin = self._byte_buffer.get_fix_string(self.DATA_ORIGIN_SIZE)  
        self._byte_buffer.skip(2)  
        self._application = self._byte_buffer.get_fix_string(self.APPLICATION_ID_SIZE)  
        self._byte_buffer.skip(2)  
        self._file_description = self._byte_buffer.get_fix_string(self.FILE_DESCRIPTION_SIZE)
        
        self._byte_buffer.set_position(BomemFile.MACHINE_CODE_OFFSET + 2) # skip machine code and filler (1 byte)
          
        flags = self._byte_buffer.get_int()
        
        self._decode_flags (flags);
        
        self._number_of_subfiles = self._byte_buffer.get_int()
        self._creation_date = self._byte_buffer.get_long()  # 1260298202875

        self._header_directory_offset = self._byte_buffer.get_long()  # 52928130
        self._subfile_directory_offset = self._byte_buffer.get_long()  # 52932916

        self._header_data_offset = self._byte_buffer.get_long()  # 52938684
        self._first_subfile_offset = self._byte_buffer.get_long()  # 504
        self._index_table_offset = self._byte_buffer.get_long()  # 52928098
        self._current_subfile_index = 0 # TODO: is the index really zero based

        self._header_directory_size = self._byte_buffer.get_int()  # 4786
        self._subfile_directory_size = self._byte_buffer.get_int()  # 5768

        self._header_data_size = self._byte_buffer.get_int()  # 352
        self._index_table_size = self._byte_buffer.get_int()  # 32

        # NOTE: We skip the CRC in read mode (should be validated eventually)
        self._byte_buffer.skip(8)
       
        # Should be at 52939044 
        self._byte_buffer.set_position(self._header_directory_offset)        
        header_directory = DataDirectory.get_instance(self._byte_buffer, 
                                                      self._header_directory_size, self._is_header_dir_compressed)
        
        self._byte_buffer.set_position(self._subfile_directory_offset)
        self._subfile_directory = DataDirectory.get_instance(self._byte_buffer, self._subfile_directory_size)

        header_data_buffer = ByteBuffer(self._byte_buffer, self._byte_buffer.byte_ordering, self._header_data_offset)        

        self._byte_buffer.skip(self._header_data_size)

        # Adjust the start off using data_start
        subfile_data_buffer = ByteBuffer(self._byte_buffer, self._byte_buffer.byte_ordering, 
                                         self._first_subfile_offset + self._data_start)        
        
        self._header_data_block = DataBlock(header_directory, header_data_buffer) 
        self._subfile_data_block = DataBlock(self._subfile_directory, subfile_data_buffer)
        
                
    def _decode_flags(self, flags):
        # type: (int) -> None
        self._is_header_dir_compressed = (flags & BomemFile.FLAGS_HEADER_DIR_COMPRESSED) != 0;

        self._is_ttable_present = (flags & BomemFile.FLAGS_INDEX_T_VALUE) != 0;
        self._is_offset_table_present = (flags & BomemFile.FLAGS_INDEX_OFFSET) != 0;
        self._is_subfile_variable_size = (flags & BomemFile.FLAGS_SUBFILE_VARSIZE) != 0;

        self._is_subfile_magic_nbr_present = (flags & BomemFile.FLAGS_SUBFILE_MAGIC) != 0;
        self._is_subfile_size_present = (flags & BomemFile.FLAGS_SUBFILE_SIZE) != 0;
        self._is_subfile_tvalue_present = (flags & BomemFile.FLAGS_SUBFILE_T_VALUE) != 0;
        self._is_subfile_crcpresent = (flags & BomemFile.FLAGS_SUBFILE_CRC) != 0;

        self._data_start = 0;
        if self._is_subfile_crcpresent:
            self._data_start += 8
            
        if self._is_subfile_magic_nbr_present:
            self._data_start += 4

        if self._is_subfile_tvalue_present:
            self._data_start += 8
            
        if self._is_subfile_size_present:
            self._data_start += 4
            
    def _get_subfile_offset(self, index: int) -> int:
        current_subfile_offset = -1
        if self._is_subfile_variable_size:
            if self._is_offset_table_present:
                current_subfile_offset = 0 # indexTable.getOffset(index);
            elif index == 0:
                current_subfile_offset = self._first_subfile_offset
            elif index == (self._current_subfile_index + 1):
                current_subfile_offset += self._subfile_data_block.total_size + self._data_start
            else:
                raise BfsAccessException("Arbitrary index is not supported")
        else:
            current_subfile_offset = self._first_subfile_offset + \
                                     index * (self._subfile_data_block.total_size + self._data_start)

        self._current_subfile_index = index
        # self._byte_buffer.set_position(current_subfile_offset)
        return current_subfile_offset

    def _get_read_size(self):
        if self._is_subfile_variable_size:
            if self._is_offset_table_present:
                raise BfsAccessException("Variable subfile size table not suupported")
        else:
            return self._data_start + self._subfile_data_block.total_size

    def get_header_data_block(self):
        # type: () -> DataBlockAccessor
        return DataBlockAccessor(self._header_data_block)
    
    def get_subfile(self, index=0):
        # type: (int) -> DataBlockAccessor
        if index == 0:
            return DataBlockAccessor(self._subfile_data_block)
        elif index < self._number_of_subfiles:
            subfile_offset = self._get_subfile_offset(index)
            read_size = self._get_read_size()  # Not really usefull to work with in-memory file

            data_buffer = ByteBuffer(self._byte_buffer, self._byte_buffer.byte_ordering,
                                     subfile_offset)
            # Skip the CRC for now since we do not use it
            if self._is_subfile_crcpresent:
                data_buffer.skip(8)
                subfile_offset += 8

            if self._is_subfile_magic_nbr_present:
                magic = data_buffer.get_int(True)
                subfile_offset += 4

            if self._is_subfile_tvalue_present:
                tvalue = data_buffer.get_double()
                subfile_offset += 8

            if self._is_subfile_size_present:
                data_buffer.skip(4)
                subfile_offset += 4

            data_buffer = ByteBuffer(self._byte_buffer, self._byte_buffer.byte_ordering,
                                     subfile_offset)
            subfile_data_block = DataBlock(self._subfile_directory, data_buffer)

            # Always return the first subfile for now
            return DataBlockAccessor(subfile_data_block)
        else:
            raise BfsAccessException("BFS subfile index out of range: {} >= {}"
                .format(index, self._number_of_subfiles))
        
        
    @property
    def is_header_dir_compressed(self):
        # type: () -> int 
        return self._is_header_dir_compressed
    
    @property
    def signature(self):
        return self._signature
        
    @property
    def origin(self):
        return self._origin
        
    @property
    def application(self):
        return self._application
        
    @property
    def file_description(self):
        return self._file_description
        
    @property
    def number_of_subfiles(self):
        return self._number_of_subfiles;

class BfsDataItem:
    '''
    Represents a single data item from a BFS BomemFile
    This is what you get when calling getters on a :BomemFile
    It provides the name, value, axis_type and dimension of this
    '''

    def __init__(self, name, value, axis_type, descriptor):
        # type: (str, Any, int, DataDescriptor) -> None
        self.name = name
        self.value = value
        self.axis_type = axis_type
        self._descriptor = descriptor
        
    @property
    def dimension(self):
        '''
        Return the dimension for this item
        A scalar has dimension equal to 1 and an array has a dimension > 1
        The dimension is not really a dimension in the mathematical sense. 
        It is more a dimension label
        '''        
        return self._descriptor.number_of_dim
        

class DataBlockAccessor:
    '''
    This is a class that hides some of the details of using a :DataBlock and
    associated :DataDirectory to access :BomemFile items
    '''
    
    def __init__(self, data_block):
        # type: (DataBlock) -> None
        self._data_block = data_block
        self._directory = data_block.directory
        
    def get_number_of_entries(self):
        # type: () -> int
        '''
        Return the number of properties in a :DataBlock
        '''
        return int(self._directory.number_of_entries)
    
    @property
    def data_block(self):
        '''
        Return the :DataBlock for this
        '''
        return self._data_block
    
    @property
    def directory(self):
        '''
        Return the :DataDirectory for this
        '''
        return self._directory
    
    def contains(self, name):
        # type: (str) -> bool
        '''
        Determine if a property with called <name> is in this data block
        '''
        return bool(self._directory.index_of(name) >= 0)
        
    def get_item_data(self, key):
        # type: (Union[int, str]) -> BfsDataItem
        '''
        Return the :BfsDataItem for the given key
        The key can be an index between 0 and :get_number_of_entries - 1
        or the key can simply be the name of the item.
        '''        
        descriptor = self._directory.descriptor(key) # type: DataDescriptor
        name = descriptor.name;
        [axis_type, value] = self._data_block.get_value(name, descriptor)
        return BfsDataItem(name, value, axis_type, descriptor)
    

class Spectrum:
    '''
    Represents a Spectrum stored in a BFS (single file). 
    It provides access to all data.
    '''
    
    INST_OP_BAND_FLAG = "Inst. OP Band Flag"
    INST_DATA_TYPE = "Data Type"
    INST_SMPL_GRID_WAVE_NUMBER = "VCSEL Sampling Grid Wavenumber"
    INST_NPTS = "Inst. Npts"
    INST_SPC_NPTS = "Inst. Spc Npts"
    INST_SPC_START = "Inst. Spc Start"
    
    RAW_SPECTRUM_DATA_TYPE = 1
    METROLOGY_OPD_DATA_TYPE = 5

    
    def __init__(self):
        # type: () -> None
        self._xAxisData = [] # type: List[float]
        self._yAxisData = [] # type: List[float]
        self._header_accessor = None # type: DataBlockAccessor
        self._npts = None # type: Int
        self._delta = None # type: float
        self._firstX = None # type: float
        self._isopen = False

    @property
    def npts(self):
        return self._npts
    
    @property
    def firstX(self):
        return self._firstX
    
    @property
    def delta(self):
        return self._delta
    
    def open(self, filename):
        '''
        Open a :BomemFile and fetch everything needed to return a 
        complete spectrum including full X axis data
        '''
        # type: (str) -> None
        expect(not self._isopen, "Cannot open a BFS more than once as a Spectrum for: &1", 
               filename)
        
        bfs = BomemFile (filename) # type: BomemFile
        data_accessor = bfs.get_subfile()
        yAxisDataItem = data_accessor.get_item_data("Data")
        expect(isinstance(yAxisDataItem, BfsDataItem), "Spectrum YData not found in BFS file : &1", filename)
        self._yAxisData = yAxisDataItem.value

        self._header_accessor = bfs.get_header_data_block()
    
        opBandFlagItem = self._header_accessor.get_item_data(Spectrum.INST_OP_BAND_FLAG)
        expect(opBandFlagItem, "Property '&1' missing in BFS", Spectrum.INST_OP_BAND_FLAG)
        opBandFlag = opBandFlagItem.value

        dataTypeItem = self._header_accessor.get_item_data(Spectrum.INST_DATA_TYPE)
        expect(dataTypeItem, "Property '&1' missing in BFS", Spectrum.INST_DATA_TYPE)
        dataType = dataTypeItem.value

        gridWaveNumberItem = self._header_accessor.get_item_data(Spectrum.INST_SMPL_GRID_WAVE_NUMBER)
        expect(gridWaveNumberItem, "Property '&1' missing in BFS", Spectrum.INST_SMPL_GRID_WAVE_NUMBER)
        gridWaveNumber = gridWaveNumberItem.value

        nptsItem = self._header_accessor.get_item_data(Spectrum.INST_NPTS)
        expect(nptsItem, "Property '&1' missing in BFS", Spectrum.INST_NPTS)
        self._npts = nptsItem.value

        spcNptsItem = self._header_accessor.get_item_data(Spectrum.INST_SPC_NPTS)
        expect(spcNptsItem, "Property '&1' missing in BFS", Spectrum.INST_SPC_NPTS)
        spcNpts = spcNptsItem.value

        spcStartItem = self._header_accessor.get_item_data(Spectrum.INST_SPC_START)
        expect(spcStartItem, "Property '&1' missing in BFS", Spectrum.INST_SPC_START)
        spcStart = spcStartItem.value

        # Perform the Voodoo calculation of the delta        
        sf = 2
        if opBandFlag == 0:
            sf = 1
        else:
            sf = 2
            
        expect(dataType != Spectrum.METROLOGY_OPD_DATA_TYPE, 
               "Invalid Data type for BFS: &1", filename);
               
        f1 = round(gridWaveNumber, 3);
        delta = (f1 * sf);
        delta /= (2 * spcNpts);

        firstX = delta * spcStart;

        expect (((spcNpts == self._npts) and (spcStart == 0)), 
                "Illegal spectrum meta data : npts=&1, spcNpts=&2, spcStart=&3",
                spcNpts, self._npts, spcStart)
        
        self._firstX = firstX
        self._delta = delta
        
        freq = firstX 
        for _ in range(self._npts):
            self._xAxisData.append(freq)
            freq = freq + delta
    
    def getXAxisData(self):
        # type: () -> List[float]
        return self._xAxisData

    def getYAxisData(self):
        # type: () -> List[float]
        return self._yAxisData
    

def writecvs(dest, spectrum):
    # type: (str, Spectrum) -> None
    with open(dest, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile, delimiter=',', quotechar='"', quoting=csv.QUOTE_NONE)
        xdata = spectrum.getXAxisData() # type: List[float]
        ydata = spectrum.getYAxisData() # type: List[float]
        for index in range(spectrum.npts):
            writer.writerow((xdata[index], ydata[index]))
    
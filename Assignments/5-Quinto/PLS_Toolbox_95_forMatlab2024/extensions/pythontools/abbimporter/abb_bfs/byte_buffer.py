'''
Created on Jan 16, 2019

@author: jslarochelle
'''

import struct

try:
    # Used only for static type checking (optional)
    from typing import Tuple, Union, List, Any, Optional
except Exception as e:
    # print("Not loading types for PEP 484 checking")
    pass


class ByteBuffer(object):
    '''
    This is a class that can be used to decode an array of bytes into different data types using the correct
    byte ordering. It provides two groups of methods:
    1) Those ending with _at will decode the bytes at the specified offset without moving the global
    buffer index. 
    2) Those not ending with _at will decode the bytes at the current global offset and adjust the the offset
    up based on the size of the data read.
    The array of bytes can be loaded from a file or provided directly 
    Because the bytes are not modified, instances of this can point to the same array of bytes and essentially
    provide multiple view of the same data since each instance can use a different start offset.
    Methods that directly specify an offset parameter will always adjust the parameter based on the initial 
    offset specified at the time the instance was created.   
    '''

    def __init__(self, data_source, byte_ordering="little", offset=0):
        # type: (Union[str, ByteBuffer, bytes], str, int) -> None
        '''
        Build an instance of this using three possible data_source
        1) The name of a file. The file is loaded in memory as one large
        byte array
        2) Another ByteBuffer
        3) An array of bytes
        In all three cases both the byte ordering and a start (base) offset
        can be specified. 
        byte_ordering is the byte order in memory ("little" or "big")
        offset is the start buffer offset used to adjust all offset parameters  
        '''
        if isinstance(data_source, str):
            input_file = open(data_source, "rb")  # type: BufferedReader
            try:
                self._byte_array = input_file.read()  # type: bytes
            except:
                raise
            else:
                input_file.close()

        elif isinstance(data_source, ByteBuffer):
            self._byte_array = data_source._byte_array
        else:
            self._byte_array = data_source

        self._offset = offset
        self._position = offset  # type: int
        self._byte_ordering = byte_ordering  # type: str
        if self._byte_ordering == "big":
            self._fformat = ">f"
            self._dformat = ">d"
        else:
            self._fformat = "<f"
            self._dformat = "<d"

    @property
    def byte_ordering(self):
        # type: () -> str
        '''
        Return the byte ordering for this : "little" or "big" endian
        '''
        return self._byte_ordering

    def _get_byte_array_at(self, offset, size):
        # type: (int, int) -> bytes
        '''
        Return the byte array at offset
        '''
        return self._byte_array[offset:size]

    def get_byte(self):
        # type: () -> int
        '''
        Get the byte at position() as an integer and move position to the next byte
        '''
        ret_byte = self._byte_array[self._position]
        self._position += 1
        return ret_byte

    def get_byte_at(self, offset):
        # type: (int) -> int
        '''
        Return the byte at offset as an integer
        '''
        ret_byte = self._byte_array[offset + self._offset]
        return ret_byte

    def get_double(self):
        # type: () -> double
        '''
        Get the 64 bits float at position() as a double and move position up 8 bytes
        '''
        first = self._position
        last = first + 8
        self._position += 8
        [ret_float] = struct.unpack(self._dformat, self._byte_array[first:last])
        return ret_float

    def get_double_at(self, offset):
        # type: (int) -> double
        '''
        Get the 64 bits float at offset as a double 
        '''
        first = offset + self._offset
        last = first + 8
        [ret_float] = struct.unpack(self._dformat, self._byte_array[first:last])
        return ret_float

    def get_float(self):
        # type: () -> float
        '''
        Get the 32 bits float at position() as a float and move position up 4 bytes
        '''
        first = self._position
        last = first + 4
        self._position += 4
        [ret_float] = struct.unpack(self._fformat, self._byte_array[first:last])
        return float(ret_float)

    def get_float_at(self, offset):
        # type: (int) -> float
        '''
        Get the 32 bits float at offset as a float 
        '''
        first = offset + self._offset
        last = first + 4
        bytes_data = self._byte_array[first:last]
        [ret_float] = struct.unpack(self._fformat, bytes_data)
        return float(ret_float)

    def get_float_array_at(self, offset, npts):
        # type: (int, int) -> List[float]
        '''
        Get the array of 32 bits float at offset
        '''
        float_array = []  # type: List[float]
        for index in range(npts):
            first = offset + self._offset + (index * 4)
            last = first + 4
            bytes_data = self._byte_array[first:last]
            [ret_float] = struct.unpack(self._fformat, bytes_data)
            float_array.append(ret_float)
        return float_array

    def get_int(self, is_signed=True):
        # type: (bool) -> int
        '''
        Get the 32 bits int at position() as an integer and move position up 4 bytes
        '''
        first = self._position
        last = first + 4
        self._position += 4
        ret_int = int.from_bytes(self._byte_array[first:last], self._byte_ordering, signed=is_signed)
        return ret_int

    def get_int_at(self, offset, is_signed=True):
        # type: (int, bool) -> int
        '''
        Get the 32 bits int at offset as an integer
        '''
        first = offset + self._offset
        last = first + 4
        ret_int = int.from_bytes(self._byte_array[first:last], self._byte_ordering, signed=is_signed)
        return ret_int

    def get_long(self, is_signed=True):
        # type: (bool) -> int
        '''
        Get the 64 bits int at position() as an integer and move position up 8 bytes
        '''
        first = self._position
        self._position += 8
        last = first + 8
        ret_int = int.from_bytes(self._byte_array[first:last], self._byte_ordering, signed=is_signed)
        return ret_int

    def get_long_at(self, index, is_signed=True):
        # type: (int, bool) -> int
        '''
        Get the 64 bits int at index as an integer
        '''
        first = index + self._offset
        last = first + 8
        ret_int = int.from_bytes(self._byte_array[first:last], self._byte_ordering, signed=is_signed)
        return ret_int

    def get_short(self, is_signed=True):
        # type: (bool) -> int        
        '''
        Get the 16 bits integer at position() as an integer and move position up 2 bytes
        '''
        first = self._position
        self._position += 2
        last = first + 2
        ret_int = int.from_bytes(self._byte_array[first:last], self._byte_ordering, signed=is_signed)
        return ret_int

    def get_short_at(self, offset, is_signed=True):
        # type: (int, bool) -> int        
        '''
        Get the 16 bits integer at position() as an integer and move position up 2 bytes
        '''
        first = offset + self._offset
        last = first + 2
        ret_int = int.from_bytes(self._byte_array[first:last], self._byte_ordering, signed=is_signed)
        return ret_int

    def get_string(self, max_bytes=-1, terminator=b'\x00\x00'):
        # type: (int, bytes) -> str
        '''
        Read a zero terminated String of maximum length maxBytes
        Length is adjusted to position of first zero byte encountered
        so that: get_string(maxBytes).length <= maxBytes
        max_bytes the expected maximum length of the String
        '''
        start_index = self._position;
        end_index = self._byte_array.find(terminator, start_index)
        if (end_index - start_index) > max_bytes and max_bytes >= 0:
            end_index = start_index + max_bytes
        self.set_position(end_index + len(terminator))
        byte_array_data = self._byte_array[start_index:end_index]
        decoded_data = byte_array_data.decode("utf-16")
        return decoded_data

    def get_ascii_string_at(self, offset, max_bytes):
        # type: (int, int) -> str
        '''
        Read a String of length maxBytes assumed to be encoded as raw ascii
        max_bytes is the expected maximum length of the String 
        '''
        start_index = offset + self._offset
        end_index = start_index + max_bytes
        byte_array_data = self._byte_array[start_index:end_index]
        # decoded_data = byte_array_data.decode("ascii") # Might not show up properly in all circumstances but is legacy
        decoded_data = byte_array_data.decode(
            "cp1252")  # Might not show up properly in all circumstances but is legacy
        return decoded_data

    def get_fix_string(self, length):
        # type: (int) -> str
        '''
        Read a fix length String
        This will read 2*length bytes (assumes utf-16 encoding) independently of the content encountered
        The string must be a utf-16 encoded string but the prefix is optional
        If some of the byte pairs do not represent utf-16 character this will 
        throw an exception 
        '''
        start_index = self._position;
        end_index = start_index + (2 * length)
        self.set_position(end_index)
        byte_array_data = self._byte_array[start_index:end_index]
        decoded_data = byte_array_data.decode("utf-16")
        return decoded_data

    def get_fix_string_at(self, offset, length):
        # type: (int, int) -> str
        '''
        Read a fix length String
        This will read 2*length bytes (assumes utf-16 encoding) independently of the content encountered
        The string must be a utf-16 encoded string but the prefix is optional
        If some of the byte pairs do not represent utf-16 character this will 
        throw an exception 
        '''
        start_index = offset + self._offset
        end_index = start_index + (2 * length)
        byte_array_data = self._byte_array[start_index:end_index]
        decoded_data = byte_array_data.decode("utf-16")
        return decoded_data

    def get_pascal_string(self):
        # type: () -> str
        '''
        This is a string that is prefixed with the number of character 
        '''
        strlen = self.get_int()
        return self.get_fix_string(strlen)

    def get_pascal_string_at(self, offset):
        # type: (offset) -> str
        '''
        This is a string that is prefixed with the number of character 
        '''
        strlen = self.get_int_at(offset)
        return self.get_fix_string_at(offset + 4, strlen)

    def position(self):
        # type: () -> int
        return self._position

    def set_position(self, new_position):
        # type: (int) -> ByteBuffer
        self._position = new_position + self._offset
        return self

    def skip(self, number_of_bytes):
        # type: (int) -> ByteBuffer
        self._position = self._position + number_of_bytes
        return self

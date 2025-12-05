'''
Created on Jan 17, 2019

@author: jslarochelle
'''

import os
import sys
#sys.path.append(os.path.dirname(os.path.realpath("__file__")) + "./src")

import unittest
from abb_bfs.byte_buffer import ByteBuffer


class Test(unittest.TestCase):
    data_path = os.path.dirname(os.path.realpath("__file__")) + "/Data/" # type: str
    binary_data_path = data_path + "bindata.bin" # type: str
    bfs_data_path = data_path + "iterator_test.spectrum" # type: str

    def setUp(self):
        # type: () -> None
        pass

    def tearDown(self):
        # type: () -> None
        pass

    def testReadingFromABinaryFile(self):
        # type: () -> None
        '''
        In this file we should be able to read in order:
        69            a byte
        666           a short
        666           an int
        2147483647    a Java int (Integer.MAX_VALUE)
        1024.5        a float (close to)
        9999.25       a double (close to)
        "ABCDEFGHIJKLMNOP"    a string (utf-16 with prefix)
        '''        
        byte_buffer = ByteBuffer(self.binary_data_path, byte_ordering="big")
        self.assertIsInstance(byte_buffer, ByteBuffer, "Instance should be a ByteBuffer")
        
        abyte = byte_buffer.get_byte()
        self.assertEqual(abyte, 69)
        
        ashort = byte_buffer.get_short()
        self.assertEqual(ashort, 666)
        
        an_int = byte_buffer.get_int()
        self.assertEqual(an_int, 666)
        
        along = byte_buffer.get_long()
        self.assertEqual(along, 2147483647)

        afloat = byte_buffer.get_float()        
        self.assertEqual(afloat, float(1024.5))

        adouble = byte_buffer.get_double()        
        self.assertEqual(adouble, 9999.25)
        
        astring = byte_buffer.get_string()
        self.assertEqual(astring, "ABCDEFGHIJKLMNOP")
                

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
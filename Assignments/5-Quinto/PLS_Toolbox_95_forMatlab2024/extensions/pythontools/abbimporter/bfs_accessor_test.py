'''
Created on Jan 16, 2019

@author: jslarochelle
'''

import os
#import sys
#sys.path.append(os.path.dirname(os.path.realpath("__file__")) + "./src")

import unittest
from abb_bfs.bfs_accessor import BomemFile, expect, writecvs
from abb_bfs.bfs_accessor import BfsDataItem
from abb_bfs.bfs_accessor import Spectrum

class Test(unittest.TestCase):

    def setUp(self):
        # type: () -> None
        pass

    def tearDown(self):
        # type: () -> None
        pass

    def testThatWeCanEnumerateAllPropertiesInHeaderOfMRI_BFS(self):
        # type: () -> None
        data_path = os.path.dirname(os.path.realpath("__file__")) + "/Data/iterator_test.spectrum" # type: str
        print(data_path)
        bfs = BomemFile(data_path)  # type: BomemFile
        
        self.assertIsInstance(bfs, BomemFile, "Instance of AbbBfsAccessor")
        
        signature = bfs.signature # type: str
        self.assertEqual(signature[:len(BomemFile.VERSION_1_1)], BomemFile.VERSION_1_1)
        self.assertEqual(bfs.origin[:len("MRI")], "MRI")
        self.assertEqual(bfs.application[:len("MRI")], "MRI")
        self.assertEqual(bfs.file_description[:len("Empty")], "Empty")
        
        header_accessor = bfs.get_header_data_block()
        number_of_items = header_accessor.get_number_of_entries()
        for index in range(number_of_items):
            item = header_accessor.get_item_data(index)
            self.assertIsNotNone(item, "A BFS directory entry at logical index '{}' must have a matching item".format(index))
            self.assertIsNotNone(item, "A BFS item named {} at logical index '{}' must have a matching value".format(item.name, index))
            print("{} = {}".format(item.name, str(item.value)))

    def testThatWeCanReadSpecificPropertiesInHeaderOfMRI_BFS(self):
        # type: () -> None
        data_path = os.path.dirname(os.path.realpath("__file__")) + "/Data/iterator_test.spectrum" # type: str
        print(data_path)
        bfs = BomemFile (data_path) # type: BomemFile
        
        self.assertIsInstance(bfs, BomemFile, "Instance of AbbBfsAccessor")
        
        signature = bfs.signature # type: str
        self.assertEqual(signature[:len(BomemFile.VERSION_1_1)], BomemFile.VERSION_1_1)
        self.assertEqual(bfs.origin[:len("MRI")], "MRI")
        self.assertEqual(bfs.application[:len("MRI")], "MRI")
        self.assertEqual(bfs.file_description[:len("Empty")], "Empty")
        
        header_accessor = bfs.get_header_data_block()
        number_of_items = header_accessor.get_number_of_entries()

        # There is the right number of properties in header        
        self.assertEqual(number_of_items, 44)

        # The first entry in the list (array lower limit)
        result = header_accessor.get_item_data("Description")
        self.assertEqual(result.value, "Empty")

        # Aother String further in the list
        result = header_accessor.get_item_data("TargetType")
        self.assertEqual(result.value, "EXTERNAL_RADIOMETRIC_REFERENCE")

        # A number
        result = header_accessor.get_item_data("LaserWaveNumber")
        self.assertEqual(result.value, 15799)

        # A float        
        result = header_accessor.get_item_data("HotBlackBodySetPoint")
        self.assertEqual(result.value, 20.0)

        # The last property (array upper limit)     
        result = header_accessor.get_item_data("SensorHeadFanSpeed")
        self.assertEqual(result.value, 0)


    def testThatWeCanReadSpecificPropertiesInSubfileOfMRI_BFS(self):
        # type: () -> None
        data_path = os.path.dirname(os.path.realpath("__file__")) + "/Data/iterator_test.spectrum" # type: str
        print(data_path)
        bfs = BomemFile (data_path) # type: BomemFile
        
        self.assertIsInstance(bfs, BomemFile, "Instance of AbbBfsAccessor")
        
        signature = bfs.signature # type: str
        self.assertEqual(signature[:len(BomemFile.VERSION_1_1)], BomemFile.VERSION_1_1)
        self.assertEqual(bfs.origin[:len("MRI")], "MRI")
        self.assertEqual(bfs.application[:len("MRI")], "MRI")
        self.assertEqual(bfs.file_description[:len("Empty")], "Empty")
        
        subfile_accessor = bfs.get_subfile()
        number_of_items = subfile_accessor.get_number_of_entries()

        # There is the right number of properties in header        
        self.assertEqual(number_of_items, 50)

        # The first entry in the list (array lower limit)
        result = subfile_accessor.get_item_data("DSPCounter")
        self.assertEqual(result.value, 2239304)

        # Aother String further in the list
        result = subfile_accessor.get_item_data("HotBlackBodyTattooTemperature")
        self.assertEqual(result.value, 47.0)

        # A float        
        result = subfile_accessor.get_item_data("HotBlackBodyTemperature")
        self.assertAlmostEqual(result.value, -245.25471, places=5)

        # The last property (array upper limit)     
        result = subfile_accessor.get_item_data("VisibleImage")
        self.assertEqual(result.value, 3222791) # TODO: Adjust this test once we have the support of arrays of int

    def testThatWeCanLoadASpectrumFromAnOMEP_BFS(self):
        # type: () -> None
        
        filename = os.path.dirname(os.path.realpath("__file__")) + "/Data/simple_bfs_with_ftir_data_only.spectrum" # type: str
        #data_path = os.path.dirname(os.path.realpath("__file__")) + "/Data/simple_ftsw_sample.spectrum" # type: str
        spectrum = Spectrum()
        spectrum.open(filename)
        
        self.assertIsInstance(spectrum, Spectrum, "Instance of AbbBfsAccessor")
        self.assertGreater(spectrum.npts, 0, "Number of point should be larger than 0")
        self.assertGreater(spectrum.delta, 0, "Delta should be larger than 0")
        self.assertEqual(spectrum.firstX, 0, "FirstX should be larger than 0")
         
        writecvs(filename + ".csv", spectrum)       

    def testThatWeCanEnumerateAllPropertiesInHeaderOfOMEP_BFS(self):
        # type: () -> None
        
        data_path = os.path.dirname(os.path.realpath("__file__")) + "/Data/simple_bfs_with_ftir_data_only.spectrum" # type: str
        #data_path = os.path.dirname(os.path.realpath("__file__")) + "/Data/simple_ftsw_sample.spectrum" # type: str
        print(data_path)
        bfs = BomemFile (data_path) # type: BomemFile
        
        self.assertIsInstance(bfs, BomemFile, "Instance of AbbBfsAccessor")
        
        signature = bfs.signature # type: str
        self.assertEqual(signature[:len(BomemFile.VERSION_1_1)], BomemFile.VERSION_1_1)
        self.assertEqual(bfs.origin[:len("OMEP")], "OMEP")
        self.assertEqual(bfs.application[:len("OMEP")], "OMEP")

#         data_accessor = bfs.get_subfile()
#         number_of_items = data_accessor.get_number_of_entries()
#         for index in range(number_of_items):
#             item = data_accessor.get_item_data(index)
#             self.assertIsNotNone(item, "A BFS directory entry at logical index '{}' must have a matching item".format(index))
#             self.assertIsNotNone(item, "A BFS item named {} at logical index '{}' must have a matching value".format(item.name, index))
#             print("{}".format(item.name))
        
        header_accessor = bfs.get_header_data_block()
        number_of_items = header_accessor.get_number_of_entries()
        for index in range(number_of_items):
            item = header_accessor.get_item_data(index)
            self.assertIsNotNone(item, "A BFS directory entry at logical index '{}' must have a matching item".format(index))
            self.assertIsNotNone(item, "A BFS item named {} at logical index '{}' must have a matching value".format(item.name, index))
            print("{} = {}".format(item.name, str(item.value)))


    def testThatWeCanReadSpecificPropertiesInHeaderOfOMEP_BFS(self):
        # type: () -> None
        data_path = os.path.dirname(os.path.realpath("__file__")) + "/Data/simple_bfs_with_ftir_data_only.spectrum" # type: str
        print(data_path)
        bfs = BomemFile (data_path) # type: BomemFile
        
        self.assertIsInstance(bfs, BomemFile, "Instance of AbbBfsAccessor")
        
        signature = bfs.signature # type: str
        self.assertEqual(signature[:len(BomemFile.VERSION_1_1)], BomemFile.VERSION_1_1)
        self.assertEqual(bfs.origin[:len("OMEP")], "OMEP")
        self.assertEqual(bfs.application[:len("OMEP")], "OMEP")
        
        header_accessor = bfs.get_header_data_block()
        number_of_items = header_accessor.get_number_of_entries()
        
        self.assertEqual(number_of_items, 329)
        
        # The first entry in the list (array lower limit)
        result = header_accessor.get_item_data("(c)  Det. Default FS gain")
        self.assertEqual(result.value, 5)
        
        # A string
        result = header_accessor.get_item_data("(c) Accessory USB Storage Path")
        self.assertEqual(result.value, "/mnt/accessories/tmp.gau")
        
        # A number
        result = header_accessor.get_item_data("(c) Apodization Type Conf")
        self.assertEqual(result.value, 0)
         
        # Another number 
        result = header_accessor.get_item_data("Voltage(HM)")
        self.assertEqual(result.value, 0)
         
        # A float
        result = header_accessor.get_item_data("VCSEL Voltage Laser")
        self.assertAlmostEqual(result.value, 2.2092774, places=6)
         
        # 
        result = header_accessor.get_item_data("VCSEL TEC Temp Setpoint")
        self.assertAlmostEqual(result.value, 34.999866, places=6)


    def testThatWeCanReadTheSpectrumDataFromAnOMEP_BFSSubfile(self):
        # type: () -> None
        data_path = os.path.dirname(os.path.realpath("__file__")) + "/Data/simple_bfs_with_ftir_data_only.spectrum" # type: str
        print(data_path)
        bfs = BomemFile (data_path) # type: BomemFile
        
        self.assertIsInstance(bfs, BomemFile, "Instance of AbbBfsAccessor")
        
        signature = bfs.signature # type: str
        self.assertEqual(signature[:len(BomemFile.VERSION_1_1)], BomemFile.VERSION_1_1)
        self.assertEqual(bfs.origin[:len("OMEP")], "OMEP")
        self.assertEqual(bfs.application[:len("OMEP")], "OMEP")
        
        data_accessor = bfs.get_subfile()
        spectrum_data = data_accessor.get_item_data("Data")
                
        self.assertIsInstance(spectrum_data, BfsDataItem, "Spectrum data is a BfsDataItem")
        self.assertIsInstance(spectrum_data.value, list, "Spectrum Data value is a list of float")
        
        # Check some points at the start of the spectra
        self.assertAlmostEqual(spectrum_data.value[0], 0.0, places=6, msg="")
        self.assertAlmostEqual(spectrum_data.value[1], -3.4500477e-5, places=6, msg="")
        self.assertAlmostEqual(spectrum_data.value[2], 1.07019994e-4, places=6, msg="")
        self.assertAlmostEqual(spectrum_data.value[3], -6.200179e-5, places=6, msg="")

        # Check some point at the end
        npts = len(spectrum_data.value)
        self.assertAlmostEqual(spectrum_data.value[npts-4], 2.5390505e-6, places=6, msg="")
        self.assertAlmostEqual(spectrum_data.value[npts-3], 3.9951096e-6, places=6, msg="")
        self.assertAlmostEqual(spectrum_data.value[npts-2], 1.7091681e-5, places=6, msg="")        
        self.assertAlmostEqual(spectrum_data.value[npts-1], -8.991665E-7, places=6, msg="")
        
        data_accessor = bfs.get_subfile()
        number_of_items = data_accessor.get_number_of_entries()
        for index in range(number_of_items):
            item = data_accessor.get_item_data(index)
            self.assertIsNotNone(item, "A BFS directory entry at logical index '{}' must have a matching item".format(index))
            self.assertIsNotNone(item, "A BFS item named {} at logical index '{}' must have a matching value".format(item.name, index))
            print("{}".format(item.name))
                

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
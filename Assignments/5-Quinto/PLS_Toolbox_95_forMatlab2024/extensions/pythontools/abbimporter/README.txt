#Installation

You must have Python 3.x running on your system.

Simply unzip the abbbfs.zip file to your project directory (for example: c:\data\myproject) 
You should now have the following files in your project directory:
1. byte_buffer_test.py is the set of unit tests for the abb_bfs.ByteBuffer class
2. bfs_accessor_test.py is the set of unit tests for the abb_bfs.BomemFile, abb_bfs.DataBlockAccessor and abb_bfs.BfsDataItem
3. example.py	is a very simple example of accessing the major BFS properties in order to work
with your spectra

The class library as such should now be found in a directory called *abb_bfs*:
1. byte_buffer.py	is the low-level binary file decoder module
2. bfs_accessor.py	is the module that defines the main classes: BomemFile, DataBlockAccessor and BfsDataItem

The test modules byte_buffer_test.py and bfs_accessor_test.py can be deleted or moved to a subdirectory
_You will have to adjust the code if you want to rerun the tests from a different directory_

Remember to look at the *example.py* file in order to see a simple example of using the abb_bfs.BomemFile.

You can look at the unit test if you want to see more details about the API.     


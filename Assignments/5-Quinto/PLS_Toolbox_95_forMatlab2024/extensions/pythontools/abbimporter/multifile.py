'''
Created on Jan 31, 2019

@author: jslarochelle
'''

if __name__ == '__main__':
    import os
    
    from abb_bfs.bfs_accessor import BomemFile
    
    #data_path = os.path.dirname(os.path.realpath("__file__")) + "/Data/BasicValidation202205.spectrum" # type: str
    #data_path = os.path.dirname(os.path.realpath("__file__")) + "/Data/file1.spectrum"  # type: str
    data_path = os.path.dirname(os.path.realpath("__file__")) + "/Data/ILS-2022_05_26-08_02_20_172.spectrum"

    # Top level BFS API entry point 
    bfs = BomemFile (data_path)

    # Get the global properties from the header (names are case sensitive)    
    header_accessor = bfs.get_header_data_block()

    # coordinate = header_accessor.get_item_data("Coordinate")
    # print("Coordinate: {}".format(coordinate.value))
    
    # The data as such is in the subfile
    #data_accessor = bfs.get_subfile()
    #spectrum_data = data_accessor.get_item_data("Data")
    
    #print("First 10 points in the spectrum are: ")
    #for i in range(10):
    #    print(spectrum_data.value[i])

    print(f"Number of subfile = {bfs.number_of_subfiles}")
    data_accessor = bfs.get_subfile(3)

    spectrum_data = data_accessor.get_item_data("Data")

    for i in range(10):
        print(spectrum_data.value[i])

    property1 = data_accessor.get_item_data("Met. Init Amplitude F")
    print(f"{property1.name} = {property1.value}")
    property2 = data_accessor.get_item_data("Neon Usage Time")
    print(f"{property2.name} = {property2.value}")

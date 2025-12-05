'''
Created on Jan 31, 2019

@author: jslarochelle
'''

if __name__ == '__main__':
    import os
    
    from abb_bfs.bfs_accessor import BomemFile
    
    data_path = os.path.dirname(os.path.realpath("__file__")) + "/Data/simple_bfs_with_ftir_data_only.spectrum" # type: str
    
    # Top level BFS API entry point 
    bfs = BomemFile (data_path)

    # Get the global properties from the header (names are case sensitive)    
    header_accessor = bfs.get_header_data_block()

    timestamp = header_accessor.get_item_data("TIMESTAMP")
    print("Data acquired at: {}".format(timestamp.value))     

    orientation = header_accessor.get_item_data("Orientation")
    print("Orientation: {}".format(orientation.value))     

    coordinate = header_accessor.get_item_data("Coordinate")
    print("Coordinate: {}".format(coordinate.value))     
    
    # The data as such is in the subfile
    data_accessor = bfs.get_subfile()
    spectrum_data = data_accessor.get_item_data("Data")
    
    print("First 10 points in the spectrum are: ")
    for i in range(10):
        print(spectrum_data.value[i])
    
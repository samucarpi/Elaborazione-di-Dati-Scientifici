'''
Created on Jan 31, 2019

@author: jslarochelle
'''

if __name__ == '__main__':
    import os
    import sys    
    
    from abb_bfs.bfs_accessor import Spectrum, writecvs
    
    if len(sys.argv) < 3:
        print("BFS2CSV version 1.1")
        print("")
        print("Missing parameter: you must supply the source and destination: ")
        print("")
        print("    bfs2csv d:\\my_spectrum\\data d:\\my_csv_destination")
        print("")
        print("But found:")
        print("")
        print("    bfs2csv " + "{}".format(sys.argv[1:]).strip(' []'''))
        sys.exit()
    
    source = os.path.abspath(sys.argv[1]) # type: str
    destination = os.path.abspath(sys.argv[2]) # type: str
    
    if not os.path.isdir(source):
        print("")
        print("Error ! Source directory does not exist: {}".format(source))
        print("")
        sys.exit()
    
    if not os.path.isdir(destination):
        print("")
        print("Error ! Destination directory does not exist: {}".format(destination))
        print("")
        sys.exit()
    
    if not destination.endswith("\\"):
        destination = destination + "\\"
    
    if not source.endswith("\\"):
        sourcedir = source + "\\"
    else:
        sourcedir = source

    # Scan the source directory and convert all files with extension .spectrum to CSV files ending in .spectrum.csv
    for root, dirs, files in os.walk(source):
        for filename in files:
            if filename.endswith(".spectrum"):
                print("Processing {} ...".format(filename))
                basename = os.path.basename(filename)
                spectrum = Spectrum()
                spectrum.open(sourcedir + filename)
                writecvs(destination + basename + ".csv", spectrum)

    print("Done!")

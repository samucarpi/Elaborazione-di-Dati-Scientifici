'''
Handle special warnings since they cannot be handled easily in MATLAB.
'''
from sklearn.exceptions import DataConversionWarning
import warnings


def main():
    #ignore DataConversionWarning because it complains that yblocks are not of size (x,) and are (x,1)
    warnings.filterwarnings('ignore',category=DataConversionWarning)

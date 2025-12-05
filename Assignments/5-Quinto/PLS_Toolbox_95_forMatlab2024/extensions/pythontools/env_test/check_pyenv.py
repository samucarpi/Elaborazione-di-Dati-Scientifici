'''This helper function is to help check the user's current PLS_Toolbox Python Virtual
environment against what should be there. The differences between the two are returned:
the user could have added on packages, or deleted packages. 

    true: unpickled Python list, elements are packages and their version types. This list will
            depend on the system, as each platform has system-dependent packages.
'''

import pkg_resources


def main(true):

    packages = sorted(["%s==%s" % (i.key, i.version) for i in pkg_resources.working_set])

    addons = set(packages).difference(set(true))
    missing = set(true).difference(set(packages))

    return addons, missing

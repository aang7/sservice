import glob
from csvConverter import GetCSVFromPDF

""" This file is the beginning of this program:
We need to create a through cycle to create the csv files from the pdfs (boletines).
And then run myscript to clean the data and extract the data by epidemic.
"""
# for filename in glob.glob('*.pdf'):
#     print(filename)

import os
rootdir = 'downloadpdf/bolep_2016/'
directory_for_csv = 'GeneratedCSV'
# for file in files:
#     #print (os.path.join(subdir, file))
#     print (subdir, file)

# dir creation where will be putted the csv's
if not os.path.exists(directory_for_csv):
    os.makedirs(directory_for_csv)

for subdir, dirs, files in os.walk(rootdir):
    # create csv folder by epidemic boletin year 
    msubdir = '%s/%s' % (directory_for_csv, subdir.split('/')[-1])
    print (subdir)
    #print (subdir.split('/')[-1])
    if not os.path.exists(msubdir):
        os.makedirs(msubdir)

    # getting the pdfs to send them to Alberto csv converter, a bit modified by me.
    mstring = ('%s/*.pdf' % subdir)
    for filename in glob.glob(mstring):
        # i need to pass the filename variable and in the funcion split the name
        #print(filename, filename.split(sep='/')[-1])
        #print(filename, msubdir)
        GetCSVFromPDF(filename, msubdir)
        

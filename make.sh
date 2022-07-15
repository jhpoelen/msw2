#!/bin/bash
#
# generate Preston archive from MSW2 DBASE FILES 
# provided by DeeAnn M. Reeder in July 2022
#
# Note that this script assumes the files are available via GitHub

find . \
| sed 's/[ ]/%20/g'\
| grep "DBASE%20FILES/"\
| sed 's+^[.]++g'\
| sed "s+^+\\'https://raw.githubusercontent.com/jhpoelen/msw2/main+g"\
| sed "s+$+'+g"\
| xargs preston track

preston ls\
| grep -v DBT\
| preston dbase-stream\
| grep TAXON\
| tee msw2.json\
| mlr --ijson --ocsv cat\
> msw2.csv

cat msw2.csv\
| head -n11\
> msw2-sample.csv

cat msw2.json\
| head\
> msw2-sample.json

preston ls\
| grep -v DBT\
| preston dbase-stream\
| grep TAXON\
| tee msw2.json\
| mlr --ijson --ocsv cat\
> msw2.csv


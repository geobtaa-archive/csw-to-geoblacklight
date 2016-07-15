#! /bin/sh

echo "Illinois"
./csw-to-geoblacklight.py -cat "Illinois State Geological Survey" -c "Illinois State Geological Survey" -pi illinois -

echo "Iowa"
./csw-to-geoblacklight.py -cat "Iowa DNR" -c "Iowa Dept. of Natural Resources" -pi iowa
./csw-to-geoblacklight.py -aj ./iowa

echo "Maryland"
./csw-to-geoblacklight.py -cat "Maryland iMap 2" -c "Maryland iMap" -pi umd -md

echo "U of Michigan"
./csw-to-geoblacklight.py -cat "Ann Arbor Data Catalog" -c "Ann Arbor Data Catalog" -pi mich
./csw-to-geoblacklight.py -cat "MI Open Data 2" -c "State of Michigan Open Data" -pi mich

echo "Michigan State"
./csw-to-geoblacklight.py -cat "SEMCOG" -c "SEMCOG" -pi msu
./csw-to-geoblacklight.py -cat "Detroit" -c "Detroit" -pi msu

echo "Minnesota"
./csw-to-geoblacklight.py -cat "Minnesota Geospatial Commons" -c "Minnesota Geospatial Commons" -pi minn -md
./csw-to-geoblacklight.py -cat "Minneapolis" -pi minn -md
./csw-to-geoblacklight.py -cat "Hennepin County" -pi minn -md
./csw-to-geoblacklight.py -cat "Ramsey County" -pi minn -md

echo "Purdue"
./csw-to-geoblacklight.py -cat "IndianaMAP" -c "IndianaMAP" -pi purdue -md
./csw-to-geoblacklight.py -cat "Purdue Georeferenced Imagery" -c "Purdue Georeferenced Imagery" -pi purdue -md

echo "Wisconsin"
./csw-to-geoblacklight.py -cat WIDNR -c "Wisc. Dept. of Natural Resources" -pi wisc
./csw-to-geoblacklight.py -cat "WI DATCP" -c "Wisc. Dept. of Agriculture, Trade and Consumer Protection" -pi wisc
./csw-to-geoblacklight.py -cat "WI LTSB" -c "Wisc. Legislative Technology Services Bureau" -pi wisc
./csw-to-geoblacklight.py -cat "WI Counties" -c "Wisc. County Open Data" -pi wisc

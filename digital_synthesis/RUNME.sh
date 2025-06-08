#!/bin/bash

# Delete old designs
if [ -d "TMP" ]; then 
	rm -r TMP
fi

cd Design
./CLEANUP.sh
cd ..

cd Scripts

cd S1.0_*
./CLEANUP.sh
cd ..

cd S2.0_*
./CLEANUP.sh
cd ..

cd S3.0_*
./CLEANUP.sh
cd ..

cd S4.0_*
./CLEANUP.sh
cd ..

cd S1.0_*
./RUNME.sh
cd ..

cd S2.0_*
./RUNME.sh
cd ..

cd S3.0_*
./RUNME.sh
cd ..

cd S4.0_*
./RUNME.sh
cd ..

echo "Done!"

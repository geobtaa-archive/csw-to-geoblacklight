# Installing csw-to-geoblacklight on Windows

## Pre-reqs

+ Python 2.7
+ Microsoft Visual C++ Compiler for Python (Download and install from here: https://www.microsoft.com/en-us/download/details.aspx?id=44266)

## Environment variables to set 
+ path to Python 2.7
+ path to Python Scripts directory

How to add an environment variable in Windows: https://www.computerhope.com/issues/ch000549.htm)


## Install modules required for CSW-to-geoblacklight script
1.	Install pip 
+ Download get-pip.py (https://bootstrap.pypa.io/get-pip.py)
+ Be sure to save the file as .py and not .txt 
2.	Launch cmd prompt as administrator
3.	Run: python <path-to-file>\get-pip.py. 
+ path-to-file is the location where you saved get-pip.py (e.g., C:\Python27\Scripts\)
4.	Run: pip install –r <path-to-csw-to-geoblacklight>\requirements.txt

+ If you encounter the following error: “Fatal error in launcher: Unable to create process using '"'
Download and run the pipreqs.py file using: python <path-to-file>\pipreqs.py

+ Note: pipreqs.py assumes default Python 2.7 configuration, and that requirements.txt is installed in C:\Python27\Scripts\csw-to-geoblacklight-master\  - Make any necessary changes to paths before running the script.


Thank you to Cole Meyer from UMN OIT for these instructions.

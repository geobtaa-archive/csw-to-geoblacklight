Installing csw-to-geoblacklight in Windows
Pre-reqs:
Python 2.7 is installed and the path is added an environment variable. Also the path to Python Scripts directory is added as an environment variable.
(Add an environment variable in Windows: https://www.computerhope.com/issues/ch000549.htm)
Microsoft Visual C++ Compiler for Python is installed. Download and install from here: https://www.microsoft.com/en-us/download/details.aspx?id=44266



1.	Install pip
a.	Download get-pip.py (https://bootstrap.pypa.io/get-pip.py)
i.	Be sure to save the file as .py and not .txt 
2.	Launch cmd prompt as administrator
3.	Run: python <path-to-file>\get-pip.py
a.	Where <path-to-file> is the location where you saved get-pip.py (e.g., C:\Python27\Scripts\)
4.	Run: pip install –r <path-to-csw-to-geoblacklight>\requirements.txt
a.	If you encounter the following error: “Fatal error in launcher: Unable to create process using '"'
 Download and run the pipreqs.py file using: python <path-to-file>\pipreqs.py

(Note: pipreqs.py assumes default Python 2.7 configuration, and that requirements.txt is installed in C:\Python27\Scripts\csw-to-geoblacklight-master\  - Make any necessary changes to paths before running the script).

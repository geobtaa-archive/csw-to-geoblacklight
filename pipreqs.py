import pip
fo = open("C:/Python27/Scripts/csw-to-geoblacklight-master/requirements.txt", "r")
inp = fo.read()
ls =inp.split()     

for i in ls:
    pip.main(['install',i])
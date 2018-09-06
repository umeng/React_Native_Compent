#!/usr/bin/env python
# coding:utf-8
import os
import sys,json,codecs
endstr = "_rn"
reload(sys)
sys.setdefaultencoding('utf-8')
def load(filepath):
    with open(filepath) as json_file:
        data = json.load(json_file)
        return data
def store(data,name):
    with codecs.open(name, 'w') as json_file:
        json_file.write(json.dumps(data,ensure_ascii=False ,indent=4))   
namelist = ["UM_analytics","UM_share","UM_common","UM_push"]      
print endstr  
for s in range(len(namelist)):
	name = namelist[s]
	source = load(name+".json")
	android = load("./../Android/"+name+".json")
	ios = load("./../iOS/"+name+".json")
	android_packages = android["packages"]
	ios_packages = ios["packages"]
	dellist = []
	for x in range(len(android_packages)):

		if not str(android_packages[x]["key"]).endswith(endstr):
			android_packages[x]["key"]=android_packages[x]["key"]+endstr
		title = android_packages[x]["title"]
		files = android_packages[x].get("files")
		a_files = android_packages[x].get("files_abroad")
		i_files = android_packages[x].get("files_internal")
		for m in range(len(ios_packages)):
			if not str(ios_packages[m]["key"]).endswith(endstr):
				ios_packages[m]["key"]=ios_packages[m]["key"]+endstr
			if cmp(ios_packages[m]["title"],title) == 0:
				if files :
					if ios_packages[m].get("files"):
						files.extend(ios_packages[m].get("files"))
				if a_files :
					if ios_packages[m].get("files_abroad"):
						a_files.extend(ios_packages[m].get("files_abroad"))
				if i_files :
					if ios_packages[m].get("files_internal"):
						i_files.extend(ios_packages[m].get("files_internal"))		
				
				dellist.append(m)
	suffix = 0			
	for i in range(len(dellist)):
		del ios_packages[dellist[i]-suffix]
		suffix+=1
	delandroid = []	
	delios = []	
	for x in range(len(android_packages)):
		title = android_packages[x]["title"]
		for n in range(len(source["packages"])):
			if cmp(source["packages"][n]["title"],title) == 0:
				source["packages"][n] = android_packages[x]
				delandroid.append(x)
	suffix = 0				
	for i in range(len(delandroid)):
		del android_packages[delandroid[i]-suffix]
		suffix+=1	
	for x in range(len(ios_packages)):
		title = ios_packages[x]["title"]
		for n in range(len(source["packages"])):
			if cmp(source["packages"][n]["title"],title) == 0:
				source["packages"][n] = ios_packages[x]
				delios.append(x)
	suffix = 0				
	for i in range(len(delios)):
		del ios_packages[delios[i]-suffix]	
		suffix+=1		
	source["packages"].extend(android_packages)		
	source["packages"].extend(ios_packages)		
	store(source,name+".json")


###########统计##########          
     

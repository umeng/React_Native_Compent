#!/usr/bin/env python
# coding:utf-8
import os
import sys,json,codecs
reload(sys)
sys.setdefaultencoding('utf-8')
def load(filepath):
    with open(filepath) as json_file:
        data = json.load(json_file)
        return data
def store(data,name):
    with codecs.open(name, 'w') as json_file:
        json_file.write(json.dumps(data,ensure_ascii=False ,indent=4))    
pf_list = ["UM_analytics.json","UM_common.json","UM_push.json","UM_share.json"] 
names = ["analytics","common","push","share"]        
for i in range(len(pf_list)):
	pf = pf_list[i]
	if os.path.exists('releaseNote_Public.json'):
		log_json=load("releaseNote_Public.json")   
		path =os.path.join("./alljson",pf) 
		alljson = load(path)   
		alljson["log"]=log_json[len(log_json)-1][names[i]]
		store(alljson,path)

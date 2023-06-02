#!/usr/bin/python

import json
import requests
import datetime
import time

#get tomorrow date
now = datetime.datetime.now()
delta = datetime.timedelta(days=1)
n_days = now + delta
tomorrowDate = n_days.strftime('%Y-%m-%d')

#open log file
f=file("/home/snsoadmin/shell/logs/create_ump_indices.log","a+")

#web
for i in range(0, 24):
   hour = str(i);
   if(i<10):
       hour = "0"+str(i)
   index_name = "ump-web-njyh-"+tomorrowDate+"-"+hour + "-0"
   req = "http://10.105.80.110:9200/" + index_name + "/"
   stats = requests.put(req).json()
   now = datetime.datetime.now()
   f.write(now.strftime('%Y-%m-%d %H:%M:%S') + ": " +  req + "----" + json.dumps(stats) + "\n")
   time.sleep(1)

#web
for i in range(0, 24):
   hour = str(i);
   if(i<10):
       hour = "0"+str(i)
   index_name = "ump-web-njyh-"+tomorrowDate+"-"+hour + "-1"
   req = "http://10.105.80.110:9200/" + index_name + "/"
   stats = requests.put(req).json()
   now = datetime.datetime.now()
   f.write(now.strftime('%Y-%m-%d %H:%M:%S') + ": " +  req + "----" + json.dumps(stats) + "\n")
   time.sleep(1)
   
#web
for i in range(0, 24):
   hour = str(i);
   if(i<10):
       hour = "0"+str(i)
   index_name = "ump-web-njyh-"+tomorrowDate+"-"+hour + "-2"
   req = "http://10.105.80.110:9200/" + index_name + "/"
   stats = requests.put(req).json()
   now = datetime.datetime.now()
   f.write(now.strftime('%Y-%m-%d %H:%M:%S') + ": " +  req + "----" + json.dumps(stats) + "\n")
   time.sleep(1)
   
#web
for i in range(0, 24):
   hour = str(i);
   if(i<10):
       hour = "0"+str(i)
   index_name = "ump-web-njyh-"+tomorrowDate+"-"+hour + "-3"
   req = "http://10.105.80.110:9200/" + index_name + "/"
   stats = requests.put(req).json()
   now = datetime.datetime.now()
   f.write(now.strftime('%Y-%m-%d %H:%M:%S') + ": " +  req + "----" + json.dumps(stats) + "\n")
   time.sleep(1)
   
#web
for i in range(0, 24):
   hour = str(i);
   if(i<10):
       hour = "0"+str(i)
   index_name = "ump-web-njyh-"+tomorrowDate+"-"+hour + "-4"
   req = "http://10.105.80.110:9200/" + index_name + "/"
   stats = requests.put(req).json()
   now = datetime.datetime.now()
   f.write(now.strftime('%Y-%m-%d %H:%M:%S') + ": " +  req + "----" + json.dumps(stats) + "\n")
   time.sleep(1)
   
#web
for i in range(0, 24):
   hour = str(i);
   if(i<10):
       hour = "0"+str(i)
   index_name = "ump-web-njyh-"+tomorrowDate+"-"+hour + "-5"
   req = "http://10.105.80.110:9200/" + index_name + "/"
   stats = requests.put(req).json()
   now = datetime.datetime.now()
   f.write(now.strftime('%Y-%m-%d %H:%M:%S') + ": " +  req + "----" + json.dumps(stats) + "\n")
   time.sleep(1)  


   
#nginx
for i in range(0, 24):
   hour = str(i);
   if(i<10):
       hour = "0"+str(i)
   index_name = "ump-nginx-njyh-"+tomorrowDate+"-"+hour + "-0"
   req = "http://10.105.80.110:9200/" + index_name + "/"
   stats = requests.put(req).json()
   now = datetime.datetime.now()
   f.write(now.strftime('%Y-%m-%d %H:%M:%S') + ": " +  req + "----" + json.dumps(stats) + "\n")
   time.sleep(1)

#nginx
for i in range(0, 24):
   hour = str(i);
   if(i<10):
       hour = "0"+str(i)
   index_name = "ump-nginx-njyh-"+tomorrowDate+"-"+hour + "-1"
   req = "http://10.105.80.110:9200/" + index_name + "/"
   stats = requests.put(req).json()
   now = datetime.datetime.now()
   f.write(now.strftime('%Y-%m-%d %H:%M:%S') + ": " +  req + "----" + json.dumps(stats) + "\n")
   time.sleep(1)
   
#nginx
for i in range(0, 24):
   hour = str(i);
   if(i<10):
       hour = "0"+str(i)
   index_name = "ump-nginx-njyh-"+tomorrowDate+"-"+hour + "-2"
   req = "http://10.105.80.110:9200/" + index_name + "/"
   stats = requests.put(req).json()
   now = datetime.datetime.now()
   f.write(now.strftime('%Y-%m-%d %H:%M:%S') + ": " +  req + "----" + json.dumps(stats) + "\n")
   time.sleep(1)
   
#nginx
for i in range(0, 24):
   hour = str(i);
   if(i<10):
       hour = "0"+str(i)
   index_name = "ump-nginx-njyh-"+tomorrowDate+"-"+hour + "-3"
   req = "http://10.105.80.110:9200/" + index_name + "/"
   stats = requests.put(req).json()
   now = datetime.datetime.now()
   f.write(now.strftime('%Y-%m-%d %H:%M:%S') + ": " +  req + "----" + json.dumps(stats) + "\n")
   time.sleep(1)
   
#nginx
for i in range(0, 24):
   hour = str(i);
   if(i<10):
       hour = "0"+str(i)
   index_name = "ump-nginx-njyh-"+tomorrowDate+"-"+hour + "-4"
   req = "http://10.105.80.110:9200/" + index_name + "/"
   stats = requests.put(req).json()
   now = datetime.datetime.now()
   f.write(now.strftime('%Y-%m-%d %H:%M:%S') + ": " +  req + "----" + json.dumps(stats) + "\n")
   time.sleep(1)
   
#nginx
for i in range(0, 24):
   hour = str(i);
   if(i<10):
       hour = "0"+str(i)
   index_name = "ump-nginx-njyh-"+tomorrowDate+"-"+hour + "-5"
   req = "http://10.105.80.110:9200/" + index_name + "/"
   stats = requests.put(req).json()
   now = datetime.datetime.now()
   f.write(now.strftime('%Y-%m-%d %H:%M:%S') + ": " +  req + "----" + json.dumps(stats) + "\n")
   time.sleep(1) 
   

   
#rsf
for i in range(0, 24):
   hour = str(i);
   if(i<10):
       hour = "0"+str(i)
   index_name = "ump-rsf-njyh-"+tomorrowDate+"-"+hour
   req = "http://10.105.80.110:9200/" + index_name + "/"
   stats = requests.put(req).json()
   now = datetime.datetime.now()
   f.write(now.strftime('%Y-%m-%d %H:%M:%S') + ": " +  req + "----" + json.dumps(stats) + "\n")
   time.sleep(1) 
   
#rsftp
for i in range(0, 24):
   hour = str(i);
   if(i<10):
       hour = "0"+str(i)
   index_name = "ump-rsftp-njyh-"+tomorrowDate+"-"+hour
   req = "http://10.105.80.110:9200/" + index_name + "/"
   stats = requests.put(req).json()
   now = datetime.datetime.now()
   f.write(now.strftime('%Y-%m-%d %H:%M:%S') + ": " +  req + "----" + json.dumps(stats) + "\n")
   time.sleep(1) 
   
#esb
for i in range(0, 24):
   hour = str(i);
   if(i<10):
       hour = "0"+str(i)
   index_name = "ump-esb-njyh-"+tomorrowDate+"-"+hour
   req = "http://10.105.80.110:9200/" + index_name + "/"
   stats = requests.put(req).json()
   now = datetime.datetime.now()
   f.write(now.strftime('%Y-%m-%d %H:%M:%S') + ": " +  req + "----" + json.dumps(stats) + "\n")
   time.sleep(1) 
   
#close log file
f.close

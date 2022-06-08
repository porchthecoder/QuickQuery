#!/usr/bin/python

import requests
import sys
import xml.etree.ElementTree as ET
import base64
import time
import re
import cgi

user = '<USERACCOUNT> DOMAIN/serviceaccount'
pwd = '<PASSWORD>'
service = 'http://<COMMVAULT WEB SERVER>:81/SearchSvc/CVWebService.svc/'

global stuffFound
global searchString

stuffFound = 0

print "Content-Type: text/html"     # HTML is following
print                               # blank line, end of headers

form = cgi.FieldStorage()

def cgiLoad():
    global searchString
    if "search" not in form:
	print "Nothing to search"
	exit()
    if (len(str(form["search"])) < 3):
	print "Keep typing"
	exit()
    else:
	searchString = form["search"].value


cgiLoad()






###########################################
##Login and get the token
loginReq = '<DM2ContentIndexing_CheckCredentialReq mode="Webconsole" username="<<username>>" password="<<password>>" />'

loginReq = loginReq.replace("<<username>>", user)
#encode password in base64
loginReq = loginReq.replace("<<password>>", base64.b64encode(pwd))

#Login request built. Send the request now:
r = requests.post(service + 'Login', data=loginReq,verify=False)
token = None

#Check response code and check if the response has an attribute "token" set
if r.status_code == 200:
	root = ET.fromstring(r.text)
	if 'token' in root.attrib:
		token = root.attrib['token']
		#print "Login Successful"
	else:
		print "Login Failed"
		sys.exit(0)
else:
	print 'there was an error logging in. Code HTML:' + str(r.status_code)
	

#print 'Login sucessful'

#Login successful.	
####################################


####################
#Based on the clientId, get the details of the last job
def jobStatus(clientId):

    jobsPropsReq = service + "Job?ClientiD=" + clientId + "&limit=10000"

#    jobsPropsReq = service + "Job/61565"
    #Return 10000 records, but we only keep the last one. Commvault does not seem to have a good way to just select the last record. 
    headers = {'Cookie2': token, "limit": str(1000)}
    jobs = requests.get(jobsPropsReq, headers=headers,verify=False)
    jobsResp = jobs.text

    #Stop here if the client is found, but does not have any backup jobs. 
#    print jobsResp
    if not "job" in jobsResp:
        print "Server found setup in Commvault (iData type), but no backups exist. Not set to backup? Powered off?"
	stuffFound = 1
	return
    
    


#    print jobsResp
#    exit()
    jobsclient = ET.fromstring(jobsResp)
    maxJobUpdateTime = 0
    for jobsSummary in jobsclient.iter('jobSummary'): #yes this is sloppy, we are looping over each record,
    
	if maxJobUpdateTime < jobsSummary.get('lastUpdateTime'):
	    maxJobUpdateTime = jobsSummary.get('lastUpdateTime')
	    jobTime = time.strftime("%a, %d %b %Y %I:%M:%S%p", time.localtime(float(jobsSummary.get('jobStartTime'))))
	    statusOutText = "iData Agent:" + str(jobsSummary.get('destClientName')) + ", Last Backup:"+ str(jobTime) + ", Status:" + str(jobsSummary.get('status')) + ", Size:" + str(int(jobsSummary.get('sizeOfApplication'))/1024/1024/1024) + "GB, Subclient:" + str(jobsSummary.get('subclientName')) + "<BR>"
	    # jobsSummary.get('subclientName') + "status:"+jobsSummary.get('status') 
	#print maxJobUpdateTime + "--" + jobsSummary.get('lastUpdateTime') + " -- " + time.strftime("%a, %d %b %Y %I:%M:%S%p", time.localtime(float(jobsSummary.get('jobStartTime'))))
#        print(jobsSummary.get('totalFailedFiles'))
#        print(jobsSummary.get('sizeOfApplication'))
#	print(jobsSummary.get('lastUpdateTime'))	
	#sizeOfApp =  str(int(jobsSummary.get('sizeOfApplication'))/1024/1024/1024)
    print statusOutText


#####################


########################
#search for a non VM server
def getNonVM():
    global stuffFound
    ##########Non-VMs
    headers = {'Cookie2': token}
    clientPropsReq = service + "Client"
    r = requests.get(clientPropsReq, headers=headers,verify=False)
    clientResp = r.text
    client = ET.fromstring(clientResp)

#    print 'boo'

    for clientEntity in client.iter('clientEntity'):
#	print(clientEntity.attrib)
#	print(clientEntity.get('clientName'))
#	print(clientEntity.get('clientId'))
	if re.search(searchString.upper(), (clientEntity.get('clientName')).upper()) is not None:
#	    print "iData Agent: "+ clientEntity.get('clientName') + clientEntity.get('clientId')
	    stuffFound = 1
	    jobStatus(clientEntity.get('clientId'))

##########################



########Get VMs

def getVCenterID():
    #Get a list of vcenters
    headers = {'Cookie2': token}
    clientPropsReq = service + "Client?PseudoClientType=VSPseudo"
    r = requests.get(clientPropsReq, headers=headers,verify=False)
    #print r.text

    client = ET.fromstring(r.text)
    for clientEntity in client.iter('client'):
	#print(clientEntity.attrib)
#	print(clientEntity.get('clientId'))
	getsubclientID(clientEntity.get('clientId'))


def getsubclientID(VCenterID):
    #Get a list of subclients
    headers = {'Cookie2': token}
    clientPropsReq = service + "Subclient?clientId=" + VCenterID
    r = requests.get(clientPropsReq, headers=headers,verify=False)
    #print r.text

    client = ET.fromstring(r.text)
    for clientEntity in client.iter('subClientEntity'):
#	print "subclientName:"
#	print(clientEntity.get('subclientName'))
#	print "subclientID:"
#	print(clientEntity.get('subclientId'))
#	print "----------"

	getfolderList(clientEntity.get('subclientId'),clientEntity.get('subclientName'))


def getfolderList(subclientID,subclientName):
    global stuffFound
    #Get a folders in each subclient
    headers = {'Cookie2': token}
    clientPropsReq = service + "Subclient/"+subclientID+"/Browse?path=%5C&showDeletedFiles=false&vsFileBrowse=true"
    r = requests.get(clientPropsReq, headers=headers,verify=False)
#    print r.text
#    print "-------------------"
    

    data = ET.fromstring(r.text)
    for dataResultSet in data.iter('dataResultSet'):

#	print dataResultSet.get('displayName')
#	print dataResultSet.get('size')

	advancedData = data.find('.//advancedData')
#        print "backupTime" + advancedData.get('backupTime')

	sizeOfApp =  str(int(dataResultSet.get('size'))/1024/1024/1024)
	jobTime = time.strftime("%a, %d %b %Y %I:%M:%S%p", time.localtime(float(advancedData.get('backupTime'))))
        returnResult = dataResultSet.get('displayName')+", Size of App:"+sizeOfApp+"GB, Last Backup: "+jobTime + ", Subclient: " + subclientName

	if re.search(searchString.upper(), (dataResultSet.get('displayName').upper())) is not None:
	    print "VM: "+ returnResult
	    stuffFound = 1








######Program starts here
getNonVM()
#getVCenterID() #too slow, does not work

if stuffFound == 0:
    print "Nothing found in Commvault (only shows if system has a backup)"



exit()












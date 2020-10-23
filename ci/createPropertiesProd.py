import os
import sys

f = open('build.properties','w')

if len(sys.argv) < 3:
    print "Could not prepare file! Please pass branch names as parameters: python helloworld.py parentBranch childBranch"
    f.write("")

else:
    f.write('sf.serverurl = https://login.salesforce.com' + '\n')
    f.write('sf.maxPoll = 50' + '\n')
    f.write('sf.username = ' + sys.argv[1] + '\n')
    f.write('sf.password = ' + sys.argv[2])

f.close()

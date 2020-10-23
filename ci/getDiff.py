import subprocess
import os
import sys

f = open('ReleasePackage' + os.sep + 'filesToIncludeInBuild.txt','w')

if len(sys.argv) < 2:
    print "Could not prepare file! Please pass branch names as parameters: python helloworld.py parentBranch childBranch"
    f.write("")

else:
    p = subprocess.Popen("git diff --name-only " + sys.argv[1], shell=True, stdout = subprocess.PIPE)
    print "\n:::::::: Differences found:"

    for aline in p.stdout.read().split('\n'):
        f.write(aline[aline.rfind(os.sep)+1:] + '\n')
        print aline

f.close()

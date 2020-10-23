import os
import sys

print "\n:::::::: Package version will be changed to from 41.0 to 43.0"

with open('src/package.xml', 'r') as oldfile:
    newText=oldfile.read()

    while '<version>41.0</version>' in newText:
        newText=newText.replace('<version>41.0</version>', '<version>45.0</version>')

with open('src/package.xml', "w") as newfile:
    newfile.write(newText)

newfile.close()
oldfile.close()

print "\n:::::::: Package version has been changed"
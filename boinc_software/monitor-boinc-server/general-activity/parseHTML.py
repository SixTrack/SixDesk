from HTMLParser import HTMLParser
from htmlentitydefs import name2codepoint
import datetime

wantedFields=[
    'Tasks ready to send',
    'Tasks in progress',
    'Workunits waiting for validation',
    'Workunits waiting for assimilation',
    'Workunits waiting for file deletion',
    'Tasks waiting for file deletion'
]

class MyHTMLParser(HTMLParser):
    '''
    main code from:
       https://docs.python.org/2/library/htmlparser.html
    '''

    def __init__( self ):
        HTMLParser.__init__( self )
        self.data={}
        self.lastField=None
# AM ->     def handle_starttag(self, tag, attrs):
# AM ->         print "Start tag:", tag
# AM ->         for attr in attrs:
# AM ->             print "     attr:", attr

# AM ->     def handle_endtag(self, tag):
# AM ->         print "End tag  :", tag

    def handle_data(self, data):
# AM ->         print "Data     :", data
        if ( self.lastField is not None ):
            # in case, acquire data:
            self.data[self.lastField]=data
            self.lastField=None
        elif ( data in wantedFields ):
            self.lastField=data

# AM ->     def handle_comment(self, data):
# AM ->         print "Comment  :", data

# AM ->     def handle_entityref(self, name):
# AM ->         c = unichr(name2codepoint[name])
# AM ->         print "Named ent:", c

# AM ->     def handle_charref(self, name):
# AM ->         if name.startswith('x'):
# AM ->             c = unichr(int(name[1:], 16))
# AM ->         else:
# AM ->             c = unichr(int(name))
# AM ->         print "Num ent  :", c

# AM ->     def handle_decl(self, data):
# AM ->         print "Decl     :", data

def parseFile(iFileName):
    parser = MyHTMLParser()
    iFile=open(iFileName,'r')
    for line in iFile.readlines():
        parser.feed( line )
    iFile.close()
    parser.close()
    return parser.data

if ( __name__ == '__main__' ):
    relevantData=parseFile('server_status.php')
    for wantedField in wantedFields:
        print relevantData[wantedField]

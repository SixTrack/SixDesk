"""
A.Mereghetti, 2017-01-29
script for parsing the server_status.php and getting values from tables
NB: html file is a table of tables!

parsing of HTML table based on:
http://codereview.stackexchange.com/questions/60769/scrape-an-html-table-with-python

reminders on html tables:
- <table>: start a new table;
- <tr>: start a new table row;
- <th>: start a table header (actually, a header cell);
- <td>: start a table cell in a row;
"""

import sys
from urllib2 import urlopen, URLError
from argparse import ArgumentParser
from bs4 import BeautifulSoup
import time

lDebug=False
lPrintTables=False
wantedApps=[ 'SixTrack', 'sixtracktest' ]
wantedH4tags=[ 'Work', 'Users', 'Computers' ]
wantedH3tags=[ 'Tasks by application' ]
findEntries=['table','h4','h3']

class TABLE():

    def __init__( self, name ):
        """creating a table"""
        self.columnNames=[]
        self.content=[]  # array (rows) of dictionary (column header: value)!
        self.name=name

    def addColumnNames( self, table_columnNames ):
        self.columnNames=[ tmpColumnName.encode('ascii','ignore') for tmpColumnName in table_columnNames ]
        if ( lDebug ):
            print "HEAD:",self.columnNames

    def addField( self, columnName, value, iRow=-1 ):
        self.columnNames.append( columnName )
        if ( len( self.content ) == 0 or iRow==len(self.content) ):
            self.content.append( {} )
        elif ( iRow>len(self.content) ):
            print "error in building table!"
            sys.exit()
        self.content[iRow][ columnName ]=value
        if ( lDebug ):
            print "HEAD: %s - VAL: %s" % ( self.columnNames[-1], self.content[iRow][self.columnNames[-1]] )

    def addContent( self, table_data ):
        self.content.append( dict( zip(self.columnNames,[data.encode('ascii','ignore') for data in table_data]) ) )
        if ( lDebug ):
            print "DATA:",self.content[-1]

    def retColumn( self, columnName ):
        if ( columnName in self.columnNames ):
            return [ tmpLine[columnName] for tmpLine in self.content ]
        else:
            return None

    def retRowName( self, columnName=None, matchName=None, columnNames=None ):
        if ( columnName is None or matchName is None ):
            return None
        if ( columnNames is None ):
            columnNames=self.columnNames
        if ( columnName in self.columnNames ):
            for tmpLine in self.content:
                if ( tmpLine[columnName]==matchName ):
                    return [ tmpLine[columnName] for columnName in columnNames ]
        else:
            return None
        

    def printAll( self ):
        print ''
        print 'TABLE:',self.name
        print 'HEADER:','\t'.join(self.columnNames)
        for tmpLine in self.content:
            print '\t'.join( [ tmpLine[tmpColumnName] for tmpColumnName in self.columnNames ] )

class TABLE_ComputingStatus( TABLE ):

    '''
Example of table to be parsed:
<h3>Computing status</h3>
<h4>Work</h4>
<div class="table">
      <table  width="100%" class="table table-condensed table-striped" >
    <tr><td>Tasks ready to send</td><td>586</td></tr>
<tr><td>Tasks in progress</td><td>207292</td></tr>
<tr><td>Workunits waiting for validation</td><td>42644</td></tr>
<tr><td>Workunits waiting for assimilation</td><td>10</td></tr>
<tr><td>Workunits waiting for file deletion</td><td>53054</td></tr>
<tr><td>Tasks waiting for file deletion</td><td>52639</td></tr>
<tr><td>Transitioner backlog (hours)</td><td>0.00</td></tr>
</table>
        </div>
    '''
    
    @staticmethod
    def fromHTML( entries, TABLES ):
        '''
        Final state of instance:

        self.columnNames=['entry','#']
        self.content=[
        {'entry':'Tasks in progress','#':207292},
        {'entry':'Tasks ready to send','#':586},
        ...
        ]
        
        '''
        parseTab=None
        
        for entry in entries:
            if(lDebug):
                print "--> reading entry:",entry," -- end entry"
            if(entry.name=='h4'):
                if (lDebug):
                    print '--> recognised h4 tag - value:',entry.text
                if (entry.text in wantedH4tags):
                    parseTab=entry.text
                    TABLES[parseTab]=TABLE(parseTab)
                    TABLES[parseTab].addColumnNames(['entry','#'])
            elif(entry.name=='table' and parseTab is not None):
                if(lDebug):
                    print '--> recognised table tag - acquring data'
                rows=entry.find_all('tr')
                for row in rows:
                    data=row.find_all('td')
                    if(len(data)==0):
                        # skip empty line
                        continue
                    if(len(data)!=2):
                        print 'error in reading table %s'%(parseTab)
                        print 'at row:', row
                        sys.exit()
                    TABLES[parseTab].addContent( [ datum.get_text() for datum in data ] )
                parseTab=None
                    
        return TABLES

class TABLE_TasksByApplication( TABLE ):

    @staticmethod
    def fromHTML( entries, TABLES ):
        '''
        Final state of instance:

        self.columnNames=['Application','Unsent','In progress',...]
        self.content=[
        {'Application':'SixTrack','Unsent':586, ...},
        {'Application':'sixtracktest','Unsent':2867, ...},
        ...
        ]
        
        '''
        parseTab=None
        
        for entry in entries:
            if(lDebug):
                print "--> reading entry:",entry," -- end entry"
            if(entry.name=='h3'):
                if(lDebug):
                    print '--> recognised h3 tag - value:',entry.text
                if(entry.text in wantedH3tags):
                    parseTab=entry.text
                    TABLES[parseTab]=TABLE(parseTab)
            elif (entry.name=='table' and parseTab is not None):
                if(lDebug):
                    print 'recognised table tag - acquring data'
                rows=entry.find_all('tr')
                for row in rows:
                    table_headers = row.find_all('th')
                    if table_headers:
                        TABLES[parseTab].addColumnNames([headers.get_text() for headers in table_headers])
                        continue
                    data=row.find_all('td')
                    if(len(data)==0):
                        # skip empty line
                        continue
                    TABLES[parseTab].addContent([datum.get_text() for datum in data])
                parseTab=None
                    
        return TABLES

def cleanIntegers( tmpArray ):
    return [ tmpNum.replace(',','' ) for tmpNum in tmpArray ]

def parse_arguments():
    """ Process command line arguments """
    parser = ArgumentParser(description='Grabs tables from html')
    parser.add_argument('-u', '--url', help='url to grab from',
                        required=False)
    parser.add_argument('-f', '--filN', help='local HTML file to grab from',
                        required=False)
    parser.add_argument('-d', '--date', help='current date',
                        required=False)
    parser.add_argument('-t', '--time', help='current time',
                        required=False)
    args = parser.parse_args()
    return args

def main():
    outServerStatus="server_status_%s.dat"
    outAppStatus="%s_status_%s.dat"
    appDesiredColumns=['Unsent','In progress','Users in last 24 hours']
    TABLES={}

    # get arguments
    args = parse_arguments()
    if args.url:
        # retrieve URL and parse HTML
        try:
            resp = urlopen(args.url)
        except URLError as e:
            print 'An error occured fetching %s \n %s' % (args.url, e.reason)   
            return 10
        try:
            soup = BeautifulSoup(resp.read(),'lxml')
        except:
            print 'Error while using BeautifulSoup'
            return 10
    elif args.filN:
        # parse file with HTML
        try:
            iFile = open( args.filN, 'r' )
        except:
            print 'No readable file %s' % (filN)
            return 10
        try:
            soup = BeautifulSoup(open('server_status.php'), 'lxml')
        except:
            print 'Error while using BeautifulSoup'
            return 10
    else:
        print ' please specify either a URL or a local file to parse'
        return 3

    # output file names will embed timestamp
    if args.date:
        currDate=args.date
    else:
        currDate=time.strftime('%Y-%m-%d')
    if args.time:
        currTime=args.time
    else:
        currTime=time.strftime('%H-%M-%S')

    # get the main table
    try:
        entries=soup.find_all(findEntries)
    except AttributeError as e:
        raise ValueError("No valid entries found")
        return 1

    if(lDebug):
        print '--> acquired',len(entries),'entries, searching for:',findEntries
    # extract tables of Work, Users, Computers
    TABLES = TABLE_ComputingStatus.fromHTML( entries[1:], TABLES )
    # extract table of tasks by apps
    TABLES = TABLE_TasksByApplication.fromHTML( entries[1:], TABLES )
    if ( lPrintTables ):
        for table in TABLES.values():
            table.printAll()

    # strem in output files:
    # - serverStatus
    #   NB: format depends directly on tables and their order of parsing:
    #       $1, $2: date (YYYY-MM-DD), time (HH-MM-SS);
    #       - Work table:
    #       $3: ready to send (plotted);
    #       $4: in progress (plotted);
    #       $5: workunits waiting for validation (plotted);
    #       $6: workunits waiting for assimilation (plotted);
    #       $7: workunits waiting for file deletion;
    #       $8: tasks waiting for file deletion;
    #       $9: transitioner backlog;
    #       - Users table:
    #       $10: credit (plotted - no longer $11);
    #       $11: recent credit (plotted - no longer $10);
    #       $12: registered in past 24h;
    #       - Computers table:
    #       $13: credit (plotted - no longer $14);
    #       $14: recent credit (plotted - no longer $13);
    #       $15: registered in past 24h;
    #       $16: current gigaflops (plotted);
    oFile=open(outServerStatus%(currDate),'a')
    oFile.write( '%s %s ' % ( currDate, currTime ) )
    for tmpTag in wantedH4tags:
        oFile.write( '%s ' % ( ' '.join(cleanIntegers(TABLES[tmpTag].retColumn('#') ) ) ) )
    oFile.write('\n')
    oFile.close()
    # - apps status:
    #   NB: format depends on appDesiredColumns
    for wantedApp in wantedApps:
        oFile=open(outAppStatus%(wantedApp,currDate),'a')
        oFile.write( '%s %s %s \n' % ( currDate, currTime, ' '.join(cleanIntegers(TABLES[wantedH3tags[0]].retRowName( columnName='Application', matchName=wantedApp, columnNames=appDesiredColumns ) ) ) ) )
        oFile.close()

    return 0

if __name__ == '__main__':
    status = main()
    sys.exit(status)

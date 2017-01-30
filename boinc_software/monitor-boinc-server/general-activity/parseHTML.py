"""
A.Mereghetti, 2017-01-29
script for parsing the server_status.pho and getting values from tables

parsing of HTML table based on:
http://codereview.stackexchange.com/questions/60769/scrape-an-html-table-with-python
"""

import sys
from urllib2 import urlopen, URLError
from argparse import ArgumentParser
from bs4 import BeautifulSoup
import time

lDebug=False
lPrintTables=False
wantedApps=[ 'SixTrack', 'sixtracktest' ]

class TABLE():

    def __init__( self ):
        """creating a table"""
        self.columnNames=[]
        self.content=[]

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
        print '\t'.join(self.columnNames)
        for tmpLine in self.content:
            print '\t'.join( [ tmpLine[tmpColumnName] for tmpColumnName in self.columnNames ] )

class TABLE_ComputingStatus( TABLE ):

    @staticmethod
    def fromHTML( table_data ):
        WorkTable=TABLE()
        UsersTable=TABLE()
        pcTable=TABLE()
        lRead=False
        for table_datum in table_data:
            if ( lDebug ):
                print "-->",'\t'.join(table_datum), len(table_datum), "<--"
            if ( table_datum[0] == "Tasks by application" ):
                lRead=False
                continue
            if ( len(table_datum)==2 ):
                if ( table_datum[0] == "Work" ):
                    tmpTable=WorkTable
                    tmpTable.addColumnNames( table_datum )
                    lRead=True
                    continue
                elif ( table_datum[0] == "Users" ):
                    tmpTable=UsersTable
                    tmpTable.addColumnNames( table_datum )
                    lRead=True
                    continue
                elif ( table_datum[0] == "Computers" ):
                    tmpTable=pcTable
                    tmpTable.addColumnNames( table_datum )
                    lRead=True
                    continue
            if ( lRead ):
                tmpTable.addContent( table_datum )
        return WorkTable, UsersTable, pcTable

class TABLE_TasksByApplication( TABLE ):

    @staticmethod
    def fromHTML( table_data ):
        lRead=False
        lFirst=False
        table=TABLE()
        for table_datum in table_data:
            if ( lDebug ):
                print "-->",'\t'.join(table_datum), len(table_datum), "<--"
            if ( table_datum[0] == "Tasks by application" ):
                lRead=True
                lFirst=True
            elif ( lRead ):
                if ( lFirst ):
                    table.addColumnNames( table_datum )
                    lFirst=False
                else:
                    table.addContent( table_datum )
        return table

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

def getRelevantData_TasksByApplication( table_data ):
    lRead=False
    lFirst=False
    table=TABLE()
    for table_datum in table_data:
        if ( "Tasks by application" in table_datum[0] ):
            lRead=True
            lFirst=True
        elif ( lRead ):
            if ( lFirst ):
                table.addColumnNames( table_datum )
                lFirst=False
            else:
                table.addContent( table_datum )
    return table

def parse_rows(rows):
    """ Get data from rows """
    results = []
    for row in rows:
        table_headers = row.find_all('th')
        if table_headers:
            results.append([headers.get_text() for headers in table_headers])
        table_data = row.find_all('td')
        if table_data:
            results.append([data.get_text() for data in table_data])
    return results

def main():
    outServerStatus="server_status_%s.dat"
    outAppStatus="%s_status_%s.dat"
    appDesiredColumns=['unsent','in progress','users in last 24h']

    # get arguments
    args = parse_arguments()
    if args.url:
        # retrieve URL and parse HTML
        try:
            resp = urlopen(args.url)
        except URLError as e:
            print 'An error occured fetching %s \n %s' % (url, e.reason)   
            return 1
        soup = BeautifulSoup(resp.read(), 'lxml')
    elif args.filN:
        # parse file with HTML
        try:
            iFile = open( args.filN, 'r' )
        except:
            print 'No readable file %s' % (filN)
            return 2
        soup = BeautifulSoup(open('server_status.php'), 'lxml')
    else:
        print ' please specify either a URL or a local file to parse'
        return 3

    if args.date:
        currDate=args.date
    else:
        currDate=time.strftime('%Y-%m-%d')
    if args.time:
        currTime=args.time
    else:
        currTime=time.strftime('%H-%M-%S')

    # get Tables
    try:
        table = soup.find('table')
        rows = table.find_all('tr')
    except AttributeError as e:
        raise ValueError("No valid table found")
    table_data = parse_rows(rows)
    if ( lDebug ):
        for i in table_data:
            print '\t'.join(i)
    WorkTable, UsersTable, pcTable = TABLE_ComputingStatus.fromHTML( table_data )
    tabApps=TABLE_TasksByApplication.fromHTML( table_data )
    if ( lPrintTables ):
        WorkTable.printAll()
        UsersTable.printAll()
        pcTable.printAll()
        tabApps.printAll()

    # strem in output files:
    # - serverStatus
    oFile=open(outServerStatus%(currDate),'a')
    oFile.write( '%s %s %s \n' % ( currDate, currTime, ' '.join(cleanIntegers(WorkTable.retColumn('#') ) ) ) )
    oFile.close()
    # - apss status:
    for wantedApp in wantedApps:
        oFile=open(outAppStatus%(wantedApp,currDate),'a')
        oFile.write( '%s %s %s \n' % ( currDate, currTime, ' '.join(cleanIntegers(tabApps.retRowName( columnName='application', matchName=wantedApp, columnNames=appDesiredColumns ) ) ) ) )
    oFile.close()

if __name__ == '__main__':
    status = main()
    sys.exit(status)

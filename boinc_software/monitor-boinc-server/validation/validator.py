import datetime
import numpy as np
import gzip
import gc

validatorTimeStampFormat='%Y-%m-%d %H:%M:%S.%f'
lDebug=False
to_timestamp = np.vectorize(lambda x: (x - datetime.datetime(1970, 1, 1)).total_seconds())
from_timestamp = np.vectorize(lambda x: datetime.datetime.utcfromtimestamp(x))

class RESULT():
    def __init__(self):
        self.ID=None
#        self.fileName=None
#        self.fileLocation=None
        self.host=None
        self.status={
            'valid': False,
            'invalid': False,
            'inconclusive': False,
            'unknown': True,     # none of the previous
            'nullF10': False,    # null fort.10 (ie 0-byte long);
            'turnx0': False,     # fort.10 full of 0s
            'badFLOPr': False,   # bad FLOP ratio;
            'trans': False,      # general transient failure;
            'fopen': False,      # fopen failure;
            'permF1': False,     # perm failure 1;
            'permF2': False,     # perm failure2;
            'errno=24': False,   # 24: too many open files <=> trans;
            'errno=2': False,    #  2: no such file or dir <=> fopen, permFx;
            'errno=-108': False  # -108: cannot try_open file => fopen, failed;
        }
        self.tClaimed=None       # CPU time claimed by client
        self.tF10=None           # CPU time read in fort.10
        self.credit=None
        self.turnx=None
        
class LOGEVENT():
    def __init__(self):
        self.timeStamp=None
        self.WUID=None
        self.WUname=None
        self.results=[]
        self.probl=None  # 1: no database rows found in lookup/enumerate for WU
                         # 2: no database rows found in lookup/enumerate for at least a result
    def addResultConditional(self,resultID,hostID):
        if ( resultID not in [tmpResult.ID for tmpResult in self.results] ):
            self.results.append(RESULT())
            self.results[-1].ID=resultID
            if (hostID is not None):
                self.results[-1].host=hostID
        return True
    def addWUIDConditional(self,WUID):
        if (self.WUID is None):
            self.WUID=WUID
        return True
    def findResult(self,resultID):
        try:
            iRes=[tmpResult.ID for tmpResult in self.results].index(resultID)
        except:
            iRes=-1
        return iRes
class HOST():
    def __init__(self):
        self.ID=None
        self.nResults={'valid':0,'invalid':0,'nullF10':0,'turnx0':0}
        self.pResults={}
def parseLoggedEvent(lineData):
    '''
    data is an array (lines) of arrays (fields):
    '''
    newLogEvent=LOGEVENT()
    tmpResults=[]
    lInhibit=False # not regular sequence of HOST# / RESULT#
    lerr=False     # not known status associated to RESULT
    if (lDebug):
        print 'parsing data: %s'%(lineData)
    for columns in lineData:
        if (lDebug):
            print 'columns: ',columns
        if(columns[2].startswith('[WU#')):
            if ( columns[3]=='handle_wu():' ):
                # ignore testing result line
                continue
            # start acquiring log event
#            newLogEvent.WUID=int(columns[2][4:-1])
#            newLogEvent.WUname=columns[3][:-1]
            newLogEvent.timeStamp=datetime.datetime.strptime('%s %s'%(columns[0],columns[1]),validatorTimeStampFormat)
            iRes=0
            eRes=0
            jRes=0
            lFirstHost=True
            lPairCheck=False
            lastRead=None
        elif (columns[2].startswith('[HOST#')):
            if ( lastRead=='HOST' ):
                lInhibit=True
                break
            if ( lPairCheck ):
                tmpResults[iRes].host=int(columns[2][6:])
                lPairCheck=False
            # end of handling a result
            if ( lFirstHost ):
                # from time to time there are double HOST lines...
                iRes+=1
                lFirstHost=False
            lastRead='HOST'
            continue
        elif (columns[2].startswith('[RESULT#')):
            if ( lastRead=='RESULT' ):
                lInhibit=True
                break
            lFirstHost=True
            for ii in range(len(tmpResults),iRes+1):
                tmpResults.append(RESULT())
#            tmpResults[iRes].ID=int(columns[2][8:])
#            tmpResults[iRes].fileName=columns[3][:-1]
            if (columns[4]=='Invalid'):
                tmpResults[iRes].status['invalid']=True
                tmpResults[iRes].status['unknown']=False
                tmpResults[iRes].host=int(columns[5][6:-1])
            elif (columns[4]=='Inconclusive'):
                tmpResults[iRes].status['inconclusive']=True
                tmpResults[iRes].status['unknown']=False
                tmpResults[iRes].host=int(columns[5][6:-1])
            elif (columns[4]=='Valid;'):
                tmpResults[iRes].status['valid']=True
                tmpResults[iRes].status['unknown']=False
                tmpResults[iRes].host=int(columns[8][6:-1])
                tmpResults[iRes].credit=float(columns[6])
            elif (columns[4]=='pair_check()'):
                lPairCheck=True
                if (columns[-1]=='invalid'):
                    tmpResults[iRes].status['invalid']=True
                    tmpResults[iRes].status['unknown']=False
                elif (columns[-1]=='valid'):
                    tmpResults[iRes].status['valid']=True
                    tmpResults[iRes].status['unknown']=False
            elif (columns[4]=='granted_credit'):
                continue
            else:
                print ' unknown data set (0):',columns
            lastRead='RESULT'
        elif (columns[2]=='[CRITICAL]'):
            if (columns[5]=='update_workunit()'):
                if (columns[-1]=='lookup/enumerate'):
                    newLogEvent.probl=1
                else:
                    print ' unknown data set (1):',columns
                continue
            elif (columns[5]=='result.update()'):
                if (columns[-1]=='lookup/enumerate'):
                    newLogEvent.probl=2
                else:
                    print ' unknown data set (2):',columns
                continue
            elif (eRes>=len(tmpResults)):
                tmpResults.append(RESULT())
            if ( columns[3]=='check_set:'):
                if ( columns[-1]=='-1' ):
                    # fort.10 null
                    tmpResults[eRes].status['nullF10']=True
                elif ( columns[-2]=='transient' and columns[-1]=='failure' ):
                    tmpResults[eRes].status['trans']=True
                elif ( columns[-2]=='fopen()' and columns[-1]=='failed' ):
                    tmpResults[eRes].status['fopen']=True
                else:
                    print ' unknown data set (3):',columns
                eRes+=1
            elif ( columns[3]=='check_pair:'):
                if ( columns[-3]=='perm' and columns[-2]=='failure' and columns[-1]=='1' ):
                    tmpResults[eRes].status['permF1']=True
                elif ( columns[-2]=='perm' and columns[-1]=='failure2' ):
                    tmpResults[eRes].status['permF2']=True
                elif ( columns[-3]=='transient' and columns[-2]=='failure' ):
                    tmpResults[eRes].status['trans']=True
                else:
                    print ' unknown data set (4):',columns
                eRes+=1
            elif ( columns[3]=='Bad' and columns[4]=='FLOP' ):
                if (jRes>=len(tmpResults)):
                    tmpResults.append(RESULT())
                # bad FLOP ratio
                tmpResults[jRes].status['badFLOPr']=True
                jRes+=1
            elif (len(columns)>14):
                if ( columns[13]=='errno=24' ):
                    # too many open files
                    tmpResults[eRes].status['errno=24']=True
#                    tmpResults[eRes].fileLocation=columns[7]
                elif ( columns[13]=='errno=2' ):
                    # no such file or dir
                    tmpResults[eRes].status['errno=2']=True
#                    tmpResults[eRes].fileLocation=columns[7]
                else:
                    print ' unknown data set (5):',columns
            else:
                print ' unknown data set (6):',columns
        elif (columns[2]=='[debug]'):
            continue
        else:
            print ' unknown data set (7):',columns
    if ( not lInhibit ):
        newLogEvent.results=tmpResults
    # sanity check of acquired event:
    nRes=len(newLogEvent.results)
    for iRes in range(len(newLogEvent.results)):
        lProbl=False
        for tmpVal in newLogEvent.results[iRes].status.values():
            lProbl=lProbl or tmpVal
        if ( not lProbl ):
            lerr=True
            if (lDebug):
                print ' problem with result %i'%(iRes)
    if (lerr):
        print 'something wrong with event at %s'%(newLogEvent.timeStamp)
    return newLogEvent, lInhibit, lerr
    
def parseLoggedEvent20170704(lineData):
    '''
    data is an array (lines) of arrays (fields):
    '''
    newLogEvent=LOGEVENT()
    lInhibit=False # result in summary not present in RES[...] lines
    lerr=False     # not known status associated to RESULT
    if (lDebug):
        print 'parsing data: %s'%(lineData)
        print 'nLines: %i'%(len(lineData))
    for columns in lineData:
        if (lDebug):
            print 'columns: ',columns
        if (columns[0]=='path:'):
            # newLogEvent.results[eRes].fileLocation=columns[1]
            if (lDebug):
                print 'found path!'
            continue
        elif(columns[2].startswith('[WU#')):
            if ( columns[3]=='handle_wu():' ):
                # ignore testing result line
                if (lDebug):
                    print 'skipping'
                continue
            # start acquiring log event
#            newLogEvent.WUID=int(columns[2][4:-1])
#            newLogEvent.WUname=columns[3][:-1]
            if (lDebug):
                print 'save timeStamp'
            newLogEvent.timeStamp=datetime.datetime.strptime('%s %s'%(columns[0],columns[1]),validatorTimeStampFormat)
            eRes=0
            jRes=0 # bad FLOP ratio message does not report resultID
            iLastRes=None # for summary of results
        elif (columns[2].startswith('RES')):
            # comparing results
            idRes1=int(columns[2].split('[')[1])
            idHst1=int(columns[5].split('[')[1])
            idRes2=int(columns[3].split(']')[0])
            idHst2=int(columns[6].split(']')[0])
            newLogEvent.addResultConditional(idRes1,idHst1)
            newLogEvent.addResultConditional(idRes2,idHst2)
            # eg: 2017-07-04 19:56:08.2581   RES[149569733 149569734] WU=72413400 HST[10415533 10297391] compare_results; MATCH m=1e+05 p=30 turnx=         0 cred=    0.00 T1=      5.4 K T2=      0.6 K outlier 1 v: 40517 40517
            # eg: 2017-07-04 19:56:08.4662   RES[149717544 149717545] WU#72482856 HOST[10452636 10388131] compare_results: DIFFER 12 -4.0104658251517122e-001 -2.8893227142302180e-001 m=1e+06 p=0 T:      26.0      23.0 V: 40517 40517
            newLogEvent.addWUIDConditional(int(columns[4][3:]))
            if (columns[8]=='MATCH' or columns[9]=='MATCH'):
                # matching results, eg:
                #       2017-07-04 14:00:47.1051   RES[148321221 149863527] WU=70126007 HST[10345457 9930009] compare_results; MATCH m=1e+05 0 p=30 turnx=   6000000 cred=   12.00 T1=    3214.2 claim=0.00 K T2=    4012.6 0.00 K 0 v: 40517 40517
                [iColTurnx]=[iCol for iCol in range(len(columns)) if 'turnx=' in columns[iCol]]
                if (columns[iColTurnx]=='turnx='):
                    turnx=int(columns[iColTurnx+1])
                else:
                    turnx=float(columns[iColTurnx].split('=')[1])
                iRes1=newLogEvent.findResult(idRes1)
                iRes2=newLogEvent.findResult(idRes2)
                if (turnx==0):
                    # zero turnx
                    newLogEvent.results[iRes1].status['turnx0']=True
                    newLogEvent.results[iRes2].status['turnx0']=True
                    # keep track of times:
                    [iColT1]=[iCol for iCol in range(len(columns)) if 'T1=' in columns[iCol]]
                    [iColT2]=[iCol for iCol in range(len(columns)) if 'T2=' in columns[iCol]]
                    if (columns[iColT1]=='T1='):
                        newLogEvent.results[iRes1].tF10=float(columns[iColT1+1])
                        t1d=2
                    else:
                        newLogEvent.results[iRes1].tF10=float(columns[iColT1].split('=')[1])
                        t1d=1
                    if (columns[iColT2]=='T2='):
                        newLogEvent.results[iRes2].tF10=float(columns[iColT2+1])
                        t2d=2
                    else:
                        newLogEvent.results[iRes2].tF10=float(columns[iColT2].split('=')[1])
                        t1d=2
                    if (columns[iColT1+t1d].startswith('claim=') or columns[iColT1+t1d]=='K'):
                        # cannot actually
                        continue
                    else:
                        newLogEvent.results[iRes1].tClaimed=float(columns[iColT1+t1d])
                        newLogEvent.results[iRes2].tClaimed=float(columns[iColT2+t2d])
                else:
                    newLogEvent.results[iRes1].turnx=turnx
                    newLogEvent.results[iRes2].turnx=turnx
                continue
            elif (columns[8]=='DIFFER' or columns[9]=='DIFFER'):
                # diffing results, eg:
                #       2017-07-05 05:28:17.5312   RES[146208976 146208977] WU=70684007  HST[10485156   10483734] compare_results: DIFFER 3 0.0000000000000000e+000 64.302958292171169e+000 m=1e+06 p=0 T:       4.6     860.1 V: 40517 40517
                continue
            else:
                print ' unknown data set (8):',columns
        elif (columns[2].startswith('[RESULT#')):
            if (columns[5].startswith('HOST[')):
                # comparing results, eg:
                #       2017-07-04 13:43:57.6815   [RESULT#146754959 147144012] WU#70953918 HOST[10484659 10450881] compare_results: DIFFER 12 -5.1201203302156983e-001 -4.3712272358251170e-001 p=0 V: 40517.000000000000e+000 40517.000000000000e+000
                newLogEvent.addResultConditional(int(columns[2].split('#')[1]),int(columns[5].split('[')[1]))
                newLogEvent.addResultConditional(int(columns[3].split(']')[0]),int(columns[6].split(']')[0]))
                newLogEvent.addWUIDConditional(int(columns[4].split('#')[1]))
            else:
                # summary of current result, eg:
                #       2017-07-05 18:51:37.1336   [RESULT#147622223 w-c8_n4_lhc2016_40_MD-105-16-476-2.5-1.0517__36__s__64.31_59.32__15_16__6__27_1_sixvf_boinc33772_0] Invalid [HOST#10405110]
                idRes=int(columns[2].split('#')[1])
                newLogEvent.addResultConditional(idRes,None)
                iRes=newLogEvent.findResult(idRes)
                iLastRes=iRes
#                newLogEvent.results[iRes].fileName=columns[3][:-1]
                if (columns[4]=='Invalid'):
                    newLogEvent.results[iRes].status['invalid']=True
                    newLogEvent.results[iRes].status['unknown']=False
                    if(newLogEvent.results[iRes].host is None):
                        newLogEvent.results[iRes].host=int((columns[-1].split('#')[1]).split(']')[0])
                elif (columns[4]=='Inconclusive'):
                    newLogEvent.results[iRes].status['inconclusive']=True
                    newLogEvent.results[iRes].status['unknown']=False
                    if(newLogEvent.results[iRes].host is None):
                        newLogEvent.results[iRes].host=int((columns[-1].split('#')[1]).split(']')[0])
                elif (columns[4]=='Valid;'):
                    newLogEvent.results[iRes].status['valid']=True
                    newLogEvent.results[iRes].status['unknown']=False
                    newLogEvent.results[iRes].credit=float(columns[6])
                    if(newLogEvent.results[iRes].host is None):
                        newLogEvent.results[iRes].host=int((columns[-1].split('#')[1]).split(']')[0])
                elif (columns[4]=='pair_check()'):
                    if (columns[-1]=='invalid'):
                        newLogEvent.results[iRes].status['invalid']=True
                        newLogEvent.results[iRes].status['unknown']=False
                    elif (columns[-1]=='valid'):
                        newLogEvent.results[iRes].status['valid']=True
                        newLogEvent.results[iRes].status['unknown']=False
                elif (columns[4]=='granted_credit'):
                    continue
                else:
                    print ' unknown data set (0):',columns
        elif (columns[2].startswith('[HOST#')):
            # summary of current host, eg:
            #       2017-07-05 18:51:37.1336   [HOST#10405110 AV#334] [outlier=0] Updating HAV in DB.  pfc.n=671.000000->671.000000
            idHost=int(columns[2].split('#')[1])
            if(iLastRes is not None):
                if(newLogEvent.results[iLastRes].host is None):
                    newLogEvent.results[iLastRes].host=idHost
                iLastRes=None
            # end of handling a result
            continue
        elif (columns[2]=='[CRITICAL]'):
            if (columns[5]=='update_workunit()'):
                if (columns[-1]=='lookup/enumerate'):
                    newLogEvent.probl=1
                else:
                    print ' unknown data set (1):',columns
                continue
            elif (columns[5]=='result.update()'):
                if (columns[-1]=='lookup/enumerate'):
                    newLogEvent.probl=2
                else:
                    print ' unknown data set (2):',columns
                continue
            if ( columns[3]=='check_set:'):
                # eg: 2017-07-06 08:07:41.1411 [CRITICAL]  check_set: init_result([RESULT#146800827 w-c0_n4_lhc2016_40_MD-185-16-476-2.5-1.234__4__s__64.31_59.32__7_8__6__51_1_sixvf_boinc3751_0]) failed: file size too big
                idRes=int(columns[4].split('#')[1])
                newLogEvent.addResultConditional(idRes,None)
                eRes=newLogEvent.findResult(idRes)
                if ( columns[-3]=='size' and columns[-2]=='too' and columns[-1]=='big' ):
                    # fort.10 null
                    newLogEvent.results[eRes].status['nullF10']=True
                elif ( columns[-2]=='transient' and columns[-1]=='failure' ):
                    newLogEvent.results[eRes].status['trans']=True
                elif ( columns[-2]=='fopen()' and columns[-1]=='failed' ):
                    newLogEvent.results[eRes].status['fopen']=True
                else:
                    print ' unknown data set (3):',columns
            elif ( columns[3]=='check_pair:'):
                # eg: 2017-07-05 18:51:37.2213 [CRITICAL]  check_pair: init_result([RESULT#148144465 w-c0_n5_lhc2016_40_MD-185-16-476-2.5-0.9878__18__s__64.31_59.32__8_9__6__12_1_sixvf_boinc19478_0]) perm failure 1
                eRes=newLogEvent.findResult(int(columns[4].split('#')[1]))
                if (eRes==-1):
                    lInhibit=True
                    break
                if ( columns[-3]=='perm' and columns[-2]=='failure' and columns[-1]=='1' ):
                    newLogEvent.results[eRes].status['permF1']=True
                elif ( columns[-2]=='perm' and columns[-1]=='failure2' ):
                    newLogEvent.results[eRes].status['permF2']=True
                elif ( columns[-3]=='transient' and columns[-2]=='failure' ):
                    newLogEvent.results[eRes].status['trans']=True
                else:
                    print ' unknown data set (4):',columns
            elif ( columns[3]=='Bad' and columns[4]=='FLOP' ):
                # bad FLOP ratio
                # -> not clear how to count
                # newLogEvent.results[jRes].status['badFLOPr']=True
                # jRes+=1
                continue
            elif ( columns[5]=='init_result:' ):
                # store eRes, for path line:
                idRes=int(columns[3].split('#')[1])
                newLogEvent.addResultConditional(idRes,None)
                eRes=newLogEvent.findResult(idRes)
                if (columns[6]=='zero' and columns[7]=='length' ):
                    # eg: 2017-07-04 13:44:11.2410 [CRITICAL]  [RESULT#149089048 w-c0_n8_lhc2016_40_MD-185-16-476-2.5-0.9878__19__s__64.31_59.32__19_20__6__69_1_sixvf_boinc21286_0] init_result: zero length file (14825416) path: 
                    idRes=int(columns[3].split('#')[1])
                    newLogEvent.addResultConditional(idRes,None)
                elif (columns[7]=='try_open'):
                    # eg: 2017-07-04 13:45:10.3571 [CRITICAL]  [RESULT#149459659 workspace1_hl10_injection_chrom_20_oct_10_B4__40__s__62.28_60.31__2_4__5__15_1_sixvf_boinc4305_0] init_result: cannot try_open file /data/boinc/project/sixtrack/upload/153/workspace1_hl10_injection_chrom_20_oct_10_B4__40__s__62.28_60.31__2_4__5__15_1_sixvf_boinc4305_0_0 retval=-108
                    newLogEvent.results[eRes].status['errno=-108']=True
                else:
                    print ' unknown data set (9):',columns
            elif (len(columns)>14):
                # eg: 2017-06-25 06:34:03.5859 [CRITICAL]  [RESULT#148214923 w-c4_n4_lhc2016_40_MD-130-16-476-2.5-1.1627__59__s__64.31_59.32__5_6__6__54_1_sixvf_boinc55259_1] Couldn't open /data/boinc/project/sixtrack/upload/a0/w-c4_n4_lhc2016_40_MD-130-16-476-2.5-1.1627__59__s__64.31_59.32__5_6__6__54_1_sixvf_boinc55259_1_0 file 0 out of 1 errno=24 Too many open files
                idRes=int(columns[3].split('#')[1])
                newLogEvent.addResultConditional(idRes,None)
                eRes=newLogEvent.findResult(idRes)
                if ( columns[13]=='errno=24' ):
                    # too many open files
                    newLogEvent.results[eRes].status['errno=24']=True
#                    newLogEvent.results[eRes].fileLocation=columns[7]
                elif ( columns[13]=='errno=2' ):
                    # no such file or dir
                    newLogEvent.results[eRes].status['errno=2']=True
#                    newLogEvent.results[eRes].fileLocation=columns[7]
                elif ( columns[6]=="case" and columns[7]=="of" and columns[8]=="zero" and columns[9]=="turns" ):
                    # eg: 2017-07-06 07:33:04.5570 [CRITICAL]  [RESULT#148184775 148184776] compare_results: case of zero turns pos= 1501 0 60 0 turns: 0 0 version: 40517 0

                    newLogEvent.results[eRes].status['turnx0']=True
                    idRes=int(columns[4].split(']')[0])
                    newLogEvent.addResultConditional(idRes,None)
                    eRes=newLogEvent.findResult(idRes)
                    newLogEvent.results[eRes].status['turnx0']=True
                else:
                    print ' unknown data set (5):',columns
            else:
                print ' unknown data set (6):',columns
        elif (columns[2]=='[debug]'):
            continue
        else:
            print ' unknown data set (7):',columns
    for result in newLogEvent.results:
        if ( result.host is None ):
            print ' none host!',result.ID,newLogEvent.WUID,' -> inhibiting'
            lInhibit=True
    if ( lInhibit ):
        print 'inhibit event: %s'%(newLogEvent.timeStamp),'results:',' '.join(['%i'%(tmpResult.ID) for tmpResult in newLogEvent.results])
        del newLogEvent.results
        newLogEvent.results=[]
    for iRes in range(len(newLogEvent.results)):
        if newLogEvent.results[iRes].status['unknown']:
            print 'unknown status for result %i - set to inconclusive'%(newLogEvent.results[iRes].ID)
            newLogEvent.results[iRes].status['inconclusive']=True
            newLogEvent.results[iRes].status['unknown']=False
    # sanity check of acquired event:
    nRes=len(newLogEvent.results)
    for iRes in range(len(newLogEvent.results)):
        lProbl=False
        for tmpVal in newLogEvent.results[iRes].status.values():
            lProbl=lProbl or tmpVal
        if ( not lProbl ):
            lerr=True
            if (lDebug):
                print ' problem with result %i'%(iRes)
    if (lerr):
        print 'something wrong with event at %s'%(newLogEvent.timeStamp)
    if (newLogEvent.timeStamp is None):
        print 'None timeStamp:',lineData
    return newLogEvent, lInhibit, lerr
    
def parseLogFile(iFile,nMaxEvents=1000000,lFirst=True):
    tmpLogEvents=[]
    eventData=[]
    ninhibit=0
    nWrong=0
    while(len(tmpLogEvents)<nMaxEvents):
        lastPos=iFile.tell()
        line=iFile.readline()
        if not line: break
        if ('Starting' in line or 'GOT STOP SIGNAL' in line or 'Quitting due to SIGHUP' in line or 'Quitting because trigger file' in line or 'Executing' in line):
            # restart of validator/daemons
            continue
        elif ( 'query' in line or 'select' in line ):
            # queries to DB
            continue
        elif ( 'Database error:' in line or 'query=update workunit' in line):
            # failing queries to DB
            continue
        line=line.strip()
        if (lDebug):
            if ('[debug]' not in line):
                print 'at line: %s'%(line)
        data=line.split()
        if (len(data)<2):
            print 'un-parsable line: %s'%(line)
            continue
        if (data[0]!='path:'):
            if (data[2].startswith('[WU#') and data[3]!='handle_wu():' ):
                # beginning of new validator event
                # - acquire present event
                if ( not lFirst ):
                    if (lValidator20170704):
                        tmpList=parseLoggedEvent20170704(eventData)
                    else:
                        tmpList=parseLoggedEvent(eventData)
                    if ( tmpList[1] ):
                        # inhibit readout of event
                        ninhibit+=1
                    else:
                        tmpLogEvents.append(tmpList[0])
                    if ( tmpList[2] ):
                        # inhibit readout of event
                        nWrong+=1
                # - get ready for new event
                del eventData
                eventData=[]
                if ( lFirst ):
                    lFirst=False
        eventData.append(data[:])
    return tmpLogEvents,ninhibit,nWrong,lastPos

def updateSummary(logEvents,summaryParsing):
    for tmpKey in summaryParsing.keys():
        summaryParsing[tmpKey]+=len([ tmpRes.status[tmpKey] for tmpLogEvent in logEvents for tmpRes in tmpLogEvent.results if (tmpRes.status[tmpKey])])
    return summaryParsing

def computeLogHistograms(logEvents,plots,dt=3600):
    '''
    compute histograms of logged events vs time
    '''
    histograms={}
    uniqeKeys=[]
    for tmpSeries in plots.itervalues():
        uniqeKeys+=tmpSeries.keys()
    uniqeKeys=sorted(set(uniqeKeys))
    
    # all events
    nBins=int((logEvents[-1].timeStamp-logEvents[0].timeStamp).total_seconds()/dt)+1
    tmpTimeStamps=[]
    for tmpLogEvent in logEvents:
        for tmpRes in tmpLogEvent.results:
            tmpTimeStamps.append( tmpLogEvent.timeStamp )
    histograms['all'], bins = np.histogram(to_timestamp(tmpTimeStamps), bins=nBins)

    # classified events
    for tmpKey in uniqeKeys:
        if (tmpKey=='all'):
            continue
        tmpTimeStamps=[]
        if ( RESULT().status.has_key(tmpKey) ):
            tmpWeights=None
            for tmpLogEvent in logEvents:
                for tmpRes in tmpLogEvent.results:
                    if ( tmpRes.status[tmpKey] ):
                        tmpTimeStamps.append( tmpLogEvent.timeStamp )
        elif (RESULT().__dict__.has_key(tmpKey)):
            tmpWeights=[]
            for tmpLogEvent in logEvents:
                for tmpRes in tmpLogEvent.results:
                    if ( tmpRes.__dict__[tmpKey] is not None ):
                        tmpTimeStamps.append( tmpLogEvent.timeStamp )
                        tmpWeights.append(tmpRes.__dict__[tmpKey])

        if (len(tmpTimeStamps)>0):
            histograms[tmpKey], tmpbins = np.histogram(to_timestamp(tmpTimeStamps), bins=bins, weights=tmpWeights)
        else:
            # null histogram
            histograms[tmpKey]=np.array([0.0 for iBin in range(len(bins)-1)])
    
    return histograms, bins, (bins[:-1]+bins[1:])/2, (bins[1:]-bins[:-1])/3600

def process1DHistograms(histograms1D,oFileNamePrefix='current',nBins=200):
    '''
    compute 1D histograms (not vs time)
    '''
    import matplotlib.pyplot as plt
    # loop over plots
    for tmpPlotName,tmpSeries in histograms1D.iteritems():

        # generate histograms for the plot
        histograms={}
        bins={}
        for tmpKey in tmpSeries.keys():
            if (len(tmpSeries[tmpKey]['data'])>0):
                histograms[tmpKey], bins[tmpKey] = np.histogram(tmpSeries[tmpKey]['data'],bins=nBins)

        # plot histograms
        if (len(histograms)>0):
            ax1=plt.gca()
            ax1.set_yscale('log')
            ax1.grid( True, which='major', linestyle='-', linewidth=0.2 )
            ax1.grid( True, which='minor', linestyle='--', linewidth=0.2 )
            ax1.set_title(tmpPlotName)
            for tmpKey in histograms.keys():
                if (len(histograms[tmpKey])>0):
                    binWidths=(bins[tmpKey][1:]-bins[tmpKey][:-1])
#                centres=(bins[tmpKey][:-1]+bins[tmpKey][1:])/2
#                    ax1.bar( bins[tmpKey][:-1], np.divide(histograms[tmpKey],binWidths), color=tmpSeries[tmpKey]['color'], edgecolor=tmpSeries[tmpKey]['color'], label=tmpSeries[tmpKey]['label'], log=True )
                    ax1.bar( bins[tmpKey][:-1], histograms[tmpKey], color=tmpSeries[tmpKey]['color'], edgecolor=tmpSeries[tmpKey]['color'], label=tmpSeries[tmpKey]['label'], log=True )
            handles, labels = ax1.get_legend_handles_labels()
            ax1.legend(handles, labels, loc='upper center',bbox_to_anchor=(1.2,0.65))
            if (oFilePrefix is None):
                plt.show()
            else:
                oFileName='%s_%s.png'%(oFileNamePrefix,tmpPlotName)
                print ' saving plot in %s ...'%(oFileName)
                plt.savefig(oFileName,bbox_inches='tight')
            plt.close()
    
    return True

def plotLogHistograms(histograms,centers,binWidths,plots,oFilePrefix='current',lDate=False):
    import matplotlib.pyplot as plt
    import matplotlib.dates as md
    
    # create plot
    for tmpPlotName,tmpPlotSeries in plots.iteritems():
        lFirst=True
        ax1=plt.gca()
        ax1.set_title('Treated results as from Validator log')
        timeSpan=centers[-1]-centers[0]
        if ( timeSpan<1E5 ):
            ax1.xaxis.set_major_locator(md.HourLocator(byhour=range(0,24), interval=1))
        elif ( timeSpan<3E5 ):
            ax1.xaxis.set_major_locator(md.HourLocator(byhour=range(0,24,3), interval=1))
        elif ( timeSpan<6E5 ):
            ax1.xaxis.set_major_locator(md.HourLocator(byhour=range(0,24,6), interval=1))
        elif ( timeSpan<3E6 ):
            ax1.xaxis.set_major_locator(md.DayLocator(bymonthday=range(1,32), interval=1))
        else:
            ax1.xaxis.set_major_locator(md.DayLocator(bymonthday=range(1,32,3), interval=1))
        xfmt = md.DateFormatter('%d/%m %H:%M')
        ax1.xaxis.set_major_formatter(xfmt)
        ax1.set_xlabel('time')
        ax1.grid()
        ax1.set_yscale('log')
        ax1.grid( True, which='major', linestyle='-', linewidth=0.2 )
        ax1.grid( True, which='minor', linestyle='--', linewidth=0.2 )
        for tmpKey in sorted(tmpPlotSeries.keys()):
            if (histograms.has_key(tmpKey)):
                if(len(histograms[tmpKey])>0):
                    if(lFirst):
                        if (tmpPlotSeries[tmpKey].has_key('ylabel')):
                            ax1.set_ylabel(tmpPlotSeries[tmpKey]['ylabel'])
                        else:
                            ax1.set_ylabel('#results [per hour]')
                        lFirst=False
                    ax1.plot( from_timestamp(centers), np.divide(histograms[tmpKey],binWidths), tmpPlotSeries[tmpKey]['color'], label=tmpPlotSeries[tmpKey]['label'], markeredgewidth=0.0 )
                    labels = ax1.get_xticklabels()
                    plt.setp(labels, rotation=90)
                else:
                    print ' ...skipping plotting histogram %s as no points have been found'%(tmpKey)
            else:
                print ' ...skipping plotting histogram %s as no points have been found'%(tmpKey)
        handles, labels = ax1.get_legend_handles_labels()
        if (oFilePrefix is None):
            ax1.legend(handles, labels, loc='upper center',bbox_to_anchor=(1.05,0.65))
            plt.show()
        else:
            ax1.legend(handles, labels, loc='upper center',bbox_to_anchor=(1.2,0.65))
            if (lDate):
                timeStr=datetime.datetime.now().strftime('_%Y-%m-%d_%H-%M-%S')
            else:
                timeStr=''
            oFileName='validator_%s_%s%s.png'%(oFilePrefix,tmpPlotName,timeStr)
            print ' saving plot in %s ...'%(oFileName)
            plt.savefig(oFileName,bbox_inches='tight')
        plt.close()
        ax1.clear()
    return True

def dumpHistograms(histograms,bins,centers,binWidths,oFileName):
    print ' dumping histograms in %s ...'%(oFileName)
    oFile=open(oFileName,'w')
    tmpKeys=sorted(histograms.keys())
    tmpLine='# tMin, tMax, tCentre, binWidth [h]'
    for tmpKey in tmpKeys:
        tmpLine+=', %s'%(tmpKey)
    oFile.write(tmpLine+'\n')
    for iBin in range(len(bins)-1):
        tmpLine='%s %s %s %s'%(from_timestamp(bins[iBin+1]),from_timestamp(bins[iBin]),from_timestamp(centers[iBin]),binWidths[iBin])
        for tmpKey in tmpKeys:
            tmpLine+=' %i'%(histograms[tmpKey][iBin])
        oFile.write(tmpLine+'\n')
    oFile.close()
    return True

def loadHistograms(iFileName):
    print ' acquiring histograms saved in %s ...'%(iFileName)
    iFile=open(iFileName,'r')
    histograms={}
    bins=[]
    centers=[]
    binWidths=[]
    lFirstData=True
    for line in iFile.readlines():
        data=line.strip().split()
        if (data[0]=='#'):
            # header - get keys starting from data[6] (they are separated by a coma)
            histKeys=[ datum.split(',')[0] for datum in data[6:] ]
            print ' ...found %i keys: '%(len(histKeys)),','.join(histKeys)
            for tmpKey in histKeys:
                histograms[tmpKey]=[]
        else:
            # actual data
            if (lFirstData):
                bins.append(datetime.datetime.strptime('%s %s'%(data[0],data[1]),validatorTimeStampFormat))
                lFirstData=False
            try:
                bins.append(datetime.datetime.strptime('%s %s'%(data[2],data[3]),validatorTimeStampFormat))
            except:
                bins.append(datetime.datetime.strptime('%s %s'%(data[2],data[3]),validatorTimeStampFormat[:-3]))
            centers.append(datetime.datetime.strptime('%s %s'%(data[4],data[5]),validatorTimeStampFormat))
            binWidths.append(float(data[6]))
            for iKey in range(len(histKeys)):
                histograms[histKeys[iKey]].append(int(data[7+iKey]))
    # numpy arrays:
    for tmpKey in histKeys:
        histograms[tmpKey]=np.array(histograms[tmpKey])
    bins=to_timestamp(np.array(bins))
    centers=to_timestamp(np.array(centers))
    binWidths=np.array(binWidths)
    iFile.close()
    return histograms,bins,centers,binWidths

def concatenateLogs(tmpHistograms,tmpBins,tmpCentres,tmpBinWidths,histograms,bins,centers,binWidths):
    for tmpKey in tmpHistograms.keys():
        if ( histograms.has_key(tmpKey) ):
            # add a 0 for the bin joining the two histograms
            histograms[tmpKey]=np.concatenate((histograms[tmpKey],np.array([0]),tmpHistograms[tmpKey]))
        else:
            histograms[tmpKey]=tmpHistograms[tmpKey]
    if (len(bins)>0):
        # add the central value and width of the bin at the joint
        centers=np.concatenate((centers,np.array([0.5*(bins[-1]+tmpBins[0])])))
        binWidths=np.concatenate((binWidths,np.array([tmpBins[0]-bins[-1]])))
    bins=np.concatenate((bins,tmpBins))
    centers=np.concatenate((centers,tmpCentres))
    binWidths=np.concatenate((binWidths,tmpBinWidths))
    return histograms,bins,centers,binWidths

def getHostsStatistics(logEvents,hosts=[]):
    for tmpEvent in logEvents:
        for tmpResult in tmpEvent.results:
            try:
                iHost=next(index for (index, d) in enumerate(hosts) if d.__dict__["ID"] == tmpResult.host)
            except:
                iHost=len(hosts)
                hosts.append(HOST())
                hosts[iHost].ID=tmpResult.host
            if (tmpResult.status['valid']):
                hosts[iHost].nResults['valid']+=1
            elif (tmpResult.status['invalid']):
                hosts[iHost].nResults['invalid']+=1
            if (tmpResult.status['nullF10']):
                hosts[iHost].nResults['nullF10']+=1
            elif (tmpResult.status['turnx0']):
                hosts[iHost].nResults['turnx0']+=1
    for tmpHost in hosts:
        tmpHostAll=tmpHost.nResults['valid']+tmpHost.nResults['invalid']
        if ( tmpHostAll!=0 ):
            for tmpKey in tmpHost.nResults.keys():
                tmpHost.pResults[tmpKey]=tmpHost.nResults[tmpKey]*100.0/tmpHostAll
        tmpHost.nResults['all']=tmpHostAll
    return hosts

def computeAndPlotHostsHistograms(hosts,oFileNamePrefix='current'):
    '''
    compute histograms of hosts
    '''
    import matplotlib.pyplot as plt
    for tmpKey in HOST().nResults.keys():
        histogram, bins=np.histogram([tmpHost.pResults[tmpKey] for tmpHost in hosts if tmpHost.pResults.has_key(tmpKey)],bins=100)
        ax1=plt.gca()
        ax1.set_title(tmpKey)
        ax1.set_xlabel('[%]')
        ax1.grid()
        ax1.set_ylabel('#hosts []')
        ax1.set_yscale('log')
        ax1.grid( True, which='major', linestyle='-', linewidth=0.2 )
        ax1.grid( True, which='minor', linestyle='--', linewidth=0.2 )
        ax1.bar( bins[:-1], histogram, color='red', label=tmpKey, log=True, edgecolor='red' )
        if (oFilePrefix is None):
            plt.show()
        else:
            oFileName='hosts_%s_%s.png'%(oFileNamePrefix,tmpKey)
            print ' saving plot in %s ...'%(oFileName)
            plt.savefig(oFileName,bbox_inches='tight')
        plt.close()
    return

def dumpHostStatistics(hosts,oFileName):
    print ' dumping data about hosts in %s ...'%(oFileName)
    oFile=open(oFileName,'w')
    oFile.write('# total number of hosts: %i \n'%(len(hosts)))
    oFile.write('# ID, nTot, nValid, nInvalid, nullF10, turnx0, valid [%], invalid [%], nullF10 [%], turnx0 [%]\n')
    for iHost in range(len(hosts)):
        hosts[iHost].nResults['all']=hosts[iHost].nResults['valid']+hosts[iHost].nResults['invalid']
    hosts=sorted(hosts, key=lambda host: host.__dict__['nResults']['all'], reverse=True)
    for tmpHost in hosts:
        if (tmpHost.nResults['all']!=0):
            oFile.write('%15i %7i %7i %7i %7i %7i %6.2f %6.2f %6.2f %6.2f\n'%(tmpHost.ID,
            tmpHost.nResults['all'],tmpHost.nResults['valid'],tmpHost.nResults['invalid'],tmpHost.nResults['nullF10'],tmpHost.nResults['turnx0'],
            tmpHost.nResults['valid']*100.0/tmpHost.nResults['all'],tmpHost.nResults['invalid']*100.0/tmpHost.nResults['all'],
            tmpHost.nResults['nullF10']*100.0/tmpHost.nResults['all'],tmpHost.nResults['turnx0']*100.0/tmpHost.nResults['all']))
    oFile.close()
    return True

if (__name__=='__main__'):
    oNameTag='20180101'
    # parsing of log files:
    logFileNames=[
#        'archive/sixtrack_validator.log-20170401.gz',
#        'archive/sixtrack_validator.log-20170501.gz',
#        'archive/sixtrack_validator.log-2017-05-pent.gz',
#        'archive/sixtrack_validator.log-20170601.gz',
#        'archive/sixtrack_validator.log.June24.gz',
#        'archive/sixtrack_validator.log-20170701.gz',
#        'archive/sixtrack_validator.log-20170704.gz'
#        'archive/sixtrack_validator.log-current.gz'
        'archive/sixtrack_validator.log-%s.gz'%(oNameTag)
#        'sixtrack_validator.log.gz'
    ]
    lLogFiles=True   # parse log files
    nMaxIter=1000000
    nMaxEvents=250000 # log events, related to amount of RAM used
    lValidator20170704=True

    # histogramsLogEventsVsTime
    dt=1800  # when building histograms
    histIFileNames=[
#       'archive/histograms_20170401.dat',
#       'archive/histograms_20170501.dat',
#       'archive/histograms_2017-05-pent.dat',
#       'archive/histograms_20170601.dat',
#       'archive/histograms_June24.dat',
#       'archive/histograms_20170701.dat',
#       'archive/histograms_20170704.dat'
#       'archive/histograms_current.dat'
       'archive/histograms_%s.dat'%(oNameTag)
        ]
    histOFileName='archive/histograms_%s.dat'%(oNameTag)
    lReadHistsFromFile=False
    lDumpHistogramsLogEventsVsTime=True

    # host analysis (only when parsing of logs is on)
    lHosts=True
    hostFileName='archive/hosts_%s.dat'%(oNameTag)

    # plotting
    oFilePrefix=oNameTag # if None, pop-up plots will appear
    lDate=False # date will appear in name of .png file
    plotsLogEventsVsTime={
        'overview': {
            'all'          : {'color':'ks-','label': 'all','lsummary':True},
            'valid'        : {'color':'go-','label':'valid','lsummary':True},
            'invalid'      : {'color':'ro-','label':'invalid','lsummary':True},
            'inconclusive' : {'color':'bo-','label':'inconclusive','lsummary':True},
            'unknown'      : {'color':'mo-','label':'unknown','lsummary':True}
            },
        'errors': {
            'all'          : {'color':'ks-','label': 'all','lsummary':True},
            'nullF10'      : {'color':'ro-','label':'NULL fort.10','lsummary':True},
            'badFLOPr'     : {'color':'co-','label':'bad FLOP ratio','lsummary':True},
            'errno=24'     : {'color':'mo-','label':'errno=24','lsummary':True},
            'errno=2'      : {'color':'yo-','label':'errno=2','lsummary':True},
            'errno=-108'   : {'color':'bo-','label':'errno=-108','lsummary':True}
        }
    }

    # stuff dependent on version of validator
    if (lValidator20170704):
        plotsLogEventsVsTime['errors']['turnx0']={'color':'go-','label':'turnx=0','lsummary':True}
        plotsLogEventsVsTime['performance']={'turnx':{'color':'ro-','label':'turnx','lsummary':False,'ylabel':'turnx'}}
        histograms1D={
            'CPUtime_client': {
                'tClaimed'     : {'color':'red','label': 'claimed', 'data': np.array([]) }
            },
            'CPUtime_fort10': {
                'tF10'         : {'color':'red','label': 'fort.10', 'data': np.array([]) }
            }
        }
        nBins1D=200

    histogramsLogEventsVsTime={}
    bins=np.array([])
    centers=np.array([])
    binWidths=np.array([])
    hosts=[]
    nWrong=0
    nInhibits=0

    # acquire existing history:
    if (lReadHistsFromFile):
        for histIFileName in histIFileNames:
            tmpHistogramsLogEventsVsTime,tmpBins,tmpCentres,tmpBinWidths=loadHistograms(histIFileName)
            histogramsLogEventsVsTime,bins,centers,binWidths=concatenateLogs(tmpHistogramsLogEventsVsTime,tmpBins,tmpCentres,tmpBinWidths,histogramsLogEventsVsTime,bins,centers,binWidths)
        
    # loading log files and plot histogramsLogEventsVsTime
    if (lLogFiles):
        iIter=0
        summaryParsing=dict((tmpKey,0) for tmpKey in RESULT().status.keys())
        for logFileName in logFileNames:
            print ' parsing %s ...'%(logFileName)
            lFirst=True
            if ( logFileName[-3:]=='.gz' ):
                iFile=gzip.open(logFileName,'rb')
            else:
                iFile=open(logFileName,'r')
            while(iIter<nMaxIter):
                logEvents,tmpNinhibits,tmpNWrong,lastPos=parseLogFile(iFile,nMaxEvents=nMaxEvents,lFirst=lFirst)
                if (len(logEvents)==0):
                    # no more events
                    break
                print ' ...acquired %i results in %i log events'%(sum([len(tmpEvent.results) for tmpEvent in logEvents]),len(logEvents))
                print ' ...computing histograms on parsed events...'
                tmpHistogramsLogEventsVsTime,tmpBins,tmpCentres,tmpBinWidths=computeLogHistograms(logEvents,plotsLogEventsVsTime,dt=dt)
                histogramsLogEventsVsTime,bins,centers,binWidths=concatenateLogs(tmpHistogramsLogEventsVsTime,tmpBins,tmpCentres,tmpBinWidths,histogramsLogEventsVsTime,bins,centers,binWidths)
                if (lHosts): 
                    print ' ...getting stats on hosts (quite lengthy process)...'
                    hosts=getHostsStatistics(logEvents,hosts=hosts)
                if (lValidator20170704):
                    # classified events
                    for tmpSeries in histograms1D.itervalues():
                        for tmpKey in tmpSeries.keys():
                            tmpArray=np.array([ tmpRes.__dict__[tmpKey] for tmpLogEvent in logEvents for tmpRes in tmpLogEvent.results if (tmpRes.__dict__[tmpKey] is not None)])
                            if (len(tmpArray)>0):
                                if (len(tmpSeries[tmpKey]['data'])>0):
                                    tmpSeries[tmpKey]['data']=np.concatenate((tmpSeries[tmpKey]['data'],tmpArray))
                                else:
                                    tmpSeries[tmpKey]['data']=tmpArray
                nInhibits+=tmpNinhibits
                nWrong+=tmpNWrong
                summaryParsing=updateSummary(logEvents,summaryParsing)
                iFile.seek(lastPos)
                iIter+=1
                del logEvents
                del tmpHistogramsLogEventsVsTime
                gc.collect()
            iFile.close()
        print ' ...summary of parsing:'
        for tmpKey in sorted(summaryParsing.keys()):
            print ' ...found %i results with state "%s";'%(summaryParsing[tmpKey],tmpKey)

    # a summary table:
    print ''
    print ' ...summary of histograms:'
    allResults=sum(histogramsLogEventsVsTime['all'])
    for tmpKey in sorted(histogramsLogEventsVsTime.keys()):
        lPrint=False
        for tmpSet in plotsLogEventsVsTime.values():
            if (tmpSet.has_key(tmpKey)):
                lPrint=tmpSet[tmpKey]['lsummary']
                break
        if lPrint:
            totResults=sum(histogramsLogEventsVsTime[tmpKey])
            print ' ...found %9i "%15s" results in total (%6.2f%%)!'%(totResults,tmpKey,totResults*100.0/allResults)
    if (nInhibits>0):
        print ' ...found %9i "%15s" results in total (%6.2f%% - not regular sequence of RESULTS#/HOST# or results not stored correctly)'%(nInhibits,'inhibited',nInhibits*100.0/allResults)
    if (nWrong>0):
        print ' ...found %9i "%15s" results in total (%6.2f%% - unrecognised error)'%(nWrong,'wrong',nWrong*100.0/allResults)

    # plotting histograms:
    print ' plotting histograms...'
    plotLogHistograms(histogramsLogEventsVsTime,centers,binWidths,plotsLogEventsVsTime,oFilePrefix=oFilePrefix,lDate=lDate)
    if (lLogFiles and lHosts):
        computeAndPlotHostsHistograms(hosts,oFileNamePrefix=oFilePrefix)

    # dumping histograms:
    if (lDumpHistogramsLogEventsVsTime):
        dumpHistograms(histogramsLogEventsVsTime,bins,centers,binWidths,histOFileName)

    # dumping data about hosts:
    if (lLogFiles and lHosts):
        dumpHostStatistics(hosts,hostFileName)

    #
    if (lValidator20170704):
        print ' 1D histograms (not vs time) ...'
        process1DHistograms(histograms1D,oFileNamePrefix=oFilePrefix,nBins=nBins1D)
        
    # done
    print '...done.'

#!/usr/bin/python

if ( __name__ == "__main__" ):

    iFileName="all_WUs.txt"
    oFileName="studies.txt"
    lPrintAssimilateState=False

    print "parsing %s file..."%(iFileName)
    studiesStates={}
    headers=None
    with open(iFileName,'r') as iFile:
        for line in iFile.readlines():
            if ( "name" in line and "assimilate_state" in line):
                headers=line.split()
                continue
            elif ( line.startswith("now:") ):
                now=line[len("now:"):].strip()
                continue
            if (headers is None):
                print "no header found or name and assimilate_state columns not in header"
                exit(1)
            for datum,fieldName in zip(line.split(),headers):
                if (fieldName=="name"):
                    studyName=datum.split("__")[0]
                    if (not studiesStates.has_key(studyName)):
                        studiesStates[studyName]={}
                        studiesStates[studyName]['assimilate_state']={}
                elif(fieldName=="assimilate_state"):
                    assimilate_state=int(float(datum))
                    if (not studiesStates[studyName]['assimilate_state'].has_key(datum)):
                        studiesStates[studyName]['assimilate_state'][datum]=0
            studiesStates[studyName]['assimilate_state']['%1i'%(assimilate_state)]+=1
        print " ...done."
    
    if (len(studiesStates)==0):
        print "no WU acquired - something wrong"
        exit(1)
    else:
        allStates=[]
        for studyName in sorted(studiesStates.keys()):
            allStates+=studiesStates[studyName]['assimilate_state'].keys()
        allStates=list(set(allStates))
        for studyName in sorted(studiesStates.keys()):
            for tmpState in allStates:
                if ( not studiesStates[studyName]['assimilate_state'].has_key(tmpState) ):
                    studiesStates[studyName]['assimilate_state'][tmpState]=0
        with open(oFileName,'w') as oFile:
            oFile.write("# found %i studies\n"%(len(studiesStates)))
            oFile.write("# status at %s\n"%(now))
            strOut="# %-58s,"%("study name")
            if (lPrintAssimilateState): strOut+=", ".join( "assimilate_state=%1s"%(key) for key in sorted(allStates) )+", "
            strOut+="%18s, %14s, %14s" %("total","assimilated [%]", "missing [%]")
            oFile.write('%s\n'%(strOut))
            for studyName in sorted(studiesStates.keys()):
                strOut="%-60s"%(studyName)
                if (lPrintAssimilateState): strOut+=" ".join( ( "%19i"%(studiesStates[studyName]['assimilate_state'][key]) for key in sorted(allStates) ) )
                tot=sum(studiesStates[studyName]['assimilate_state'].values())
                strOut+=" %18i"%(tot)
                strOut+=" % 16.3f"%(studiesStates[studyName]['assimilate_state']['2']*100.0/tot)
                strOut+=" % 15.3f"%((1-studiesStates[studyName]['assimilate_state']['2']*1.0/tot)*100)
                oFile.write('%s\n'%(strOut))
    
    exit(0)
    


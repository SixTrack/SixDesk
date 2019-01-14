#!/bin/bash

# A.Mereghetti, 2017-03-07
# job file for HTCondor as replacement of LSF

# exe/runDirBaseName are filled by run_six.sh
# please do not tuch these lines
exe=
runDirBaseName=
additionalFilesOutMAD=
additionalFilesInp6T=
# $1 is received from HTCONDOR
WUdir=$1

# echo input parameters
echo "exe: ${exe}"
echo "runDirBaseName: ${runDirBaseName}"
echo "WUdir: ${WUdir}"

# declare job has started
rm -f ${runDirBaseName}/${WUdir}/JOB_NOT_YET_STARTED
touch ${runDirBaseName}/${WUdir}/JOB_NOT_YET_COMPLETED

# prepare dir
cp ${runDirBaseName}/${WUdir}/fort.*.gz .
rm -f fort.10.gz
gunzip fort.*.gz
cp $exe sixtrack
ls -al

# additional file
for tmpFil in ${additionalFilesOutMAD[@]} ; do
    cp ${runDirBaseName}/${WUdir}/${tmpFil}.gz .
    gunzip ${tmpFil}.gz
done
for tmpFil in ${additionalFilesInp6T[@]} ; do
    cp ${runDirBaseName}/${WUdir}/${tmpFil} .
done

# actually run
./sixtrack | tail -100

# show status after run
ls -al

# usual results for DA
if [ ! -s fort.10 ] ; then
    rm -f fort.10
else
    gzip fort.10
    cp fort.10.gz ${runDirBaseName}/${WUdir}
fi

# sixout.zip
if [ -f Sixout.zip ] ; then
    cp Sixout.zip ${runDirBaseName}/${WUdir}
elif [ -f fma_sixtrack ] ; then
    # (old) results for fma analysis
    gzip fma_sixtrack
    cp fma_sixtrack.gz ${runDirBaseName}/${WUdir}
    # for debugging also copy files with particle coordinates
    dumpFiles=`ls -1 *_DUMP_* 2> /dev/null`
    if [ -n "${dumpFiles}" ] ; then
	for tmpDumpFile in ${dumpFiles} ; do
	    gzip ${tmpDumpFile}
	    cp ${tmpDumpFile}.gz ${runDirBaseName}/${WUdir}
	done
    fi
fi

# mark run as finished
rm -f ${runDirBaseName}/${WUdir}/JOB_NOT_YET_COMPLETED


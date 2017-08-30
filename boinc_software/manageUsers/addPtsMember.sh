#!/bin/bash

function howToUse(){
    cat <<EOF
    `basename $0` <list_of_users>
EOF
}

ptsGroups=( boinc:users sixtadm:sixdesk_users )

if [ $# -eq 0 ] ; then
    howToUse
    exit 1
else
    tmpUsers=$*
    tmpUsers=( ${tmpUsers} )
fi

# initial status of pts groups
for ptsGroup in ${ptsGroups[@]} ; do
    pts membership ${ptsGroup} > ${ptsGroup}_bef.txt
done

for tmpUser in ${tmpUsers[@]} ; do
    # existence of user
    lFound=`phonebook ${tmpUser} | wc -l`
    if [ ${lFound} -eq 0 ] ; then
	echo " user ${tmpUser} not found in phonebook - typo?"
	echo " aborting..."
	exit 1
    elif [ ${lFound} -gt 1 ] ; then
	echo " more than one user ${tmpUser}"
	echo " aborting..."
	exit 1
    fi

    # addition to pts group
    for ptsGroup in ${ptsGroups[@]} ; do
	lFound=`pts membership ${ptsGroup} | grep ${tmpUser} | wc -l`
	if [ ${lFound} -eq 0 ] ; then
	    echo " ...adding ${tmpUser} to pts group ${ptsGroup}!"
	    pts adduser ${tmpUser} ${ptsGroup}
	    if [ `pts membership ${ptsGroup} | grep ${tmpUser} | wc -l` -eq 0 ] ; then
		echo " ...something wrong with addition!"
		echo " aborting..."
		exit 1
	    fi
	else
	    echo " ...${tmpUser} already present in pts group ${ptsGroup}!"
	fi
    done
done

# final status of pts groups
for ptsGroup in ${ptsGroups[@]} ; do
    pts membership ${ptsGroup} > ${ptsGroup}_aft.txt
done

# diff
for ptsGroup in ${ptsGroups[@]} ; do
    echo "diffs in ${ptsGroup} before/after"
    colordiff ${ptsGroup}_bef.txt ${ptsGroup}_aft.txt
    rm ${ptsGroup}_bef.txt ${ptsGroup}_aft.txt
done

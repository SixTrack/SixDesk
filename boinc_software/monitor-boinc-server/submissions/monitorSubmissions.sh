#!/bin/bash

if [ -n "$1" ] ; then
    if [ "$1" == "today" ] ; then
	rqstDate=`date +"%F"`
    elif [ "$1" == "yesterday" ] ; then
	rqstDate=`date -d "yesterday 13:00 " '+%Y-%m-%d'`
    else
	rqstDate=$1
    fi
else
    rqstDate=`date +"%F"`
fi

#
echo ""
echo "new query at: `date` - requested date: ${rqstDate}"

# get data
echo " querying data..."
./retrieveData.sh ${rqstDate}

# plot
echo " updating plots..."
sed -i "s#^today=.*#today='${rqstDate}'#" plotData.gnu
gnuplot plotData.gnu
ps2pdf submitAll_${rqstDate}.ps

# clean
echo " cleaning..."
rm submitAll_${rqstDate}.ps

#
echo " ...done."

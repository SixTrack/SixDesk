BEGIN{}
{
    if (index($2,"windows")>0) {
	totWin+=$4;
	if (index($3,"avx")>0){
	    totWinAvx+=$4;
	}
	if (index($2,"64")>0){
	    totWin64+=$4;
	}
    }
    else if (index($2,"linux")>0) {
	totLin+=$4;
	if (index($3,"avx")>0){
	    totLinAvx+=$4;
	}
	if (index($2,"64")>0){
	    totLin64+=$4;
	}
    }
    else if (index($2,"apple")>0) {
	totMac+=$4;
	if (index($3,"avx")>0){
	    totMacAvx+=$4;
	}
	if (index($2,"64")>0){
	    totMac64+=$4;
	}
    }
    else {
	totUnk+=$4;
    }
}
END{
    tot=totWin+totLin+totMac+totUnk;
    print ("====  totals  ====");
    print ("Win:",totWin,"-",totWin/tot*100.,"%");
    print ("Lin:",totLin,"-",totLin/tot*100.,"%");
    print ("Mac:",totMac,"-",totMac/tot*100.,"%");
    print ("Unk:",totUnk,"-",totUnk/tot*100.,"%");
    print ("tot []:",tot);
    print ("====    avx   ====");
    print ("Win:",totWinAvx,"-",totWinAvx/totWin*100.,"%");
    print ("Lin:",totLinAvx,"-",totLinAvx/totLin*100.,"%");
    print ("Mac:",totMacAvx,"-",totMacAvx/totMac*100.,"%");
    print ("====    64b   ====");
    print ("Win:",totWin64 ,"-",totWin64 /totWin*100.,"%");
    print ("Lin:",totLin64 ,"-",totLin64 /totLin*100.,"%");
    print ("Mac:",totMac64 ,"-",totMac64 /totMac*100.,"%");
}

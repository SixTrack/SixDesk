BEGIN {
  s=0
  n=0
  totals1=0
  totals2=0
  maxs1=-1
  maxs2=-1
  mins1=10000 
  mins2=10000 
}

{
  s++
  if(FNR==1)
  {
    nfields=split(FILENAME,fields,".")
    myname=fields[1]
    for (myi=2;myi<=nfields-2;myi++) myname=myname "." fields[myi]
    myname=myname ".sum"
    j=fields[nfields-1]
  }
  if($1=s)
  {
    if($2!=0&&$3!=0)
    {
      s2=$2
      if(s2<0)
      {
       s2=-s2
      }
      s3=$3
      if(s3<0)
      {
       s3=-s3
      }
      n=n+1
      sdiff=s2-s3
      rdiff=sdiff/s2
      print s," ",s2," ",s3," ",sdiff," ",rdiff
      totals1=totals1+s2
      totals2=totals2+s3
      if(s2<mins1)
      {
        mins1=s2
      }
      if(s3<mins2)
      {
        mins2=s3
      }
      if(s2>maxs1)
      {
        maxs1=s2
      }
      if(s3>maxs2)
      {
        maxs2=s3
      }
    }
    else
    {
      print s," ",$2," and/or ",$3," IS EQUAL to ZERO!!!"
    }
  }
  else
  {
    print s," Problem with the seed number, missing data!"
  }
}

END {
# print j," ",n," t1 ",totals1," t2 ",totals2 >> myname
  averages1=totals1/n
  averages2=totals2/n
# print j," ",n," a1 ",averages1," t1 ",totals1," a2 ",averages2," t2 ",totals2 >> myname
# print j," ",n," mins1 ",mins1," maxs1 ",maxs1, " mins2 ",mins2," maxs2 ",maxs2 >> myname
# print j," ",averages1-mins1," ",averages1," ",maxs1-averages1," ",\
#             averages2-mins2," ",averages2," ",maxs2-averages2 >> myname 
  print j," ",averages1," ",mins1," ",maxs1," ",\
              averages2," ",mins2," ",maxs2 >> myname 
}

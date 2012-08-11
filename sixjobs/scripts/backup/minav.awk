BEGIN {
  i=0
  j=0
  k=0
  l=0
  a=0
  b=100000
  e=0
  d=0
  Amax=0
  Amin=100000
  belowmin=0
}

{
  j++
  if($1!="No_fort10")
  {
    if(FNR==1)
    {
      nfields=split(FILENAME,fields,".")
      angle=fields[nfields]
      myname=fields[1]
      for (myi=2;myi<=nfields-1;myi++) myname=myname "." fields[myi]
    }
    if($7>Amax)
    {
      Amax=$7
    }
    if($6<Amin)
    {
      Amin=$6
    }
    if($4!=0)
    {
      i++
      c=sqrt($4*$4)
      a+=c
      if(c<b)
      {
         b=c
         k=j
      }
      if(c>e)
      {
        e=c
        l=j
      }
      if($5==$6)
      {
        printf("%s %d %s %.2f %s\n", "Seed #: ",j," Dynamic Aperture below: ",$6," Sigma")
        belowmin=1
      }
    }
    else
    {
      print "Seed #: ",j," all particles stable"
    }
    if($4<0)
    {
      d+=1
    }
  }
  else
  {
    print "Seed #: ",j," not yet run"
  }
}

END {
  if (i==0)
  {
    b=-Amax
    e=-Amax
    av=-Amax 
  }
  else
  {
    print "Dynamic Aperture found for ",i," Seeds"
    av=a/i
    if (i<NR)
    {
      e=-Amax 
    }
    if (belowmin==1)
    {
      b=-Amin
    }
    {printf("%s %.2f %s %s %d\n", "Minimum: ",b," Sigma"," at Seed #: ",k)}
    {printf("%s %.2f %s %s %d\n", "Maximum: ",e," Sigma"," at Seed #: ",l)}
    {printf("%s %.2f %s\n", "Average: ",av," Sigma")}
  }
  {printf("%s %d\n", "# of (Aav-A0)/A0 >10%: ",d)}
  {printf ("%s %d %.2f %.2f %.2f %d %.2f %.2f\n",myname,angle,b,av,e,d,Amin,Amax) >> myname".plot"}
}

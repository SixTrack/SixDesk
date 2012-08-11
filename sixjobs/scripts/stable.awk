BEGIN {
  s=0
}

{
  s++
  if($1!="No_fort10")
  {
    four=$4
    if(four>=0)
    {
      print s," ",four
    }
    else
    {
      four=-four
      print s," ",four
    }
  }
  else
  {
    print s," ",0
  }
}

END {
}

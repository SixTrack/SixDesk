  BEGIN  {
  }

  {
    n = split($0,tasks,",")
    for (i in tasks)  {
      spaces = gsub(/ */,"",tasks[i])
      print (tasks[i]) 
    }
  }

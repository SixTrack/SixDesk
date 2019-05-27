BEGIN {
      }

      {
      n=gsub("\r","",$0)
      print $0
      }

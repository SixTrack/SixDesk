import re


old_notation=False

with open('run_six.sh') as f:
    for line in f:
        if 'sixdeskmess=' in line:
            old_notation = True
            old_line     = line
            whitespace   = re.match(r"\s*", line).group()
            continue
        elif old_notation and 'sixdeskmess' in line:
            outid = line.split()[1]
            try:
                if int(outid)>0:
                    spce=' '
                else:
                    spce=''
            except:
                old_notation=False
                print line
                continue
            print whitespace+'sixdeskmess '+spce+outid+' '+old_line.split('=')[1],
            old_notation=False
            continue
        elif old_notation and 'sixdeskmess' not in line:
            old_notation=False
            continue
        else:
            print line,


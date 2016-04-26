import glob
import re
import numpy as np
from scipy.interpolate import griddata

dco = {}

for filename in glob.glob('DAres.lhc2016_scan_*'):
  m = re.match(r"(?:DAres\.lhc2016_scan_)(?P<chroma>[0-9]*)(?:_)(?P<octupo>[0-9]*)(?:\.)(?P<tunex>[0-9]*\.[0-9]*)(?:_)(?P<tuney>[0-9]*\.[0-9]*)(?:\.)(?P<angles>[0-9]*)", filename)
  chroma = m.group("chroma")
  octupo = m.group("octupo")
  angles = m.group("angles")
  #print "chroma:", chroma, "  octupo:", octupo, "  Angles:", angles
  with open(filename) as f:
    for line in f:
      columns  = line.split()
      aperture = columns[3]
      key = chroma+' '+octupo
      ### min aperture over angles
      dco[key] = aperture if key not in dco else min(dco[key], aperture)
      ### average aperture over angles
      #dco[key] = float(aperture)/float(angles) + (dco[key] if key in dco else 0.)

out = []
for key, value in dco.iteritems():
  out.append(key+' '+str(value))
out.sort()

xyz = zip(*[[float(val) for val in line.split()] for line in out])

grid_x, grid_y = np.mgrid[1:20:70j, 50:550:50j]
z = griddata((xyz[0], xyz[1]), xyz[2], (grid_x, grid_y), method='cubic')

x0 = [row[0] for row in grid_x]
y0 = grid_y[0]

for i in range(len(x0)):
  for j in range(len(y0)):
    print x0[i], y0[j], z[i][j]
  print

#print "#chroma octupo aperture"
#prev_chroma = None
#for line in out:
#  chroma = line.split()[0]
#  if chroma != prev_chroma:
#    print
#  prev_chroma = chroma
#  print line


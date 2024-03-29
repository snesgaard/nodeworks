import cv2
import numpy as np
import sys
from functools import reduce

print(sys.argv)

output = sys.argv[-1]
input = sys.argv[1:-1]

#ims = map(lambda p: cv2.imread(p, -1), input)
ims = [cv2.imread(p, -1) for p in input]

#print ims[0].shape
#print len(ims)

width = reduce(lambda a, b: max(a, b), map(lambda a: a.shape[1], ims), 1)
height = reduce(
    lambda a, b: a + b,
    map(lambda a: a.shape[0], ims),
    1
)

atlas = np.zeros((height, width, 4), dtype="uint8")

y = 0
for im in ims:
    h, w = im.shape[:2]
    atlas[y:y+h, :w] = im
    y = y + h

cv2.imwrite(output, atlas)

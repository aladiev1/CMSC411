import math
import struct
bin(struct.unpack('!i',struct.pack('!f',1.0))[0])
def genTable():
	for i in range(0, 32):
		print(bin(struct.unpack('!i',struct.pack('!f',math.atan(1/(2**i))))[0]))

if __name__ == "__main__":
	genTable()
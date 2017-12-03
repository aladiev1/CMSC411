import math
import struct
bin(struct.unpack('!i',struct.pack('!f',1.0))[0])

def genRecriprocalFactorialTable():
	print("RecriprocalFactorial Table-------------")
	for i in range(0, 32):
		print(hex(int(bin(struct.unpack('!i',struct.pack('!f',1 / math.factorial(i)))[0]), 2)))
	print("---------------------------------------")

def genATanTable():
	print("Atan Table-----------------------------")
	for i in range(0, 32):
		print(bin(struct.unpack('!i',struct.pack('!f',math.atan(1/(2**i))))[0]))
	print("---------------------------------------")

def genATanhTable():
	print("Atan hyperbolic Table------------------")
	for i in range(1, 32):
		print(bin(struct.unpack('!i',struct.pack('!f',math.log((1 + 1/(2**i)) / (1 - 1/(2**i)))))[0]))
	print("---------------------------------------")

		
if __name__ == "__main__":
	genATanTable()
	genATanhTable()
	genRecriprocalFactorialTable()
import ctypes

libisd = ctypes.CDLL('./isd/build/libisd.so')
DUMMER_NTHREADS = 8

# Input: Parity check matrix H
def Dummer_LW_codeword(H):
	global DUMMER_NTHREADS
	n=H.ncols()
	k=n-H.nrows()
	r=n-k
	q=2
	# Dummer terminates when found a codeword of weight not greater than w
	# ToDo: Specify the bound.
	w=floor(n*q^(k-1)*(q-1)/(q^k-1)) # Plotkin bound
	
	H=H.echelon_form()
	pivots=H.pivots()
	H=H.transpose()
	pivots_d = [elm for elm in range(n) if elm not in pivots]
	#print(H)
	#print(pivots)
	#print(pivots_d)
	len_h = int(k*(n-k))
	mat_h_type = ctypes.c_uint8 * len_h
	mat_h_listed = []
	for i in pivots_d:
		for j in [0..r-1]:
			mat_h_listed.append(ctypes.c_uint8(H[i,j]))
	res_pointer = (ctypes.c_int*int(n))(*range(int(n)))
	doom = libisd.code_LW(ctypes.c_size_t(n), ctypes.c_size_t(k), ctypes.c_size_t(w), mat_h_type(*mat_h_listed), ctypes.c_int(DUMMER_NTHREADS), ctypes.pointer(res_pointer))
	res = [0..n-1]
	for i in [0..len(pivots)-1]:
		res[pivots[i]] = res_pointer[i]
	for i in [0..len(pivots_d)-1]:
		res[pivots_d[i]] = res_pointer[len(pivots)+i]
	return vector(res)

F=GF(2)
n=30
k=15
while true:
	B=random_matrix(F,k,n)
	C=LinearCode(B)
	H = C.parity_check_matrix()
	x = C._minimum_weight_codeword()
	res = Dummer_LW_codeword(H)
	succ = (x == res) or (x.hamming_weight() == res.hamming_weight())
	if(succ):
		print("Dummer SUCCESS")
	else:
		print("Dummer FAIL!")
		print(f"Min weight codeword: wt={x.hamming_weight()}")
		print(f"Dummer found codeword: wt={res.hamming_weight()}")
		print(x)
		print(res)
		break
	

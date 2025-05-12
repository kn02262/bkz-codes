# coding: utf-8

import ctypes

libisd = ctypes.CDLL('./isd/build/libisd.so')
DUMMER_NTHREADS = 8
DUMMER_MIN_K = 8 # For k less than DUMMER_MIN_K, use GAP _minimum_weight_codeword() instead

# Input: LinearCode C
def Dummer_LW_codeword(C):
    global DUMMER_NTHREADS
    H=C.parity_check_matrix()
    n=H.ncols()
    k=n-H.nrows()
    r=n-k
    assert C.base_field().order() == 2, "Dummer: only binary codes are supported"
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
    if doom == -1: # Dummer LW failed
        return C._minimum_weight_codeword()
    res = [0..n-1]
    for i in [0..len(pivots)-1]:
        res[pivots[i]] = res_pointer[i]
    for i in [0..len(pivots_d)-1]:
        res[pivots_d[i]] = res_pointer[len(pivots)+i]
    #print(f"Dummer_LW_codeword: {res}")
    return vector(res)

def matrix_weight(B):
    c = 0
    for i in range(B.nrows()):
        c += B[i].hamming_weight()
    return c

def intersection_basis(S, B):
    # Implementation of the method from Lemma 1 of the paper: 
    # Micciancio D. - Efficient reductions among lattice problems (2007)
    #
    S = matrix(S)
    H = matrix(S.transpose().left_kernel().basis())
    assert H.ncols() == B.ncols(), f"{H.ncols()} != {B.ncols()}"
    C = H * B.transpose()
    #C = C.stack(zero_matrix(ZZ, B.nrows() - H.nrows(), B.nrows()))
    sD,sU,sV = C.smith_form(transformation=True)
    assert sD == sU * C * sV
    B_t = B.transpose() * sV
    return B_t.transpose()[::-1,:]

def intersection_basis_reduced(S, B):
    S = matrix(S)
    assert S.nrows() <= B.nrows()
    B0 = intersection_basis(S, B)
    if S.nrows() == B.nrows():
        return B0
    for i in range(S.nrows(), B.nrows()):
        Bt = B0[i:]
        C = LinearCode(Bt)
        p = C._minimum_weight_codeword()
        S = S.stack(matrix(p))
        B0 = intersection_basis(S, B)
    return B0

def proper_basis(B):
    k = B.nrows()
    A = B[:,:k]
    assert A.ncols() == k and A.nrows() == k
    return A^(-1) * B

def or_vector(a,b):
    return vector([a[i] or b[i] for i in range(len(a))])

def proj_orthogonal_vector(a,b):
    return vector([(a[i]+1)*b[i] for i in range(len(a))])

def proj_orthogonal_vector_q(a,b):
     # Projection of b orthogonal to a
     res = []
     for i in range(len(a)):
         if a[i] != 0:
             res.append(0)
         else:
             res.append(b[i])
     return vector(res)

S_epipodal = []

def orthogonal_projections(B, i, j, i_stored=0):
    global S_epipodal
    k = B.nrows()
    if B.base_ring() == GF(2):
        proj_orth = proj_orthogonal_vector
    else:
        proj_orth = proj_orthogonal_vector_q
    assert i < k and i >= 0 and i <= j
    assert j >= 0
    if i == 0:
        return matrix(B.base_ring(), B[i:j+1,:])
    # Build a proj system
    for i0 in range(i_stored, i):
        S_epipodal[i0+1] = or_vector(S_epipodal[i0], B[i0])
    prj = []
    for i0 in range(i, min(j+1,k)):
        pr = proj_orth(S_epipodal[i], B[i0])
        prj.append(pr)
    B = matrix(B.base_ring(), prj)
    return B

def insert_primitive(B, p):
    k = B.nrows()
    B = copy(B)
    B0 = copy(B)
    a = B.solve_left(p)
    assert a * B == p
    m = infinity
    for i in range(0,B.nrows()):
        if a[i] != 0:
            m = i
            break
    B[m] = p
    B.swap_rows(0, m)
    B_proj = orthogonal_projections(B, 1, k - 1)
    B_proj_ech = B_proj.echelon_form()
    T = B_proj.solve_left(B_proj_ech)
    assert T.nrows() == k-1
    assert T.ncols() == k-1
    T1 = block_diagonal_matrix(identity_matrix(1), T)
    B = T1 * B
    A = B0.solve_left(B)
    assert (A*B0).rank() == k
    assert (A*B0)[0] == p
    #assert (A*B0)[0].hamming_weight() == p.hamming_weight(), f"{(A*B0)[0].hamming_weight()} != {p.hamming_weight()}"
    return A

def MW_Codeword_fast(B, proj_system):
    zero_pos = []
    for i in [0..len(proj_system)-1]:
        if(proj_system[i] == 1):
            zero_pos.append(i)
    B=B.delete_columns(zero_pos)
    C = LinearCode(B)
    p = C._minimum_weight_codeword()
    res = []
    ptr = 0
    for i in [0..len(proj_system)-1]:
        if i in zero_pos:
            res.append(0)
        else:
            res.append(p[ptr])
            ptr = ptr + 1
    return vector(res)

def bkz(B, beta, preproc=[], dummer=True):
    global DUMMER_MIN_K, S_epipodal
    k = B.nrows()
    # Never use Dummer in q-ary case, of if Dummer is manually disabled
    if B.base_ring() != GF(2) or (not dummer):
        DUMMER_MIN_K = B.ncols()+1;
    assert 2 <= beta and beta <= k
    B = preprocess(B, algs=preproc)
    # Prepare S_epipodal
    S_epipodal = matrix(B.base_ring(), B.nrows()+1, B.ncols())
    S_epipodal[0] = vector([0 for x in range(B.ncols())])
    i = 0
    i_stored = 0
    while i < k - 1:
        j = min(i+beta-1, k-1)
        B_proj = orthogonal_projections(B, i, j, i_stored)
        i_stored = i
        p = MW_Codeword_fast(B_proj, S_epipodal[i])
        if B_proj[0].hamming_weight() == p.hamming_weight():
            i = i + 1
        else:
            A = insert_primitive(B_proj, p)
            T = block_diagonal_matrix(identity_matrix(i), A, identity_matrix(k-j-1))
            B = T * B
            i = max(0, i-beta+1)
            i_stored = 0
        #print(f"i = {i} / {k-1}")
    return B

def bkz_v2(B, beta):
    k = B.nrows()
    assert 2 <= beta and beta <= k
    i = 0
    while i < k - 1:
        j = min(i+beta-1, k-1)
        B_proj = orthogonal_projections(B, i, j)
        C = LinearCode(B_proj)
        p = C._minimum_weight_codeword()
        if B_proj[0].hamming_weight() == p.hamming_weight():
            i = i + 1
        else:
            B_proj_t = intersection_basis(p, B_proj)
            assert B_proj_t[0].hamming_weight() == p.hamming_weight(), f"{B_proj_t[0].hamming_weight()} != {p.hamming_weight()}"
            A = B_proj.solve_left(B_proj_t)
            T = block_diagonal_matrix(identity_matrix(i), A, identity_matrix(k-j-1))
            B = T * B
            i = max(0, i-beta+1)
    return B

def lll(B):
    return bkz(B, 2)

def lll_v2(B):
    return bkz_v2(B, 2)

def epipodal_vector(B, i):
    # Build a proj system
    p = vector([0 for x in range(B.ncols())])
    for i0 in range(i):
        p = or_vector(p, B[i0])
    return proj_orthogonal_vector_q(p,B[i])

def epipodal_matrix(B):
    Bp = []
    p = vector([0 for x in range(B.ncols())])
    for i in range(B.nrows()):
        Bp.append(proj_orthogonal_vector_q(p, B[i]))
        p = or_vector(p, B[i])
    return matrix(Bp)

def ell(B, i):
    return epipodal_vector(B, i).hamming_weight()

def ell_profile(B):
    return [epipodal_vector(B, i).hamming_weight() for i in range(B.nrows())]

def get_k1(ells):
    return len([x for x in ells if x != 1])    

def epi_sort(B):
    k = B.nrows()
    n = B.ncols()
    if B.base_ring() == GF(2):
        proj_orth = proj_orthogonal_vector
    else:
        proj_orth = proj_orthogonal_vector_q
    p = vector([0 for x in range(n)])
    for i in range(k):
        best_j = i
        best_w = proj_orth(p, B[i]).hamming_weight()
        for j in range(i+1,k):
            w = proj_orth(p, B[j]).hamming_weight()
            if w < best_w:
                best_w = w
                best_j = j
        if i != best_j:
            B.swap_rows(i, best_j)
        p = or_vector(p, B[i])
    return

def subfields_basis(B):
    F = B.base_ring()
    sf = sorted(F.subfields(), key=lambda x: x[0].degree())
    C = LinearCode(B)
    S = matrix(B.base_ring(), 0, B.ncols())
    found = False
    for i in range(len(sf)):
        s = sf[i][0]
        C_s = codes.SubfieldSubcode(C, s, sf[i][1])
        G_s = C_s.generator_matrix()
        for j in range(G_s.nrows()):
            S0 = S.stack(G_s[j])
            if S0.rank() == S.rank() + 1:
                S = S0
            if S.rank() == B.nrows():
                found = True
                break
        if found:
            break
    assert S.nrows() == B.nrows()
    A = B.solve_left(S)
    assert S == A*B
    assert not A.is_singular()
    B = S
    return B

def randomize(B):
    while True:
        G = random_matrix(B.base_ring(), B.nrows(), B.nrows())
        if not G.is_singular():
            break
    return G,G*B

def preprocess(B, algs=["systemize", "episort"]):
    for i in range(len(algs)):
        if algs[i] == 'systemize':
            B = proper_basis(B)
        elif algs[i] == 'randomize':
            _,B = randomize(B)
        elif algs[i] == 'episort':
            B = copy(B)
            epi_sort(B)
        elif algs[i] == 'subfields':
            B = subfields_basis(B)
    return B

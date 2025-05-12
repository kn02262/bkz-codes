# This is a hack to run examples from parent directory
import os
import sys
sys.path.append(os.path.dirname(__file__) + "/../")

#load("bkz.sage") # use this instead of import to run code without compilation of binary module
from bkz import *

for r in range(4, 10):
    q = 2^r
    #print(f"q = {q}")
    k.<a> = GF(q)
    A.<x,y> = AffineSpace(k, 2)
    C0 = EllipticCurve_from_j(k.random_element())
    f,h = C0.hyperelliptic_polynomials()
    C = Curve(y^2 + y*h - f)
    print(f"{C}")
    F = C.function_field()
    pls = F.places()
    Q, = C.places_at_infinity()
    pls.remove(Q)
    #E = floor(q-sqrt(q)-1)*Q
    E = floor(C0.order() / 2)*Q
    C = codes.EvaluationAGCode(pls, E)
    B = C.generator_matrix()
    while True:
        G = random_matrix(k, B.nrows())
        if not G.is_singular():
            break
    P = Permutations(B.ncols()).random_element()
    P = matrix(P)
    B = G*B*P
    #print("Input matrix:")
    #print(B)
    print(f"dimensions: {B.nrows()} x {B.ncols()}")
    #print(f"#Supp(C) = {len(C.support())}")
    print(f"weight: {matrix_weight(B)}")
    #print(f"epipodal_matrix:\n{epipodal_matrix(B)}")
    print(f"profile: {ell_profile(B)}")
    B = proper_basis(B)
    print(f"weight (proper basis): {matrix_weight(B)}")
    #print(f"epipodal_matrix:\n{epipodal_matrix(B)}")
    #print(f"weight (epipodal_matrix): {matrix_weight(epipodal_matrix(B))}")
    print(f"profile: {ell_profile(B)}")

    epi_sort(B)
    print(f"profile (after episort): {ell_profile(B)}")

    for beta in range(2,3+1):
        print(f"beta = {beta}")
        t = walltime()
        B_red = bkz(B, beta)
        print(f"weight (method 1): {matrix_weight(B_red)}, {walltime() - t} sec.")
        A = B.solve_left(B_red)
        #print(f"epipodal_matrix:\n{epipodal_matrix(B)}")
        assert not A.is_singular()
        print(f"profile: {ell_profile(B_red)}")

        t = walltime()
        B_red = bkz_v2(B, beta)
        print(f"weight (method 2): {matrix_weight(B_red)}, {walltime() - t} sec.")
        A = B.solve_left(B_red)
        assert not A.is_singular()
        print(f"profile: {ell_profile(B_red)}")
        print("-" * 40)
    print("*" * 40)

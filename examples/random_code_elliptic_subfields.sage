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
    G,_ = randomize(B)
    P = Permutations(B.ncols()).random_element()
    P = matrix(P)
    B = G*B*P
    
    #print("Input matrix:")
    #print(B)
    print(f"dimensions: {B.nrows()} x {B.ncols()}")
    print(f"weight: {matrix_weight(B)}")
    print(f"profile: {ell_profile(B)}")

    B_red = subfields_basis(B)
    A = B.solve_left(B_red)
    assert not A.is_singular()
    B = matrix(k, B_red)
    print(f"weight (transformed basis): {matrix_weight(B)}")
    print(f"profile: {ell_profile(B)}")
    
    B = proper_basis(B)
    #print(f"proper basis:\n{B}")
    print(f"weight (proper basis): {matrix_weight(B)}")
    #print(f"epipodal_matrix:\n{epipodal_matrix(B)}")
    #print(f"weight (epipodal_matrix): {matrix_weight(epipodal_matrix(B))}")
    print(f"profile: {ell_profile(B)}")

    epi_sort(B)
    print(f"profile (after episort): {ell_profile(B)}")
    
    while True:
        if B[:B.nrows()].rank() != B.nrows():
            P0 = Permutations(B.ncols()).random_element()
            B = B * P0 # don't forget to apply inverse transform later
        else:
            break

    for beta in range(2,4+1):
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

# This is a hack to run examples from parent directory
import os
import sys
sys.path.append(os.path.dirname(__file__) + "/../")

#load("bkz.sage") # use this to run code without compilation of binary module
from bkz import *

n = 256
k = 128

while True:
    B = random_matrix(GF(3), k, n)
    if B[:,:k].rank() == k:
        break

assert B.rank() == B.nrows()
print("Input matrix:")
print(B)
print(f"dimensions: {B.nrows()} x {B.ncols()}")
print(f"weight: {matrix_weight(B)}")
print(f"profile: {ell_profile(B)}")

B = proper_basis(B)
print(f"weight (proper basis): {matrix_weight(B)}")
print(f"profile: {ell_profile(B)}")

epi_sort(B)
print(f"weight (after episort): {matrix_weight(B)}")
print(f"profile: {ell_profile(B)}")

for beta in range(2,4+1):
    print(f"beta = {beta}")
    t = walltime()
    B_red = bkz(B, beta)
    print(f"weight (method 1): {matrix_weight(B_red)}, {walltime() - t} sec.")
    A = B.solve_left(B_red)
    assert not A.is_singular()
    print(f"profile: {ell_profile(B_red)}")

    t = walltime()
    B_red = bkz_v2(B, beta)
    print(f"weight (method 2): {matrix_weight(B_red)}, {walltime() - t} sec.")
    A = B.solve_left(B_red)
    assert not A.is_singular()
    print(f"profile: {ell_profile(B_red)}")

    print("-------")

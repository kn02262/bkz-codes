# This is a hack to run examples from parent directory
import os
import sys
sys.path.append(os.path.dirname(__file__) + "/../")

#load("bkz.sage") # use this to run code without compilation of binary module
from bkz import *

import cProfile
import pstats
from pstats import SortKey
profile = cProfile.Profile()

rate = 0.5
#n = 1280
n = 1280
k = floor(n*rate)

while True:
    B = random_matrix(GF(2), k, n)
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

# t = walltime()
# profile.enable()
# epi_sort(B)
# profile.disable()
# profile.create_stats()
# print(f"weight (after episort): {matrix_weight(B)}, {walltime() - t} sec.")
# print(f"profile: {ell_profile(B)}")
# pstats.Stats(profile).strip_dirs().sort_stats(SortKey.CUMULATIVE).print_stats(int(50))

profile = cProfile.Profile()

for beta in [2] + list(range(6,32)):
    
    print(f"beta = {beta}", flush=True)
    t = walltime()

    profile.enable()
    B_red = bkz(B, beta)
    profile.disable()
    profile.create_stats()
    print(f"weight (method 1): {matrix_weight(B_red)}, {walltime() - t} sec.")
    A = B.solve_left(B_red)
    assert not A.is_singular()
    print(f"profile: {ell_profile(B_red)}", flush=True)
    
    print("*" * 30 + " Profiler report " + "*" * 30)
    pstats.Stats(profile).strip_dirs().sort_stats(SortKey.CUMULATIVE).print_stats(int(50))

    # t = walltime()
    # B_red = bkz_v2(B, beta)
    # print(f"weight (method 2): {matrix_weight(B_red)}, {walltime() - t} sec.")
    # A = B.solve_left(B_red)
    # assert not A.is_singular()
    # print(f"profile: {ell_profile(B_red)}")
    print("-------")
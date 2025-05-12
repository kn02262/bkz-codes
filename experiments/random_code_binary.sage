# This is a hack to run examples from parent directory
import os
import sys
sys.path.append(os.path.dirname(__file__) + "/../")

#load("bkz.sage") # use this to run code without compilation of binary module
from bkz import *

import numpy
import argparse
import cProfile
import pstats
from pstats import SortKey
profile = cProfile.Profile()

#rate = 0.5
#n = 1280
#n = 1280
#k = floor(n*rate)

parser = argparse.ArgumentParser(description='This script selects random matrices and computes average metrics for reduced matrices.')
parser.add_argument("-n", required=False, type=Integer, default=1280, help='length of code.')
parser.add_argument("-r", required=False, dest="rate", type=RR, default=0.5, help='rate of code.')
parser.add_argument("-k", required=False, type=Integer, help='dimension of code, default=rate*n.')
parser.add_argument("-s", required=False, type=Integer, dest="samples", default=10, help='number of samples.')
parser.add_argument("-bs", required=False, dest="beta", type=Integer, default=[2,4], nargs=2, help='beta, start/end values for block size of BKZ.')
parser.add_argument("-sq", dest="subsequent", required=False, action=argparse.BooleanOptionalAction, default=False, help="Subsequently reduce input matrix with block sizes beta_start ... beta_end")
parser.add_argument("--dummer", dest="dummer", required=False, action=argparse.BooleanOptionalAction, default=False, help="Use Dummer's algorithm to compute minimum weight codewords.")
parser.add_argument("--episort", dest="episort", required=False, action=argparse.BooleanOptionalAction, default=False, help="Use episort as preprocessing.")

args = parser.parse_args()

if args.k == None:
    args.k = floor(args.n * args.rate)

stats = {}

def update_avg(category):
    global stats
    if category not in stats:
        return
    if "k1" in stats[category]:
        stats[category]["k1_mean"] = numpy.mean(stats[category]["k1"])
    if "ells" in stats[category]:
        ells = stats[category]["ells"]
        stats[category]["ell_mean"] = []
        for i in range(len(ells[0])):
            ell_i_mean = numpy.mean([ells[j][i] for j in range(len(ells))])
            stats[category]["ell_mean"].append(ell_i_mean)

def collect_stats(B, category):
    global stats
    ellprof=ell_profile(B)
    print(f"profile: {ellprof}")
    k1 = get_k1(ellprof)
    print(f"k1 = {k1}")
    if category not in stats:
        stats[category] = {}
    if "k1" in stats[category]:
        stats[category]["k1"] += [k1]
    else:
        stats[category]["k1"] = [k1]
    if "ells" not in stats[category]:
        stats[category]["ells"] = [ellprof]
    else:
        stats[category]["ells"] += [ellprof]
    update_avg(category)

for sample in range(1,args.samples+1):
    print("*"*20 + f" Sample {sample} " + "*"*20)

    while True:
        B = random_matrix(GF(2), args.k, args.n)
        if B[:,:args.k].rank() == args.k:
            break

    assert B.rank() == B.nrows()
    print("Input matrix:")
    print(B)
    print(f"dimensions: {B.nrows()} x {B.ncols()}")
    print(f"weight: {matrix_weight(B)}")
    print(f"profile: {ell_profile(B)}")

    B = proper_basis(B)
    print(f"weight (proper basis): {matrix_weight(B)}")
    collect_stats(B, "proper_basis")
    print(f"\nCurrent stats for 'proper_basis':\n", stats["proper_basis"])

    if args.episort:
        t = walltime()
        profile.enable()
        epi_sort(B)
        profile.disable()
        profile.create_stats()
        print(f"weight (after episort): {matrix_weight(B)}, {walltime() - t} sec.")
        print(f"profile: {ell_profile(B)}")
        pstats.Stats(profile).strip_dirs().sort_stats(SortKey.CUMULATIVE).print_stats(int(50))
        collect_stats(B, "episort")
        print(f"\nCurrent stats for 'episort':\n", stats["episort"])

    profile = cProfile.Profile()

    for beta in range(args.beta[0], args.beta[1]+1):    
        print(f"\nbeta = {beta}", flush=True)
        t = walltime()

        profile.enable()
        B_red = bkz(B, beta, dummer=args.dummer)
        profile.disable()
        profile.create_stats()
        A = B.solve_left(B_red)
        assert not A.is_singular()
        collect_stats(B_red, f"bkz_{beta}")
        print(f"\nCurrent stats for 'bkz_{beta}':\n", stats[f"bkz_{beta}"])
        #print(f"profile: {ell_profile(B_red)}", flush=True)
            
        print("*" * 30 + " Profiler report " + "*" * 30)
        pstats.Stats(profile).strip_dirs().sort_stats(SortKey.CUMULATIVE).print_stats(int(50))
        print("-------")
        
        if args.subsequent:
            B = B_red

    print("\n")

print(f"Raw statistics:\n{stats}\n")

for k,v in stats.items():
    print(f"{k}:")
    print(f"\tk1_mean: {v['k1_mean']}")
    print(f"\tell_mean: {v['ell_mean']}")
    print()

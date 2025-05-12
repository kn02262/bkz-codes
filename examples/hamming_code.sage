# This is a hack to run examples from parent directory
import os
import sys
sys.path.append(os.path.dirname(__file__) + "/../")

#load("bkz.sage") # use this instead of import to run code without compilation of binary module
from bkz import *
from MarquezCorbella import *

r=2
q = 3^r
#print(f"q = {q}")
F.<a> = GF(q)
alpha = F.primitive_element()
P.<X,Y,Z> = ProjectiveSpace(F, 2)
C = Curve([Y^3*Z+Y*Z^3-X^4], P); # Hermitian curve
print(f"{C}")
g=3;
RatPts = C.rational_points();
m=8;
E=C.divisor([ (m, RatPts[1]) ]);
print(f"{E}")
dimE=m+1-g;
print(f"k={dimE}");
Q=RatPts[1];
CodePts=[];
n=17;
#n=len(RatPts)-2
for i in [2..n+1]:
    CodePts.append(RatPts[i]);
print(f"n={n}");
G=matrix(F, dimE, n);
for i in [0..n-1]:
    G[0,i] = 1; # f0 = 1
    G[1,i] = CodePts[i][0] / CodePts[i][2]; # f1 = x = X/Z
    G[2,i] = CodePts[i][1] / CodePts[i][2]; # f2 = y = Y/Z
    G[3,i] = (CodePts[i][0] / CodePts[i][2])^2; # f3 = x^2 = (X/Z)^2
    G[4,i] = (CodePts[i][0] / CodePts[i][2])*(CodePts[i][1] / CodePts[i][2]); # f4 = x*y = (X/Z)*(Y/Z)
    G[5,i] = (CodePts[i][1] / CodePts[i][2])^2; # y^2
    #G[6,i] = (CodePts[i][0] / CodePts[i][2])^3; # x^3
print('G matrix:');
print(G)
print('G subfield basis:');
print(subfields_basis(G))
print('Proper basis for G:');
G = proper_basis(G);
print(G);
print("H(2) Matrix from G:");
H=MarCorMatrix(G);
print(H);
print(f"wt(H(2))={matrix_weight(H)}");
#H=proper_basis(H); ToDo: Rewrite proper_basis() s.t. A must not be non-singular
for beta in range(2,3+1):
	print(f"wt(bkz(H(2),{beta}))={matrix_weight(bkz(H, beta))}");






# codes-red
To build submodule isd, run in directory 'isd/':
```bash
cmake -B build -DDUMER_L=6 -DDUMER_P=4 -DDUMER_EPS=6 -DDUMER_DOOM=0 -DDUMER_LW=1 && cmake --build build/
```

To build binary modules use
```bash
make
```

or

```bash
make DUMER_L=6 DUMER_P=4 DUMER_EPS=6
```
for tweaking of parameters of Dumer's subroutine.

Now experiments can be performed by
```
sage experiments/random_code_binary.sage
```

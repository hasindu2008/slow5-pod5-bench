# Results

**UPDATE**

 ### NA12878 subsample (500,000 reads)

Conversion (done on server with SSD using 40 threads/processes):
```
 slow5tools f2s:      98.208s
 slow5tools cat:      52.703s
 pod5-convert-fast5:  137.51s

 merged_zstd.blow5 37G
 pod5/output.pod5 37G
  ```

### Benchmark 1

On server with SSD using:
```
BLOW5:  55.969939 s
POD5:   151.387814
```

On server with NAS:
```
BLOW5: 89.589880
POD5:  254.235119
```

### NA12878 prom (9.1M reads)

On server with NAS:
```
BLOW5: 1839.534667s # 1321.919755s for disk operations, rest for decompression and parsing
POD5:  4933.334736s
```

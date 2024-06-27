## Experiment setup

### Datasets

Two datasets are used:
1. [HG002 PromethION 40X](https://gentechgp.github.io/gtgseq/docs/data.html#na24385-hg002-promethion-data-40x)
2. [HG002 PromethION 20X](https://gentechgp.github.io/gtgseq/docs/data.html#na24385-hg002-promethion-data-20x)

### System information

- Server with SSD: 20-core (40-threads) Intel(R) Xeon(R) Silver 4114 CPU, 377 GB of RAM, Ubuntu 18.04.5 LTS, local NVME SSD storage
- Server with NFS: same above server with  network file system mounted over NFS (A synology NAS with traditional spinning disks with RAID)

### Software versions used

- slow5lib bench branch commit 9ebde8f
- pod5 library 0.3.2

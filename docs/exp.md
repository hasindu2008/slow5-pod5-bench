

## Experiment setup

### Datasets

**UPDATE**
Two datasets are used:
1. NA12878 subset contains 500,000 reads. Download the [subset of Nanopore WGS of NA12878 from SRA](https://www.ncbi.nlm.nih.gov/sra?linkname=bioproject_sra_all&from_uid=744329).
2. NA12878 promethION sample containing 9.1M reads. Download the [Nanopore WGS of NA12878 - raw signal data from SRA](https://www.ncbi.nlm.nih.gov/sra?linkname=bioproject_sra_all&from_uid=744329).


### System information

**UPDATE**
Server with SSD: 20-core (40-threads) Intel(R) Xeon(R) Silver 4114 CPU, 377 GB of RAM, Ubuntu 18.04.5 LTS, local NVME SSD storage
Server with NFS: same above server with  network file system mounted over NFS (A synology NAS with traditional spinning disks with RAID)



### Software versions used

slow5lib dev branch
pod5 library vxxxx

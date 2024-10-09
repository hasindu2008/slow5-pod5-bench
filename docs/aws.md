# AWS setup

```
aws s3 cp /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads.pod5 s3://slow5test/
aws s3 cp /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads_zstd-sv16-zd.blow5 s3://slow5test/
aws s3 cp /home/hasindu/scratch/hg2_prom_lsk114_5khz/500k.list s3://slow5test/
```

1. Select c5a.16xlarge, Ubuntu 24.04, 32GB gp3 disk, make sure to add key-pair
2. ssh with the key
3. copy/clone the slow5-pod5-bench recursively [check if commit is c254055ea7811ce3daec541141a8608d5dc15243 for slow5lib]

```
git clone --recursive git@github.com:hasindu2008/slow5-pod5-bench.git
cd slow5-pod5-bench
```

4. install packages
```
sudo apt-get update
sudo apt-get install -y gcc-10 g++-10 zlib1g-dev make
```

5. follow instructions in [slow5-pod5-bench/slow5](../slow5) to build the slow5 benchmarks or just the following:

```
cd slow5/
./build_cxxpool.sh
cd ..
```

7. follow instructions in [slow5-pod5-bench/pod5](../pod5) to build the pod5 benchmarks  or just the following:
```
cd pod5/
wget https://github.com/nanoporetech/pod5-file-format/releases/download/0.3.2/lib_pod5-0.3.2-linux-x64.tar.gz
tar -xvf lib_pod5-0.3.2-linux-x64.tar.gz -C pod5_format
export LD_LIBRARY_PATH=$PWD/pod5_format/lib
./build.sh
cd ..
```

8. clean_fscache
```
cd ..
git clone https://github.com/hasindu2008/biorand/
cd biorand
gcc-10 -Wall clean_fscache.c -o clean_fscache
sudo chown root:root clean_fscache && sudo chmod +s clean_fscache
sudo mv clean_fscache /usr/local/bin/
clean_fscache
cd ..
```


# S3fs

```
sudo apt install s3fs
mkdir ./s3
s3fs slow5test ./s3/ -o public_bucket=1  -o url=http://s3.amazonaws.com/ -o dbglevel=info -o curldbg -o umask=0005 -o  uid=$(id -u)
```

Run:
```
manualbench/system/run-seq-aws-s3.sh
```

# FSx for Lustre

## provision the foollowing

1. Deployment and storage type: Persistent SSD, Throughput per unit of storage: 125 MB/s/TiB,  Storage capacity: 2.4TB, no compression, Throughput capacity = 300MB/s

2. Persistent, HDD with SSD cache, 12 MB/s/TiB, 6 TiB, no compression

Data repository association information: 
File system path: /data
Data repository path: s3://slow5test/

## Machine setup - Need ubuntu 22 for lustre

1. Select c5a.16xlarge, Ubuntu 22.04, 32GB gp3 disk, make sure to add key-pair
2.  IMPORTANT: Right click on instance -> change security group -> ADD the default security group

3. Follow 2-8 above under s3
   
4. lustre setup
```
wget -O - https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-ubuntu-public-key.asc | gpg --dearmor | sudo tee /usr/share/keyrings/fsx-ubuntu-public-key.gpg >/dev/null
sudo bash -c 'echo "deb [signed-by=/usr/share/keyrings/fsx-ubuntu-public-key.gpg] https://fsx-lustre-client-repo.s3.amazonaws.com/ubuntu jammy main" > /etc/apt/sources.list.d/fsxlustreclientrepo.list && apt-get update'
sudo apt install -y linux-aws lustre-client-modules-aws && sudo reboot
sudo apt install -y lustre-client-modules-aws
sudo apt-get install -y  linux-image-6.5.0-1024-aws
sudo sed -i 's/GRUB_DEFAULT=.\+/GRUB\_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux 6.5.0-1024-aws"/' /etc/default/grub
sudo update-grub
sudo reboot
sudo mkdir /fsx
sudo mount -t lustre -o relatime,flock fs-08c831373173eaa2a.fsx.us-east-1.amazonaws.com@tcp:/2zv2zb4v /fsx
nohup find /fsx/data -type f -print0 | xargs -0 -n 1 -P 8 sudo lfs hsm_restore &
# check if available:
lfs hsm_action /fsx/data/PGXXXX230339_reads_zstd-sv16-zd.blow5
```

5. run
```
sceen
cd ~/slow5-pod5-bench/slow5
manualbench/system/run-seq-aws-lustre.sh
```

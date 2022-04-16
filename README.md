# XRP: In-Kernel Storage Functions with eBPF

This repository contains source code and instructions to reproduce key results in the XRP paper (to appear in OSDI '22). A draft of the paper is added to this repository.

XRP requires a low latency NVMe SSD so that the overhead of Linux storage stack is significant. We use Intel Optane SSD P5800X in all the experiments. We provide SSH access to a host equipped with P5800X for artifact reviewers. Reviewers can find the credential on HotCRP. We assume that the operating system is Ubuntu 20.04 and there are 6 physical CPU cores on the machine. Other configurations may require changing the scripts accordingly.

There are four major components:
* Modified Linux kernel (based on v5.12) that supports XRP
* BPF-KV: A simple key-value store using XRP to accelerate both point and range lookups
* Modified WiredTiger (based on v4.4.0) with XRP support
* My-YCSB: An efficient YCSB benchmark written in C++ for WiredTiger

There are also four specialized versions of BPF-KV. We use them to evaluate the performance of SPDK and io_uring with both closed-loop and open-loop load generators.

## Getting Started

First, clone this repository in a folder that is large enough to compile Linux kernel:
```
$> git clone https://github.com/xrp-project/XRP.git
$> cd XRP
```



Compile and install Linux kernel:

```
$> ./build_and_install_kernel.sh
```
This step will take some time since it needs to download the source code, install dependencies, and compile the kernel from scratch.



After the kernel is compiled and installed, you will be prompted to reboot into the XRP kernel:
```
$> sudo grub-reboot "Advanced options for Ubuntu>Ubuntu, with Linux 5.12.0-xrp+"
$> sudo reboot
```
Note that other components can only be compiled when you are in the XRP kernel.



Then, build and install BPF-KV:
```
$> ./build_and_install_bpfkv.sh
```
There are some places in the specialized BPF-KV where we hardcoded the disk name at compile time. We assume `/dev/nvme0n1` is used as the storage device. If you want to choose another disk, you can specify it by `./build_and_install_bpfkv.sh [disk name(e.g., /dev/nvme1n1)]`. The test machine for reviewers can always use the default setting.

Run a simple BPF-KV test:
```
$> ./test_bpfkv.sh
```
Use `./test_bpfkv.sh [disk name]` if you need to specify a disk.



After that, compile and install both WiredTiger and My-YCSB:

```
$> ./build_and_install_wiredtiger.sh
$> ./build_and_install_ycsb.sh
```

Run a quick WiredTiger test:
```
$> ./test_wiredtiger.sh
```
Use `./test_wiredtiger.sh [disk name]` if you need to specify a disk.

## Claims and Key Results

Our modified Linux kernel includes the following parts:
* A new syscall `read_xrp`
* I/O request resubmission logic in the NVMe driver
* Metadata digest for ext4 logical-to-physical file offset translation
* A new BPF program type `BPF_PROG_TYPE_XRP`
* A new BPF hook in the NVMe driver
* An augmented BPF verifier to support XRP use cases while keeping the safty guarantees

However, our prototype also has some limitations: I/O request size is limited to 512 B, and fanout is not supported.

Here is a list of the key results in the paper:
* Table 3: Average latency of random lookup in BPF-KV
* Figure 5(a): 99-percentile latency of BPF-KV
* Figure 5(b): Single-thread throughput of BPF-KV for varying I/O index depth
* Figure 5(c): Multi-thread throughput of BPF-KV with index depth 3
* Figure 5(d): Multi-thread throughput of BPF-KV with index depth 6
* Figure 6(a): Throughput of BPF-KV using a open-loop load generator
* Figure 6(b): Latency-throughput graph of BPF-KV
* Figure 7: Average latency of range query in BPF-KV
* Figure 8(a): Throughput of WiredTiger for varying client threads
* Figure 8(b): Throughput of WiredTiger for varying cache size
* Figure 9(a): Throughput speedup of WiredTiger for varying skewness
* Figure 9(b): 99-th percentile latency of WiredTiger

The motivation graphs and numbers in the introduction section and the motivation section are out of the scope of this repository. They are already published in the HotOS '21 paper [BPF for storage: an exokernel-inspired approach](https://dl.acm.org/doi/10.1145/3458336.3465290). The source code for the HotOS '21 paper is also available: https://github.com/yuhong-zhong/bpf-storage-hotos.

Table 3, Figure 5, and Figure 6 in the draft are measured under an old version of the XRP kernel that does not have metadata digest. Therefore, the measurements may be different from the ones presented in the draft. We will revise the paper based on the new results.

## Instructions to Reproduce Key Results

For every experiment, there is a corresponding folder in the `evaluation` directory. You can run the full-length experiment by `./run_full_exp.sh` or only run a partial experiment by `./run_single_exp.sh`. To choose a disk other than `/dev/nvme0n1`, run `./run_full_exp.sh [disk name]` instead (not required on the test machine for reviewers). After running the experiment, all the raw results will be stored in the `result` folder within each experiment directory. Figures and tables can be generated using the `plot_*.py` and `get_*.py` Python scripts in each experiment folder.

Since some full-length experiments can take a few hours to finish, we recommend running partial experiments by `./run_single.exp.sh` first. For example, if you want to reproduce a specific data point in a figure or a table, you can find the corresponding experiment folder and run `./run_single_exp.sh` in it without any argument. This will print the list of required parameters for this partial experiment. Then, you can run this script again with the arguments which describe the setting of that data point. After the experiment is done, you can check out the raw result in the `result` folder. Note that even `./run_single_exp.sh` can take more than 20 minutes to finish.

For full-length experiments, each BPF-KV experiment usually terminates within one hour, while each WiredTiger experiment may need at least a few hours to finish.

Loading data into a new WiredTiger database is very time consuming. Therefore, we provide a pre-loaded WiredTiger database at `/tigerhome` on the test server. The scripts for WiredTiger experiments will copy the pre-loaded database automatically instead of creating a new one from scratch if it presents. We encourage others to also create a pre-loaded database for WiredTiger in advance. You can make a copy of the database left behind by YCSB C workload since it is read-only.

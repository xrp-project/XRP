import matplotlib
matplotlib.use('Agg')

import numpy as np
import matplotlib.pyplot as plt
import re

zipfian_constant_list = [0, 0.6, 0.7, 0.8, 0.9, 0.99, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6]
config_list = ["read", "xrp"]

perf_dict = dict()

for zipfian_constant in zipfian_constant_list:
    for config in config_list:
        with open(f"result/{zipfian_constant}-zipf-{config}.txt", "r") as fp:
            data = fp.read()
        perf_dict[(zipfian_constant, config, "average_latency")] = {
            op: float(re.search(f"{op} average latency (.*?) ns", data).group(1))
            for op in ["UPDATE", "INSERT", "READ", "SCAN", "READ_MODIFY_WRITE"]
        }
        perf_dict[(zipfian_constant, config, "p99_latency")] = {
            op: float(re.search(f"{op} p99 latency (.*?) ns", data).group(1))
            for op in ["UPDATE", "INSERT", "READ", "SCAN", "READ_MODIFY_WRITE"]
        }
        perf_dict[(zipfian_constant, config, "throughput")] = {
            op: float(re.search(f".*overall:.*{op} throughput (.*?) ops/sec", data).group(1))
            for op in ["UPDATE", "INSERT", "READ", "SCAN", "READ_MODIFY_WRITE"]
        }

plt.rcParams.update({'font.size': 22})
plt.rcParams.update({'axes.linewidth': 2})

plot_zipfian_constant_list = [0.6, 0.7, 0.8, 0.9, 0.99, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6]

plt.figure(figsize=(6.4 * 1.5, 4.8 * 1.1))
tp_speedup = np.ndarray(shape=(len(plot_zipfian_constant_list),), dtype=np.float)
plt.axhline(sum(perf_dict[(0, "xrp", "throughput")].values()) / sum(perf_dict[(0, "read", "throughput")].values()),
            ls='--', color='C1', linewidth=3, label="Uniform")
for i, zipfian_constant in enumerate(plot_zipfian_constant_list):
    tp_speedup[i] = (sum(perf_dict[(zipfian_constant, "xrp", "throughput")].values())
                     / sum(perf_dict[(zipfian_constant, "read", "throughput")].values()))
plt.plot(plot_zipfian_constant_list, tp_speedup, marker='.', markersize=20, linewidth=3, label="Zipfian")

plt.grid()
plt.legend()
plt.ylim(1, 1.4)
plt.xlabel("Zipfian Constant")
plt.ylabel("Throughput Speedup")
plt.tight_layout()
plt.savefig(f"9a.pdf", format="pdf", bbox_inches='tight', pad_inches=0.1)

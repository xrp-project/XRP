import matplotlib
matplotlib.use('Agg')
matplotlib.rcParams['pdf.fonttype'] = 42
matplotlib.rcParams['ps.fonttype'] = 42

import numpy as np
import matplotlib.pyplot as plt
import re
import itertools

config_list = ["spdk", "iouring", "read", "xrp"]
config_dict = {
    "spdk": "SPDK",
    "iouring": "io_uring",
    "read": "read",
    "xrp": "XRP",
}
layer_list = [3, 6]
thread_list = [i for i in range(1, 12 + 1)]
marker = itertools.cycle(('X', 's', 'v', 'o'))

perf_dict = dict()

for config in config_list:
    for layer in layer_list:
        for thread in thread_list:
            with open(f"result/{layer}-layer-{thread}-threads-{config}.txt", "r") as fp:
                data = fp.read()
            perf_dict[(layer, thread, config, "throughput")] = float(re.search("Average throughput: (.*?) op/s", data).group(1))
            perf_dict[(layer, thread, config, "average_latency")] = float(re.search("latency: (.*?) usec", data).group(1))
            perf_dict[(layer, thread, config, "p99_latency")] = float(re.search("99%   latency: (.*?) us", data).group(1))

plt.rcParams.update({'font.size': 16})
plt.rcParams.update({'axes.linewidth': 1.5})
plt.rcParams.update({'xtick.major.width': 1.5})
plt.rcParams.update({'ytick.major.width': 1.5})
plt.rcParams.update({'ytick.minor.width': 1.5})
fig = plt.figure(figsize=(6.4 * 1, 4.8 * 0.8))

layer = 3
for config in config_list:
    plt.plot(thread_list, [perf_dict[(layer, thread, config, "throughput")] / 1000 for thread in thread_list],
             label=config_dict[config], markersize=9, marker=next(marker), linewidth=2)
plt.xlabel("Number of Threads")
plt.ylabel("Throughput (kOps/Sec)")
plt.legend(loc="upper left")
plt.xticks(thread_list[::])
plt.ylim(bottom=0, top=500)
plt.savefig("6b.pdf", format="pdf", bbox_inches='tight', pad_inches=0.1)

max_tp_speedup = 0
min_tp_speedup = 1
max_p99_reduction = 0
min_p99_reduction = 1
for thread in thread_list:
    read_tp = perf_dict[(layer, thread, "read", "throughput")]
    read_p99 = perf_dict[(layer, thread, "read", "p99_latency")]

    xrp_tp = perf_dict[(layer, thread, "xrp", "throughput")]
    xrp_p99 = perf_dict[(layer, thread, "xrp", "p99_latency")]

    tp_speedup = (xrp_tp - read_tp) / read_tp
    p99_reduction = (read_p99 - xrp_p99) / read_p99

    max_tp_speedup = max(max_tp_speedup, tp_speedup)
    min_tp_speedup = min(min_tp_speedup, tp_speedup)

    max_p99_reduction = max(max_p99_reduction, p99_reduction)
    min_p99_reduction = min(min_p99_reduction, p99_reduction)

print(f"Throughput Speedup: {100 * min_tp_speedup:.2f}%-{100 * max_tp_speedup:.2f}%")
print(f"P99 Reduction: {100 * min_p99_reduction:.2f}%-{100 * max_p99_reduction:.2f}%")

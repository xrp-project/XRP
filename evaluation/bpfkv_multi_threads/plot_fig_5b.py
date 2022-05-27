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
            perf_dict[(layer, thread, config, "p999_latency")] = float(re.search("99.9% latency: (.*?) us", data).group(1))

plt.rcParams.update({'font.size': 16})
plt.rcParams.update({'axes.linewidth': 1.5})
plt.rcParams.update({'xtick.major.width': 1.5})
plt.rcParams.update({'ytick.major.width': 1.5})
plt.rcParams.update({'ytick.minor.width': 1.5})
fig = plt.figure(figsize=(6.4 * 1, 4.8 * 0.8))

layer = 6
for config in config_list:
    plt.plot(thread_list, [perf_dict[(layer, thread, config, "p999_latency")] for thread in thread_list],
             label=config_dict[config], markersize=9, marker=next(marker), linewidth=2)
plt.xlabel("Number of Threads")
plt.ylabel("99.9th Latency (µs)")
plt.legend()
plt.yscale("log")
plt.xticks(thread_list[::2])
plt.savefig("5b.pdf", format="pdf", bbox_inches='tight', pad_inches=0.1)

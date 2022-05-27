import matplotlib
matplotlib.use('Agg')
matplotlib.rcParams['pdf.fonttype'] = 42
matplotlib.rcParams['ps.fonttype'] = 42

import numpy as np
import matplotlib.pyplot as plt
import re
import itertools

config_list = ["spdk", "xrp"]
config_dict = {
    "spdk": "SPDK",
    "xrp": "XRP",
}
layer = 6
thread_list = [i for i in range(6, 24 + 1)]
marker = itertools.cycle(('X', 'o'))

perf_dict = dict()

for config in config_list:
    for thread in thread_list:
        with open(f"result/{thread}-threads-{config}.txt", "r") as fp:
            data = fp.read()
        perf_dict[(layer, thread, config, "throughput")] = float(re.search("Average throughput: (.*?) op/s", data).group(1))
        perf_dict[(layer, thread, config, "average_latency")] = float(re.search("latency: (.*?) usec", data).group(1))
        perf_dict[(layer, thread, config, "p99_latency")] = float(re.search("99%   latency: (.*?) us", data).group(1))

plt.rcParams.update({'font.size': 24})
plt.rcParams.update({'axes.linewidth': 2})
plt.rcParams.update({'xtick.major.width': 2})
plt.rcParams.update({'ytick.major.width': 2})
plt.rcParams.update({'ytick.minor.width': 2})

plt.axhline(700000 / 1000,
            ls='--', color='grey', linewidth=4, label="Hardware Limit")
for config_index, config in enumerate(config_list):
    plt.plot(thread_list, [perf_dict[(layer, thread, config, "throughput")] / 1000 for thread in thread_list],
             label=config_dict[config], markersize=12, marker=next(marker), linewidth=3, color=f"C{config_index * 3}")
plt.xlabel("Number of Threads")
plt.ylabel("Throughput (kOps/Sec)")
plt.legend()
plt.ylim(bottom=0)
plt.xticks(thread_list[::4])
plt.savefig("7a.pdf", format="pdf", bbox_inches='tight', pad_inches=0.1)

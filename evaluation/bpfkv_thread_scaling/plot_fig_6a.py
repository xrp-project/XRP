import matplotlib
matplotlib.use('Agg')

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
marker = itertools.cycle(('X', '.', 'v', '<', '>', 's')) 

perf_dict = dict()

for config in config_list:
    for thread in thread_list:
        with open(f"result/{thread}-threads-{config}.txt", "r") as fp:
            data = fp.read()
        perf_dict[(layer, thread, config, "throughput")] = float(re.search("Average throughput: (.*?) op/s", data).group(1))
        perf_dict[(layer, thread, config, "average_latency")] = float(re.search("latency: (.*?) usec", data).group(1))
        perf_dict[(layer, thread, config, "p99_latency")] = float(re.search("99%   latency: (.*?) us", data).group(1))

plt.axhline(700000 / 1000,
            ls='--', color='grey', linewidth=3, label="Hardware Limit")
for config in config_list:
    plt.plot(thread_list, [perf_dict[(layer, thread, config, "throughput")] / 1000 for thread in thread_list],
             label=config_dict[config], markersize=10, marker=next(marker))
plt.xlabel("Thread Number")
plt.ylabel("Throughput (kOps/Sec)")
plt.legend()
plt.ylim(bottom=0)
plt.xticks(thread_list[::2])
plt.savefig("6a.pdf", format="pdf")

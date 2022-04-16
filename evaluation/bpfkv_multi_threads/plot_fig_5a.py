import matplotlib
matplotlib.use('Agg')

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
marker = itertools.cycle(('X', '.', 'v', '<', '>', 's')) 

perf_dict = dict()

for config in config_list:
    for layer in layer_list:
        for thread in thread_list:
            with open(f"result/{layer}-layer-{thread}-threads-{config}.txt", "r") as fp:
                data = fp.read()
            perf_dict[(layer, thread, config, "throughput")] = float(re.search("Average throughput: (.*?) op/s", data).group(1))
            perf_dict[(layer, thread, config, "average_latency")] = float(re.search("latency: (.*?) usec", data).group(1))
            perf_dict[(layer, thread, config, "p999_latency")] = float(re.search("99.9% latency: (.*?) us", data).group(1))

layer = 6
for config in config_list:
    plt.plot(thread_list, [perf_dict[(layer, thread, config, "p999_latency")] for thread in thread_list],
             label=config_dict[config], markersize=10, marker=next(marker))
plt.xlabel("Threads")
plt.ylabel("99.9th Latency (µs)")
plt.legend()
plt.yscale("log")
plt.xticks(thread_list)
plt.savefig("5a.pdf", format="pdf")

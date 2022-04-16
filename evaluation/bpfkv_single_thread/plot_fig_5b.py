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
layer_list = [1, 2, 3, 4, 5, 6]
thread = 1
marker = itertools.cycle(('X', '.', 'v', '<', '>', 's')) 

perf_dict = dict()

for config in config_list:
    for layer in layer_list:
        with open(f"result/{layer}-layer-{config}.txt", "r") as fp:
            data = fp.read()
        perf_dict[(layer, thread, config, "throughput")] = float(re.search("Average throughput: (.*?) op/s", data).group(1))
        perf_dict[(layer, thread, config, "average_latency")] = float(re.search("latency: (.*?) usec", data).group(1))
        perf_dict[(layer, thread, config, "p99_latency")] = float(re.search("99%   latency: (.*?) us", data).group(1))

for config in config_list:
    plt.plot(layer_list, [perf_dict[(layer, thread, config, "throughput")] / 1000 for layer in layer_list],
             label=config_dict[config], markersize=10, marker=next(marker))
plt.xlabel("I/O Chain Length")
plt.ylabel("Throughput (kOps/Sec)")
plt.legend()
plt.ylim(bottom=0)
plt.savefig("5b.pdf", format="pdf", bbox_inches='tight', pad_inches=0.1)

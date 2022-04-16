import matplotlib
matplotlib.use('Agg')

import numpy as np
import matplotlib.pyplot as plt
import re
import itertools

config_list = ["read", "xrp"]
config_dict = {
    "read": "read",
    "xrp": "XRP",
}
range_len_list = [i for i in range(1, 100, 5)]
marker = itertools.cycle(('X', '.', 'v', '<', '>', 's')) 

perf_dict = dict()

for config in config_list:
    for range_len in range_len_list:
        with open(f"result/{range_len}-range-{config}.txt", "r") as fp:
            data = fp.read()
        perf_dict[(range_len, config, "throughput")] = float(re.search("Average throughput: (.*?) op/s", data).group(1))
        perf_dict[(range_len, config, "average_latency")] = float(re.search("latency: (.*?) usec", data).group(1))

for config in config_list:
    plt.plot(range_len_list, [perf_dict[(range_len, config, "average_latency")] for range_len in range_len_list],
             label=config_dict[config], markersize=10, marker=next(marker))
plt.xlabel("Range Length")
plt.ylabel("Average Latency (µs)")
plt.legend()
plt.ylim(bottom=0)
plt.savefig("7.pdf", format="pdf")

import numpy as np
import matplotlib.pyplot as plt
import re

config_list = ["spdk", "iouring", "read", "xrp"]
config_dict = {
    "spdk": "SPDK",
    "iouring": "io_uring",
    "read": "read",
    "xrp": "XRP",
}
layer_list = [3, 6]
thread_list = [i for i in range(1, 12 + 1)]

perf_dict = dict()

for config in config_list:
    for layer in layer_list:
        for thread in thread_list:
            with open(f"result/{layer}-layer-{thread}-threads-{config}.txt", "r") as fp:
                data = fp.read()
            perf_dict[(layer, thread, config, "throughput")] = float(re.search("Average throughput: (.*?) op/s", data).group(1))
            perf_dict[(layer, thread, config, "average_latency")] = float(re.search("latency: (.*?) usec", data).group(1))
            perf_dict[(layer, thread, config, "p99_latency")] = float(re.search("99%   latency: (.*?) us", data).group(1))

layer = 6
for config in config_list:
    plt.plot(thread_list, [perf_dict[(layer, thread, config, "throughput")] for thread in thread_list],
             label=config_dict[config], markersize=15)
plt.xlabel("Threads")
plt.ylabel("Throughput (ops/sec)")
plt.legend()
plt.savefig("5d.pdf", format="pdf")

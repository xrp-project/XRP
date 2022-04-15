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
layer_list = [1, 2, 3, 4, 5, 6]
thread = 1

perf_dict = dict()

for config in config_list:
    for layer in layer_list:
        with open(f"result/{layer}-layer-{config}.txt", "r") as fp:
            data = fp.read()
        perf_dict[(layer, thread, config, "throughput")] = float(re.search("Average throughput: (.*?) op/s", data).group(1))
        perf_dict[(layer, thread, config, "average_latency")] = float(re.search("latency: (.*?) usec", data).group(1))
        perf_dict[(layer, thread, config, "p99_latency")] = float(re.search("99%   latency: (.*?) us", data).group(1))

for config in config_list:
    plt.plot(layer_list, [perf_dict[(layer, thread, config, "throughput")] for layer in layer_list],
             label=config_dict[config], markersize=15)
plt.xlabel("I/O Chain Length")
plt.ylabel("Throughput (ops/sec)")
plt.legend()
plt.savefig("5b.pdf", format="pdf")

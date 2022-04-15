import numpy as np
import matplotlib.pyplot as plt
import re

config_list = ["spdk", "xrp"]
config_dict = {
    "spdk": "SPDK",
    "xrp": "XRP",
}
layer = 6
thread_list = [i for i in range(6, 24 + 1)]

perf_dict = dict()

for config in config_list:
    for thread in thread_list:
        with open(f"result/{thread}-threads-{config}.txt", "r") as fp:
            data = fp.read()
        perf_dict[(layer, thread, config, "throughput")] = float(re.search("Average throughput: (.*?) op/s", data).group(1))
        perf_dict[(layer, thread, config, "average_latency")] = float(re.search("latency: (.*?) usec", data).group(1))
        perf_dict[(layer, thread, config, "p99_latency")] = float(re.search("99%   latency: (.*?) us", data).group(1))

for config in config_list:
    plt.plot(thread_list, [perf_dict[(layer, thread, config, "throughput")] for thread in thread_list],
             label=config_dict[config], markersize=15)
plt.xlabel("Thread Number")
plt.ylabel("Throughput (op/s)")
plt.legend()
plt.savefig("6a.pdf", format="pdf")

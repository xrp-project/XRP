import numpy as np
import matplotlib.pyplot as plt
import re

config_list = ["spdk", "xrp"]
config_dict = {
    "spdk": "SPDK",
    "xrp": "XRP",
}
req_per_sec_list = [60000 * i for i in range(1, 12 + 1)]

perf_dict = dict()

for config in config_list:
    for req_per_sec in req_per_sec_list:
        with open(f"result/{req_per_sec}-ops-{config}.txt", "r") as fp:
            data = fp.read()
        perf_dict[(req_per_sec, config, "throughput")] = float(re.search("Average throughput: (.*?) op/s", data).group(1))
        perf_dict[(req_per_sec, config, "average_latency")] = float(re.search("latency: (.*?) usec", data).group(1))
        perf_dict[(req_per_sec, config, "p99_latency")] = float(re.search("99%   latency: (.*?) us", data).group(1))

for config in config_list:
    plt.plot([perf_dict[(req_per_sec, config, "throughput")] for req_per_sec in req_per_sec_list],
             [perf_dict[(req_per_sec, config, "average_latency")] for req_per_sec in req_per_sec_list],
             label=f"avg latency ({config_dict[config]})", markersize=15)
    plt.plot([perf_dict[(req_per_sec, config, "throughput")] for req_per_sec in req_per_sec_list],
             [perf_dict[(req_per_sec, config, "p99_latency")] for req_per_sec in req_per_sec_list],
             label=f"99% latency ({config_dict[config]})", markersize=15)
plt.xlabel("Throughput (op/s)")
plt.ylabel("Latency (usec)")
plt.legend()
plt.savefig("6b.pdf", format="pdf")

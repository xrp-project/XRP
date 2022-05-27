import matplotlib
matplotlib.use('Agg')
matplotlib.rcParams['pdf.fonttype'] = 42
matplotlib.rcParams['ps.fonttype'] = 42

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
marker = itertools.cycle(('v', 'o'))

perf_dict = dict()

for config in config_list:
    for range_len in range_len_list:
        with open(f"result/{range_len}-range-{config}.txt", "r") as fp:
            data = fp.read()
        perf_dict[(range_len, config, "throughput")] = float(re.search("Average throughput: (.*?) op/s", data).group(1))
        perf_dict[(range_len, config, "average_latency")] = float(re.search("latency: (.*?) usec", data).group(1))

plt.rcParams.update({'font.size': 24})
plt.rcParams.update({'axes.linewidth': 2})
plt.rcParams.update({'xtick.major.width': 2})
plt.rcParams.update({'ytick.major.width': 2})
plt.rcParams.update({'ytick.minor.width': 2})

for config_index, config in enumerate(config_list):
    plt.plot(range_len_list, [perf_dict[(range_len, config, "throughput")] / 1000 for range_len in range_len_list],
             label=config_dict[config], markersize=12, marker=next(marker), color=f"C{config_index + 2}", linewidth=3)
plt.xlabel("Range Length")
plt.ylabel("Throughput (kOps/Sec)")
plt.legend()
plt.ylim(bottom=0)
plt.xticks([1, 20, 40, 60, 80])
plt.savefig("8b.pdf", format="pdf", bbox_inches='tight', pad_inches=0.1)

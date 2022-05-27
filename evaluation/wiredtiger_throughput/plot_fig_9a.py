import matplotlib
matplotlib.use('Agg')
matplotlib.rcParams['pdf.fonttype'] = 42
matplotlib.rcParams['ps.fonttype'] = 42

import numpy as np
import matplotlib.pyplot as plt
import re

workload_dict = {
    "ycsb_a.yaml": "YCSB A",
    "ycsb_b.yaml": "YCSB B",
    "ycsb_c.yaml": "YCSB C",
    "ycsb_d.yaml": "YCSB D",
    "ycsb_e.yaml": "YCSB E",
    "ycsb_f.yaml": "YCSB F",
}
cache_size_dict = {
    "4096M": "4GB",
    "2048M": "2GB",
    "1024M": "1GB",
    "512M": "512MB",
}
thread_list = [
    1,
    2,
    3,
]
config_list = ["read", "xrp"]

perf_dict = dict()

for workload in workload_dict:
    cache_size = "512M"
    for thread in thread_list:
        for config in config_list:
            with open(f"result/{workload}-{cache_size}-cache-{thread}-threads-{config}.txt", "r") as fp:
                data = fp.read()
            perf_dict[(workload, cache_size, thread, config, "average_latency")] = {
                op: float(re.search(f"{op} average latency (.*?) ns", data).group(1))
                for op in ["UPDATE", "INSERT", "READ", "SCAN", "READ_MODIFY_WRITE"]
            }
            perf_dict[(workload, cache_size, thread, config, "p99_latency")] = {
                op: float(re.search(f"{op} p99 latency (.*?) ns", data).group(1))
                for op in ["UPDATE", "INSERT", "READ", "SCAN", "READ_MODIFY_WRITE"]
            }
            perf_dict[(workload, cache_size, thread, config, "throughput")] = {
                op: float(re.search(f".*overall:.*{op} throughput (.*?) ops/sec", data).group(1))
                for op in ["UPDATE", "INSERT", "READ", "SCAN", "READ_MODIFY_WRITE"]
            }
    
    thread = 1    
    for cache_size in cache_size_dict:
        for config in config_list:
            with open(f"result/{workload}-{cache_size}-cache-{thread}-threads-{config}.txt", "r") as fp:
                data = fp.read()
            perf_dict[(workload, cache_size, thread, config, "average_latency")] = {
                op: float(re.search(f"{op} average latency (.*?) ns", data).group(1))
                for op in ["UPDATE", "INSERT", "READ", "SCAN", "READ_MODIFY_WRITE"]
            }
            perf_dict[(workload, cache_size, thread, config, "p99_latency")] = {
                op: float(re.search(f"{op} p99 latency (.*?) ns", data).group(1))
                for op in ["UPDATE", "INSERT", "READ", "SCAN", "READ_MODIFY_WRITE"]
            }
            perf_dict[(workload, cache_size, thread, config, "throughput")] = {
                op: float(re.search(f".*overall:.*{op} throughput (.*?) ops/sec", data).group(1))
                for op in ["UPDATE", "INSERT", "READ", "SCAN", "READ_MODIFY_WRITE"]
            }

plt.rcParams.update({'font.size': 30})
plt.rcParams.update({'axes.linewidth': 2})

plot_workload_list = ["ycsb_a.yaml", "ycsb_b.yaml", "ycsb_c.yaml", "ycsb_d.yaml", "ycsb_e.yaml", "ycsb_f.yaml"]
plot_thread_list = [1, 2, 3]

nr_group = len(plot_workload_list)
nr_bar_per_group = len(plot_thread_list) * 2

inter_bar_width = 0.008
bar_width = 0.11

X = np.arange(nr_group)
fig = plt.figure(figsize=(6.4 * 2.2, 4.8 * 1.5))
bar_dict = dict()
for thread_index, thread in enumerate(plot_thread_list):
    color = f"C{thread_index}"
    for config_index, config in enumerate(["read", "xrp"]):
        value_arr = [sum(perf_dict[(workload, "512M", thread, config, "throughput")].values()) / 1000
                     for workload in plot_workload_list]
        bar_dict[(thread, config)] = plt.bar(X + (inter_bar_width + bar_width) * (2 * thread_index + config_index),
                value_arr, color=color, width=bar_width, alpha=0.5 if config == "xrp" else 1,
                label=f'{thread} Thread{" " if thread == 1 else "s"} ({"Baseline" if config == "read" else "XRP"})')
        for workload_index, workload in enumerate(plot_workload_list):
            x = X[workload_index] + (inter_bar_width + bar_width) * (2 * thread_index + config_index)
            x -= bar_width / 2
            y = value_arr[workload_index] + 10
            if y >= 190:
                y = 140
            value = value_arr[workload_index]
            plt.text(x, y, f"{int(value)}", rotation='vertical', fontsize=18,
                     color=color if value < 180 else 'w', fontweight='bold')

plt.ylim(0, 250)
plt.ylabel("KV Operations/Second\n(Thousands)")
plt.xticks(X + (bar_width) * (nr_bar_per_group / 2.2),
           [workload_dict[workload] for workload in plot_workload_list])

plt.tick_params(axis='y', direction='in', length=6, width=2, colors='k',
                grid_color='k', grid_alpha=0.5)
plt.tick_params(axis='x', direction='in', length=6, width=0, colors='k',
                grid_color='k', grid_alpha=0.5)
plt.xlim(-0.1, 5.7)
legend_0 = plt.legend([bar_dict[(1, "read")], bar_dict[(1, "xrp")]],
                      ["1 Thread (Baseline)", "1 Thread (XRP)"],
                      ncol=1, labelspacing=0.2, columnspacing=1, fontsize=24,
                      loc="upper left", bbox_to_anchor=(0.12, 1))
legend_1 = plt.legend([bar_dict[(2, "read")], bar_dict[(2, "xrp")], bar_dict[(3, "read")], bar_dict[(3, "xrp")]],
                      ["2 Threads (Baseline)", "2 Threads (XRP)", "3 Threads (Baseline)", "3 Threads (XRP)"],
                      ncol=1, labelspacing=0.2, columnspacing=1, fontsize=24,
                      loc="upper right", bbox_to_anchor=(1, 1))
plt.gca().add_artist(legend_0)

plt.tight_layout()
plt.savefig(f"9a.pdf", format="pdf", bbox_inches='tight', pad_inches=0.1)

max_tp_speedup = 0
for workload in workload_dict:
    cache_size = "512M"
    for thread in thread_list:
        read_tp = sum(perf_dict[(workload, cache_size, thread, "read", "throughput")].values())
        xrp_tp = sum(perf_dict[(workload, cache_size, thread, "xrp", "throughput")].values())
        tp_speedup = (xrp_tp - read_tp) / read_tp
        max_tp_speedup = max(max_tp_speedup, tp_speedup)
    thread = 1
    for cache_size in cache_size_dict:
        read_tp = sum(perf_dict[(workload, cache_size, thread, "read", "throughput")].values())
        xrp_tp = sum(perf_dict[(workload, cache_size, thread, "xrp", "throughput")].values())
        tp_speedup = (xrp_tp - read_tp) / read_tp
        max_tp_speedup = max(max_tp_speedup, tp_speedup)
print(f"Max throughput speedup: {100 * max_tp_speedup:.2f}%")

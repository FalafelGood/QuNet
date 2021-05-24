# Libraries
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.colors as colors
from scipy.stats import kde

# Set up figure

num_pairs = [1, 500, 2500]
max_paths = [1, 2, 4]

big_fig, big_axes = plt.subplots(3, 3, figsize=(20, 20))

# # Modify fonts
# plt.rcParams.update({'font.size': 12, 'font.weight': 'bold'})

nbins = 100
for i, pair in enumerate(num_pairs):
    for j, path in enumerate(max_paths):

        # Import data
        df = pd.read_csv("~/.julia/dev/QuNet/data/heatmap_data/%spair%spath.csv" % (pair, path))

        # Extract data into x, y
        e = df["Efficiency"].tolist()
        f = df["Fidelity"].tolist()

        out = big_axes[i, j].hist2d(e, f, range=((0, 1), (0.5, 1)), bins=nbins, cmap=plt.cm.plasma, norm=colors.LogNorm())
        big_axes[i, j].set_xlabel("Efficiency", fontsize=12)
        big_axes[i, j].set_ylabel("Fidelity", fontsize=12)
        big_axes[i, j].set_title("%s user pairs, %s max paths" % (str(num_pairs[i]), str(max_paths[j])), fontsize=14)

big_fig.colorbar(out[3], ax=big_axes, shrink=0.75, aspect=40)
plt.savefig("big_plot.pdf")

# High resolution plot

# Import data
df = pd.read_csv("~/.julia/dev/QuNet/data/heatmap_data/HiRes_50pair4path.csv")

# Extract data into x, y
e = df["Efficiency"].tolist()
f = df["Fidelity"].tolist()

fig, axes = plt.subplots()
nbins = 300
out = axes.hist2d(e, f, range=((0,1), (0.5, 1)), bins=nbins, cmap=plt.cm.plasma, norm=colors.LogNorm())
fig.colorbar(out[3], ax=axes)
axes.set_xlabel("Efficiency")
axes.set_ylabel("Fidelity")

e1 = np.arange(0., 1., 0.01)
f1 = 1/2 * e1 + 1/2
f2 = f1 ** 2 / (f1 ** 2 + (1 - f1) ** 2)
e2 = e1 ** 2 * (f1 ** 2 + (1 - f1) ** 2)
f3 = f1 * f2 / (f1 * f2 + (1 - f1) * (1 - f2))
e3 = e1 * e2 * (f1 * f2  + (1 - f1) * (1 - f2))
f4 = f1 * f3 / (f1 * f3 + (1 - f1) * (1 - f3))
e4 = e1 * e3 * (f1 * f3  + (1 - f1) * (1 - f3))

axes.plot(e1, f1, 'r-', linewidth=0.5)
axes.plot(e2, f2, 'r-', linewidth=0.5)
axes.plot(e3, f3, 'r-', linewidth=0.5)
axes.plot(e4, f4, 'r-', linewidth=0.5)
plt.savefig("analytic_heatmap.pdf")


# High resolution true color contour:
nbins = 100
fig, axes = plt.subplots()
out = axes.hist2d(e, f, range=((0,1), (0.5, 1)), bins=nbins, cmap=plt.cm.hot)
fig.colorbar(out[3], ax=axes)
axes.set_xlabel("Efficiency")
axes.set_ylabel("Fidelity")

# Collect data for the QKD contour plots
delta = 0.01
x = np.arange(0.0, 1.0, delta)
y = np.arange(0.5, 1.0, delta )
E, F = np.meshgrid(x, y)

# End to end failure rate of a 100 x 100 grid lattice with 50 competing user pairs
P0 = 0.201

# Average rate of transmission per user pair
R = (1-P0) * E

# QKD contour
C = R * (1 + (F * np.log(F)/np.log(2) + (1 - F) * np.log(1 - F)/np.log(2)))

# Overlay the contour for Z = 1, 2, 3, ...
CS = axes.contour(E, F, C, [0.01, 0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6], cmap="cool")
axes.clabel(CS, inline=1, fontsize=10, fmt="%1.2f")
plt.savefig("multiheat.pdf")

print("Finished!")
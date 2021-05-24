# Preceeding from heatmap.jl (start there if you haven't already)

# Libraries
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.colors as colors
from scipy.stats import kde
# This could be used for smoothing the heatmap out
# from scipy.stats import kde

# Import data
df = pd.read_csv("~/.julia/dev/QuNet/data/heatmap_data/1pair1path.csv")

# Extract data into x, y
e = df["Efficiency"].tolist()
f = df["Fidelity"].tolist()

nbins = 50
# Create a heatmap of end-user data
fig, axes = plt.subplots()
# plt.cm.hot
# plt.cm.plasma
out = axes.hist2d(e, f, range=((0,1), (0.5, 1)), bins=nbins, cmap=plt.cm.hot, norm=colors.LogNorm())
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

# Gaussian plot
# Evaluate a gaussian kde on a regular grid of nbins x nbins over data extents
fig, axes = plt.subplots()
e = np.array(e)
f = np.array(f)
k = kde.gaussian_kde([e, f])
ei, fi = np.mgrid[e.min():e.max():nbins*1j, f.min():f.max():nbins*1j]
zi = k(np.vstack([ei.flatten(), fi.flatten()]))
axes.pcolormesh(ei, fi, zi.reshape(ei.shape), shading='auto', cmap=plt.cm.hot)
plt.savefig("gaussian_plot.pdf")

# Bell plot
histdata = out[0]
#onepathdata = np.fliplr(histdata).diagonal()
onepathdata = histdata.diagonal()
plt.figure()
plt.plot(onepathdata)
plt.savefig("bell_plot.pdf")

# Line plot
fig, axes = plt.subplots()
nbins = 400
# plt.cm.hot
out = axes.hist2d(e, f, range=((0,1), (0.5, 1)), bins=nbins, cmap=plt.cm.plasma, norm=colors.LogNorm())
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
plt.savefig("linetest.pdf")







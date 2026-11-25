"""Independent Euclidean integral of I29/u using two identical one-loop triangles."""
import argparse
import numpy as np
from scipy.special import spence
from scipy.stats import qmc


def norm2(x):
    return np.einsum("ij,ij->i", x, x)


def draw_point(random, centers, size):
    # Mixture of normalized four-dimensional densities s/[r²(r²+s)²]
    # with respect to the graph measure d^4x/pi².
    location = 3 * random[:, 0]
    index = location.astype(int)
    r2 = size * (location-index) / (1-(location-index))
    t, phi, theta = random[:, 1], 2*np.pi*random[:, 2], 2*np.pi*random[:, 3]
    a, b = np.sqrt(r2*t), np.sqrt(r2*(1-t))
    point = centers[index] + np.column_stack((a*np.cos(phi), a*np.sin(phi), b*np.cos(theta), b*np.sin(theta)))
    distances = [norm2(point-c) for c in centers]
    density = sum(size/(d*(d+size)**2) for d in distances)/3
    return point, distances, density


def integrate(z, power, count):
    centers = np.array([[0.,0.,0.,0.], [z.real,z.imag,0.,0.], [1.,0.,0.,0.]])
    samples = []
    for seed in range(count):
        sampler = qmc.Sobol(8, scramble=True, seed=87901+seed)
        total = 0.
        chunk = min(power, 15)
        for _ in range(2**(power-chunk)):
            random = sampler.random(2**chunk)
            p, dp, wp = draw_point(random[:, :4], centers, 0.7)
            q, dq, wq = draw_point(random[:, 4:], centers, 0.7)
            # Integrating points 5 and 6 gives T(1,p,q)^2. Divide the
            # squared sides by the largest to keep the dilogarithm inside the disk.
            sides = np.sort(np.stack((dp[2], dq[2], norm2(p-q))), axis=0)
            u, v = sides[:2]/sides[2]
            re = (1+u-v)/2
            im = np.sqrt(np.maximum(u-re*re, 0))
            arg = re+1j*im
            triangle = (2*spence(1-arg).imag + np.log(u)*np.log(1-arg).imag)/(im*sides[2])
            total += (triangle**2/(dp[0]*dp[1]*wp*dq[0]*dq[1]*wq)).sum()
        samples.append(total/2**power)
    return float(np.mean(samples)), float(np.std(samples, ddof=1)/np.sqrt(count))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--z", type=complex, default=0.35+0.25j)
    parser.add_argument("--power", type=int, default=16)
    parser.add_argument("--scrambles", type=int, default=12)
    args = parser.parse_args()
    print("I29/u (mean and between-scramble standard error):",
          *integrate(args.z, args.power, args.scrambles))

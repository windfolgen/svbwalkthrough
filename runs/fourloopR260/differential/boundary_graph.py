"""Direct two-box representation of the signed R260 graph in the Euclidean region."""

import numpy as np
from scipy.special import spence


def norm2(a, b):
    return np.sum((a - b) ** 2, axis=-1)


def dot(a, b):
    return np.sum(a * b, axis=-1)


def box_function(u, v):
    real = (1 + u - v) / 2
    imag = np.sqrt(np.maximum(u - real**2, 0))
    z = real + 1j * imag
    return (2 * spence(1 - z).imag + np.log(u) * np.angle(1 - z)) / imag


def triangle(a, b, c):
    scale = norm2(a, c)
    return box_function(norm2(a, b) / scale, norm2(b, c) / scale) / scale


def integrate_box(origin, p, a, b, common_triangle):
    scale = norm2(origin, a) * norm2(p, b)
    box = (
        box_function(norm2(origin, p) * norm2(a, b) / scale, norm2(origin, b) * norm2(p, a) / scale)
        / scale
    )
    tri = triangle(p, a, b)
    diff = np.stack(
        (tri - common_triangle, tri - triangle(origin, p, b), tri - triangle(origin, p, a)), axis=-1
    )
    corners = np.stack((np.broadcast_to(p, a.shape), a, b), axis=1)
    gram = corners @ corners.transpose(0, 2, 1)
    rhs = np.stack((np.diagonal(gram, axis1=1, axis2=2), diff), axis=-1) / 2
    vec = corners.transpose(0, 2, 1) @ np.linalg.solve(gram, rhs)
    return box, tri, vec[:, :, 0] * box[:, None] + vec[:, :, 1]


def sample(unit, centres):
    # Relative to d^4x/pi^2, each channel has density 1/[r^2(1+r^2)^2].
    channel = unit[:, 0] * len(centres)
    index = channel.astype(int)
    p = channel - index
    radius = np.sqrt(p / (1 - p))
    h, a, b = unit[:, 1], 2 * np.pi * unit[:, 2], 2 * np.pi * unit[:, 3]
    direction = np.stack(
        (
            np.sqrt(h) * np.cos(a),
            np.sqrt(h) * np.sin(a),
            np.sqrt(1 - h) * np.cos(b),
            np.sqrt(1 - h) * np.sin(b),
        ),
        axis=-1,
    )
    centre = np.choose(index[:, None], [np.broadcast_to(x, direction.shape) for x in centres])
    x = centre + radius[:, None] * direction
    distances = [norm2(x, c) for c in centres]
    return x, len(centres) / sum(1 / (s * (1 + s) ** 2) for s in distances)


def signed_graph(u, v, rows):
    real = (1 + u - v) / 2
    p = np.array([real, np.sqrt(u - real**2), 0.0, 0.0])
    k, origin = np.array([1.0, 0.0, 0.0, 0.0]), np.zeros(4)
    result = 0.0
    for points in np.array_split(rows, max(1, len(rows) // 8192)):
        a, wa = sample(points[:, :4], [origin, p, k])
        b, wb = sample(points[:, 4:], [origin, p, k, a])
        s, sa = norm2(a, b), norm2(a, origin)
        outer = sa * norm2(b, origin) * norm2(a, p) * norm2(b, p) * norm2(a, k) * norm2(b, k)
        common = triangle(origin, a, b)
        be, te, ve = integrate_box(origin, k, a, b, common)
        bp, tp, vp = integrate_box(origin, p, a, b, common)
        pair = te * bp + be * tp - 2 * dot(ve, vp)
        result += np.sum(wa * wb / outer * (u * v * s * (sa * pair - s * common * (be + bp))))
    return float(result / len(rows))

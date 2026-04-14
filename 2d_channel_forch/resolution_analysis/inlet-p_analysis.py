#!/usr/bin/env python3
"""
Plot the error in inlet pressure versus resolution for SIMPLE and Newton results.

Expected files in the current directory:
    simple_inlet-p.csv
    newton_inlet-p.csv

Each CSV must contain exactly these columns:
    ix,inlet-p

The plotted quantity is:
    |p_analytic - p_inlet|

with:
    p_analytic = 14500 Pa
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path


ANALYTICAL_PRESSURE = 14500.0

SIMPLE_FILE = Path("simple_inlet-p.csv")
NEWTON_FILE = Path("newton_inlet-p.csv")

EXPECTED_IX = [20, 40, 80, 160, 320]

SIMPLE_COLOR = "#d62728"   # keep the same red
NEWTON_COLOR = "#FF674A"   # same orange/red as before


def _read_csv(path: Path):
    with path.open("r", newline="") as f:
        reader = csv.reader(f)
        header = None
        rows = []

        for row in reader:
            if not row:
                continue
            if row[0].lstrip().startswith("#"):
                continue
            if header is None:
                header = [h.strip() for h in row]
                continue
            rows.append(row)

    if header is None:
        raise RuntimeError(f"No header found in {path}")

    if "ix" not in header or "inlet-p" not in header:
        raise RuntimeError(
            f"{path} must contain columns 'ix' and 'inlet-p'. Found: {header}"
        )

    ix_idx = header.index("ix")
    p_idx = header.index("inlet-p")

    data = []
    for row in rows:
        if len(row) != len(header):
            raise RuntimeError(f"Row length mismatch in {path}")
        ix = int(float(row[ix_idx]))
        inlet_p = float(row[p_idx])
        data.append((ix, inlet_p))

    data.sort(key=lambda t: t[0])
    return data


def _validate_ix(data, path: Path):
    ix_values = [ix for ix, _ in data]
    if ix_values != EXPECTED_IX:
        raise RuntimeError(
            f"Unexpected ix values in {path}.\n"
            f"Expected: {EXPECTED_IX}\n"
            f"Found:    {ix_values}"
        )


def _compute_error(data):
    ix = [n for n, _ in data]
    err = [abs(ANALYTICAL_PRESSURE - p) for _, p in data]
    return ix, err


def _build_figure(simple_xy, newton_xy):
    import matplotlib as mpl
    import matplotlib.pyplot as plt
    from matplotlib.ticker import ScalarFormatter

    mpl.rcParams.update(
        {
            "font.family": "serif",
            "font.serif": ["Computer Modern Roman", "CMU Serif", "DejaVu Serif"],
            "mathtext.fontset": "cm",
            "axes.unicode_minus": False,
            "axes.grid": False,
            "grid.alpha": 0.3,
            "axes.spines.top": True,
            "axes.spines.right": True,
        }
    )

    fig, ax = plt.subplots(figsize=(6.5, 4.5))

    ix_simple, err_simple = simple_xy
    ix_newton, err_newton = newton_xy

    ax.plot(
        ix_simple,
        err_simple,
        color=SIMPLE_COLOR,
        linestyle="-",
        linewidth=1.5,
        marker="o",
        markersize=4,
        label="New solver (SIMPLE)",
    )

    ax.plot(
        ix_newton,
        err_newton,
        color=NEWTON_COLOR,
        linestyle="-",
        linewidth=1.5,
        marker="s",
        markersize=4,
        label="Existing solver (Newton's method)",
    )

    ax.set_xlabel(r"Resolution $i_x$")
    ax.set_ylabel(r"$|p_{\mathrm{analytic}} - p_{\mathrm{inlet}}|$ [Pa]")

    ax.set_yscale('log')
    ax.set_xscale('log')

    ax.set_xticks(EXPECTED_IX)
    ax.get_xaxis().set_major_formatter(ScalarFormatter())
    ax.ticklabel_format(style="plain", axis="x", useOffset=False)

    for spine in ax.spines.values():
        spine.set_visible(True)
        spine.set_linewidth(1.0)

    ax.legend(
        loc="best",
        frameon=True,
        fontsize=9,
        ncol=1,
        handlelength=2.5,
    )

    fig.tight_layout()
    return fig


def main(argv):
    if argv:
        raise RuntimeError("This script takes no arguments.")

    if not SIMPLE_FILE.exists():
        raise RuntimeError(f"Missing file: {SIMPLE_FILE}")
    if not NEWTON_FILE.exists():
        raise RuntimeError(f"Missing file: {NEWTON_FILE}")

    simple_data = _read_csv(SIMPLE_FILE)
    newton_data = _read_csv(NEWTON_FILE)

    _validate_ix(simple_data, SIMPLE_FILE)
    _validate_ix(newton_data, NEWTON_FILE)

    simple_xy = _compute_error(simple_data)
    newton_xy = _compute_error(newton_data)

    import matplotlib.pyplot as plt

    fig = _build_figure(simple_xy, newton_xy)
    out_path = Path("inlet_pressure_error.png")
    fig.savefig(out_path, dpi=300, bbox_inches="tight")
    plt.close(fig)

    print(f"Wrote {out_path}")


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
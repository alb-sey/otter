#!/usr/bin/env python3
"""
Plot inlet pressure error versus resolution for SIMPLE and Newton results,
and fit a power law

    error(p) = C * ix**alpha

in log-log space.

Expected files in the current directory:
    simple_inlet-p.csv
    newton_inlet-p.csv

Each CSV must contain exactly these columns:
    ix,inlet-p
"""

from __future__ import annotations

import csv
import math
import sys
from pathlib import Path


ANALYTICAL_PRESSURE = 14500.0

SIMPLE_FILE = Path("simple_inlet-p.csv")
NEWTON_FILE = Path("newton_inlet-p.csv")

EXPECTED_IX = [20, 40, 80, 160, 320]

SIMPLE_COLOR = "#d62728"
NEWTON_COLOR = "#FF674A"


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


def _fit_power_law(ix, err):
    """
    Fit err = C * ix**alpha using least squares in log-log space.

    Returns:
        alpha, C, fitted_values
    """
    if len(ix) != len(err):
        raise RuntimeError("ix and err must have same length")

    if any(x <= 0 for x in ix):
        raise RuntimeError("All ix values must be > 0 for log-log fitting")

    if any(e <= 0 for e in err):
        raise RuntimeError(
            "All error values must be > 0 for log-log fitting. "
            "A zero error cannot be shown on a log scale."
        )

    logx = [math.log(x) for x in ix]
    logy = [math.log(y) for y in err]

    n = len(logx)
    mean_x = sum(logx) / n
    mean_y = sum(logy) / n

    sxx = sum((x - mean_x) ** 2 for x in logx)
    sxy = sum((x - mean_x) * (y - mean_y) for x, y in zip(logx, logy))

    if sxx == 0.0:
        raise RuntimeError("Cannot fit power law: all ix values are identical")

    alpha = sxy / sxx
    intercept = mean_y - alpha * mean_x
    C = math.exp(intercept)

    fitted = [C * (x ** alpha) for x in ix]
    return alpha, C, fitted


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

    alpha_simple, C_simple, fit_simple = _fit_power_law(ix_simple, err_simple)
    alpha_newton, C_newton, fit_newton = _fit_power_law(ix_newton, err_newton)

    ax.plot(
        ix_simple,
        err_simple,
        color=SIMPLE_COLOR,
        linestyle="-",
        linewidth=1.5,
        marker="o",
        markersize=4,
        label=f"New solver (SIMPLE)",
    )

    ax.plot(
        ix_newton,
        err_newton,
        color=NEWTON_COLOR,
        linestyle="-",
        linewidth=1.5,
        marker="s",
        markersize=4,
        label=f"Existing solver (Newton's method)",
    )

    ax.plot(
        ix_simple,
        fit_simple,
        color='black',
        linestyle="--",
        linewidth=1.2,
        label=rf"SIMPLE : $\alpha = {alpha_simple:.3f}$",
    )

    ax.plot(
        ix_newton,
        fit_newton,
        color='black',
        linestyle="--",
        linewidth=1.2,
        label=rf"Newton : $\alpha = {alpha_newton:.3f}$",
    )

    # # --- Annotation text (LaTeX style) ---
    # text_simple = rf"SIMPLE: $e \sim {C_simple:.1e}\, i_x^{{{alpha_simple:.2f}}}$"
    # text_newton = rf"Newton: $e \sim {C_newton:.1e}\, i_x^{{{alpha_newton:.2f}}}$"

    # # Place in axes coordinates (0–1)
    # ax.text(
    #     0.05, 0.15,
    #     text_simple,
    #     transform=ax.transAxes,
    #     fontsize=9,
    #     color='black',
    #     verticalalignment="bottom",
    # )

    # ax.text(
    #     0.55, 0.55,
    #     text_newton,
    #     transform=ax.transAxes,
    #     fontsize=9,
    #     color='black',
    #     verticalalignment="top",
    # )

    ax.set_xlabel(r"Resolution $i_x$")
    ax.set_ylabel(r"$|p_{\mathrm{analytic}} - p_{\mathrm{inlet}}|$ [Pa]")

    ax.set_xscale("log")
    ax.set_yscale("log")

    ax.set_xticks(EXPECTED_IX)
    ax.get_xaxis().set_major_formatter(ScalarFormatter())
    ax.ticklabel_format(style="plain", axis="x", useOffset=False)

    for spine in ax.spines.values():
        spine.set_visible(True)
        spine.set_linewidth(1.0)

    ax.legend(
        loc="best",
        frameon=True,
        fontsize=8,
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
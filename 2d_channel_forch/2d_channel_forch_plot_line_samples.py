#!/usr/bin/env python3
"""
Plot LineValueSampler CSV outputs for velocity and pressure with LaTeX-style fonts.

Expected files in the current directory, for example:
    2d_channel_forch_newton_out_u_line_0001.csv
    2d_channel_forch_newton_out_p_line_0001.csv
    2d_channel_forch_simple_out_u_line_0001.csv
    2d_channel_forch_simple_out_p_line_0001.csv
"""

from __future__ import annotations

import csv
import re
import sys
from pathlib import Path


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

    cols = {name: [] for name in header}
    for row in rows:
        if len(row) != len(header):
            raise RuntimeError(f"Row length mismatch in {path}")
        for name, val in zip(header, row):
            cols[name].append(float(val))

    return cols


def _pick_x(cols):
    if "x" not in cols:
        raise RuntimeError("Expected an 'x' column in the CSV")
    return cols["x"]


def _pick_y(cols, y_col):
    if y_col not in cols:
        raise RuntimeError(f"Column '{y_col}' not found in CSV")
    return cols[y_col]


def _sample_key(path: Path):
    """
    Extract a matching key from filenames like:
        2d_channel_forch_newton_out_u_line_0001.csv
        2d_channel_forch_simple_out_p_line_0001.csv

    Returns:
        (case_name, line_index)
    Example:
        ("2d_channel_forch_newton", 1)
    """
    match = re.match(r"(.+)_out_[up]_line_(\d+)\.csv$", path.name)
    if not match:
        raise RuntimeError(f"Could not parse sample key from {path}")
    case_name = match.group(1)
    line_index = int(match.group(2))
    return case_name, line_index


def _pretty_label(case_name: str):
    mapping = {
        "2d_channel_forch_newton": "Existing solver (Newton's method)",
        "2d_channel_forch_simple": "New solver (SIMPLE)",
    }
    return mapping.get(case_name, case_name)


def _solver_colors(label: str):
    """
    Keep SIMPLE colors unchanged.
    Use custom colors for Newton:
      - velocity Newton: #70C9FF
      - pressure Newton: #FF674A
    """
    if "Newton" in label:
        return "#00B9FF", "#FF674A"
    return "#1f77b4", "#d62728"


def _build_expected_pressure_profile():
    """
    Expected pressure profile:
      p(x) = 14500              for x < 1
      p(1+) = 13000
      affine to p(2-) = 3000
      p(2+) = 500
      affine to p(3-) = -4000
      p(x) = 0                 for x > 3
    """
    x = [0.0, 1.0, 1.0, 2.0, 2.0, 3.0, 3.0, 4.0]
    p = [14500.0, 14500.0, 13000.0, 3000.0, 500.0, -4000.0, 0.0, 0.0]
    return x, p


def _build_figure(u_series, p_series, x_label, title, u_styles, p_styles, labels):
    import matplotlib as mpl
    import matplotlib.pyplot as plt
    from matplotlib.ticker import MultipleLocator

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

    fig, (ax1, ax2) = plt.subplots(1, 2, sharex=False, figsize=(10, 4))

    markers = ["o", "s", "^", "D", "v", ">", "<"]

    for i, ((x_u, u), style, label) in enumerate(zip(u_series, u_styles, labels)):
        vel_color, _ = _solver_colors(label)
        ax1.plot(
            x_u,
            u,
            color=vel_color,
            # linestyle=style,
            linewidth=1,
            alpha=1.0,
            marker=markers[i % len(markers)],
            markersize=2,
            markevery=(10 * i, max(1, len(x_u) // 10)),
            label=label,
        )

    ax1.plot(
        [0.0, 4.0],
        [1.0, 1.0],
        color="black",
        linestyle="--",
        linewidth=0.8,
        alpha=0.9,
        label="expected",
    )
    ax1.set_ylabel(r"Superficial velocity [m/s]")
    ax1.set_xlabel(x_label)
    ax1.set_title(title)
    ax1.set_ylim(1 - 10e-6, 1 + 10e-6)

    for i, ((x_p, p), style, label) in enumerate(zip(p_series, p_styles, labels)):
        _, pres_color = _solver_colors(label)
        ax2.plot(
            x_p,
            p,
            color=pres_color,
            # linestyle=style,
            linewidth=1,
            alpha=1.0,
            marker=markers[i % len(markers)],
            markersize=2,
            markevery=(10 * i, max(1, len(x_p) // 10)),
            label=label,
        )

    expected_x, expected_p = _build_expected_pressure_profile()
    ax2.plot(
        expected_x,
        expected_p,
        color="black",
        linestyle="--",
        linewidth=0.8,
        alpha=0.9,
        label="Analytic",
    )

    ax2.set_ylabel(r"Pressure [Pa]")
    ax2.set_xlabel(x_label)
    ax2.set_ylim(-5000, 15500)

    for ax in (ax1, ax2):
        for spine in ax.spines.values():
            spine.set_visible(True)
            spine.set_linewidth(1.0)
        ax.axvline(1.0, color="0.2", linestyle="--", linewidth=1.0, alpha=0.7)
        ax.axvline(2.0, color="0.2", linestyle="--", linewidth=1.0, alpha=0.7)
        ax.axvline(3.0, color="0.2", linestyle="--", linewidth=1.0, alpha=0.7)
        ax.set_xlim(left=0.0, right=4.0)
        ax.xaxis.set_major_locator(MultipleLocator(0.5))
        ax.ticklabel_format(style="plain", axis="both", useOffset=False)

    fig.tight_layout()

    if labels:
        legend_kwargs = dict(
            loc="best",
            frameon=True,
            fontsize=8,
            ncol=1,
            handlelength=2.5,
        )
        ax1.legend(**legend_kwargs)
        ax2.legend(**legend_kwargs)

    return fig


def _save_figure(out_path: Path, make_fig):
    import matplotlib.pyplot as plt

    fig = make_fig()
    fig.savefig(out_path, dpi=300, bbox_inches="tight")
    plt.close(fig)


def main(argv):
    if argv:
        raise RuntimeError("This script takes no arguments.")

    u_files = sorted(Path(".").glob("2d_channel_forch_*_out_u_line_*.csv"))
    p_files = sorted(Path(".").glob("2d_channel_forch_*_out_p_line_*.csv"))

    if not u_files or not p_files:
        raise RuntimeError(
            "No line sample CSV files found for pattern "
            "'2d_channel_forch_*_out_[u|p]_line_*.csv'."
        )

    u_map = {_sample_key(path): path for path in u_files}
    p_map = {_sample_key(path): path for path in p_files}

    if set(u_map.keys()) != set(p_map.keys()):
        missing_in_p = sorted(set(u_map.keys()) - set(p_map.keys()))
        missing_in_u = sorted(set(p_map.keys()) - set(u_map.keys()))
        raise RuntimeError(
            "Mismatch between velocity and pressure sample files.\n"
            f"Missing in pressure set: {missing_in_p}\n"
            f"Missing in velocity set: {missing_in_u}"
        )

    sample_indices = sorted(u_map.keys())

    u_series = []
    p_series = []
    labels = []

    for key in sample_indices:
        u_cols = _read_csv(u_map[key])
        p_cols = _read_csv(p_map[key])

        x_u = _pick_x(u_cols)
        x_p = _pick_x(p_cols)

        u = _pick_y(u_cols, "superficial_u")
        p = _pick_y(p_cols, "pressure")

        u_series.append((x_u, u))
        p_series.append((x_p, p))

        case_name, line_index = key
        base_label = _pretty_label(case_name)
        label = base_label if line_index == 1 else f"{base_label} (line {line_index})"
        labels.append(label)

    x_label = r"$x$"

    def make_fig():
        base_styles = [
            "-",
            "--",
            "-.",
            ":",
            (0, (5, 1)),
            (0, (3, 1, 1, 1)),
            (0, (1, 1)),
        ]
        u_styles = [base_styles[i % len(base_styles)] for i in range(len(u_series))]
        p_styles = [base_styles[i % len(base_styles)] for i in range(len(p_series))]
        return _build_figure(
            u_series=u_series,
            p_series=p_series,
            x_label=x_label,
            title="",
            u_styles=u_styles,
            p_styles=p_styles,
            labels=labels,
        )

    out_path = Path("line_samples.png")
    _save_figure(out_path, make_fig)
    print(f"Wrote {out_path}")


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
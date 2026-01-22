#!/usr/bin/env python3
"""
Compare unit test coverage between two branches.
Usage: python3 compare_coverage.py <branch1> <branch2>
"""

import sys
import subprocess
import re
from collections import defaultdict
from typing import Dict, Tuple

def parse_coverage_output(branch: str) -> Dict[str, float]:
    """Parse go tool cover -func output for a specific branch."""
    try:
        # Get coverage file from branch
        result = subprocess.run(
            ['git', 'show', f'{branch}:coverage_unit.out'],
            capture_output=True, text=True, check=True
        )
        coverage_data = result.stdout
        
        # Save to temp file and analyze
        with open(f'/tmp/{branch}_coverage.out', 'w') as f:
            f.write(coverage_data)
        
        # Run go tool cover
        result = subprocess.run(
            ['go', 'tool', 'cover', '-func', f'/tmp/{branch}_coverage.out'],
            capture_output=True, text=True
        )
        
        # Parse output: filename:line: function coverage%
        coverage_by_file = defaultdict(lambda: {'covered': 0, 'total': 0})
        pattern = r'([^:]+\.go):\d+:\s+\S+\s+(\d+\.\d+)%'
        
        for line in result.stdout.split('\n'):
            match = re.match(pattern, line)
            if match:
                filename = match.group(1)
                coverage = float(match.group(2))
                coverage_by_file[filename]['covered'] += coverage
                coverage_by_file[filename]['total'] += 100
        
        # Calculate average coverage per file
        file_coverage = {}
        for filename, data in coverage_by_file.items():
            if data['total'] > 0:
                file_coverage[filename] = (data['covered'] / data['total']) * 100
        
        # Get total coverage
        total_match = re.search(r'total:\s+\(statements\)\s+(\d+\.\d+)%', result.stdout)
        if total_match:
            file_coverage['TOTAL'] = float(total_match.group(1))
        
        return file_coverage
    except subprocess.CalledProcessError as e:
        print(f"Error getting coverage from branch {branch}: {e}", file=sys.stderr)
        return {}

def print_comparison_table(cov1: Dict[str, float], cov2: Dict[str, float], 
                          branch1: str, branch2: str):
    """Print a comparison table in markdown format."""
    all_files = sorted(set(cov1.keys()) | set(cov2.keys()))
    
    print(f"\n# Coverage Comparison: {branch1} vs {branch2}\n")
    print(f"| File | {branch1} | {branch2} | Diff |")
    print("|------|-----------|-----------|------|")
    
    for filename in all_files:
        c1 = cov1.get(filename, 0.0)
        c2 = cov2.get(filename, 0.0)
        diff = c2 - c1
        
        diff_str = f"+{diff:.1f}%" if diff > 0 else f"{diff:.1f}%"
        if abs(diff) < 0.1:
            diff_str = "±0.0%"
        
        # Highlight total row
        if filename == 'TOTAL':
            print(f"| **{filename}** | **{c1:.1f}%** | **{c2:.1f}%** | **{diff_str}** |")
        else:
            print(f"| {filename} | {c1:.1f}% | {c2:.1f}% | {diff_str} |")

def create_visualization(cov1: Dict[str, float], cov2: Dict[str, float],
                        branch1: str, branch2: str, output_file: str):
    """Create a bar chart visualization using matplotlib."""
    try:
        import matplotlib.pyplot as plt
        import numpy as np
    except ImportError:
        print("\nNote: Install matplotlib for graphical visualization:")
        print("  pip install matplotlib")
        return
    
    # Get top files with coverage changes
    changes = []
    for filename in set(cov1.keys()) | set(cov2.keys()):
        if filename != 'TOTAL':
            c1 = cov1.get(filename, 0.0)
            c2 = cov2.get(filename, 0.0)
            diff = abs(c2 - c1)
            if diff > 0.1:  # Only show files with >0.1% change
                changes.append((filename, c1, c2, c2 - c1))
    
    # Sort by absolute difference
    changes.sort(key=lambda x: abs(x[3]), reverse=True)
    top_changes = changes[:20]  # Top 20 changes
    
    if not top_changes and 'TOTAL' in cov1 and 'TOTAL' in cov2:
        # Show just total if no file-level changes
        top_changes = [('TOTAL', cov1['TOTAL'], cov2['TOTAL'], cov2['TOTAL'] - cov1['TOTAL'])]
    
    if not top_changes:
        print("No significant coverage changes to visualize.")
        return
    
    # Create plot
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, max(8, len(top_changes) * 0.4)))
    
    files = [x[0].split('/')[-1][:40] for x in top_changes]  # Shorten filenames
    cov1_vals = [x[1] for x in top_changes]
    cov2_vals = [x[2] for x in top_changes]
    diffs = [x[3] for x in top_changes]
    
    y_pos = np.arange(len(files))
    
    # Coverage comparison chart
    ax1.barh(y_pos - 0.2, cov1_vals, 0.4, label=branch1, alpha=0.8)
    ax1.barh(y_pos + 0.2, cov2_vals, 0.4, label=branch2, alpha=0.8)
    ax1.set_yticks(y_pos)
    ax1.set_yticklabels(files)
    ax1.set_xlabel('Coverage (%)')
    ax1.set_title('Coverage Comparison by File')
    ax1.legend()
    ax1.grid(axis='x', alpha=0.3)
    ax1.set_xlim(0, 100)
    
    # Difference chart
    colors = ['green' if d >= 0 else 'red' for d in diffs]
    ax2.barh(y_pos, diffs, color=colors, alpha=0.6)
    ax2.set_yticks(y_pos)
    ax2.set_yticklabels(files)
    ax2.set_xlabel('Coverage Difference (%)')
    ax2.set_title(f'Coverage Change ({branch2} - {branch1})')
    ax2.axvline(x=0, color='black', linestyle='-', linewidth=0.5)
    ax2.grid(axis='x', alpha=0.3)
    
    # Add value labels
    for i, (diff, cov2) in enumerate(zip(diffs, cov2_vals)):
        ax2.text(diff, i, f' {diff:+.1f}%', va='center', fontsize=8)
    
    plt.tight_layout()
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"\n✓ Visualization saved to: {output_file}")

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python3 compare_coverage.py <branch1> <branch2>")
        print("Example: python3 compare_coverage.py master test-improvements")
        sys.exit(1)
    
    branch1, branch2 = sys.argv[1], sys.argv[2]
    
    print(f"Analyzing coverage from branch '{branch1}'...")
    cov1 = parse_coverage_output(branch1)
    
    print(f"Analyzing coverage from branch '{branch2}'...")
    cov2 = parse_coverage_output(branch2)
    
    if not cov1 or not cov2:
        print("Error: Could not parse coverage data from one or both branches.")
        sys.exit(1)
    
    # Print table
    print_comparison_table(cov1, cov2, branch1, branch2)
    
    # Create visualization
    output_file = f"coverage_comparison_{branch1}_vs_{branch2}.png"
    create_visualization(cov1, cov2, branch1, branch2, output_file)

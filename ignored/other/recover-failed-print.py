#!/usr/bin/env python3
"""
G-code Resume Script - Interactive layer/line selection for print recovery
Removes initialization lines and resumes printing from specified layer or line
"""

import re
import sys
from pathlib import Path


def parse_gcode(filepath):
    """Parse G-code file into lines with metadata."""
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    parsed = []
    current_z = 0
    
    for idx, line in enumerate(lines, 1):
        stripped = line.strip()
        
        # Extract Z height from comments
        z_match = re.search(r'^;Z:([\d.]+)', stripped)
        if z_match:
            current_z = float(z_match.group(1))
        
        parsed.append({
            'line_num': idx,
            'content': line,
            'stripped': stripped,
            'z_height': current_z,
            'is_comment': stripped.startswith(';'),
            'is_layer_change': ';LAYER_CHANGE' in stripped or ';Z:' in stripped
        })
    
    return parsed


def find_resume_point(parsed, user_input):
    """Find resume point by Z-height or line number."""
    
    # Check if input is a Z-height (e.g., "80.4")
    try:
        z_height = float(user_input)
        # Find first line with matching Z height
        for item in parsed:
            if item['z_height'] == z_height and item['is_layer_change']:
                return item['line_num'], z_height
        
        # If exact match not found, find closest
        closest = min(parsed, key=lambda x: abs(x['z_height'] - z_height))
        print(f"⚠ Exact Z:{z_height} not found. Using closest: Z:{closest['z_height']} at line {closest['line_num']}")
        return closest['line_num'], closest['z_height']
    
    except ValueError:
        # Try as line number
        try:
            line_num = int(user_input)
            if 1 <= line_num <= len(parsed):
                return line_num, parsed[line_num - 1]['z_height']
            else:
                print(f"❌ Line number {line_num} out of range (1-{len(parsed)})")
                return None, None
        except ValueError:
            print("❌ Invalid input. Use Z-height (e.g., 80.4) or line number (e.g., 1234)")
            return None, None


def should_remove_line(stripped):
    """Determine if line should be removed during initialization cleanup."""
    skip_prefixes = [
        'M486',    # Object cancellation
        'M862',    # Version checks
        'M115',    # Firmware version
        'M708',    # MMU setup
        'M555',    # Purge area definition
        'M140',    # Set bed temp
        'M104',    # Set hotend temp
        'M109',    # Wait for hotend
        'M190',    # Wait for bed
        'G28',     # Home
        'G29',     # Mesh leveling
        'M17',     # Enable steppers (keep this)
        'M221',    # Flow rate (optional)
    ]
    
    skip_comments = [
        'LAYER_CHANGE',
        'HEIGHT:',
        'Z:',
        ';TYPE:',
        ';WIDTH:',
        'BEFORE_LAYER',
        'AFTER_LAYER',
        'purge',
        'Extrude',
        'WIPE_START',
        'WIPE_END',
    ]
    
    # Skip most comments except important ones
    if stripped.startswith(';'):
        for pattern in skip_comments:
            if pattern in stripped:
                return True
        return True
    
    # Skip setup commands
    for prefix in skip_prefixes:
        if stripped.startswith(prefix):
            return True
    
    return False


def create_resume_gcode(parsed, resume_line, output_path):
    """Create resume G-code file."""
    
    resume_z = parsed[resume_line - 1]['z_height']
    
    output_lines = []
    
    # Header
    output_lines.append(f"; Generated resume file from line {resume_line}\n")
    output_lines.append(f"; Resuming at Z:{resume_z}\n")
    output_lines.append(f"; Current date: {Path(__file__).stat().st_mtime}\n")
    output_lines.append(";\n")
    output_lines.append("; Motion settings (preserved from original)\n")
    
    # First pass: collect all motion settings before resume point
    for item in parsed[:resume_line]:
        stripped = item['stripped']
        if stripped.startswith(('M201', 'M203', 'M204', 'M205', 'G90', 'M83', 'M572', 'M17')):
            output_lines.append(item['content'])
    
    # Add setup for resuming print
    output_lines.append(";\n")
    output_lines.append("; Resume sequence\n")
    output_lines.append("M104 S205  ; Set hotend temp\n")
    output_lines.append("M140 S60   ; Set bed temp\n")
    output_lines.append("G1 Z{:.1f} F720  ; Move to resume height\n".format(resume_z + 5))
    output_lines.append("M109 S215  ; Wait for hotend\n")
    output_lines.append("M190 S60   ; Wait for bed\n")
    output_lines.append(";\n")
    output_lines.append("; Begin print from resume point\n")
    
    # Second pass: add lines from resume point onward
    skip_next_temps = True
    for item in parsed[resume_line - 1:]:
        stripped = item['stripped']
        
        # Skip duplicate temp settings at start
        if skip_next_temps and stripped.startswith(('M104', 'M109', 'M140', 'M190')):
            continue
        
        if stripped and not stripped.startswith(';'):
            skip_next_temps = False
        
        # Skip wipe operations at resume point
        if 'WIPE' in stripped or (stripped.startswith('G1') and 'E-' in stripped and item['line_num'] < resume_line + 50):
            continue
        
        output_lines.append(item['content'])
    
    # Write output file
    with open(output_path, 'w') as f:
        f.writelines(output_lines)
    
    return output_path


def main():
    print("=" * 60)
    print("G-code Resume Generator")
    print("=" * 60)
    
    # Get input file
    if len(sys.argv) > 1:
        input_file = sys.argv[1]
    else:
        input_file = input("\n📁 Enter G-code file path: ").strip()
    
    try:
        input_path = Path(input_file)
        if not input_path.exists():
            print(f"❌ File not found: {input_file}")
            return
    except Exception as e:
        print(f"❌ Error: {e}")
        return
    
    print(f"\n✅ Parsing {input_path.name}...")
    parsed = parse_gcode(input_path)
    print(f"   Total lines: {len(parsed)}")
    
    # Get unique Z heights
    z_heights = sorted(set(item['z_height'] for item in parsed if item['z_height'] > 0))
    print(f"\n📊 Available layers:")
    for i, z in enumerate(z_heights[:20], 1):
        print(f"   {i:2d}. Z:{z:.1f}")
    if len(z_heights) > 20:
        print(f"   ... and {len(z_heights) - 20} more")
    
    # Get resume point
    print("\n🎯 Resume point selection:")
    print("   Enter Z-height (e.g., 80.4) or line number (e.g., 2500)")
    user_input = input("   > ").strip()
    
    resume_line, resume_z = find_resume_point(parsed, user_input)
    
    if resume_line is None:
        return
    
    print(f"\n✓ Resuming from line {resume_line} (Z:{resume_z})")
    
    # Show context
    context_start = max(0, resume_line - 5)
    context_end = min(len(parsed), resume_line + 3)
    print("\n📝 Context around resume point:")
    for i in range(context_start, context_end):
        marker = ">>>" if i == resume_line - 1 else "   "
        preview = parsed[i]['stripped'][:60]
        print(f"   {marker} {parsed[i]['line_num']:5d}: {preview}")
    
    # Generate output
    output_filename = f"RESUMED_AT-L{resume_line}_{input_path.stem}.gcode"
    output_path = input_path.parent / output_filename
    
    print(f"\n💾 Writing resume file...")
    create_resume_gcode(parsed, resume_line, output_path)
    print(f"✅ Created: {output_path}")
    print(f"   File size: {output_path.stat().st_size / 1024:.1f} KB")
    
    print("\n" + "=" * 60)
    print("✓ Resume file ready!")
    print("=" * 60)


if __name__ == '__main__':
    main()

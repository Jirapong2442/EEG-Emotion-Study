
"""
Video Duration Scanner

This script scans a directory for video files and prints their durations
in milliseconds, rounded to the nearest 10 milliseconds.
"""

import os
import subprocess
from pathlib import Path

def get_video_duration(video_path):
    """Get video duration with high precision using ffprobe"""
    try:
        # Use ffprobe to get duration with high precision
        cmd = [
            'ffprobe',
            '-v', 'quiet',
            '-show_entries', 'format=duration',
            '-of', 'default=nw=1',
            str(video_path)
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            # Parse the output to extract duration
            output = result.stdout.strip()
            # Look for duration value in the output
            for line in output.split('\n'):
                if 'duration=' in line:
                    duration_str = line.split('=')[1].strip()
                    try:
                        # Convert to float for high precision
                        duration_seconds = float(duration_str)
                        return duration_seconds
                    except ValueError:
                        pass
        return None
    except Exception as e:
        print(f"Error getting duration for {video_path.name}: {e}")
        return None

def format_duration_ms(seconds):
    """Format duration in seconds to milliseconds, rounded to nearest 10ms"""
    if seconds is None:
        return "Unknown"
    
    # Convert to milliseconds
    milliseconds = seconds * 1000
    
    # Round to nearest 10 milliseconds
    rounded_ms = round(milliseconds / 10) * 10
    
    return f"{rounded_ms} ms"

def scan_video_durations(directory_path):
    """Scan directory for video files and print their durations"""
    directory = Path(directory_path)
    
    if not directory.exists():
        print(f"Error: Directory '{directory_path}' does not exist.")
        return
    
    # Common video file extensions
    video_extensions = {'.mp4', '.mov', '.avi', '.mkv', '.wmv', '.flv', '.webm', '.m4v'}
    
    video_files = []
    
    # Find all video files in the directory
    try:
        for file_path in directory.iterdir():
            if file_path.is_file() and file_path.suffix.lower() in video_extensions:
                video_files.append(file_path)
    except PermissionError:
        print(f"Permission denied accessing directory '{directory_path}'")
        return
    except Exception as e:
        print(f"Error scanning directory '{directory_path}': {e}")
        return
    
    if not video_files:
        print(f"No video files found in '{directory_path}'")
        return
    
    # Sort files by name for consistent output
    video_files.sort(key=lambda x: x.name.lower())
    
    print(f"Found {len(video_files)} video file(s) in '{directory_path}':")
    print("-" * 60)
    print(f"{'Filename':<40} {'Duration (ms)':<15}")
    print("-" * 60)
    
    for video_file in video_files:
        duration_seconds = get_video_duration(video_file)
        duration_formatted = format_duration_ms(duration_seconds)
        print(f"{video_file.name:<40} {duration_formatted:<15}")

def main():
    """Main function"""
    directory_path = r"D:\EEE\generalized_vids"
    print("=" * 60)
    print("VIDEO DURATION SCANNER (Milliseconds)")
    print("=" * 60)
    print(f"Scanning directory: {directory_path}")
    print()
    
    scan_video_durations(directory_path)
    
    print()
    print("=" * 60)
    print("Scan completed!")
    input("\nPress Enter to exit...")

if __name__ == "__main__":
    main()
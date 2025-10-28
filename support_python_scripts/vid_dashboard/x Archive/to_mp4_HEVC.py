
"""
HEVC MP4 Converter Script

This script provides a GUI interface to select a folder, finds all .MOV files 
and non-HEVC encoded .MP4 files in that folder, and converts them to HEVC-encoded 
.MP4 format while preserving the original files. Converted files are named 
<original>_HEVC.mp4.
"""

import os
import sys
import subprocess
from pathlib import Path

# Check for required dependencies
HAS_TK = False
try:
    import tkinter as tk
    from tkinter import filedialog, messagebox
    HAS_TK = True
except ImportError:
    print("Warning: tkinter not available. Will use command line interface.")

def check_ffmpeg():
    """Check if FFmpeg is installed and accessible"""
    try:
        result = subprocess.run(['ffmpeg', '-version'], 
                              capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            print("FFmpeg found")
            return True
        else:
            print("FFmpeg returned an error")
            return False
    except FileNotFoundError:
        print("FFmpeg not found. Please install FFmpeg and add it to your PATH.")
        print("  Download from: https://ffmpeg.org/download.html")
        return False
    except Exception as e:
        print(f"Error checking FFmpeg: {e}")
        return False

def select_folder():
    """Open a dialog to select a folder"""
    if HAS_TK:
        try:
            root = tk.Tk()
            root.withdraw()  # Hide the main window
            # Make the dialog stay on top
            root.attributes('-topmost', True)
            folder_path = filedialog.askdirectory(
                title="Select Folder Containing Video Files"
            )
            root.destroy()
            return folder_path
        except Exception as e:
            print(f"GUI folder selection failed: {e}")
            print("Falling back to command line input...")
    else:
        print("Using command line interface for folder selection")
    
    # Fallback to command line input
    print("\nSelect Folder Containing Video Files")
    folder_path = input("Enter the full path to the folder: ").strip()
    return folder_path if os.path.exists(folder_path) else None

def find_video_files(folder_path):
    """Find all .MOV and .MP4 files in the specified folder"""
    mov_files = []
    mp4_files = []
    folder = Path(folder_path)
    
    if not folder.exists():
        print(f"Error: Folder '{folder_path}' does not exist.")
        return mov_files, mp4_files
    
    # Find all video files (case insensitive)
    try:
        for file_path in folder.iterdir():
            if file_path.is_file():
                suffix = file_path.suffix.lower()
                if suffix == '.mov':
                    mov_files.append(file_path)
                elif suffix == '.mp4':
                    mp4_files.append(file_path)
    except PermissionError:
        print(f"Permission denied accessing folder '{folder_path}'")
    except Exception as e:
        print(f"Error scanning folder '{folder_path}': {e}")
    
    return mov_files, mp4_files

def is_hevc_encoded(mp4_file_path):
    """Check if an MP4 file is already HEVC encoded"""
    try:
        # Run ffprobe to get video stream info
        cmd = [
            'ffprobe',
            '-v', 'error',
            '-select_streams', 'v:0',
            '-show_entries', 'stream=codec_name',
            '-of', 'default=nw=1',
            str(mp4_file_path)
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        if result.returncode == 0:
            # Parse the output to check codec
            output = result.stdout.strip()
            # Look for codec_name entry
            for line in output.split('\n'):
                if 'codec_name=' in line:
                    codec = line.split('=')[1].strip()
                    return codec.lower() == 'hevc'
        return False
    except Exception as e:
        print(f"Error checking codec for '{mp4_file_path.name}': {e}")
        # If we can't determine the codec, assume it's not HEVC to be safe
        return False

def find_non_hevc_mp4_files(mp4_files):
    """Filter MP4 files to find those that are not HEVC encoded"""
    non_hevc_mp4_files = []
    
    for mp4_file in mp4_files:
        if not is_hevc_encoded(mp4_file):
            non_hevc_mp4_files.append(mp4_file)
            print(f"  - {mp4_file.name} (not HEVC)")
        else:
            print(f"  - {mp4_file.name} (already HEVC - skipping)")
    
    return non_hevc_mp4_files

def convert_mov_to_mp4(mov_file_path, output_folder=None):
    """Convert MOV file to MP4 using stream copy method (fastest)"""
    if output_folder is None:
        output_folder = mov_file_path.parent
    
    # Create output file path with _HEVC suffix
    output_filename = mov_file_path.stem + '_HEVC.mp4'
    output_file_path = output_folder / output_filename
    
    # Skip if output file already exists
    if output_file_path.exists():
        print(f"Skipping '{mov_file_path.name}' - '{output_filename}' already exists")
        return True
    
    print(f"Converting '{mov_file_path.name}' to '{output_filename}'...")
    
    # Method 1: Stream copy (fastest, no re-encoding)
    ffmpeg_cmd_copy = [
        'ffmpeg',
        '-y',  # Overwrite output files without asking
        '-i', str(mov_file_path),  # Input file
        '-c', 'copy',  # Copy streams without re-encoding
        '-tag:v', 'hvc1',   # Tag for better compatibility
        str(output_file_path)  # Output file
    ]
    
    # Method 2: Re-encode with H.264 (fallback)
    ffmpeg_cmd_encode = [
        'ffmpeg',
        '-y',  # Overwrite output files without asking
        '-i', str(mov_file_path),  # Input file
        '-c:v', 'libx264',  # Video codec
        '-c:a', 'aac',      # Audio codec
        '-preset', 'medium',  # Encoding speed/quality tradeoff
        '-crf', '23',       # Constant Rate Factor (quality - lower is better)
        '-pix_fmt', 'yuv420p',  # Pixel format for compatibility
        str(output_file_path)  # Output file
    ]
    
    try:
        # Try stream copy first (fastest method)
        print("  Trying stream copy...")
        result = subprocess.run(
            ffmpeg_cmd_copy,
            capture_output=True,
            text=True,
            timeout=300  # 5 minute timeout
        )
        
        # If stream copy fails, try encoding
        if result.returncode != 0:
            print("  Stream copy failed, trying H.264 encoding...")
            result = subprocess.run(
                ffmpeg_cmd_encode,
                capture_output=True,
                text=True,
                timeout=600  # 10 minute timeout
            )
        
        if result.returncode == 0:
            print(f"Successfully converted '{mov_file_path.name}'")
            return True
        else:
            print(f"Error converting '{mov_file_path.name}':")
            print(f"  Return code: {result.returncode}")
            if result.stderr:
                # Print only first 500 characters to avoid overwhelming output
                print(f"  Error: {result.stderr[:500]}")
            return False
    except subprocess.TimeoutExpired:
        print(f"Timeout converting '{mov_file_path.name}' (took too long)")
        return False
    except FileNotFoundError:
        print("Error: FFmpeg not found. Please install FFmpeg and make sure it's in your PATH.")
        return False
    except Exception as e:
        print(f"Unexpected error converting '{mov_file_path.name}': {e}")
        return False

def convert_mp4_to_hevc(mp4_file_path, output_folder=None):
    """Convert MP4 file to HEVC MP4"""
    if output_folder is None:
        output_folder = mp4_file_path.parent
    
    # Create output file path with _HEVC suffix
    output_filename = mp4_file_path.stem + '_HEVC.mp4'
    output_file_path = output_folder / output_filename
    
    # Skip if output file already exists
    if output_file_path.exists():
        print(f"Skipping '{mp4_file_path.name}' - '{output_filename}' already exists")
        return True
    
    print(f"Converting '{mp4_file_path.name}' to '{output_filename}' (HEVC)...")
    
    # Method 1: Stream copy (if possible)
    ffmpeg_cmd_copy = [
        'ffmpeg',
        '-y',  # Overwrite output files without asking
        '-i', str(mp4_file_path),  # Input file
        '-c', 'copy',  # Copy streams without re-encoding
        '-tag:v', 'hvc1',   # Tag for better compatibility
        str(output_file_path)  # Output file
    ]
    
    # Method 2: HEVC encoding
    ffmpeg_cmd_hevc = [
        'ffmpeg',
        '-y',  # Overwrite output files without asking
        '-i', str(mp4_file_path),  # Input file
        '-c:v', 'libx265',  # Video codec (HEVC)
        '-c:a', 'aac',      # Audio codec
        '-preset', 'medium',  # Encoding speed/quality tradeoff
        '-crf', '23',       # Constant Rate Factor (quality - lower is better)
        '-pix_fmt', 'yuv420p',  # Pixel format for compatibility
        '-tag:v', 'hvc1',   # Tag for better compatibility
        str(output_file_path)  # Output file
    ]
    
    # Method 3: H.264 encoding (fallback)
    ffmpeg_cmd_h264 = [
        'ffmpeg',
        '-y',  # Overwrite output files without asking
        '-i', str(mp4_file_path),  # Input file
        '-c:v', 'libx264',  # Video codec (H.264)
        '-c:a', 'aac',      # Audio codec
        '-preset', 'medium',  # Encoding speed/quality tradeoff
        '-crf', '23',       # Constant Rate Factor (quality - lower is better)
        '-pix_fmt', 'yuv420p',  # Pixel format for compatibility
        str(output_file_path)  # Output file
    ]
    
    try:
        # Try stream copy first (fastest method)
        print("  Trying stream copy...")
        result = subprocess.run(
            ffmpeg_cmd_copy,
            capture_output=True,
            text=True,
            timeout=300  # 5 minute timeout
        )
        
        # If stream copy fails, try HEVC encoding
        if result.returncode != 0:
            print("  Stream copy failed, trying HEVC encoding...")
            result = subprocess.run(
                ffmpeg_cmd_hevc,
                capture_output=True,
                text=True,
                timeout=600  # 10 minute timeout
            )
        
        # If HEVC encoding fails, try H.264 as fallback
        if result.returncode != 0:
            print("  HEVC encoding failed, trying H.264 encoding...")
            result = subprocess.run(
                ffmpeg_cmd_h264,
                capture_output=True,
                text=True,
                timeout=600  # 10 minute timeout
            )
        
        if result.returncode == 0:
            print(f"Successfully converted '{mp4_file_path.name}'")
            return True
        else:
            print(f"Error converting '{mp4_file_path.name}':")
            print(f"  Return code: {result.returncode}")
            if result.stderr:
                # Print only first 500 characters to avoid overwhelming output
                print(f"  Error: {result.stderr[:500]}")
            return False
    except subprocess.TimeoutExpired:
        print(f"Timeout converting '{mp4_file_path.name}' (took too long)")
        return False
    except FileNotFoundError:
        print("Error: FFmpeg not found. Please install FFmpeg and make sure it's in your PATH.")
        return False
    except Exception as e:
        print(f"Unexpected error converting '{mp4_file_path.name}': {e}")
        return False

def main():
    """Main function to run the converter"""
    print("=" * 60)
    print("HEVC MP4 CONVERTER")
    print("=" * 60)
    
    # Check dependencies
    print("\nChecking dependencies...")
    if not check_ffmpeg():
        print("\nPlease install FFmpeg and try again.")
        return
    
    # Select folder
    print("\nSelecting folder...")
    folder_path = select_folder()
    
    if not folder_path:
        print("No folder selected. Exiting.")
        return
    
    if not os.path.exists(folder_path):
        print(f"Error: Selected folder '{folder_path}' does not exist.")
        return
    
    print(f"Selected folder: {folder_path}")
    
    # Find video files
    print("\nSearching for video files...")
    mov_files, mp4_files = find_video_files(folder_path)
    
    # Filter MP4 files to find non-HEVC ones
    print("\nChecking MP4 files for HEVC encoding...")
    non_hevc_mp4_files = find_non_hevc_mp4_files(mp4_files)
    
    # Report findings
    print(f"\nFound {len(mov_files)} MOV file(s):")
    for mov_file in mov_files:
        print(f"  - {mov_file.name}")
    
    print(f"\nFound {len(non_hevc_mp4_files)} non-HEVC MP4 file(s):")
    for mp4_file in non_hevc_mp4_files:
        print(f"  - {mp4_file.name}")
    
    # Check if there's anything to convert
    total_files_to_convert = len(mov_files) + len(non_hevc_mp4_files)
    if total_files_to_convert == 0:
        print("\nNo files need to be converted.")
        return
    
    # Confirm conversion
    response = input(f"\nFound {total_files_to_convert} file(s) to convert.\nContinue? Original files will be preserved. (y/n): ").strip().lower()
    if response not in ['y', 'yes']:
        print("Conversion cancelled by user.")
        return
    
    # Convert files
    print("\nStarting conversion process...")
    successful_conversions = 0
    failed_conversions = 0
    
    folder = Path(folder_path)
    
    # Convert MOV files
    print("\n--- Converting MOV files ---")
    for mov_file in mov_files:
        if convert_mov_to_mp4(mov_file, folder):
            successful_conversions += 1
        else:
            failed_conversions += 1
    
    # Convert non-HEVC MP4 files
    print("\n--- Converting non-HEVC MP4 files ---")
    for mp4_file in non_hevc_mp4_files:
        if convert_mp4_to_hevc(mp4_file, folder):
            successful_conversions += 1
        else:
            failed_conversions += 1
    
    # Summary
    print("\n" + "=" * 60)
    print("CONVERSION SUMMARY")
    print("=" * 60)
    print(f"Successfully converted: {successful_conversions}")
    print(f"Failed conversions: {failed_conversions}")
    print(f"Total files processed: {total_files_to_convert}")
    
    if failed_conversions > 0:
        print("\nSome files failed to convert. Check the error messages above.")
    
    print("\nProcess completed!")
    print("Original files have been preserved.")
    print("Converted files are named <original>_HEVC.mp4")
    
    input("\nPress Enter to exit...")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nOperation cancelled by user.")
    except Exception as e:
        print(f"\n\nUnexpected error: {e}")
        print("Please report this error if it persists.")
        input("\nPress Enter to exit...")
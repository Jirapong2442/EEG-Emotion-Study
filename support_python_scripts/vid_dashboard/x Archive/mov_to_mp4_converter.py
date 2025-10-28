
"""
MOV to MP4 Converter Script

This script provides a GUI interface to select a folder, finds all .MOV files 
in that folder, and converts them to .MP4 format while preserving the original files.
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
            print("✓ FFmpeg found")
            return True
        else:
            print("✗ FFmpeg returned an error")
            return False
    except FileNotFoundError:
        print("✗ FFmpeg not found. Please install FFmpeg and add it to your PATH.")
        print("  Download from: https://ffmpeg.org/download.html")
        return False
    except Exception as e:
        print(f"✗ Error checking FFmpeg: {e}")
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
                title="Select Folder Containing MOV Files"
            )
            root.destroy()
            return folder_path
        except Exception as e:
            print(f"GUI folder selection failed: {e}")
            print("Falling back to command line input...")
    else:
        print("Using command line interface for folder selection")
    
    # Fallback to command line input
    print("\nSelect Folder Containing MOV Files")
    folder_path = input("Enter the full path to the folder: ").strip()
    return folder_path if os.path.exists(folder_path) else None

def find_mov_files(folder_path):
    """Find all .MOV files in the specified folder"""
    mov_files = []
    folder = Path(folder_path)
    
    if not folder.exists():
        print(f"Error: Folder '{folder_path}' does not exist.")
        return mov_files
    
    # Find all .MOV files (case insensitive)
    try:
        for file_path in folder.iterdir():
            if file_path.is_file() and file_path.suffix.lower() == '.mov':
                mov_files.append(file_path)
    except PermissionError:
        print(f"Permission denied accessing folder '{folder_path}'")
    except Exception as e:
        print(f"Error scanning folder '{folder_path}': {e}")
    
    return mov_files

def convert_mov_to_mp4(mov_file_path, output_folder=None):
    """Convert a single MOV file to MP4 using FFmpeg"""
    if output_folder is None:
        output_folder = mov_file_path.parent
    
    # Create output file path
    mp4_filename = mov_file_path.stem + '.mp4'
    mp4_file_path = output_folder / mp4_filename
    
    # Skip if MP4 file already exists
    if mp4_file_path.exists():
        print(f"Skipping '{mov_file_path.name}' - MP4 version already exists")
        return True
    
    # FFmpeg command to convert MOV to MP4
    # Using H.264 codec for compatibility
    # Try with preset first, fall back to simpler command if preset fails
    ffmpeg_cmd = [
        'ffmpeg',
        '-y',  # Overwrite output files without asking
        '-i', str(mov_file_path),  # Input file
        '-c:v', 'libx264',  # Video codec
        '-c:a', 'aac',      # Audio codec
        '-strict', 'experimental',  # Allow experimental codecs
        '-preset', 'medium',  # Encoding speed/quality tradeoff
        '-crf', '23',       # Constant Rate Factor (quality - lower is better)
        '-pix_fmt', 'yuv420p',  # Pixel format for compatibility
        str(mp4_file_path)  # Output file
    ]
    
    # Alternative command without preset for incompatible FFmpeg builds
    ffmpeg_cmd_simple = [
        'ffmpeg',
        '-y',  # Overwrite output files without asking
        '-i', str(mov_file_path),  # Input file
        '-c:v', 'libx264',  # Video codec
        '-c:a', 'aac',      # Audio codec
        '-strict', 'experimental',  # Allow experimental codecs
        '-crf', '23',       # Constant Rate Factor (quality - lower is better)
        '-pix_fmt', 'yuv420p',  # Pixel format for compatibility
        str(mp4_file_path)  # Output file
    ]
    
    # Stream copy command (fastest, no re-encoding)
    ffmpeg_cmd_copy = [
        'ffmpeg',
        '-y',  # Overwrite output files without asking
        '-i', str(mov_file_path),  # Input file
        '-c', 'copy',  # Copy streams without re-encoding
        str(mp4_file_path)  # Output file
    ]
    
    
    try:
        print(f"Converting '{mov_file_path.name}' to '{mp4_filename}'...")
        # Try with preset command first
        result = subprocess.run(
            ffmpeg_cmd,
            capture_output=True,
            text=True,
            timeout=300  # 5 minute timeout
        )
        
        # If preset command fails due to unrecognized preset option, try the simple command
        if result.returncode != 0 and "Unrecognized option 'preset'" in result.stderr:
            print("  Preset option not supported, trying alternative command...")
            result = subprocess.run(
                ffmpeg_cmd_simple,
                capture_output=True,
                text=True,
                timeout=300  # 5 minute timeout
            )
        
        # If both encoding methods fail, try stream copying (fastest method)
        if result.returncode != 0:
            print("  Encoding failed, trying stream copying...")
            result = subprocess.run(
                ffmpeg_cmd_copy,
                capture_output=True,
                text=True,
                timeout=300  # 5 minute timeout
            )
        
        if result.returncode == 0:
            print(f"✓ Successfully converted '{mov_file_path.name}'")
            return True
        else:
            print(f"✗ Error converting '{mov_file_path.name}':")
            print(f"  Return code: {result.returncode}")
            if result.stderr:
                print(f"  Error: {result.stderr}")
            return False
    except subprocess.TimeoutExpired:
        print(f"✗ Timeout converting '{mov_file_path.name}' (took more than 5 minutes)")
        return False
    except FileNotFoundError:
        print("✗ Error: FFmpeg not found. Please install FFmpeg and make sure it's in your PATH.")
        return False
    except Exception as e:
        print(f"✗ Unexpected error converting '{mov_file_path.name}': {e}")
        return False
def main():
    """Main function to run the converter"""
    print("=" * 60)
    print("MOV to MP4 CONVERTER")
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
    
    # Find MOV files
    print("\nSearching for MOV files...")
    mov_files = find_mov_files(folder_path)
    
    if not mov_files:
        print("No MOV files found in the selected folder.")
        return
    
    print(f"Found {len(mov_files)} MOV file(s):")
    for mov_file in mov_files:
        print(f"  - {mov_file.name}")
    
    # Confirm conversion
    if HAS_TK:
        try:
            root = tk.Tk()
            root.withdraw()
            confirm = messagebox.askyesno(
                "Confirm Conversion", 
                f"Found {len(mov_files)} MOV file(s). Convert all to MP4?\n\nOriginal files will be preserved."
            )
            root.destroy()
            if not confirm:
                print("Conversion cancelled by user.")
                return
        except Exception as e:
            print(f"GUI confirmation failed: {e}")
            print("Falling back to command line confirmation...")
            response = input(f"\nFound {len(mov_files)} MOV file(s).\nConvert all to MP4? Original files will be preserved. (y/n): ").strip().lower()
            if response not in ['y', 'yes']:
                print("Conversion cancelled by user.")
                return
    else:
        print(f"\nFound {len(mov_files)} MOV file(s).")
        response = input("Convert all to MP4? Original files will be preserved. (y/n): ").strip().lower()
        if response not in ['y', 'yes']:
            print("Conversion cancelled by user.")
            return
    
    # Convert files
    print("\nStarting conversion process...")
    successful_conversions = 0
    failed_conversions = 0
    
    folder = Path(folder_path)
    
    for mov_file in mov_files:
        if convert_mov_to_mp4(mov_file, folder):
            successful_conversions += 1
        else:
            failed_conversions += 1
    
    # Summary
    print("\n" + "=" * 60)
    print("CONVERSION SUMMARY")
    print("=" * 60)
    print(f"Successfully converted: {successful_conversions}")
    print(f"Failed conversions: {failed_conversions}")
    print(f"Total files processed: {len(mov_files)}")
    
    if failed_conversions > 0:
        print("\n⚠️  Some files failed to convert. Check the error messages above.")
    
    print("\n✅ Process completed!")
    print("Original MOV files have been preserved.")
    
    # Pause before exit if running from executable
    if HAS_TK:
        try:
            root = tk.Tk()
            root.withdraw()
            messagebox.showinfo("Conversion Complete", 
                              f"Conversion finished!\n\n"
                              f"Successfully converted: {successful_conversions}\n"
                              f"Failed conversions: {failed_conversions}")
            root.destroy()
        except:
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
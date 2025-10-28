#!/usr/bin/env python3

#

import subprocess
import os

def convert_to_5fps():
    """
    Convert test.mp4 to 5 FPS
    """
    input_video = '/Users/alanspace/Desktop/Work/EEE/Python/test.mp4'
    output_video = '/Users/alanspace/Desktop/Work/EEE/Python/test_5fps.mp4'
    
    if not os.path.exists(input_video):
        print(f"❌ Input video not found: {input_video}")
        return False
    
    # FFmpeg command to convert to 5 FPS
    cmd = [
        'ffmpeg', '-y',  # -y to overwrite output file
        '-i', input_video,
        '-r', '5',  # Set output frame rate to 5 FPS
        '-c:v', 'libx264',  # Use H.264 codec
        '-preset', 'fast',  # Fast encoding
        '-crf', '23',  # Good quality
        output_video
    ]
    
    print(f"Converting {input_video} to 5 FPS...")
    print(f"Output: {output_video}")
    
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        print("✅ Conversion successful!")
        
        # Get file sizes for comparison
        input_size = os.path.getsize(input_video) / (1024 * 1024)  # MB
        output_size = os.path.getsize(output_video) / (1024 * 1024)  # MB
        
        print(f"Input size: {input_size:.2f} MB")
        print(f"Output size: {output_size:.2f} MB")
        print(f"Size reduction: {((input_size - output_size) / input_size * 100):.1f}%")
        
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"❌ Error during conversion: {e}")
        if e.stderr:
            print(f"Error details: {e.stderr}")
        return False
    except FileNotFoundError:
        print("❌ FFmpeg not found. Please install FFmpeg.")
        return False

if __name__ == "__main__":
    print("Video FPS Converter")
    print("=" * 30)
    print("Converting test.mp4 to 5 FPS...")
    
    success = convert_to_5fps()
    
    if success:
        print("\n✅ Conversion completed successfully!")
        print("You can now use test_5fps.mp4 in your video dashboard script.")
    else:
        print("\n❌ Conversion failed.")


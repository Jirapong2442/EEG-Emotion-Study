#!/usr/bin/env python3

import subprocess
import os

def normalize_video_fps(input_video, output_video, target_fps=30):
    """
    Normalize video FPS using FFmpeg
    """
    cmd = [
        'ffmpeg', '-y',
        '-i', input_video,
        '-r', str(target_fps),
        '-c:v', 'libx264',
        '-preset', 'fast',
        '-crf', '23',
        output_video
    ]
    
    try:
        subprocess.run(cmd, check=True, capture_output=True)
        print(f"✅ Normalized {input_video} to {target_fps} FPS → {output_video}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Error normalizing {input_video}: {e}")
        return False

def main():
    print("Video FPS Normalizer")
    print("=" * 40)
    
    # Normalize both videos to 30 FPS
    videos = [
        ('/Users/alanspace/Desktop/Work/EEE/Python/test.mp4', '/Users/alanspace/Desktop/Work/EEE/Python/test_30fps.mp4'),
        ('/Users/alanspace/Desktop/Work/EEE/Python/test2.mp4', '/Users/alanspace/Desktop/Work/EEE/Python/test2_30fps.mp4')
    ]
    
    target_fps = 30
    
    for input_vid, output_vid in videos:
        if os.path.exists(input_vid):
            normalize_video_fps(input_vid, output_vid, target_fps)
        else:
            print(f"❌ Input video not found: {input_vid}")

if __name__ == "__main__":
    main()

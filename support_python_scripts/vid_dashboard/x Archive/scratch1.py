import cv2
import numpy as np
import subprocess
import os

# Open both video files
cap1 = cv2.VideoCapture('/Users/alanspace/Desktop/Work/EEE/Python/test.mp4')
cap2 = cv2.VideoCapture('/Users/alanspace/Desktop/Work/EEE/Python/test2.mp4')

if not cap1.isOpened() or not cap2.isOpened():
    print("Error: Could not open one or both video files.")
    exit()

# Get video properties
fps1 = cap1.get(cv2.CAP_PROP_FPS)
fps2 = cap2.get(cv2.CAP_PROP_FPS)
total_frames1 = int(cap1.get(cv2.CAP_PROP_FRAME_COUNT))
total_frames2 = int(cap2.get(cv2.CAP_PROP_FRAME_COUNT))

# Use the higher FPS for output
output_fps = max(fps1, fps2)
total_output_frames = max(total_frames1, total_frames2)

# Get frame dimensions
ret1, frame1 = cap1.read()
ret2, frame2 = cap2.read()

if not ret1 or not ret2:
    print("Error: Could not read frames from videos.")
    exit()

h1, w1 = frame1.shape[:2]
h2, w2 = frame2.shape[:2]

# Calculate dashboard dimensions
# Each video will be resized to fit in half the width
dashboard_width = max(w1, w2) * 2
dashboard_height = max(h1, h2) * 2

# Define the four quadrants
quadrant_width = dashboard_width // 2
quadrant_height = dashboard_height // 2

print(f"Dashboard size: {dashboard_width}x{dashboard_height}")
print(f"Quadrant size: {quadrant_width}x{quadrant_height}")
print(f"Output FPS: {output_fps}")
print(f"Total output frames: {total_output_frames}")

# Set up video writer (without audio first)
fourcc = cv2.VideoWriter_fourcc(*'mp4v')
video_output_path = '/Users/alanspace/Desktop/Work/EEE/Python/dashboard_video_temp.mp4'
out = cv2.VideoWriter(video_output_path, fourcc, output_fps, (dashboard_width, dashboard_height))

# Reset video positions
cap1.set(cv2.CAP_PROP_POS_FRAMES, 0)
cap2.set(cv2.CAP_PROP_POS_FRAMES, 0)

frame_count = 0
video1_ended = False
video2_ended = False

print("Creating dashboard video...")

while frame_count < total_output_frames:
    # Create black dashboard frame
    dashboard = np.zeros((dashboard_height, dashboard_width, 3), dtype=np.uint8)
    
    # Read frames from both videos
    if not video1_ended:
        ret1, frame1 = cap1.read()
        if not ret1:
            video1_ended = True
            print(f"Video 1 ended at frame {frame_count}")
    
    if not video2_ended:
        ret2, frame2 = cap2.read()
        if not ret2:
            video2_ended = True
            print(f"Video 2 ended at frame {frame_count}")
    
    # Place video 1 in top left (if not ended)
    if not video1_ended and ret1:
        # Resize frame1 to fit quadrant
        frame1_resized = cv2.resize(frame1, (quadrant_width, quadrant_height))
        dashboard[0:quadrant_height, 0:quadrant_width] = frame1_resized
    
    # Place video 2 in top right (if not ended)
    if not video2_ended and ret2:
        # Resize frame2 to fit quadrant
        frame2_resized = cv2.resize(frame2, (quadrant_width, quadrant_height))
        dashboard[0:quadrant_height, quadrant_width:quadrant_width*2] = frame2_resized
    
    # Bottom left and right remain black (already set to zeros)
    
    # Write the dashboard frame
    out.write(dashboard)
    
    frame_count += 1
    
    # Progress indicator
    if frame_count % 30 == 0:  # Every 30 frames
        progress = (frame_count / total_output_frames) * 100
        print(f"Progress: {progress:.1f}% ({frame_count}/{total_output_frames})")

# Clean up
cap1.release()
cap2.release()
out.release()
cv2.destroyAllWindows()

print(f"\nVideo processing completed!")
print(f"Total frames processed: {frame_count}")
print(f"Video 1 ended at frame: {total_frames1}")
print(f"Video 2 ended at frame: {total_frames2}")

# Now add audio using FFmpeg
print("\nAdding audio from both videos...")

# Get video durations for audio mixing
duration1 = total_frames1 / fps1 if fps1 > 0 else 0
duration2 = total_frames2 / fps2 if fps2 > 0 else 0
max_duration = max(duration1, duration2)

# Create FFmpeg command to combine video with mixed audio
final_output = '/Users/alanspace/Desktop/Work/EEE/Python/dashboard_output.mp4'

# FFmpeg command to mix audio from both videos and combine with our video
ffmpeg_cmd = [
    'ffmpeg', '-y',  # -y to overwrite output file
    '-i', video_output_path,  # Input video (our dashboard)
    '-i', '/Users/alanspace/Desktop/Work/EEE/Python/test.mp4',  # Audio from video 1
    '-i', '/Users/alanspace/Desktop/Work/EEE/Python/test2.mp4',  # Audio from video 2
    '-filter_complex', 
    f'[1:a]volume=0.5[a1];[2:a]volume=0.5[a2];[a1][a2]amix=inputs=2:duration=longest:dropout_transition=0[audio]',
    '-map', '0:v',  # Map video from first input
    '-map', '[audio]',  # Map mixed audio
    '-c:v', 'copy',  # Copy video without re-encoding
    '-c:a', 'aac',  # Encode audio as AAC
    '-shortest',  # End when shortest stream ends
    final_output
]

try:
    print("Running FFmpeg to add audio...")
    result = subprocess.run(ffmpeg_cmd, capture_output=True, text=True)
    
    if result.returncode == 0:
        print(f"✅ Dashboard video with audio created successfully!")
        print(f"Output file: {final_output}")
        
        # Clean up temporary file
        if os.path.exists(video_output_path):
            os.remove(video_output_path)
            print("Temporary video file removed.")
    else:
        print("❌ Error adding audio with FFmpeg:")
        print(result.stderr)
        print(f"Video without audio saved as: {video_output_path}")
        
except FileNotFoundError:
    print("❌ FFmpeg not found. Please install FFmpeg to add audio.")
    print(f"Video without audio saved as: {video_output_path}")
    print("You can manually add audio later using FFmpeg.")
except Exception as e:
    print(f"❌ Error running FFmpeg: {e}")
    print(f"Video without audio saved as: {video_output_path}")

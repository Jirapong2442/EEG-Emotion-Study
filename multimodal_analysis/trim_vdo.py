import cv2
import pandas as pd
import numpy as np
import argparse
import os

'''
if face this error 
Error: Could not read frame.
Video trimmed and cropped successfully and saved as output_trimmed_video.mp4
[av1 @ 0x27300b40] Your platform doesn't suppport hardware accelerated AV1 decoding.
[av1 @ 0x27300b40] Failed to get pixel format.
[av1 @ 0x27300b40] Missing Sequence Header.

change encoder from AV1 to h264 in command
ffmpeg -i ice_trial1.mp4 -c:v libx264 -preset fast -crf 23 OUTPUT_VDO_N AME.mp4
'''

parser = argparse.ArgumentParser(description="run")

parser.add_argument('--startTime', type=int, help='Start time when Relax Shows')
parser.add_argument('--endTime', type=int, help='End of the experiment')
parser.add_argument('--path_vdo', type=str, default='raw_vid/', help='Path to all videos')
parser.add_argument('--path_out_vdo', type=str, default='EMO-AffetNetModel-main/', help='Path to save the report')

args = parser.parse_args()

def crop_frame(frame, crop_percentage=0.25):
    """Crop left and right sides of the frame, keeping the middle portion."""
    height, width = frame.shape[:2]
    crop_pixels = int(width * crop_percentage)
    x_start = crop_pixels
    x_end = width - crop_pixels
    return frame[:, x_start:x_end], x_start

def trim_video(input_path, output_path, start_time, end_time, crop_percentage=0.2):
    # Open the video file
    cap = cv2.VideoCapture(input_path)
    if not cap.isOpened():
        print("Error: Could not open video.")
        return

    # Get video properties
    fps = cap.get(cv2.CAP_PROP_FPS)  # Frames per second
    frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    # Calculate start and end frames
    start_frame = int(start_time * fps)
    end_frame = int(end_time * fps)

    # Validate start and end times
    if start_frame >= total_frames or end_frame > total_frames or start_frame >= end_frame:
        print("Error: Invalid start or end time.")
        cap.release()
        return

    # Calculate cropped frame width
    cropped_width = int(frame_width * (1 - 2 * crop_percentage))

    # Set up video writer with cropped dimensions
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')  # Codec for MP4
    out = cv2.VideoWriter(output_path, fourcc, fps, (cropped_width, frame_height))

    # Set the starting frame
    cap.set(cv2.CAP_PROP_POS_FRAMES, start_frame)

    # Read and write frames within the specified range
    current_frame = start_frame
    while current_frame < end_frame:
        ret, frame = cap.read()
        if not ret:
            print("Error: Could not read frame.")
            break
        # Crop the frame
        cropped_frame, _ = crop_frame(frame, crop_percentage)
        out.write(cropped_frame)
        current_frame += 1

    # Release resources
    cap.release()
    out.release()
    print(f"Video trimmed and cropped successfully and saved as {output_path}")


if __name__ == "__main__":
    input_video =  "./p1_h.mp4"
    output_video = "./EMO-AffectNetModel-main/video/p1_trimmed.mp4"
    start_time = 28 #37  # Start at 5 seconds
    end_time = 636 #630   # End at 10 seconds
    trim_video(input_video, output_video, start_time, end_time, crop_percentage=0.25)


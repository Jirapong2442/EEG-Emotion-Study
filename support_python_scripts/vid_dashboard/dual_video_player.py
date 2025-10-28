import cv2
import numpy as np
import os
import json
try:
    import tkinter as tk
    from tkinter import filedialog, messagebox
    HAS_TK = True
except ImportError:
    HAS_TK = False

# Root paths (relative to this script)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Video file paths - will be populated by file selection
VIDEOS = [None, None]  # [first_video, second_video]

def select_video_file(title, file_types):
    """Open a file dialog to select a video file"""
    if HAS_TK:
        root = tk.Tk()
        root.withdraw()  # Hide the main window
        # Make the dialog stay on top
        root.attributes('-topmost', True)
        file_path = filedialog.askopenfilename(
            title=title,
            filetypes=file_types
        )
        root.destroy()
        return file_path
    else:
        # Fallback to command line input
        print(title)
        file_path = input("Enter the full path to the video file: ").strip()
        return file_path if os.path.exists(file_path) else None

def time_to_seconds(time_str):
    """Convert time string (HH:MM:SS) to total seconds"""
    parts = list(map(int, time_str.split(':')))
    if len(parts) == 3:
        hours, minutes, seconds = parts
        return hours * 3600 + minutes * 60 + seconds
    elif len(parts) == 2:
        minutes, seconds = parts
        return minutes * 60 + seconds
    else:
        return parts[0]

def seconds_to_time(total_seconds):
    """Convert total seconds to time string (HH:MM:SS)"""
    hours = int(total_seconds // 3600)
    minutes = int((total_seconds % 3600) // 60)
    seconds = int(total_seconds % 60)
    return f"{hours:02d}:{minutes:02d}:{seconds:02d}"


def ask_use_config(config_path):
    """Ask user if they want to use the existing config file"""
    if not HAS_TK:
        response = input(f"Found config file {config_path}. Use it? (y/n): ").strip().lower()
        return response in ['y', 'yes']
    else:
        root = tk.Tk()
        root.withdraw()
        root.attributes('-topmost', True)
        result = messagebox.askyesno("Config File Found", f"Found config file:\n{config_path}\n\nDo you want to use it?")
        root.destroy()
        return result

def load_config(config_path):
    """Load synchronization data from config file"""
    try:
        with open(config_path, 'r') as f:
            config = json.load(f)
        return config
    except Exception as e:
        print(f"Error loading config file: {e}")
        return None

def save_config(config_path, sync_points, start_frame, video_paths):
    """Save synchronization data to config file"""
    try:
        # Calculate delays between videos
        t1 = time_to_seconds(sync_points[0]['time'])
        t2 = time_to_seconds(sync_points[1]['time'])
        delay = t2 - t1  # Positive if video 2 is behind, negative if video 2 is ahead
        
        config = {
            'video1_path': video_paths[0],
            'video2_path': video_paths[1],
            'sync_points': sync_points,
            'start_frame': start_frame,
            'delay_seconds': delay,
            'which_video_is_behind': 2 if delay > 0 else (1 if delay < 0 else 0),  # 0 means synchronized
            'version': '1.0'
        }
        
        with open(config_path, 'w') as f:
            json.dump(config, f, indent=4)
        print(f"Configuration saved to {config_path}")
    except Exception as e:
        print(f"Error saving config file: {e}")

def select_two_videos():
    """Prompt user to select two video files"""
    global VIDEOS
    
    print("\nSelecting video files...")
    
    # Common video file types
    video_types = [
        ('Video files', '*.mp4 *.avi *.mov *.mkv *.wmv *.flv *.webm'),
        ('MP4 files', '*.mp4'),
        ('MOV files', '*.mov'),
        ('AVI files', '*.avi'),
        ('MKV files', '*.mkv'),
        ('All files', '*.*')
    ]
    
    # Select first video
    print("Please select the FIRST video file...")
    first_video = select_video_file("Select First Video File", video_types)
    if not first_video or not os.path.exists(first_video):
        print("First video file not selected or not found. Exiting.")
        return False, None
    
    # Check for config file
    config_path = os.path.join(os.path.dirname(first_video), 'vid_dashboard.config')
    if os.path.exists(config_path):
        print(f"Found config file: {config_path}")
        if ask_use_config(config_path):
            config = load_config(config_path)
            if config and 'video1_path' in config and 'video2_path' in config:
                # Verify the videos in config match the selected video
                if os.path.abspath(config['video1_path']) == os.path.abspath(first_video):
                    second_video = config['video2_path']
                    if os.path.exists(second_video):
                        VIDEOS = [first_video, second_video]
                        print("\nSelected videos (from config):")
                        print(f"  VIDEO 1: {VIDEOS[0]}")
                        print(f"  VIDEO 2: {VIDEOS[1]}")
                        return True, config
                    else:
                        print(f"Second video from config not found: {second_video}")
                else:
                    print("Config file doesn't match selected first video")
    
    # Select second video normally
    print("Please select the SECOND video file...")
    second_video = select_video_file("Select Second Video File", video_types)
    if not second_video or not os.path.exists(second_video):
        print("Second video file not selected or not found. Exiting.")
        return False, None
    
    # Store in order: first, second
    VIDEOS = [first_video, second_video]
    
    print("\nSelected videos:")
    print(f"  VIDEO 1: {VIDEOS[0]}")
    print(f"  VIDEO 2: {VIDEOS[1]}")
    
    return True, None
def play_video_for_sync(video_path, video_number, require_time_input=True):
    """Play video and get sync point from user"""
    cap = cv2.VideoCapture(video_path)
    
    if not cap.isOpened():
        print(f"Error: Could not open video file: {video_path}")
        return None
    
    # Get video properties
    fps = cap.get(cv2.CAP_PROP_FPS)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    duration = total_frames / fps if fps > 0 else 0
    
    print(f"\n=== Playing: {os.path.basename(video_path)} ===")
    print(f"Video FPS: {fps:.2f}")
    print(f"Total frames: {total_frames}")
    print(f"Duration: {duration:.2f} seconds")
    print("Controls: 'q' to quit, SPACEBAR to pause/resume, ','/'.' for frame-by-frame, 'j'/'l' for 10s skip, 'h'/';' for 30s skip, 'i'/'p' for 2s skip, 's' to return to start frame, ENTER to set sync point")
    
    paused = False
    current_frame = 0
    video_ended = False
    manually_paused = False

    while cap.isOpened():
        if not paused and not video_ended:
            ret, frame = cap.read()
            if not ret:
                video_ended = True
                print("Video ended - staying at last frame")
                # Stay at the last frame
                cap.set(cv2.CAP_PROP_POS_FRAMES, total_frames - 1)
                ret, frame = cap.read()
            else:
                current_frame = int(cap.get(cv2.CAP_PROP_POS_FRAMES)) - 1
        
        if ret:
            # Resize frame for better display
            height, width = frame.shape[:2]
            if width > 800:
                scale = 800 / width
                new_width = int(width * scale)
                new_height = int(height * scale)
                frame = cv2.resize(frame, (new_width, new_height))
            
            cv2.imshow('Video Player', frame)
            
            # Check for key presses
            key = cv2.waitKey(25) & 0xFF
            if key == ord('q'):  # Press 'q' to quit
                cap.release()
                cv2.destroyAllWindows()
                return None
            elif key == ord(' '):  # Press SPACEBAR to pause/resume
                paused = not paused
                manually_paused = paused
                print("Paused" if paused else "Resumed")
                # If resuming and not at the last frame, clear video_ended flag
                if not paused and current_frame < total_frames - 1:
                    video_ended = False
            elif key == 13:  # Press ENTER to set sync point
                print(f"ENTER pressed at frame {current_frame}")
                cap.release()
                cv2.destroyAllWindows()
                if not require_time_input:
                    return {'video': video_number, 'frame': current_frame, 'fps': fps}
                else:
                    try:
                        # Get time input from user
                        print("Getting user input...")
                        time_input = input(f"Enter time for current frame {current_frame} (HH:MM:SS format, e.g., 0:02:01). Enter 0 for 00:00:00: ").strip()
                        if time_input == '0':
                            time_input = '00:00:00'
                        print(f"User entered: {time_input}")
                        return {'video': video_number, 'frame': current_frame, 'time': time_input, 'fps': fps}
                    except Exception as e:
                        print(f"Error getting input: {e}")
                        return None
            elif key == ord(','):  # Press ',' to go back one frame
                if current_frame > 0:
                    current_frame -= 1
                    cap.set(cv2.CAP_PROP_POS_FRAMES, current_frame)
                    ret, frame = cap.read()
                    if ret:
                        # Resize frame for better display
                        height, width = frame.shape[:2]
                        if width > 800:
                            scale = 800 / width
                            new_width = int(width * scale)
                            new_height = int(height * scale)
                            frame = cv2.resize(frame, (new_width, new_height))
                        cv2.imshow('Video Player', frame)
                    print(f"Frame: {current_frame}")
                    # If video had ended and we're not at last frame, resume playing (unless manually paused)
                    if video_ended and current_frame < total_frames - 1 and not manually_paused:
                        video_ended = False
                        paused = False
                        print("Resumed playing")
            elif key == ord('.'):  # Press '.' to go forward one frame
                if current_frame < total_frames - 1:
                    current_frame += 1
                    cap.set(cv2.CAP_PROP_POS_FRAMES, current_frame)
                    ret, frame = cap.read()
                    if ret:
                        # Resize frame for better display
                        height, width = frame.shape[:2]
                        if width > 800:
                            scale = 800 / width
                            new_width = int(width * scale)
                            new_height = int(height * scale)
                            frame = cv2.resize(frame, (new_width, new_height))
                        cv2.imshow('Video Player', frame)
                    print(f"Frame: {current_frame}")
                    # If video had ended and we're not at last frame, resume playing (unless manually paused)
                    if video_ended and current_frame < total_frames - 1 and not manually_paused:
                        video_ended = False
                        paused = False
                        print("Resumed playing")
            elif key == ord('j'):  # Press 'j' to skip 10 seconds back
                frames_to_skip = int(10 * fps)
                new_frame = max(0, current_frame - frames_to_skip)
                current_frame = new_frame
                cap.set(cv2.CAP_PROP_POS_FRAMES, current_frame)
                ret, frame = cap.read()
                if ret:
                    # Resize frame for better display
                    height, width = frame.shape[:2]
                    if width > 800:
                        scale = 800 / width
                        new_width = int(width * scale)
                        new_height = int(height * scale)
                        frame = cv2.resize(frame, (new_width, new_height))
                    cv2.imshow('Video Player', frame)
                print(f"Skipped 10s back to frame: {current_frame}")
                # If video had ended and we're not at last frame, resume playing (unless manually paused)
                if video_ended and current_frame < total_frames - 1 and not manually_paused:
                    video_ended = False
                    paused = False
                    print("Resumed playing")
            elif key == ord('l'):  # Press 'l' to skip 10 seconds forward
                frames_to_skip = int(10 * fps)
                new_frame = min(total_frames - 1, current_frame + frames_to_skip)
                current_frame = new_frame
                cap.set(cv2.CAP_PROP_POS_FRAMES, current_frame)
                ret, frame = cap.read()
                if ret:
                    # Resize frame for better display
                    height, width = frame.shape[:2]
                    if width > 800:
                        scale = 800 / width
                        new_width = int(width * scale)
                        new_height = int(height * scale)
                        frame = cv2.resize(frame, (new_width, new_height))
                    cv2.imshow('Video Player', frame)
                print(f"Skipped 10s forward to frame: {current_frame}")
                # If video had ended and we're not at last frame, resume playing (unless manually paused)
                if video_ended and current_frame < total_frames - 1 and not manually_paused:
                    video_ended = False
                    paused = False
                    print("Resumed playing")
            elif key == ord('h'):  # Press 'h' to skip 30 seconds back
                frames_to_skip = int(30 * fps)
                new_frame = max(0, current_frame - frames_to_skip)
                current_frame = new_frame
                cap.set(cv2.CAP_PROP_POS_FRAMES, current_frame)
                ret, frame = cap.read()
                if ret:
                    # Resize frame for better display
                    height, width = frame.shape[:2]
                    if width > 800:
                        scale = 800 / width
                        new_width = int(width * scale)
                        new_height = int(height * scale)
                        frame = cv2.resize(frame, (new_width, new_height))
                    cv2.imshow('Video Player', frame)
                print(f"Skipped 30s back to frame: {current_frame}")
                # If video had ended and we're not at last frame, resume playing (unless manually paused)
                if video_ended and current_frame < total_frames - 1 and not manually_paused:
                    video_ended = False
                    paused = False
                    print("Resumed playing")
            elif key == ord(';'):  # Press ';' to skip 30 seconds forward
                frames_to_skip = int(30 * fps)
                new_frame = min(total_frames - 1, current_frame + frames_to_skip)
                current_frame = new_frame
                cap.set(cv2.CAP_PROP_POS_FRAMES, current_frame)
                ret, frame = cap.read()
                if ret:
                    # Resize frame for better display
                    height, width = frame.shape[:2]
                    if width > 800:
                        scale = 800 / width
                        new_width = int(width * scale)
                        new_height = int(height * scale)
                        frame = cv2.resize(frame, (new_width, new_height))
                    cv2.imshow('Video Player', frame)
                print(f"Skipped 30s forward to frame: {current_frame}")
                # If video had ended and we're not at last frame, resume playing (unless manually paused)
                if video_ended and current_frame < total_frames - 1 and not manually_paused:
                    video_ended = False
                    paused = False
                    print("Resumed playing")
            elif key == ord('i'):  # Press 'i' to skip 2 seconds back
                frames_to_skip = int(2 * fps)
                new_frame = max(0, current_frame - frames_to_skip)
                current_frame = new_frame
                cap.set(cv2.CAP_PROP_POS_FRAMES, current_frame)
                ret, frame = cap.read()
                if ret:
                    # Resize frame for better display
                    height, width = frame.shape[:2]
                    if width > 800:
                        scale = 800 / width
                        new_width = int(width * scale)
                        new_height = int(height * scale)
                        frame = cv2.resize(frame, (new_width, new_height))
                    cv2.imshow('Video Player', frame)
                print(f"Skipped 2s back to frame: {current_frame}")
                # If video had ended and we're not at last frame, resume playing (unless manually paused)
                if video_ended and current_frame < total_frames - 1 and not manually_paused:
                    video_ended = False
                    paused = False
                    print("Resumed playing")
            elif key == ord('p'):  # Press 'p' to skip 2 seconds forward
                frames_to_skip = int(2 * fps)
                new_frame = min(total_frames - 1, current_frame + frames_to_skip)
                current_frame = new_frame
                cap.set(cv2.CAP_PROP_POS_FRAMES, current_frame)
                ret, frame = cap.read()
                if ret:
                    # Resize frame for better display
                    height, width = frame.shape[:2]
                    if width > 800:
                        scale = 800 / width
                        new_width = int(width * scale)
                        new_height = int(height * scale)
                        frame = cv2.resize(frame, (new_width, new_height))
                    cv2.imshow('Video Player', frame)
                print(f"Skipped 2s forward to frame: {current_frame}")
                # If video had ended and we're not at last frame, resume playing (unless manually paused)
                if video_ended and current_frame < total_frames - 1 and not manually_paused:
                    video_ended = False
                    paused = False
                    print("Resumed playing")
            elif key == ord('s'):  # Press 's' to return to start frame
                # For frame selection, return to frame 0
                current_frame = 0
                cap.set(cv2.CAP_PROP_POS_FRAMES, current_frame)
                ret, frame = cap.read()
                if ret:
                    # Resize frame for better display
                    height, width = frame.shape[:2]
                    if width > 800:
                        scale = 800 / width
                        new_width = int(width * scale)
                        new_height = int(height * scale)
                        frame = cv2.resize(frame, (new_width, new_height))
                    cv2.imshow('Video Player', frame)
                print(f"Returned to start frame: {current_frame}")
                # Clear video_ended flag when returning to start
                if video_ended:
                    video_ended = False
                    paused = False
                    print("Resumed playing")
        else:
            break
    
    cap.release()
    cv2.destroyAllWindows()
    return None

def get_sync_points():
    """Get synchronization points by playing videos"""
    sync_points = []
    
    print("\n" + "="*60)
    print("DUAL VIDEO SYNCHRONIZATION SETUP")
    print("="*60)
    print("You will watch each video and set sync points.")
    print("Navigate to the frame you want, then press ENTER and enter the time.")
    print("="*60)
    
    # Play video 1 and get sync point
    video1_name = os.path.basename(VIDEOS[0])
    print(f"\n--- VIDEO 1 ({video1_name}) ---")
    print("Navigate to the frame you want to sync, then press ENTER")
    sync_point1 = play_video_for_sync(VIDEOS[0], 1, require_time_input=True)
    if sync_point1 is None:
        print("No sync point set for video 1. Exiting.")
        return None
    
    # Play video 2 and get sync point
    video2_name = os.path.basename(VIDEOS[1])
    print(f"\n--- VIDEO 2 ({video2_name}) ---")
    print("Navigate to the frame you want to sync, then press ENTER")
    sync_point2 = play_video_for_sync(VIDEOS[1], 2, require_time_input=True)
    if sync_point2 is None:
        print("No sync point set for video 2. Exiting.")
        return None
    
    # Play second video again to select start frame (no time input needed)
    print(f"\n--- VIDEO 2 PLAYBACK 2 ({video2_name}) ---")
    print("Navigate to the frame where you want both videos to start, then press ENTER")
    start_frame_data = play_video_for_sync(VIDEOS[1], 3, require_time_input=False)  # No time input needed
    start_frame = start_frame_data['frame'] if start_frame_data else 0
    if start_frame_data is None:
        print("No start frame set for second video. Will start from beginning.")
        start_frame = 0
    else:
        print(f"Both videos will start from frame: {start_frame}")
    
    sync_points = [sync_point1, sync_point2]
    
    print(f"\nSync points recorded:")
    print(f"Video 1: Frame {sync_point1['frame']} = {sync_point1['time']}")
    print(f"Video 2: Frame {sync_point2['frame']} = {sync_point2['time']}")
    print(f"Start frame: {start_frame}")
    
    return sync_points, start_frame

def calculate_alignment_params(sync_points, fps1, fps2, total_frames1, total_frames2):
    """Compute timeline alignment using selected frames and entered times.
    For each video i:
      index_i(t) = base_i + t * fps_i, where base_i = f_i - t_i * fps_i
    We choose a timeline [t_start, t_end] that covers when either video has valid frames.
    """
    # Extract
    f1 = sync_points[0]['frame']
    t1 = time_to_seconds(sync_points[0]['time'])
    f2 = sync_points[1]['frame']
    t2 = time_to_seconds(sync_points[1]['time'])

    # Bases so that at real time t, the frame index is base + t*fps
    base1 = f1 - t1 * fps1
    base2 = f2 - t2 * fps2

    # For each video, find t range where indices are within bounds [0, total-1]
    # Solve: 0 <= base + t*fps <= total-1
    # t >= (-base)/fps and t <= (total-1 - base)/fps
    t1_min = (-base1) / fps1
    t1_max = (total_frames1 - 1 - base1) / fps1
    t2_min = (-base2) / fps2
    t2_max = (total_frames2 - 1 - base2) / fps2

    # Overall timeline start/end (include any overlap or gaps -> black frames handled automatically)
    t_start = min(t1_min, t2_min)
    t_end = max(t1_max, t2_max)

    return {
        'base1': base1,
        'base2': base2,
        't_start': t_start,
        't_end': t_end,
        't1': t1,
        't2': t2,
        'f1': f1,
        'f2': f2,
    }

def play_videos_simultaneously(sync_points, start_frame):
    """Play both videos simultaneously with synchronized navigation"""
    # Open both video files
    cap1 = cv2.VideoCapture(VIDEOS[0])
    cap2 = cv2.VideoCapture(VIDEOS[1])

    if not cap1.isOpened() or not cap2.isOpened():
        print("Error: Could not open one or both video files.")
        return

    # Get video properties
    fps1 = cap1.get(cv2.CAP_PROP_FPS)
    fps2 = cap2.get(cv2.CAP_PROP_FPS)
    total_frames1 = int(cap1.get(cv2.CAP_PROP_FRAME_COUNT))
    total_frames2 = int(cap2.get(cv2.CAP_PROP_FRAME_COUNT))

    print(f"\nVideo 1: {fps1:.2f} FPS, {total_frames1} frames")
    print(f"Video 2: {fps2:.2f} FPS, {total_frames2} frames")

    # Compute alignment based on selected frames and entered times
    align = calculate_alignment_params(sync_points, fps1, fps2, total_frames1, total_frames2)
    base1 = align['base1']
    base2 = align['base2']
    t_start = align['t_start']
    t_end = align['t_end']

    # Use the higher FPS for output
    output_fps = max(fps1, fps2)

    # Get frame dimensions
    ret1, frame1 = cap1.read()
    ret2, frame2 = cap2.read()

    if not ret1 or not ret2:
        print("Error: Could not read frames from videos.")
        return

    # Reset video positions
    cap1.set(cv2.CAP_PROP_POS_FRAMES, 0)
    cap2.set(cv2.CAP_PROP_POS_FRAMES, 0)

    # Calculate the time corresponding to the start frame
    # Using video 2's parameters since that's what we're using for the start frame
    start_time = (start_frame - base2) / fps2
    
    # Calculate the starting frame indices for both videos at start_time
    start_idx1 = int(round(base1 + start_time * fps1))
    start_idx2 = int(round(base2 + start_time * fps2))
    
    print(f"\nStarting synchronized playback from time: {start_time:.3f}s")
    print(f"Video 1 will start at frame: {start_idx1}")
    print(f"Video 2 will start at frame: {start_idx2}")

    # Set video positions to start frames
    cap1.set(cv2.CAP_PROP_POS_FRAMES, max(0, start_idx1))
    cap2.set(cv2.CAP_PROP_POS_FRAMES, max(0, start_idx2))

    # Initialize variables for synchronized playback
    paused = False
    manually_paused = False
    current_time = start_time
    time_step = 1.0 / output_fps
    last_valid_frame1 = None
    last_valid_frame2 = None
    video1_ended = False
    video2_ended = False
    
    print("\nPlaying videos simultaneously...")
    print("Controls: 'q' to quit, SPACEBAR to pause/resume, ','/'.' for frame-by-frame, 'j'/'l' for 10s skip, 'h'/';' for 30s skip")

    while True:
        # Calculate current frame indices
        current_idx1 = int(round(base1 + current_time * fps1))
        current_idx2 = int(round(base2 + current_time * fps2))
        
        # Check if either video has reached its boundaries
        video1_before_start = current_idx1 < 0
        video1_after_end = current_idx1 >= total_frames1
        video2_before_start = current_idx2 < 0
        video2_after_end = current_idx2 >= total_frames2
        
        # Update ended flags
        if video1_before_start or video1_after_end:
            video1_ended = True
        if video2_before_start or video2_after_end:
            video2_ended = True
        
        # If either video has ended, pause both videos
        if video1_ended or video2_ended:
            # Both videos should freeze - stop advancing time
            pass
        # If both videos have truly ended (reached the actual end), stop playback
        elif video1_ended and video2_ended:
            print("Both videos have ended. Stopping playback.")
            break
        
        # Read frames from both videos
        frame1 = None
        frame2 = None
        
        # Read frame 1 if in range
        if not video1_before_start and not video1_after_end:
            cap1.set(cv2.CAP_PROP_POS_FRAMES, current_idx1)
            ret1, temp_frame1 = cap1.read()
            if ret1:
                frame1 = temp_frame1
                last_valid_frame1 = temp_frame1.copy()
        
        # Read frame 2 if in range
        if not video2_before_start and not video2_after_end:
            cap2.set(cv2.CAP_PROP_POS_FRAMES, current_idx2)
            ret2, temp_frame2 = cap2.read()
            if ret2:
                frame2 = temp_frame2
                last_valid_frame2 = temp_frame2.copy()
        
        # Use last valid frames if current frames are None
        if frame1 is None and last_valid_frame1 is not None:
            frame1 = last_valid_frame1
        if frame2 is None and last_valid_frame2 is not None:
            frame2 = last_valid_frame2
        
        # Create side-by-side display
        if frame1 is not None or frame2 is not None:
            # Resize frames to similar heights for better display
            target_height = 400
            
            if frame1 is not None:
                h1, w1 = frame1.shape[:2]
                scale1 = target_height / h1
                new_w1 = int(w1 * scale1)
                new_h1 = int(h1 * scale1)
                resized_frame1 = cv2.resize(frame1, (new_w1, new_h1))
            else:
                new_w1 = 400
                new_h1 = target_height
                resized_frame1 = np.zeros((new_h1, new_w1, 3), dtype=np.uint8)
                cv2.putText(resized_frame1, "NO FRAME", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
            
            if frame2 is not None:
                h2, w2 = frame2.shape[:2]
                scale2 = target_height / h2
                new_w2 = int(w2 * scale2)
                new_h2 = int(h2 * scale2)
                resized_frame2 = cv2.resize(frame2, (new_w2, new_h2))
            else:
                new_w2 = 400
                new_h2 = target_height
                resized_frame2 = np.zeros((new_h2, new_w2, 3), dtype=np.uint8)
                cv2.putText(resized_frame2, "NO FRAME", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
            
            # Create a combined frame
            combined_width = new_w1 + new_w2
            combined_frame = np.zeros((target_height, combined_width, 3), dtype=np.uint8)
            
            # Place frames side by side
            combined_frame[0:new_h1, 0:new_w1] = resized_frame1
            combined_frame[0:new_h2, new_w1:new_w1+new_w2] = resized_frame2
            
            # Add labels
            cv2.putText(combined_frame, f"VIDEO 1: {os.path.basename(VIDEOS[0])}",
                       (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
            cv2.putText(combined_frame, f"VIDEO 2: {os.path.basename(VIDEOS[1])}",
                       (new_w1 + 10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
            
            # Add frame info and status
            status1 = "ENDED" if (video1_before_start or video1_after_end) else f"Frame: {current_idx1}"
            status2 = "ENDED" if (video2_before_start or video2_after_end) else f"Frame: {current_idx2}"
            color1 = (0, 0, 255) if (video1_before_start or video1_after_end) else (255, 255, 255)
            color2 = (0, 0, 255) if (video2_before_start or video2_after_end) else (255, 255, 255)
            
            # Move frame number to top right
            cv2.putText(combined_frame, status1,
                       (new_w1 - 150, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.6, color1, 1)
            cv2.putText(combined_frame, status2,
                       (combined_width - 150, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.6, color2, 1)
            
            # Add millisecond timer to bottom left of second video (right video)
            # Calculate milliseconds from start_time and current_time
            elapsed_time_ms = int((current_time - start_time) * 1000)
            timer_text = f"{elapsed_time_ms} ms"
            cv2.putText(combined_frame, timer_text,
                       (new_w1 + 10, target_height - 20), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 0), 1)
            
            cv2.imshow('Dual Video Player', combined_frame)
        else:
            # Both videos have no frames to show
            print("Both videos have no frames to display. Stopping playback.")
            break
        
        # Advance time only if not manually paused and neither video has ended
        if not manually_paused and not (video1_ended or video2_ended):
            current_time += time_step
        
        # Handle keyboard input
        key = cv2.waitKey(25) & 0xFF
        if key == ord('q'):  # Press 'q' to quit
            break
        elif key == ord(' '):  # Press SPACEBAR to pause/resume
            paused = not paused
            manually_paused = paused
            print("Paused" if paused else "Resumed")
        elif key == ord(','):  # Press ',' to go back one frame
            # Calculate new time
            new_time = current_time - time_step
            
            # Calculate what the new indices would be
            new_idx1 = int(round(base1 + new_time * fps1))
            new_idx2 = int(round(base2 + new_time * fps2))
            
            # Apply the new time (move both videos together)
            current_time = new_time
            print(f"Time: {current_time:.3f}s, Frames: {new_idx1}, {new_idx2}")
            
            # Reset ended flags if we're going back into valid range
            if 0 <= new_idx1 < total_frames1:
                video1_ended = False
            if 0 <= new_idx2 < total_frames2:
                video2_ended = False
        elif key == ord('.'):  # Press '.' to go forward one frame
            # Calculate new time
            new_time = current_time + time_step
            
            # Calculate what the new indices would be
            new_idx1 = int(round(base1 + new_time * fps1))
            new_idx2 = int(round(base2 + new_time * fps2))
            
            # Apply the new time (move both videos together)
            current_time = new_time
            print(f"Time: {current_time:.3f}s, Frames: {new_idx1}, {new_idx2}")
            
            # Reset ended flags if we're going back into valid range
            if 0 <= new_idx1 < total_frames1:
                video1_ended = False
            if 0 <= new_idx2 < total_frames2:
                video2_ended = False
        elif key == ord('j'):  # Press 'j' to skip 10 seconds back
            # Calculate new time
            new_time = current_time - 10
            
            # Calculate what the new indices would be
            new_idx1 = int(round(base1 + new_time * fps1))
            new_idx2 = int(round(base2 + new_time * fps2))
            
            # Check boundaries to determine which video reaches limits first
            video1_new_in_range = 0 <= new_idx1 < total_frames1
            video2_new_in_range = 0 <= new_idx2 < total_frames2
            
            # If both videos would be out of range, adjust to keep at least one in range
            if not video1_new_in_range and not video2_new_in_range:
                # Find the limiting factor
                if new_idx1 < 0 and new_idx2 < 0:
                    # Both would be before start, use the one that hits start last
                    time_if_1_at_start = (0 - base1) / fps1
                    time_if_2_at_start = (0 - base2) / fps2
                    current_time = max(time_if_1_at_start, time_if_2_at_start)
                elif new_idx1 >= total_frames1 and new_idx2 >= total_frames2:
                    # Both would be after end, use the one that hits end first
                    time_if_1_at_end = ((total_frames1 - 1) - base1) / fps1
                    time_if_2_at_end = ((total_frames2 - 1) - base2) / fps2
                    current_time = min(time_if_1_at_end, time_if_2_at_end)
                elif new_idx1 < 0:
                    # Only video 1 would be before start
                    current_time = (0 - base1) / fps1
                elif new_idx2 < 0:
                    # Only video 2 would be before start
                    current_time = (0 - base2) / fps2
                elif new_idx1 >= total_frames1:
                    # Only video 1 would be after end
                    current_time = ((total_frames1 - 1) - base1) / fps1
                elif new_idx2 >= total_frames2:
                    # Only video 2 would be after end
                    current_time = ((total_frames2 - 1) - base2) / fps2
            else:
                # At least one video is in range, apply the new time
                current_time = new_time
            
            # Recalculate indices after adjustment
            final_idx1 = int(round(base1 + current_time * fps1))
            final_idx2 = int(round(base2 + current_time * fps2))
            print(f"Skipped 10s back to time: {current_time:.3f}s, Frames: {final_idx1}, {final_idx2}")
            
            # Reset ended flags if we're going back into valid range
            if 0 <= final_idx1 < total_frames1:
                video1_ended = False
            if 0 <= final_idx2 < total_frames2:
                video2_ended = False
        elif key == ord('l'):  # Press 'l' to skip 10 seconds forward
            # Calculate new time
            new_time = current_time + 10
            
            # Calculate what the new indices would be
            new_idx1 = int(round(base1 + new_time * fps1))
            new_idx2 = int(round(base2 + new_time * fps2))
            
            # Check boundaries to determine which video reaches limits first
            video1_new_in_range = 0 <= new_idx1 < total_frames1
            video2_new_in_range = 0 <= new_idx2 < total_frames2
            
            # If both videos would be out of range, adjust to keep at least one in range
            if not video1_new_in_range and not video2_new_in_range:
                # Find the limiting factor
                if new_idx1 < 0 and new_idx2 < 0:
                    # Both would be before start, use the one that hits start last
                    time_if_1_at_start = (0 - base1) / fps1
                    time_if_2_at_start = (0 - base2) / fps2
                    current_time = max(time_if_1_at_start, time_if_2_at_start)
                elif new_idx1 >= total_frames1 and new_idx2 >= total_frames2:
                    # Both would be after end, use the one that hits end first
                    time_if_1_at_end = ((total_frames1 - 1) - base1) / fps1
                    time_if_2_at_end = ((total_frames2 - 1) - base2) / fps2
                    current_time = min(time_if_1_at_end, time_if_2_at_end)
                elif new_idx1 < 0:
                    # Only video 1 would be before start
                    current_time = (0 - base1) / fps1
                elif new_idx2 < 0:
                    # Only video 2 would be before start
                    current_time = (0 - base2) / fps2
                elif new_idx1 >= total_frames1:
                    # Only video 1 would be after end
                    current_time = ((total_frames1 - 1) - base1) / fps1
                elif new_idx2 >= total_frames2:
                    # Only video 2 would be after end
                    current_time = ((total_frames2 - 1) - base2) / fps2
            else:
                # At least one video is in range, apply the new time
                current_time = new_time
            
            # Recalculate indices after adjustment
            final_idx1 = int(round(base1 + current_time * fps1))
            final_idx2 = int(round(base2 + current_time * fps2))
            print(f"Skipped 10s forward to time: {current_time:.3f}s, Frames: {final_idx1}, {final_idx2}")
            
            # Reset ended flags if we're going back into valid range
            if 0 <= final_idx1 < total_frames1:
                video1_ended = False
            if 0 <= final_idx2 < total_frames2:
                video2_ended = False
        elif key == ord('h'):  # Press 'h' to skip 30 seconds back
            # Calculate new time
            new_time = current_time - 30
            
            # Calculate what the new indices would be
            new_idx1 = int(round(base1 + new_time * fps1))
            new_idx2 = int(round(base2 + new_time * fps2))
            
            # Check boundaries to determine which video reaches limits first
            video1_new_in_range = 0 <= new_idx1 < total_frames1
            video2_new_in_range = 0 <= new_idx2 < total_frames2
            
            # If both videos would be out of range, adjust to keep at least one in range
            if not video1_new_in_range and not video2_new_in_range:
                # Find the limiting factor
                if new_idx1 < 0 and new_idx2 < 0:
                    # Both would be before start, use the one that hits start last
                    time_if_1_at_start = (0 - base1) / fps1
                    time_if_2_at_start = (0 - base2) / fps2
                    current_time = max(time_if_1_at_start, time_if_2_at_start)
                elif new_idx1 >= total_frames1 and new_idx2 >= total_frames2:
                    # Both would be after end, use the one that hits end first
                    time_if_1_at_end = ((total_frames1 - 1) - base1) / fps1
                    time_if_2_at_end = ((total_frames2 - 1) - base2) / fps2
                    current_time = min(time_if_1_at_end, time_if_2_at_end)
                elif new_idx1 < 0:
                    # Only video 1 would be before start
                    current_time = (0 - base1) / fps1
                elif new_idx2 < 0:
                    # Only video 2 would be before start
                    current_time = (0 - base2) / fps2
                elif new_idx1 >= total_frames1:
                    # Only video 1 would be after end
                    current_time = ((total_frames1 - 1) - base1) / fps1
                elif new_idx2 >= total_frames2:
                    # Only video 2 would be after end
                    current_time = ((total_frames2 - 1) - base2) / fps2
            else:
                # At least one video is in range, apply the new time
                current_time = new_time
            
            # Recalculate indices after adjustment
            final_idx1 = int(round(base1 + current_time * fps1))
            final_idx2 = int(round(base2 + current_time * fps2))
            print(f"Skipped 30s back to time: {current_time:.3f}s, Frames: {final_idx1}, {final_idx2}")
            
            # Reset ended flags if we're going back into valid range
            if 0 <= final_idx1 < total_frames1:
                video1_ended = False
            if 0 <= final_idx2 < total_frames2:
                video2_ended = False
        elif key == ord(';'):  # Press ';' to skip 30 seconds forward
            # Calculate new time
            new_time = current_time + 30
            
            # Calculate what the new indices would be
            new_idx1 = int(round(base1 + new_time * fps1))
            new_idx2 = int(round(base2 + new_time * fps2))
            
            # Check boundaries to determine which video reaches limits first
            video1_new_in_range = 0 <= new_idx1 < total_frames1
            video2_new_in_range = 0 <= new_idx2 < total_frames2
            
            # If both videos would be out of range, adjust to keep at least one in range
            if not video1_new_in_range and not video2_new_in_range:
                # Find the limiting factor
                if new_idx1 < 0 and new_idx2 < 0:
                    # Both would be before start, use the one that hits start last
                    time_if_1_at_start = (0 - base1) / fps1
                    time_if_2_at_start = (0 - base2) / fps2
                    current_time = max(time_if_1_at_start, time_if_2_at_start)
                elif new_idx1 >= total_frames1 and new_idx2 >= total_frames2:
                    # Both would be after end, use the one that hits end first
                    time_if_1_at_end = ((total_frames1 - 1) - base1) / fps1
                    time_if_2_at_end = ((total_frames2 - 1) - base2) / fps2
                    current_time = min(time_if_1_at_end, time_if_2_at_end)
                elif new_idx1 < 0:
                    # Only video 1 would be before start
                    current_time = (0 - base1) / fps1
                elif new_idx2 < 0:
                    # Only video 2 would be before start
                    current_time = (0 - base2) / fps2
                elif new_idx1 >= total_frames1:
                    # Only video 1 would be after end
                    current_time = ((total_frames1 - 1) - base1) / fps1
                elif new_idx2 >= total_frames2:
                    # Only video 2 would be after end
                    current_time = ((total_frames2 - 1) - base2) / fps2
            else:
                # At least one video is in range, apply the new time
                current_time = new_time
            
            # Recalculate indices after adjustment
            final_idx1 = int(round(base1 + current_time * fps1))
            final_idx2 = int(round(base2 + current_time * fps2))
            print(f"Skipped 30s forward to time: {current_time:.3f}s, Frames: {final_idx1}, {final_idx2}")
            
            # Reset ended flags if we're going back into valid range
            if 0 <= final_idx1 < total_frames1:
                video1_ended = False
            if 0 <= final_idx2 < total_frames2:
                video2_ended = False
    
    # Clean up
    cap1.release()
    cap2.release()
    cv2.destroyAllWindows()

def main():
    print("="*60)
    print("DUAL VIDEO PLAYER WITH SYNCHRONIZATION")
    print("="*60)
    
    # Ask user to select two video files
    print("\nSelect two video files for playback...")
    success, config = select_two_videos()
    if not success:
        return

    # If config was loaded, use it directly
    if config and 'sync_points' in config and 'start_frame' in config:
        print("Using synchronization data from config file...")
        sync_points = config['sync_points']
        start_frame = config['start_frame']
    else:
        # Get synchronization points from user
        sync_result = get_sync_points()
        if not sync_result:
            print("Failed to collect sync points. Exiting.")
            return
        sync_points, start_frame = sync_result
        
        # Check if sync points were collected successfully
        if not sync_points or len(sync_points) < 2:
            print("Failed to collect sync points. Exiting.")
            return
        
        # Save config file
        config_path = os.path.join(os.path.dirname(VIDEOS[0]), 'vid_dashboard.config')
        save_config(config_path, sync_points, start_frame, VIDEOS)
    
    # Play both videos simultaneously
    play_videos_simultaneously(sync_points, start_frame)
    
    print("\n" + "="*60)
    print("PLAYBACK COMPLETED!")
    print("="*60)

if __name__ == "__main__":
    main()
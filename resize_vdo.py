import os
from moviepy.editor import *

# Define input and output parameters
path_folder = "C:/Users/NA/Saved Games/cloned/reels3/original/"
output_folder = "C:/Users/NA/Saved Games/cloned/reels3/"
new_width = 450
new_height = 800

# Process each video file in the folder
for file in os.listdir(path_folder):
    if file.endswith('.mp4'):
        file_name = file[:-4]
        out_name = "resized_" + file
        input_path = os.path.join(path_folder, file)
        out_path = os.path.join(output_folder, out_name)

        try:
            # Load the video file
            video = VideoFileClip(input_path)
            video = video.volumex(0.8)

            # Resize (crop) the video to the desired dimensions
            resized_video = video.resize((new_width, new_height))

            # Write the output video with audio
            resized_video.write_videofile(out_path, codec='libx264', audio_codec='aac')

            # Close the video file to free resources
            resized_video.close()
            video.close()

            print(f"Video cropped and saved with audio as {out_path}")

        except Exception as e:
            print(f"Error processing {file}: {str(e)}")
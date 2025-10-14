import os
from moviepy.editor import *

def resize_vdo(folder_name, width=450, height=800, main_path = "C:/Users/NA/jirapong/cloned/new_reels/", resize_path = "resized/"):

    folder_name = folder_name
    path_folder = main_path + folder_name + "/"
    output_folder = path_folder + resize_path
    new_width = width
    new_height = height

    try:
        os.mkdir(output_folder)
    except FileExistsError:
        pass

    file_names = os.listdir(path_folder)
    name = 1
    # Process each video file in the folder
    for file in file_names:
        if file.endswith('.mp4'):
            new_name = 'v' + str(name) 
            name += 1
            try:
                os.rename(os.path.join(path_folder, file), os.path.join(path_folder, new_name + '.mp4'))
            except FileExistsError:
                pass 
            #file_name = file[:-4]
            out_name =  new_name
            input_path = os.path.join(path_folder, out_name) + '.mp4'
            out_path = os.path.join(output_folder, out_name) + '.mp4'

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

if __name__ == "__main__":
    input_path = "C:/Users/NA/jirapong/cloned/new_reels/p2g_5/v15.mp4"
    out_path = "C:/Users/NA/jirapong/cloned/new_reels/p2g_5/resized/v15.mp4"
    video = VideoFileClip(input_path)
    video = video.volumex(0.8)

    # Resize (crop) the video to the desired dimensions
    resized_video = video.resize((450, 800))

    # Write the output video with audio
    resized_video.write_videofile(out_path, codec='libx264', audio_codec='aac')

    # Close the video file to free resources
    resized_video.close()
    video.close()

    print(f"Video cropped and saved with audio as {out_path}")
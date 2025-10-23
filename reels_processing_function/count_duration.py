import cv2
import pandas as pd
from moviepy import *
import os

main_path  = "C:/Users/NA/jirapong/cloned/new_reels/"
folder_name = os.listdir(main_path)

for folder in folder_name:
    current_path = os.path.join(main_path,folder)
    if os.path.isdir(current_path):
        print(folder)
        #path_folder = "C:/Users/NA/jirapong/cloned/new_reels/g2p_1/"
        file_names = os.listdir(current_path)
        time = []
        vid_name = []
        for file in file_names:
            if file.endswith('.mp4'):
                input_path = os.path.join(current_path, file) 
                video = VideoFileClip(input_path)
                vid_name.append(file[:-4])
                time.append(video.duration * 1000)
            else:
                pass
        zip_list = list(zip(vid_name, time))
        vid_time = pd.DataFrame(zip_list,columns=["video", "duration(ms)"])
        vid_time.to_csv(main_path + folder + "_vid_duration.csv")
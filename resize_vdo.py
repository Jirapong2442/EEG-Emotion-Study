import cv2
import os

path_folder = "C:/Users/NA/Saved Games/reels1/"
new_width = 450
new_height = 800

for file in os.listdir(path_folder):
    if '.mp4' in file:
        file_name = file[:-4]
        out_name = "resized_" + file
        cap = cv2.VideoCapture(os.path.join(path_folder,file))
        if not cap.isOpened():
            print("Error: could not open VDO")

        fps = cap.get(cv2.CAP_PROP_FPS)
        num_frame = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')  
        out_path_vod = os.path.join(path_folder,out_name)
        out_vdo = cv2.VideoWriter(out_path_vod, fourcc, fps, (new_width, new_height))

        current_frame = 0
        while current_frame < num_frame:
            ret, frame = cap.read()
            if not ret:
                print("Error: Could not read frame.")
                break
            resized_frame = cv2.resize(frame, (new_width, new_height), interpolation=cv2.INTER_AREA)
            out_vdo.write(resized_frame)
            current_frame += 1

        # Release resources
        cap.release()
        out_vdo.release()
        print(f"Video trimmed and cropped successfully and saved as {out_path_vod}")


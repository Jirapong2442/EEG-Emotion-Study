import instaloader
from instaloader import Post
import os
from moviepy.editor import *
import requests

def download_reels(out_name, main_path = "C:/Users/NA/jirapong/cloned/new_reels/", url_path = "code.txt"):
    out_path = os.path.join(main_path, out_name)
    in_url = out_path +'/' + url_path

    with open(in_url, 'r') as file:
        urls = file.readlines()
        url_list =urls[0].split(',')
        code_list = [url.strip().split('/')[4] for url in url_list] # get code only
        print(code_list)
        file.close()

    vid_num = 1
    L = instaloader.Instaloader()
    L.login("alan_eeg_xp_2", "abcdefg12345>>") # or L.login("your_username", "your_password")
    for code in code_list:
        post = Post.from_shortcode(L.context, code)
        url = post.video_url
        response = requests.get(url, stream=True)
        if response.status_code == 200:
            vid_name = 'v' + str(vid_num)+ '.mp4'
            vid_num += 1
            with open(os.path.join(out_path, vid_name), 'wb') as file:
                for chunk in response.iter_content(chunk_size=1024):
                    if chunk:
                        file.write(chunk)

if __name__ == "__main__":
    pass
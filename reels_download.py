from reels_processing_function import insta_loader, resize_vdo
import argparse
parser = argparse.ArgumentParser(description="A script that folder path of video that we want to resize.")
parser.add_argument("--folder_name", type=str, help="folder name", required=True)

args = parser.parse_args()
insta_loader.download_reels(out_name=args.folder_name)
resize_vdo.resize_vdo(folder_name=args.folder_name)

import torch
import cv2
import numpy as np
from transformers import VideoMAEImageProcessor, VideoMAEForVideoClassification
from function import extract_frames

video_path = "./reels1/v1_58.mp4"
frames = extract_frames(video_path)
processor = VideoMAEImageProcessor.from_pretrained("MCG-NJU/videomae-base-finetuned-kinetics")
model = VideoMAEForVideoClassification.from_pretrained("MCG-NJU/videomae-base-finetuned-kinetics")

inputs = processor(frames, return_tensors="pt")
with torch.no_grad():
  outputs = model(**inputs)
  logits = outputs.logits

predicted_class_idx = logits.argmax(-1).item()
print("Predicted class:", model.config.id2label[predicted_class_idx])


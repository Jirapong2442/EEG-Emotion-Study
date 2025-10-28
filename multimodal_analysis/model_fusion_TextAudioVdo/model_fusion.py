import torch
import torch.nn as nn
from transformers import AutoTokenizer, AutoProcessor, AutoModel, AutoImageProcessor, AutoFeatureExtractor, ASTForAudioClassification, Wav2Vec2FeatureExtractor, Wav2Vec2Model# ViTImageProcessor, ViTModel  #BertTokenizer, BertModel,
from moviepy import *
import whisper
import cv2
import numpy as np
from speechbrain.inference.interfaces import foreign_class
import librosa
from speechbrain.inference import EncoderClassifier
from PIL import Image
from sklearn.decomposition import PCA

# Load pre-trained models
#Roberta for sentiment classification
text_tokenizer = AutoTokenizer.from_pretrained('cardiffnlp/twitter-roberta-base-sentiment-latest')
text_model = AutoModel.from_pretrained('cardiffnlp/twitter-roberta-base-sentiment-latest')

audio_feature_extractor = AutoFeatureExtractor.from_pretrained("MIT/ast-finetuned-audioset-10-10-0.4593")
audio_model = ASTForAudioClassification.from_pretrained("MIT/ast-finetuned-audioset-10-10-0.4593")
#for image classification
#image_processor = ViTImageProcessor.from_pretrained('google/vit-base-patch16-224')
#image_model = ViTModel.from_pretrained('google/vit-base-patch16-224')

#for image feature extraction
image_feature_processor = AutoImageProcessor.from_pretrained('facebook/dinov2-small')
image_feature_model = AutoModel.from_pretrained('facebook/dinov2-small')

#image classification with provided label text
vid_model = AutoModel.from_pretrained("openai/clip-vit-base-patch32", attn_implementation="sdpa")
vid_processor = AutoProcessor.from_pretrained("openai/clip-vit-base-patch32")
# for audio emotion classfication
audio_classifier = foreign_class(
    source="speechbrain/emotion-recognition-wav2vec2-IEMOCAP",
    pymodule_file="custom_interface.py",
    classname="CustomEncoderWav2vec2Classifier",
    run_opts={"device": "cuda" if torch.cuda.is_available() else "cpu"}
)


def extract_modalities(video_path):
    separator = '/'
    out_path = separator.join(video_path.split("/")[:-1]) + separator
    # Extract audio
    video = VideoFileClip(video_path)
    audio_path = out_path + "temp_audio.wav"
    video.audio.write_audiofile(audio_path)
    
    # Transcribe audio to text
    whisper_model = whisper.load_model("base")
    transcription = whisper_model.transcribe(audio_path, verbose=False, word_timestamps=False)
    
    # Extract segments with timestamps
    text_segments = [
        {"text": segment["text"], "start": segment["start"], "end": segment["end"]}
        for segment in transcription["segments"]
    ]
    
    # Extract keyframes for visual analysis
    cap = cv2.VideoCapture(video_path)
    frames = []
    frame_count = 0
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        if frame_count % 30== 0: # extract every 30 frame
            # Convert BGR (OpenCV) to RGB (PIL)
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            frames.append(Image.fromarray(frame_rgb))
        frame_count += 1
    cap.release()
    
    return text_segments, audio_path, frames

def process_text(text_segments):
    text_embeddings = []
    for segment in text_segments:
        text = segment["text"]
        inputs = text_tokenizer(text, return_tensors="pt", truncation=True, padding=True, max_length=512)
        with torch.no_grad():
            outputs = text_model(**inputs)
        text_embeddings.append({
            "embedding": outputs.last_hidden_state[:, 0, :],  # CLS token embedding
            "start": segment["start"],
            "end": segment["end"],
            "text": text
        })
    return text_embeddings

def process_audio(audio_path):
    # Use SpeechBrain's emotion-recognition-wav2vec2-IEMOCAP model
    out_prob, score, index, text_lab = audio_classifier.classify_file(audio_path)
    embedding = out_prob  # Extract embedding from the output tuple

    aud= AudioFileClip(audio_path)
    audio_arr = aud.to_soundarray()
    sampling_rate = aud.fps
    if sampling_rate != 16000:
        # Convert to mono if stereo
        audio_mono = audio_arr.mean(axis=1) if audio_arr.ndim > 1 else audio_arr
        audio_resampled = librosa.resample(audio_mono.T, orig_sr=sampling_rate, target_sr=16000)
    waveform = torch.tensor(audio_resampled, dtype=torch.float32).unsqueeze(0).unsqueeze(0)  

    feature = audio_feature_extractor(audio_resampled, sampling_rate=16000, return_tensors="pt")
    aud_feature = feature['input_values']
    with torch.no_grad():
        classified_aud_feature = audio_model(**feature).logits

    predicted_class_ids = torch.argmax(classified_aud_feature, dim=-1).item()
    predicted_label = audio_model.config.id2label[predicted_class_ids]
    return embedding, aud_feature, classified_aud_feature

def process_image(image):
    labels = [
    "A happy scene", "A sad scene", "An angry scene", 
    "A calm moment", "An exciting moment", "A funny moment"
    ]
    if image is None:
        return None
    
    frame_probs = []
    frame_embeddings = []

    for frame in image:
        # Preprocess frame and text
        inputs = vid_processor(text=labels, images=frame, return_tensors="pt", padding=True)
        
        # Get CLIP outputs
        with torch.no_grad():
            outputs = vid_model(**inputs)
            logits_per_image = outputs.logits_per_image  # Shape: (1, num_labels)
            probs = logits_per_image.softmax(dim=1)  # Probabilities per label
            image_features = vid_model.get_image_features(inputs["pixel_values"])  # Shape: (1, 512)
        
        frame_probs.append(probs.cpu().numpy()[0])  # Store probabilities
        frame_embeddings.append(image_features.cpu().numpy()[0])  # Store embeddings

    # Convert to numpy arrays
    frame_probs = np.array(frame_probs)  # Shape: (num_frames, num_labels)
    frame_embeddings = np.array(frame_embeddings)  # Shape: (num_frames, 512)
    return frame_probs, frame_embeddings#outputs.last_hidden_state#[:, 0, :]  # CLS token embedding

def aggregate_modalities(text_embeddings, audio_features, video_features):
    # Text: Aggregate multiple segment embeddings
    text_embeds = np.array([seg["embedding"].numpy() for seg in text_embeddings])  # (num_segments, 768)
    text_agg = np.mean(text_embeds, axis=0) if len(text_embeds) > 0 else np.zeros(768)  # (768)
    audio_agg = audio_features[0].mean(axis = 0) # (128)
    video_agg = np.mean(video_features, axis=0)  # (512)
    return text_agg, audio_agg, video_agg

def fuse_modalities(text_agg, audio_agg, video_agg, reduce_dim=128):
    '''
    fuse feature for multiple modalities, apply multihead self-attnetion to comparing contribution of 3 features with themselves (3 heads) 
    resulting in 3 heads capture features relevance / interaction of 3 modalities

    '''
    # Convert numpy arrays to PyTorch tensors
    text_agg = torch.tensor(text_agg.squeeze(), dtype=torch.float32)  # (768)
    video_agg = torch.tensor(video_agg, dtype=torch.float32)  # (512)
    audio_agg = torch.tensor(audio_agg, dtype=torch.float32)  # (128)

    # Define linear projection layers
    text_projection = nn.Linear(text_agg.shape[0], reduce_dim)
    video_projection = nn.Linear(video_agg.shape[0], reduce_dim)
    
    # Project to reduce_dim (128)
    text_reduced = text_projection(text_agg).detach().numpy()  # (128)
    video_reduced = video_projection(video_agg).detach().numpy()  # (128)
    audio_reduced = audio_agg.numpy()  # Already (128)

    # Attention-based fusion (from previous response, with num_heads=3)
    class AttentionFusion(nn.Module):
        def __init__(self, input_dim, output_dim, num_modalities):
            super().__init__()
            self.attention = nn.MultiheadAttention(embed_dim=input_dim, num_heads=4)
            self.fc = nn.Linear(input_dim, output_dim)
            self.weights = nn.Parameter(torch.ones(num_modalities) / num_modalities)

        def forward(self, x):
            x, attn_weights = self.attention(x, x, x, need_weights=True)  # (3, 1, input_dim), (3, 3)
            x = self.fc(x.squeeze(1))  # (3, output_dim)
            weights = torch.softmax(self.weights, dim=0)
            x = torch.sum(x * weights.unsqueeze(-1), dim=0)  # (output_dim)
            return x, attn_weights

    modalities = torch.tensor([text_reduced, audio_reduced, video_reduced], dtype=torch.float32).unsqueeze(1)  # (3, 1, 128)
    model = AttentionFusion(input_dim=128, output_dim=128, num_modalities=3)
    fused_attention, attn_weights = model(modalities) #weighted representation of each modality after attending to all others
    return fused_attention.detach().numpy(), attn_weights.detach().numpy()

# Main function
def classify_reel_sentiment(video_path):
    text, audio_path, keyframe = extract_modalities(video_path)
    text_emb = process_text(text)
    emotion_class, audio_feature, classified_feature = process_audio(audio_path)
    vid_class, vid_emb = process_image(keyframe)
    # text embedding 768, audio feature (1,1024,128), video feature (31 (seconds),512)
    text_agg, audio_agg, video_agg = aggregate_modalities(text_emb, audio_feature, vid_emb)
    fused_concat, fused_attention = fuse_modalities(text_agg, audio_agg, video_agg)
    
    return fused_concat, fused_attention 

if __name__  == "__main__":
    # Example usage
    video_path = "C:/Users/NA/jirapong/cloned/new_reels/g2p_4/v9.mp4"
    fused_concat,fused_attention = classify_reel_sentiment(video_path)

    import seaborn as sns
    import matplotlib.pyplot as plt

    attn_weights = fused_attention  # (4, 4)
    modalities = ["Text", "Audio", "Video"]
    sns.heatmap(attn_weights.squeeze(), xticklabels=modalities, yticklabels=modalities, cmap="Blues")
    plt.title("Attention Weights Across Modalities")
    plt.show()
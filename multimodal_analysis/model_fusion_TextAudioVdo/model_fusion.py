import torch
from transformers import AutoTokenizer,  AutoModel, Wav2Vec2Processor, Wav2Vec2Model, ViTImageProcessor, ViTModel #BertTokenizer, BertModel,
from moviepy import VideoFileClip
import whisper
import cv2
import numpy as np
from speechbrain.inference.interfaces import foreign_class

# Load pre-trained models
 #Roberta for sentiment classification
text_tokenizer = AutoTokenizer.from_pretrained('cardiffnlp/twitter-roberta-base-sentiment-latest')
text_model = AutoModel.from_pretrained('cardiffnlp/twitter-roberta-base-sentiment-latest')

#audio_processor = Wav2Vec2Processor.from_pretrained('speechbrain/emotion-recognition-wav2vec2-IEMOCAP')
#audio_model = Wav2Vec2Model.from_pretrained('speechbrain/emotion-recognition-wav2vec2-IEMOCAP')
# When using the model wav2vec2 make sure that your speech input is also sampled at 16Khz.

image_processor = ViTImageProcessor.from_pretrained('google/vit-base-patch16-224')
image_model = ViTModel.from_pretrained('google/vit-base-patch16-224')
audio_classifier = foreign_class(
    source="speechbrain/emotion-recognition-wav2vec2-IEMOCAP",
    pymodule_file="custom_interface.py",
    classname="CustomEncoderWav2vec2Classifier",
    run_opts={"device": "cuda" if torch.cuda.is_available() else "cpu"}
)

# Step 1: Extract modalities from reel video
def extract_modalities(video_path):
    # Extract audio
    video = VideoFileClip(video_path)
    audio_path = "temp_audio2.wav"
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
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        frames.append(frame)
    cap.release()
    # Select a keyframe (e.g., middle frame)
    keyframe = frames[len(frames)//2] if frames else None
    
    return text_segments, audio_path, keyframe

# Step 2: Process each modality
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
    return embedding

'''
def process_audio(audio_path):
    audio, sr = librosa.load(audio_path)
    inputs = audio_processor(audio, sampling_rate=sr, return_tensors="pt")
    with torch.no_grad():
        outputs = audio_model(**inputs)
    return outputs.last_hidden_state.mean(dim=1)  # Average pooling
'''

def process_image(image):
    if image is None:
        return None
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    inputs = image_processor(image, return_tensors="pt")
    with torch.no_grad():
        outputs = image_model(**inputs)
    return outputs.last_hidden_state[:, 0, :]  # CLS token embedding

def fuse_modalities(text_embeddings, audio_emb, image_emb):
    # Aggregate text embeddings (average)
    text_emb = torch.mean(torch.cat([seg["embedding"] for seg in text_embeddings], dim=0), dim=0, keepdim=True)
    
    # Collect valid embeddings
    valid_embs = [emb for emb in [text_emb, audio_emb, image_emb] if emb is not None]
    if not valid_embs:
        return None, text_embeddings
    
    # Align embedding dimensions (e.g., project to common dimension)
    embed_dim = 768  # Common dimension (e.g., BERT's output size)
    projections = [
        torch.nn.Linear(emb.shape[-1], embed_dim) if emb.shape[-1] != embed_dim else torch.nn.Identity()
        for emb in valid_embs
    ]
    valid_embs = [proj(emb) for proj, emb in zip(projections, valid_embs)]
    
    # Stack embeddings for attention (shape: [num_modalities, batch_size, embed_dim])
    emb_stack = torch.stack(valid_embs, dim=0)  # [num_modalities, 1, embed_dim]
    
    # Cross-modal attention
    attention = torch.nn.MultiheadAttention(embed_dim=embed_dim, num_heads=8)
    attn_output, _ = attention(emb_stack, emb_stack, emb_stack)
    fused = attn_output.mean(dim=0)  # Average over modalities
    
    # Classifier
    classifier = torch.nn.Linear(embed_dim, 3)  # 3 classes: positive, negative, neutral
    logits = classifier(fused)
    probabilities = torch.nn.functional.softmax(logits, dim=-1)
    sentiment_map = {0: "Positive", 1: "Negative", 2: "Neutral"}
    return sentiment_map[torch.argmax(probabilities).item()], text_embeddings

# Main function
def classify_reel_sentiment(video_path):
    text, audio_path, keyframe = extract_modalities(video_path)
    text_emb = process_text(text)
    audio_emb = process_audio(audio_path)
    image_emb = process_image(keyframe)
    sentiment, text_embeddings = fuse_modalities(text_emb, audio_emb, image_emb)
    
    print(f"Predicted Sentiment: {sentiment}")
    print("Transcribed Text with Timestamps:")
    for segment in text_embeddings:
        print(f"Text: {segment['text']}, Start: {segment['start']:.2f}s, End: {segment['end']:.2f}s")
    
    return sentiment, text_embeddings

# Example usage
video_path = "C:/Users/NA/Saved Games/short_vdo/reels1/v7_71.mp4"
sentiment,text = classify_reel_sentiment(video_path)
print(f"Predicted Sentiment: {sentiment}")
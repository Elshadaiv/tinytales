import os
import numpy as np
import librosa
from PIL import Image

DATA_DIR = "baby_sounds_dataset_binary"       # folder containing pain/non pain audio
SPEC_DIR = "spectrograms_binary_flutter"      


def loudest_3s(y, sr):
    w = sr * 3                                # 3 second window
    if len(y) <= w:
        return np.pad(y, (0, w - len(y)))     # pad if shorter than 3 seconds

    step = sr // 4                            # slide window every 0.25s
    best, score = 0, -1

    for i in range(0, len(y) - w + 1, step):
        seg = y[i:i+w]
        s = np.sum(np.abs(seg))               # loudness score
        if s > score:
            score, best = s, i

    return y[best:best+w]                     # return loudest segment


def create_spec(audio_path, out_path):
    try:
        y, sr = librosa.load(audio_path, sr=16000, mono=True)   #
        y = loudest_3s(y, sr)                                   # take loudest 3 seconds

        S = np.abs(librosa.stft(y, n_fft=512, hop_length=256))   # stft magnitude and log scaling
        S = np.log(S + 1)                                        

        denom = S.max() - S.min()
        S = (S - S.min()) / denom if denom > 0 else np.zeros_like(S)  # normalise

        img = (S * 255).astype(np.uint8)                         # convert image to grayscale
        img = np.flipud(img)                                     # flip frequency axis
        img = Image.fromarray(img).resize((128, 128))            

        img.save(out_path)                                       

    except Exception as e:
        print(f"Skipped {audio_path}: {e}")

for label in os.listdir(DATA_DIR):                          
    in_dir = os.path.join(DATA_DIR, label)

    if not os.path.isdir(os.path.join(DATA_DIR, label)):
        continue

    out_dir = os.path.join(SPEC_DIR, label)

    os.makedirs(out_dir, exist_ok=True)

    for f in os.listdir(in_dir):
        if f.endswith(".wav"):
            create_spec(
                os.path.join(in_dir, f),
                os.path.join(out_dir, f + ".png")
            )

print("done")
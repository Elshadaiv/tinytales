import os
import librosa
import librosa.display
import matplotlib.pyplot as plt
import numpy as np
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

DATA_DIR = os.path.join(BASE_DIR, "..", "baby_sounds_dataset")
SPEC_DIR = os.path.join(BASE_DIR, "..", "spectrograms")
def create_spectrogram(audio_path, output_path): # output folder for generated spectrogram images
    try:
        y, sr = librosa.load(audio_path, sr=22050)

        target_seconds = 3.0        # force all audio clips to be exactly 3 seconds long

        target_len = int(sr * target_seconds)

        if len(y) < target_len:
            y = np.pad(y, (0, target_len - len(y)))
        else:
            y = y[:target_len]

        S = librosa.feature.melspectrogram(y=y, sr=sr, n_mels=128) # compute the mel spectrogram
        S_dB = librosa.power_to_db(S, ref=np.max) # converting to decibels

        plt.figure(figsize=(3, 3)) 
        plt.axis('off')
        librosa.display.specshow(S_dB, sr=sr, cmap='magma') # plot of spectrogram
        plt.savefig(output_path, bbox_inches='tight', pad_inches=0)
        plt.close()


    except Exception as e:
        print(f"Error {audio_path}: {e}")

def process_dataset():
    for category in os.listdir(DATA_DIR):
        category_path = os.path.join(DATA_DIR, category) # path of each category folder
        if not os.path.isdir(category_path):
            continue 

        output_category = os.path.join(SPEC_DIR, category)
        os.makedirs(output_category, exist_ok=True) # create output directory for each category

        for filename in os.listdir(category_path):
            if not filename.lower().endswith((".wav")): # check for wav files
                continue

            input_file = os.path.join(category_path, filename)
            output_file = os.path.join(output_category, filename + ".png") 

            print(f"processing {input_file} → {output_file}")
            create_spectrogram(input_file, output_file) # create spectrogram for each audio file and save as png

if __name__ == "__main__":
    process_dataset()
    print("spectrograms created")

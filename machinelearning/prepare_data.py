import os
import librosa
import numpy as np

DATASET_PATH = 'baby_sounds_dataset'  #This is the path to my dataset folder where its all saved
    



#  Function to extract MFCC 
def extract_features_from_file(file_path):

    try:
        audio, sample_rate = librosa.load(file_path, sr=None)

        # Extract MFCC 
        mfccs = librosa.feature.mfcc(y=audio, sr=sample_rate, n_mfcc=40)
        mfccs_mean = np.mean(mfccs.T, axis=0)

        # return this numerical representation of the sound
        return mfccs_mean
    except Exception as e:
        # if anything fails print error and return none
        print(f"Error {file_path}: {e}")
        return None

# loop through dataset folders 
def load_dataset():
    
    features = [] 
    labels = []   
    for label in os.listdir(DATASET_PATH):  # loop over each folder
        folder = os.path.join(DATASET_PATH, label)
        if not os.path.isdir(folder):
            continue
        for file_name in os.listdir(folder):
            if file_name.endswith('.wav'):  # process only .wav files
                file_path = os.path.join(folder, file_name)
                mfcc = extract_features_from_file(file_path)

                if mfcc is not None:
                    features.append(mfcc)
                    labels.append(label)

    # convert lists into numpy arrays for ml use
    return np.array(features), np.array(labels)


if __name__ == '__main__':
    X, y = load_dataset()
    print(" data loaded ")
    print(f"feature shape {X.shape}")  
    print(f"unique labels {np.unique(y)}")



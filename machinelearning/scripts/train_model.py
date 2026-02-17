import tensorflow as tf
import os
import numpy as np
from tensorflow.keras import layers, models
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.callbacks import EarlyStopping

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

SPEC_DIR = os.path.join(BASE_DIR, "..", "spectrograms")
MODELS_DIR = os.path.join(BASE_DIR, "..", "models")
# image and training settings
IMG_SIZE = (128, 128)
BATCH_SIZE = 16
EPOCHS = 20


datagen = ImageDataGenerator(
     rescale=1./255,
    validation_split=0.2,
    zoom_range=0.1,
    width_shift_range=0.05,
    height_shift_range=0.05 # 20% of images go to validation
) # data generator for loading images

train_data = datagen.flow_from_directory(
    SPEC_DIR,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    subset='training'
) # load training data


valu_data = datagen.flow_from_directory( # load validation data

    SPEC_DIR,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode="categorical",
    subset="validation"
)


model = models.Sequential([ #neural network model for image classification
    layers.Input(shape=(128,128,3)),
    layers.Conv2D(32, (3,3), activation="relu"),
    layers.MaxPooling2D(),
    layers.Conv2D(64, (3,3), activation="relu"),
    layers.MaxPooling2D(),
    layers.Conv2D(128, (3,3), activation="relu"),
    layers.MaxPooling2D(),
    layers.Flatten(),
    layers.Dense(128,activation="relu"),
    layers.Dense(train_data.num_classes, activation="softmax")
])

model.compile( 
    optimizer="adam",
    loss="categorical_crossentropy", 
    metrics=["accuracy"]
)

early_stopping = EarlyStopping(monitor="val_loss", patience=5, restore_best_weights=True) # early stopping prevents overfitting validation loss does not improve for 5 epochstraining stops

history = model.fit( # train the model
    train_data,
    validation_data=valu_data,
    epochs=EPOCHS,
    callbacks=[early_stopping]
)

model.save("../models/baby_sound_classifier.h5") # save the model

model.export("../models/baby_sound_classifier")
converter = tf.lite.TFLiteConverter.from_saved_model("../models/baby_sound_classifier") # convert the model to tensorflow format
tflite_model = converter.convert()
with open("../models/baby_sound_classifier.tflite", "wb") as f:
    f.write(tflite_model)

    labels = list(train_data.class_indices.keys())
with open("../models/labels.txt", "w") as f: # save class labels
    for label in labels:
        f.write(f"{label}\n")

print("completed")

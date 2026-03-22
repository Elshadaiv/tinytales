import tensorflow as tf
import os
import numpy as np
from tensorflow.keras import layers, models
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from sklearn.utils.class_weight import compute_class_weight
from tensorflow.keras.callbacks import EarlyStopping

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

SPEC_DIR = os.path.join(BASE_DIR, "..", "spectrograms_binary")
MODELS_DIR = os.path.join(BASE_DIR, "..", "models")
# image and training settings
IMG_SIZE = (128, 128)
BATCH_SIZE = 16
EPOCHS = 20


datagen = ImageDataGenerator(
     rescale=1./255,
    validation_split=0.1,# 10% of images go to validation
) # data generator for loading images

train_data = datagen.flow_from_directory(
    SPEC_DIR,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='binary',
    subset='training',
    shuffle=True
) # load training data


valu_data = datagen.flow_from_directory( # load validation data

    SPEC_DIR,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode="binary",
    subset="validation",
    shuffle=False
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
    layers.Dropout(0.4),
    layers.Dense(1, activation="sigmoid")]
)

model.compile( 
    optimizer=tf.keras.optimizers.Adam(learning_rate=0.0003),
    loss="binary_crossentropy", 
    metrics=["accuracy"]
)

early_stopping = EarlyStopping(monitor="val_loss",mode="min", patience=5, restore_best_weights=True) # early stopping prevents overfitting validation loss does not improve for 5 epochstraining stops


class_weights = compute_class_weight('balanced', classes=np.unique(train_data.classes), y=train_data.classes)
class_weight_dict = dict(enumerate(class_weights))

history = model.fit( # train the model now using class weights too
    train_data,
    validation_data=valu_data,
    epochs=EPOCHS,
    callbacks=[early_stopping],
    class_weight=class_weight_dict
)

model.save("../models/baby_sound_classifier.h5") # save the model

model.export("../models/baby_sound_classifier")
converter = tf.lite.TFLiteConverter.from_saved_model("../models/baby_sound_classifier") # convert the model to tensorflow format
tflite_model = converter.convert()
with open("../models/baby_sound_classifier.tflite", "wb") as f:
    f.write(tflite_model)

    labels = list(train_data.class_indices.keys())
with open("../models/labels.txt", "w") as f: #save labels
    f.write("non_pain\n")
    f.write("pain\n")

print("completed")

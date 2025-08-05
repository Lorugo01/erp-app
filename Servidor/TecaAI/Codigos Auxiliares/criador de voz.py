import torch
from TTS.api import TTS
import sounddevice as sd
import soundfile as sf

tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2").to("cuda")
def converte(texto):
    palavras=texto.split()
    titulo=" ".join(texto.split()[:4])
    tts.tts_to_file(
        text=texto, 
        speaker_wav="voz/Teca_v2.wav", 
        #speaker="Gracie Wise",
        language="pt", 
        file_path=f"voz/{titulo}.wav",
        speed=1.5,
        temperature=0.7
        )
while True:
    entrada= input("Digite:")
    converte(entrada)
import warnings
warnings.filterwarnings(
    "ignore",
    message=".*You are using `torch.load` with `weights_only=False`.*",
    category=FutureWarning
)

import os
import torch
from TTS.api import TTS

# Carrega o modelo TTS uma única vez e o mantém em memória para reutilização
device = "cuda" if torch.cuda.is_available() else "cpu"
tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2").to(device)

def tts_to_file(
    text: str,
    speaker_wav: str = None,
    language: str = "pt",
    file_path: str = "output.wav",
    speed: float = 1.0,
    temperature: float = 0.7
) -> None:
    """
    Gera um arquivo de áudio WAV a partir do texto usando a instância global de TTS.

    :param text: Texto de entrada a ser sintetizado.
    :param speaker_wav: Caminho para o arquivo de voz (speaker wav), opcional.
    :param language: Código do idioma.
    :param file_path: Caminho de destino do arquivo WAV.
    :param speed: Fator de velocidade da fala (1.0 = normal).
    :param temperature: Grau de variação da fala.
    """
    try:
        if speaker_wav and os.path.isfile(speaker_wav):
            tts.tts_to_file(
                text=text,
                speaker_wav=speaker_wav,
                language=language,
                file_path=file_path,
                speed=speed,
                temperature=temperature
            )
        else:
            tts.tts_to_file(
                text=text,
                language=language,
                file_path=file_path,
                speed=speed,
                temperature=temperature
            )
    except Exception as e:
        print(f"[tts_model] Erro ao gerar áudio: {e}")

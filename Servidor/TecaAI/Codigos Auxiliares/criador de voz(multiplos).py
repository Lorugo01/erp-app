import torch
from TTS.api import TTS
import sounddevice as sd
import soundfile as sf
import os  # Importa o módulo para trabalhar com arquivos

# Modificar o nome da pasta dentro de /voz_itens que queira salvar
pasta_voz = "demonstrativo"

# Criar a pasta se não existir
os.makedirs(f"voz_presets", exist_ok=True) #Colocar voz_presets/{pasta_voz} se for necessário criar subpasta

def adicionar_espaco_antes_pontuacao(texto):
    # Substitui os pontos e vírgulas por eles seguidos de um espaço
    texto = texto.replace(',', ' ,').replace('.', '  ')
    return texto

# Carregar o modelo TTS
tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2").to("cuda")

# Lista de textos dos itens de química
textos = [
"Luzes ligadas",
]

# Iterar sobre cada texto na lista
for texto in textos:
    texto_formatado = adicionar_espaco_antes_pontuacao(texto)
    titulo = texto_formatado.split(',')[0]  # Armazena tudo antes da primeira vírgula
    caminho_arquivo = f"voz_itens/{pasta_voz}/{titulo}.wav"  # Cria o caminho do arquivo
    
    # Verificar se o arquivo já existe
    if os.path.exists(caminho_arquivo):
        print(f"Arquivo já existe, pulando: {caminho_arquivo}")
        continue  # Pula para o próximo item
    
    # Se não existir, gera o áudio
    tts.tts_to_file(
        text=texto_formatado,
        speaker_wav="voz/Teca_v2.wav",
        language="pt",
        file_path=caminho_arquivo,
        temperature=1
    )
    print(f"Áudio gerado: {caminho_arquivo}")  # Mensagem de confirmação
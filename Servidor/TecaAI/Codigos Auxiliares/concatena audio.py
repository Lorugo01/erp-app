from pydub import AudioSegment
import os

# Defina o diretório onde os arquivos .wav estão localizados
diretorio = 'C:/Users/User/Desktop/Conc'

# Inicializa uma variável para armazenar o áudio combinado
audio_combinado = AudioSegment.empty()

# Loop para percorrer os arquivos de 1.wav a 4.wav
for i in range(1, 5):
    caminho_arquivo = os.path.join(diretorio, f'{i}.wav')
    if os.path.isfile(caminho_arquivo):
        audio = AudioSegment.from_wav(caminho_arquivo)
        audio_combinado += audio
    else:
        print(f'Arquivo {i}.wav não encontrado no diretório especificado.')

# Exporta o áudio combinado para um novo arquivo
caminho_saida = os.path.join(diretorio, 'audio_combinado.wav')
audio_combinado.export(caminho_saida, format='wav')
print(f'Áudio combinado salvo em: {caminho_saida}')

import speech_recognition as sr
import torch
from TTS.api import TTS
from pydub import AudioSegment
import socket
import requests
import audio_player
import comandos 
import itens
import historico_conversa
import text_format
import IAGen


# Configurações do TTS (Linguagem)
device = "cuda" # if torch.cuda.is_available() else "cpu"
tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2").to(device)


# Endereço esp32 para comandos
esp_ip="192.168.100.144"
porta_comando=1234
porta_indexled=666
client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Configuração de endereço de Visão de Maquina
url_VM="http://localhost:8000/detected"


# Função para gerar a voz da IA
def gen_voz(text):
    sentences = text_format.split_text_to_sentences(text)
    for i, sentence in enumerate(sentences):
        temp_audio_path = f"IA/segmentos/temp_sentence_{i}.wav"
        tts.tts_to_file(  # Usando tts em vez de tts_model
            text=sentence,
            speaker_wav="voz/Teca.wav",
            language="pt",
            file_path=temp_audio_path
        )
        # Reproduz o áudio assim que estiver pronto
        audio_player.play_audio(temp_audio_path)
        print(f"Áudio {i+1}/{len(sentences)} gerado e reproduzido")
    
    # Aguarda todos os áudios serem processados
    audio_player.audio_player.audio_queue.join()
    print("Todos os áudios foram processados e reproduzidos")

# função de reconhecimento de voz
def main_loop():
    recognizer = sr.Recognizer()
    try:
        with sr.Microphone() as source:
            recognizer.adjust_for_ambient_noise(source, duration=2)  # Ajusta para ruído ambiente
            recognizer.energy_threshold = 100
            print("Iniciando transcrição. Fale algo...")
            while True:
                try:
                    audio = recognizer.listen(source)
                    texto = recognizer.recognize_google(audio, language="pt-BR").lower()
                    print(f"Texto reconhecido: {texto}")
            
                    # Detecta quando for dito "Olá Teca"
                    if "olá teca" in texto or "olá teka" in texto or "olá te" in texto:                    
                        print("Estou ouvindo! Diga o comando.")
                        audio_player.play_now("voz_presets/estou ouvindo.wav")
                        audio = recognizer.listen(source)
                        comando = recognizer.recognize_google(audio, language="pt-BR").lower()
                        print(f"Comando recebido: {comando}")
                        
                        if "responda" in comando:
                            print("Pode perguntar!")
                            audio_player.play_now("voz_presets/qual sua duvida.wav")
                            audio = recognizer.listen(source)
                            pergunta = recognizer.recognize_google(audio, language="pt-BR").lower()
                            print(f"Pergunta recebida: {pergunta}")
                            resposta = IAGen.responderIA(pergunta)
                            gen_voz(resposta)
                            print(f"Teca: {resposta}")
                        
                        elif "o que é isso" in comando:
                            respostaVM = requests.get(url_VM)
                            data = respostaVM.text.strip()
                            print(f"Teca: item => {data}")
                            item = " ".join(data.split())
                            audio_player.play_now(itens.verificar_item(item))
                            audio_player.play_now("voz_presets/saber.wav")
                            audio = recognizer.listen(source)
                            saber_mais=recognizer.recognize_google(audio,language="pt-BR").lower()
                            print(f"Saber: {saber_mais}")
                            if "sim" in saber_mais:
                                resposta=IAGen.responderIA(f"fale mais sobre{item}")
                                audio_player.play_audio(gen_voz(resposta))
                        elif "onde está" in texto:
                            return
                        
                        else:
                            # Chama a função de verificação do comando
                            resposta = comandos.verificar_comando(comando)
                            print(resposta)
                        #client.close()   
                except sr.UnknownValueError:
                    print("Não foi possível entender o áudio.")
                except sr.RequestError:
                    print("Erro ao conectar-se ao serviço de reconhecimento de fala.")
    except OSError as e:
        print(f"Erro ao abrir o microfone: {e}")

if __name__ == "__main__":
    comandos.criar_tabelas()  # Cria a tabela ao iniciar o programa
    audio_player.play_now("voz_presets/carregando comandos.wav")
    
    # Exemplo de como adicionar um comando
    comandos.adicionar_comando("ligue a luz", "Luz ligada!", "lon")
    comandos.adicionar_comando("desligue a luz", "Luz desligada!", "loff")
    comandos.adicionar_comando("ligue modo festa", "Modo Festa Ativado!", "mpartyon")
    comandos.adicionar_comando("desligue modo festa", "Modo Festa Desativado!", "mpartyoff")
    
    conversation_history = historico_conversa.load_conversation_from_json()
    context = "\n".join([f"User: {entry['user']}\nAI: {entry['Teca']}" for entry in conversation_history])
    audio_player.play_now("voz_presets/inicializacao concluida.wav")
    main_loop()
import queue
import threading
import sounddevice as sd
import soundfile as sf
import time

class AudioPlayer:
    def __init__(self):
        self.audio_queue = queue.Queue()
        self.playing = False
        self.player_thread = threading.Thread(target=self._play_audio_loop)
        self.player_thread.daemon = True
        self.player_thread.start()
    
    def _play_audio_loop(self):
        while True:
            if not self.audio_queue.empty():
                audio_path = self.audio_queue.get()
                try:
                    data, samplerate = sf.read(audio_path)
                    sd.play(data, samplerate)
                    sd.wait()
                except Exception as e:
                    print(f"Erro ao reproduzir áudio: {e}")
                finally:
                    self.audio_queue.task_done()
            time.sleep(0.1)
    
    def play_audio(self, file_path):
        self.audio_queue.put(file_path)

# Instancia o player global
audio_player = AudioPlayer()

# Função para reproduzir o audio
def play_audio(file_path):
    audio_player.play_audio(file_path)

def play_now(file):
    try:
        data,samplerate=sf.read(file)
        sd.play(data,samplerate)
        sd.wait()
    except sf.SoundFileError as sf_erro:
        print(f"Erro ao abrir arquivo: {sf_erro}")
        print("Verifique se o arquivo existe e é um formato suportado por soundfile.")
    except sd.PortAudioError as pa_erro:
        print(f"Erro ao acessar o dispositivo de áudio: {pa_erro}")
        print("Verifique se o dispositivo de áudio está disponível e configurado corretamente.")
    except Exception as e:
        print(f"Erro inesperado ocorreu: {e}")


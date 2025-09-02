import os
from difflib import SequenceMatcher
# Desativa aviso e uso de symlinks no cache do huggingface_hub no Windows
os.environ["HF_HUB_DISABLE_SYMLINKS_WARNING"] = "1"
os.environ["HF_HUB_DISABLE_SYMLINKS"] = "1"

import webbrowser
import socket
import json
import requests
import time
import threading
import speech_recognition as sr
import recv_audio
from led_control import send_command  # Controle local dos LEDs via serial
import wave
import pyaudio
import tempfile
import random
from googleapiclient.discovery import build  # Biblioteca para acessar a API do YouTube Music
import cv2
from faster_whisper import WhisperModel

# --- Configurações Globais ---
BASE_DIR             = os.path.dirname(os.path.abspath(__file__))
VOICE_PRESETS_DIR    = os.path.join(BASE_DIR, "voz_presets")  # Pasta dos áudios

# Configurações do Whisper
model = "small"
device = "cpu"  # Forçando uso de CPU para evitar erros de CUDA
compute_type = "int8"  # Usando int8 para CPU

# STT local com faster-whisper usando CPU (int8 para maior velocidade)
whisper_model = WhisperModel(
    model,
    device=device,
    compute_type=compute_type
)

# Configurações de reconhecimento de fala
LISTEN_TIMEOUT       = 5
PHRASE_TIMEOUT       = 3
PAUSE_THRESHOLD      = 0.5

# Áudios de controle (placeholders)
INITIAL_AUDIO         = os.path.join(VOICE_PRESETS_DIR, "Inicializando sistema .wav")
SUCCESS_AUDIO         = os.path.join(VOICE_PRESETS_DIR, "Sistema iniciado com sucesso.wav")
ERROR_AUDIO           = os.path.join(VOICE_PRESETS_DIR, "Erro ao se conectar ao servidor .wav")
APRESENTATION_AUDIO   = os.path.join(VOICE_PRESETS_DIR, "Olá .wav")

# Servidores e portas
host        = "192.168.18.24"
porta       = 5000
portaVM     = 8000

# Identificador e API keys
armario            = "A"
YOUTUBE_API_KEY    = os.getenv("YOUTUBE_API_KEY", "")

# Detecção contínua por câmera
STREAM_DURATION    = 5
REQUIRED_DURATION  = 1
FRAME_INTERVAL     = 0.2

# Estado e lock
led_state              = "off"
last_server_connection = time.time()
lock                   = threading.Lock()

def play_local_audio(file_path: str):
    if not os.path.isfile(file_path):
        print(f"Arquivo de áudio não encontrado: {file_path}")
        return
    try:
        wf = wave.open(file_path, 'rb')
        pa = pyaudio.PyAudio()
        stream = pa.open(
            format=pa.get_format_from_width(wf.getsampwidth()),
            channels=wf.getnchannels(),
            rate=wf.getframerate(),
            output=True
        )
        data = wf.readframes(1024)
        while data:
            stream.write(data)
            data = wf.readframes(1024)
        stream.stop_stream()
        stream.close()
        pa.terminate()
    except Exception as e:
        print(f"Erro ao reproduzir áudio local: {e}")

def check_server():
    print(f"[DEBUG CLIENTE] ==========================================")
    print(f"[DEBUG CLIENTE] Iniciando verificação de conexão com servidor {host}:{porta}")
    print(f"[DEBUG CLIENTE] ==========================================")
    
    # Faz apenas uma verificação inicial
    try:
        print(f"[DEBUG CLIENTE] Tentando conectar ao servidor...")
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(5)
        s.connect((host, porta))
        print(f"[DEBUG CLIENTE] Conexão estabelecida com sucesso!")
        print(f"[DEBUG CLIENTE] Enviando mensagem de teste...")
        
        # Envia mensagem de teste no formato JSON esperado
        test_data = {"ID": armario, "funcao": "teste", "parametro": "conexao"}
        s.sendall(json.dumps(test_data).encode('utf-8'))
        print(f"[DEBUG CLIENTE] Mensagem de teste enviada: {test_data}")
        
        # Aguarda resposta
        response = s.recv(1024).decode().strip()
        print(f"[DEBUG CLIENTE] Resposta recebida do servidor: '{response}'")
        
        # Processa resposta com header de tamanho
        if response:
            try:
                # Primeiro 10 dígitos são o tamanho
                if len(response) >= 10:
                    size_str = response[:10]
                    try:
                        size = int(size_str)
                        actual_response = response[10:10+size]
                        print(f"[DEBUG CLIENTE] Tamanho da resposta: {size}")
                        print(f"[DEBUG CLIENTE] Resposta processada: '{actual_response}'")
                    except ValueError:
                        print(f"[DEBUG CLIENTE] Resposta simples: '{response}'")
                else:
                    print(f"[DEBUG CLIENTE] Resposta curta: '{response}'")
            except Exception as e:
                print(f"[DEBUG CLIENTE] Erro ao processar resposta: {e}")
                print(f"[DEBUG CLIENTE] Resposta bruta: '{response}'")
        
        s.close()
        print(f"[DEBUG CLIENTE] Conexão fechada")
        print(f"[DEBUG CLIENTE] Status: CONECTADO ✓")
        print(f"[DEBUG CLIENTE] Teste de conexão concluído - cliente pronto para comandos!")
        
    except Exception as e:
        print(f"[DEBUG CLIENTE] Erro na conexão: {e}")
        print(f"[DEBUG CLIENTE] Status: DESCONECTADO ✗")
        print(f"[DEBUG CLIENTE] Tentando novamente em 30 segundos...")
        time.sleep(30)
        check_server()  # Tenta novamente

def send_heartbeat():
    """Envia heartbeat periódico para manter conexão ativa"""
    while True:
        try:
            print(f"[DEBUG CLIENTE] Enviando heartbeat...")
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(5)
            s.connect((host, porta))
            
            # Envia heartbeat usando a função enviar_dados para processar corretamente
            heartbeat_data = {"ID": armario, "funcao": "heartbeat", "parametro": "ping"}
            s.sendall(json.dumps(heartbeat_data).encode('utf-8'))
            
            # Processa resposta usando o mesmo método que outras funções
            header = s.recv(10)
            if not header:
                print(f"[DEBUG CLIENTE] Heartbeat - sem resposta do servidor")
                s.close()
                continue
                
            try:
                text_len = int(header.decode('utf-8'))
                text_data = b""
                while len(text_data) < text_len:
                    text_data += s.recv(text_len - len(text_data))
                response = text_data.decode('utf-8')
            except ValueError:
                response = header.decode('utf-8')
                
            print(f"[DEBUG CLIENTE] Heartbeat enviado - resposta: '{response}'")
            
            s.close()
            
        except Exception as e:
            print(f"[DEBUG CLIENTE] Erro no heartbeat: {e}")
        
        # Aguarda 15 segundos antes do próximo heartbeat
        time.sleep(15)

def update_last_connection():
    global last_server_connection
    with lock:
        last_server_connection = time.time()

def monitor_inactivity():
    while True:
        time.sleep(1)

def enviar_dados(conexao, funcao, parametro):
    dados = {"ID": armario, "funcao": funcao, "parametro": parametro}
    conexao.sendall(json.dumps(dados).encode('utf-8'))
    header = conexao.recv(10)
    if not header:
        return ""
    try:
        text_len = int(header.decode('utf-8'))
        text_data = b""
        while len(text_data) < text_len:
            text_data += conexao.recv(text_len - len(text_data))
        return text_data.decode('utf-8')
    except ValueError:
        return header.decode('utf-8')

def cliente_tcp(host, porta, funcao, parametro):
    resposta = ""
    try:
        cliente = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        cliente.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        cliente.connect((host, porta))
        print(f"[DEBUG CLIENTE] Conectado ao Servidor em {host}:{porta}")
        update_last_connection()
        
        # DEBUG: Mostra o comando que está sendo enviado
        print(f"[DEBUG CLIENTE] Enviando comando: Função='{funcao}', Parâmetro='{parametro}'")
        
        resposta = enviar_dados(cliente, funcao, parametro)
        
        # DEBUG: Mostra a resposta recebida do servidor
        print("[DEBUG CLIENTE] Resposta do servidor recebida:", resposta)

        # Processa comandos ESP32
        if funcao == "comando_esp32":
            print(f"[DEBUG CLIENTE] Comando ESP32 recebido: '{parametro}'")
            try:
                # Envia comando para ESP32 via Serial
                from led_control import send_command
                resultado = send_command(parametro)
                print(f"[DEBUG CLIENTE] Comando ESP32 enviado via Serial: '{parametro}'")
                print(f"[DEBUG CLIENTE] Resultado: {resultado}")
            except Exception as e:
                print(f"[DEBUG CLIENTE] Erro ao enviar comando ESP32: {e}")
                resultado = f"Erro: {e}"
            print(f"[DEBUG CLIENTE] Comando ESP32 processado com sucesso")

        # Máscara de áudio para IA
        if funcao == "responda":
            mascara_audios = [
                os.path.join(VOICE_PRESETS_DIR, "Interessante a sua pergunta!.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Uma dúvida muito válida.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Isso merece uma análise cuidadosa.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Esse é um tema que vale aprofundar.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Ótimo ponto para esclarecermos.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Você está no caminho certo com essa pergunta.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Um questionamento bastante relevante.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Interessante você ter pensado nisso.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Boa pergunta.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Curiosa essa dúvida.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Que bom que perguntou isso.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Essa questão merece atenção.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Show de bola essa dúvida.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Curioso isso que você perguntou.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Sua pergunta é daquelas que puxam o assunto certo.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Essa dúvida é super válida e rende bastante.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Mandou bem demais nessa!.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Bela sacada!.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Essa dúvida vale ouro!.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Muito bom você ter levantado isso.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Legal que você pensou nisso.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Sua dúvida ajuda a clarear o tema.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Essa pergunta é bem estratégica.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Você sacou um ponto importante.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Essa é daquelas que fazem a diferença.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Muito boa essa pergunta.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Excelente momento pra falar disso.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Ótima pergunta pra puxar o raciocínio.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Gostei do que você trouxe!.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Essa dúvida abre um bom caminho.wav"),            
                os.path.join(VOICE_PRESETS_DIR, "Essa colocação foi cirúrgica!.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Você mandou uma que vale desenvolver com calma.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Essa dúvida aí é certeira.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Boa! Essa é uma daquelas que sempre surgem.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Muito pertinente isso que você disse.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Você trouxe uma ótima oportunidade de explicar melhor.wav"),
                os.path.join(VOICE_PRESETS_DIR, "Essa questão mostra atenção aos detalhes.wav")
            ]
            play_local_audio(random.choice(mascara_audios))

        recv_audio.solicitar_audio(cliente)
    except Exception as e:
        print(f"Erro ao se conectar ao servidor: {e}")
        resposta = "erro"
    finally:
        cliente.close()
        update_last_connection()
        print("Conexão encerrada.")
        return resposta

def stream_and_detect():
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Erro ao abrir a câmera do cliente.")
        return ""

    start_time  = time.time()
    last_label  = ""
    label_start = None

    while time.time() - start_time < STREAM_DURATION:
        ret, frame = cap.read()
        if not ret:
            print("Falha ao capturar frame.")
            break

        _, img_encoded = cv2.imencode('.jpg', frame)

        try:
            resp = requests.post(
                f"http://{host}:{portaVM}/detectar_frame",
                files={"file": ("frame.jpg", img_encoded.tobytes(), "image/jpeg")},
                timeout=2
            )
            if resp.status_code == 200:
                label = resp.json().get("detected", "")
            else:
                print("Resposta inválida do servidor:", resp.status_code)
                label = ""
        except requests.exceptions.Timeout:
            print("Timeout na requisição de detecção.")
            label = ""
        except Exception as e:
            print("Erro na requisição de detecção:", e)
            label = ""

        if label:
            if label == last_label:
                if label_start is None:
                    label_start = time.time()
                elif time.time() - label_start >= REQUIRED_DURATION:
                    print(f"Label '{label}' detectado de forma estável por {REQUIRED_DURATION}s.")
                    cap.release()
                    return label
            else:
                last_label  = label
                label_start = time.time()
        else:
            last_label  = ""
            label_start = None

        time.sleep(FRAME_INTERVAL)

    cap.release()
    print("Nenhum label detectado de forma estável dentro do tempo.")
    return ""

def transcribe_faster_whisper(audio_data: sr.AudioData) -> str:
    wav_bytes = audio_data.get_wav_data()
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_file:
        tmp_file.write(wav_bytes)
        file_path = tmp_file.name

    segments, _ = whisper_model.transcribe(
        file_path,
        language="pt",
        beam_size=1,      # << mais rápido
        vad_filter=True
    )
    return "".join(seg.text for seg in segments).lower().strip()


def capturar_audio(recognizer, source, timeout=None, phrase_time_limit=None):
    try:
        recognizer.pause_threshold = PAUSE_THRESHOLD
        audio = recognizer.listen(source, timeout=timeout, phrase_time_limit=phrase_time_limit)
        texto = transcribe_faster_whisper(audio)
        return texto
    except Exception:
        return ""

greetings = ["olá teca", "olá te", "olá tec", "loteca", "olá", "placa", "polaca", "olá tekka", "olá teca", "oi teca", "teca"]

if __name__ == "__main__":
    print("Iniciando cliente TecaAI...")
    
    # Inicia o servidor de comandos em uma thread separada
    print("[DEBUG CLIENTE] Iniciando servidor de comandos...")
    command_server_thread = threading.Thread(target=lambda: __import__('command_server').start_command_server(), daemon=True)
    command_server_thread.start()
    print("[DEBUG CLIENTE] Servidor de comandos iniciado na porta 5002")
    
    recognizer = sr.Recognizer()
    with sr.Microphone() as source:
        recognizer.adjust_for_ambient_noise(source, duration=1)
        recognizer.energy_threshold = 200
        recognizer.dynamic_energy_threshold = False
    monitor_thread = threading.Thread(target=monitor_inactivity, daemon=True)
    monitor_thread.start()

    play_local_audio(INITIAL_AUDIO)
    
    # Inicia o teste de conexão
    check_server()
    
    # Inicia o heartbeat em uma thread separada
    heartbeat_thread = threading.Thread(target=send_heartbeat, daemon=True)
    heartbeat_thread.start()
    print("[DEBUG CLIENTE] Thread de heartbeat iniciada")
    
    activated = False

    try:
        with sr.Microphone() as source:
            print("Fale algo: ")
            while True:
                if not activated:
                    try:
                        recognizer.pause_threshold = 0.5
                        texto = capturar_audio(
                            recognizer,
                            source,
                            timeout=LISTEN_TIMEOUT,
                            phrase_time_limit=3
                        )
                        if not any(g in texto for g in greetings):
                            if led_state == "on":
                                send_command("tecaoff")
                                print("Áudio não identificado como greeting. Comando tecaoff enviado.")
                                led_state = "off"
                            continue
                        else:
                            activated = True
                    except sr.WaitTimeoutError:
                        if led_state == "on":
                            send_command("tecaoff")
                            print("Nenhum áudio captado em 5 segundos. Comando tecaoff enviado.")
                            led_state = "off"
                        continue
                else:
                    recognizer.pause_threshold = PAUSE_THRESHOLD
                    texto = capturar_audio(
                        recognizer,
                        source,
                        timeout=LISTEN_TIMEOUT,
                        phrase_time_limit=PHRASE_TIMEOUT
                    )
                    if not texto:
                        continue

                if texto == "sair":
                    print("Encerrando o programa...")
                    break

                if "tecaoff" in texto:
                    send_command("tecaoff")
                    activated = False
                    led_state = "off"
                    print("Comando tecaoff enviado. LED desligado.")
                    continue
        
                if any(g in texto for g in greetings):
                    activated = True
                    led_on_response = send_command("tecaon")
                    play_local_audio(os.path.join(VOICE_PRESETS_DIR, "estou ouvindo.wav"))
                    print("LED ligado:", led_on_response)
                    led_state = "on"
                    
                    print("Estou ouvindo!")
                    update_last_connection()
                    print("Qual sua pergunta ou comando?")
                    
                    start_wait = time.time()
                    pergunta = ""
                    while time.time() - start_wait < LISTEN_TIMEOUT:
                        remaining = LISTEN_TIMEOUT - (time.time() - start_wait)
                        print("Aguardando uma pergunta válida...")
                        tentativa = capturar_audio(recognizer, source, timeout=remaining, phrase_time_limit=PHRASE_TIMEOUT)
                        if tentativa.strip() and len(tentativa.strip()) >= 3:
                            pergunta = tentativa
                            break
                        else:
                            print("Entrada muito curta, por favor, repita sua pergunta.")
                    
                    if not pergunta.strip() or len(pergunta.strip()) < 3:
                        print("[DEBUG CLIENTE] Não foi capturada uma pergunta válida a tempo. Reiniciando.")
                        send_command("tecaoff")
                        led_state = "off"
                        activated = False
                        continue
                    
                    print("[DEBUG CLIENTE] Pergunta capturada:", pergunta)
                    update_last_connection()
                        
                    if pergunta in ["abrir gmail", "abrir e-mail", "gmail", "email"]:
                        audios_gmail = [
                            os.path.join(VOICE_PRESETS_DIR, "Gmail aberto.wav"),
                            os.path.join(VOICE_PRESETS_DIR, "Email aberto.wav")
                        ]
                        play_local_audio(random.choice(audios_gmail))
                        print("Abrindo Gmail no navegador...")
                        webbrowser.open("https://mail.google.com")
                        activated = False
                        continue

                    if pergunta in ["abrir drive", "abrir google drive", "drive", "google drive"]:
                        audios_drive = [
                            os.path.join(VOICE_PRESETS_DIR, "Google Drive aberto.wav"),
                            os.path.join(VOICE_PRESETS_DIR, "Drive aberto.wav")
                        ]
                        play_local_audio(random.choice(audios_drive))
                        print("Abrindo Drive no navegador...")
                        webbrowser.open("https://drive.google.com")
                        activated = False
                        continue

                    if pergunta in ["abrir docs.", "abrir google docs", "google documento", "google documentos", "abrir google documentos"]:
                        audios_drive = [
                            os.path.join(VOICE_PRESETS_DIR, "Google Docs aberto.wav"),
                            os.path.join(VOICE_PRESETS_DIR, "Google Documentos aberto.wav")
                        ]
                        play_local_audio(random.choice(audios_drive))
                        print("Abrindo Google Docs no navegador...")
                        webbrowser.open("https://docs.google.com/")
                        activated = False
                        continue
                    
                    elif pergunta in ["abrir planilha", "abrir google planilha", "google planilhas", "google sheets"]:
                        audios_sheets = [
                            os.path.join(VOICE_PRESETS_DIR, "Google Planilhas aberto.wav"),
                            os.path.join(VOICE_PRESETS_DIR, "Google Sheets aberto.wav")
                        ]
                        play_local_audio(random.choice(audios_sheets))
                        print("Abrindo Google Planilhas no navegador...")
                        webbrowser.open("https://sheets.google.com/")
                        activated = False
                        continue
                    
                    elif pergunta in ["abrir agenda", "abrir google agenda", "google agenda", "abrir calendário", "abrir calendario"]:
                        audios_calendar = [
                            os.path.join(VOICE_PRESETS_DIR, "Google Agenda aberta.wav"),
                            os.path.join(VOICE_PRESETS_DIR, "Google Calendar aberto.wav")
                        ]
                        play_local_audio(random.choice(audios_calendar))
                        print("Abrindo Google Agenda no navegador...")
                        webbrowser.open("https://calendar.google.com/")
                        activated = False
                        continue
                    
                    elif "procurar" in pergunta and "youtube" in pergunta:
                        termos = pergunta.replace("procurar", "").replace("no youtube", "").strip()
                        if termos:
                            url = f"https://www.youtube.com/results?search_query={'+'.join(termos.split())}"
                            audios_youtube = [
                                os.path.join(VOICE_PRESETS_DIR, "Procurando no YouTube.wav"),
                                os.path.join(VOICE_PRESETS_DIR, "Buscando vídeos no YouTube.wav")
                            ]
                            play_local_audio(random.choice(audios_youtube))
                            print(f"Procurando por '{termos}' no YouTube...")
                            webbrowser.open(url)
                        else:
                            print("Nenhum termo de busca especificado para o YouTube.")
                        activated = False
                        continue
                        
                    if pergunta.startswith("tocar"):
                        musica = pergunta[7:].strip()
                        if musica:
                            print("Buscando a música:", musica)
                            try:
                                youtube = build('youtube', 'v3', developerKey=YOUTUBE_API_KEY)
                                search_response = youtube.search().list(
                                    q=musica,
                                    part="snippet",
                                    type="video",
                                    maxResults=1
                                ).execute()
                                items = search_response.get("items")
                                if items and len(items) > 0:
                                    video_id = items[0]["id"]["videoId"]
                                    url = "https://music.youtube.com/watch?v=" + video_id
                                    print("Abrindo e tocando a música:", musica)
                                    webbrowser.open(url)
                                else:
                                    print("Nenhum resultado encontrado para:", musica)
                            except Exception as e:
                                print("Erro ao buscar a música:", e)
                        activated = False
                        continue
                    
                    if "onde está" in pergunta:
                        objeto = pergunta.split("onde está", 1)[1].strip()
                        if not objeto:
                            print("Fale o nome do objeto:")
                            play_local_audio(os.path.join(VOICE_PRESETS_DIR, "Qual item você gostaria.wav"))
                            objeto = capturar_audio(recognizer, source, timeout=LISTEN_TIMEOUT, phrase_time_limit=PHRASE_TIMEOUT)
                            if not objeto:
                                print("[DEBUG CLIENTE] Não foi possível entender o objeto falado.")
                                activated = False
                                continue
                        print("[DEBUG CLIENTE] Objeto para localizar:", objeto)
                        update_last_connection()
                        resposta = cliente_tcp(host, porta, "localizar", objeto)
                        if "item encontrado" in resposta.lower() or "comando led enviado" in resposta.lower():
                            print("[DEBUG CLIENTE] Item encontrado (resposta do servidor):", resposta)
                            print("Item encontrado")
                            play_local_audio(os.path.join(VOICE_PRESETS_DIR, "Está aqui!.wav"))
                        else:
                            print("[DEBUG CLIENTE] Item não encontrado (resposta do servidor):", resposta)
                            print("Item não encontrado")
                            play_local_audio(os.path.join(VOICE_PRESETS_DIR, "Objeto não encontrado .wav"))
                    elif "o que é isso" in pergunta:
                        print("Iniciando stream de 5s para detecção contínua...")
                        resultado = stream_and_detect()
                        if resultado:
                            print("[DEBUG CLIENTE] Objeto detectado continuamente:", resultado)
                            cliente_tcp(host, porta, "IA_item", resultado)
                        else:
                            print("[DEBUG CLIENTE] Nenhuma detecção estável encontrada.")
                            play_local_audio(os.path.join(VOICE_PRESETS_DIR, "Objeto não encontrado .wav"))
                    else:
                        print("[DEBUG CLIENTE] Enviando pergunta 'responda' para o servidor:", pergunta)
                        cliente_tcp(host, porta, "responda", pergunta)
                    activated = False
                else:
                    if not activated:
                        print("Por favor, inicie a conversa com uma saudação (ex.: 'olá teca').")
                    else:
                        print("Conversa já ativada. Por favor, formule sua pergunta.")
                update_last_connection()
    except OSError as e:
        print(f"Erro ao acessar o microfone: {e}")

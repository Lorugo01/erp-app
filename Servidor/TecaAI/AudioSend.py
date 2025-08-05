import socket
import os

def send_audio(conn, arquivo_audio):
    try:
        if os.path.exists(arquivo_audio):
            file_size = os.path.getsize(arquivo_audio)
            header = f"{file_size:010d}".encode('utf-8')
            conn.sendall(header)
            with open(arquivo_audio, 'rb') as arquivo:
                while True:
                    dados = arquivo.read(4096)
                    if not dados:
                        break
                    conn.send(dados)
            print(f"[AudioSend] Arquivo '{arquivo_audio}' enviado com sucesso.")
        else:
            conn.send("Erro: Arquivo de áudio não encontrado.".encode('utf-8'))
            print(f"[AudioSend] Arquivo '{arquivo_audio}' não encontrado.")
    except Exception as e:
        print(f"[AudioSend] Erro durante o envio do áudio: {e}")

import io
import wave
import pyaudio
import socket

def _recv_exact(conn: socket.socket, n: int) -> bytes:
    buf = b""
    while len(buf) < n:
        chunk = conn.recv(n - len(buf))
        if not chunk:
            raise ConnectionError("Conexão encerrada durante a leitura.")
        buf += chunk
    return buf

def solicitar_audio(conn: socket.socket):
    """
    Lê o stream conforme protocolo:
      loop:
        - header (10 bytes, decimal)
        - se 0: encerra
        - lê payload de 'len' bytes
        - toca o WAV do payload
    Reaproveita o mesmo stream PyAudio quando formato coincidir.
    """
    p = None
    stream = None
    current_fmt = None  # (sampwidth, channels, rate)

    try:
        p = pyaudio.PyAudio()

        while True:
            header = conn.recv(10)
            if not header:
                # conexão fechada pelo servidor (ex.: IA_item)
                break
            try:
                seg_len = int(header.decode('utf-8'))
            except ValueError:
                # header inválido → encerra
                break

            if seg_len == 0:
                # sentinel final (ex.: IA_resposta)
                break

            seg_data = _recv_exact(conn, seg_len)

            wf = wave.open(io.BytesIO(seg_data), 'rb')
            fmt = (wf.getsampwidth(), wf.getnchannels(), wf.getframerate())

            if stream is None or fmt != current_fmt:
                if stream:
                    stream.stop_stream()
                    stream.close()
                stream = p.open(format=p.get_format_from_width(fmt[0]),
                                channels=fmt[1],
                                rate=fmt[2],
                                output=True)
                current_fmt = fmt

            CHUNK = 8192
            data = wf.readframes(CHUNK)
            while data:
                stream.write(data)
                data = wf.readframes(CHUNK)
            wf.close()
            print("Segmento reproduzido.")

    except Exception as e:
        print(f"[recv_audio] Erro: {e}")
    finally:
        try:
            if stream:
                stream.stop_stream()
                stream.close()
        except Exception:
            pass
        try:
            if p:
                p.terminate()
        except Exception:
            pass

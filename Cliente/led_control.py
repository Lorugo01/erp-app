# led_control.py

import serial
import serial.tools.list_ports
import time

def select_serial_port(keyword: str = None) -> str:
    """
    Retorna a primeira porta serial disponível. Se `keyword` for fornecido,
    retorna a porta cujo device ou descrição contenha essa palavra.
    """
    ports = list(serial.tools.list_ports.comports())
    if not ports:
        raise IOError("Nenhuma porta serial encontrada.")
    if keyword:
        for p in ports:
            combined = (p.device or "") + " " + (p.description or "")
            if keyword.lower() in combined.lower():
                return p.device
    return ports[0].device

# Inicializa a conexão serial com ESP32 de forma dinâmica
try:
    print("[DEBUG LED] ==========================================")
    print("[DEBUG LED] Iniciando conexão serial com ESP32...")
    # Você pode ajustar o filtro, por exemplo "esp32", ou deixar None para pegar a primeira porta
    port = select_serial_port(keyword="esp32")
    print(f"[DEBUG LED] Porta selecionada: {port}")
    ser = serial.Serial(port, 115200, timeout=1)
    time.sleep(2)  # Aguarda o reset da placa
    print(f"[DEBUG LED] Conectado na porta {port} a 115200 bps")
    print(f"[DEBUG LED] Conexão serial estabelecida com sucesso!")
    print("[DEBUG LED] ==========================================")
except Exception as e:
    print(f"[led_control] Erro ao inicializar conexão serial: {e}")
    ser = None

def send_command(cmd: str) -> str:
    """
    Envia um comando ao ESP32 via serial.
    :param cmd: texto do comando (será convertido para minúsculas, trim e com newline)
    :return: status ou mensagem de erro
    """
    if ser is None:
        print("[DEBUG LED] Erro: Serial não inicializada")
        return "Erro: Serial não inicializada"

    # Preparar e exibir o comando
    cmd_formatted = cmd.lower().strip()
    if not cmd_formatted.endswith('\n'):
        cmd_formatted += '\n'
    print(f"[DEBUG LED] ==========================================")
    print(f"[DEBUG LED] Enviando comando para ESP32: '{cmd_formatted.strip()}'")
    print(f"[DEBUG LED] Porta serial: {port}")
    print(f"[DEBUG LED] ==========================================")

    try:
        ser.write(cmd_formatted.encode('utf-8'))
        ser.flush()
        print(f"[DEBUG LED] Comando enviado com sucesso!")
        
        # Aguarda resposta do ESP32
        time.sleep(0.5)  # Aguarda resposta
        if ser.in_waiting > 0:
            response = ser.readline().decode('utf-8').strip()
            print(f"[DEBUG LED] Resposta do ESP32: '{response}'")
        else:
            print(f"[DEBUG LED] Nenhuma resposta do ESP32")
            
    except Exception as e:
        print(f"[DEBUG LED] Erro durante envio: {e}")
        return f"Erro durante envio: {e}"

    print(f"[DEBUG LED] Comando finalizado")
    return "Comando enviado"

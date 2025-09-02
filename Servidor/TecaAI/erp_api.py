from flask import Flask, request, jsonify
from flask_cors import CORS
import socket
import json
import threading
import time
import logging
from datetime import datetime
import sqlite3
import os
import difflib

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)  # Permite CORS para o frontend

# Configurações do TecaAI (modificado para teste)
TECAAI_HOST = "localhost"
TECAAI_PORT = 5000

# MODO TESTE - Simula respostas sem precisar do Ollama
TEST_MODE = True

# Configurações para servidor TCP (porta 5000)
TCP_HOST = '0.0.0.0'
TCP_PORT = 5000

# Cliente TCP para comunicação interna
class TCPClientHandler:
    """Manipulador de conexões TCP para o cliente Python."""
    
    def __init__(self):
        self.active_clients = [] # Lista para manter sockets de clientes ativos
        self.lock = threading.Lock()

    def add_client(self, client_socket):
        with self.lock:
            self.active_clients.append(client_socket)
            logger.info(f"Cliente TCP adicionado. Total: {len(self.active_clients)}")

    def remove_client(self, client_socket):
        with self.lock:
            if client_socket in self.active_clients:
                self.active_clients.remove(client_socket)
                logger.info(f"Cliente TCP removido. Total: {len(self.active_clients)}")
            client_socket.close()
    
    def broadcast_command(self, funcao, parametro, voice="Teca") -> list:
        """Envia um comando para todos os clientes TCP conectados e retorna as respostas."""
        responses = []
        clients_to_remove = []
        
        with self.lock:
            for client_socket in self.active_clients:
                try:
                    # Prepara dados JSON
                    dados = {
                        "ID": "server_broadcast", # ID especial para comandos broadcast
                        "funcao": funcao,
                        "parametro": parametro,
                        "voice": voice
                    }
                    data_to_send = json.dumps(dados).encode('utf-8')
                    
                    # Envia dados
                    client_socket.sendall(f"{len(data_to_send):010d}".encode('utf-8') + data_to_send)
                    
                    # Tenta receber uma resposta (com timeout)
                    client_socket.settimeout(2.0) # Curto timeout para não bloquear o broadcast
                    size_data = client_socket.recv(10)
                    if not size_data:
                        raise Exception("Conexão fechada pelo cliente")
                    size = int(size_data.decode('utf-8'))
                    response_data = b""
                    while len(response_data) < size:
                        chunk = client_socket.recv(size - len(response_data))
                        if not chunk:
                            raise Exception("Conexão fechada durante recebimento")
                        response_data += chunk
                    
                    responses.append({"success": True, "response": response_data.decode('utf-8')})
                    
                except (socket.timeout, Exception) as e:
                    logger.warning(f"Erro ao enviar/receber broadcast para cliente TCP: {e}")
                    responses.append({"success": False, "error": str(e)})
                    clients_to_remove.append(client_socket)
            
            # Remove clientes que falharam
            for client_socket in clients_to_remove:
                self.remove_client(client_socket)

        return responses
    
    def handle_tcp_connection(self, client_socket, address):
        """Manipula conexão TCP do cliente Python"""
        self.add_client(client_socket) # Adiciona o cliente à lista de ativos
        try:
            logger.info(f"Conexão TCP recebida de {address}")
            
            # Recebe dados JSON do cliente
            data = client_socket.recv(8192).decode('utf-8').strip()
            if not data:
                return
                
            dados_json = json.loads(data)
            id = dados_json.get('ID', 'unknown')
            funcao = dados_json.get('funcao', '')
            parametro = dados_json.get('parametro', '')
            voice = dados_json.get('voice', 'Teca')
            
            logger.info(f"Comando TCP: {funcao} - {parametro}")
            
            # Processa o comando usando o cliente TecaAI (que já está em modo de teste)
            result = teca_client.send_command(funcao, parametro, voice)
            
            # Envia resposta seguindo o protocolo do API_Rpi.py
            response_text = result.get('response', 'Erro: Sem resposta')
            response_data = response_text.encode('utf-8')
            
            # Envia tamanho (10 dígitos) + dados
            size_header = f"{len(response_data):010d}".encode('utf-8')
            client_socket.sendall(size_header + response_data)
            
            logger.info(f"Resposta TCP enviada para {address}")
            
        except Exception as e:
            logger.error(f"Erro na conexão TCP {address}: {e}")
        finally:
            self.remove_client(client_socket) # Remove o cliente ao encerrar a conexão
            logger.info(f"Conexão TCP {address} encerrada")

# Instância do manipulador TCP
tcp_handler = TCPClientHandler()

def start_tcp_server():
    """Inicia servidor TCP na porta 5000"""
    import socket
    import threading
    
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
            server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            server.bind((TCP_HOST, TCP_PORT))
            server.listen(10)
            
            logger.info(f" Servidor TCP iniciado na porta {TCP_PORT}")
            print(f" Servidor TCP iniciado na porta {TCP_PORT}")
            
            while True:
                try:
                    client_sock, address = server.accept()
                    logger.info(f"Conexão TCP aceita de {address}")
                    client_thread = threading.Thread(
                        target=tcp_handler.handle_tcp_connection, 
                        args=(client_sock, address),
                        daemon=True
                    )
                    client_thread.start()
                except Exception as e:
                    logger.error(f"Erro ao aceitar conexão TCP: {e}")
    except Exception as e:
        logger.critical(f"Erro fatal no servidor TCP: {e}")
        print(f"Erro fatal no servidor TCP: {e}")

class TecaAIClient:
    """Cliente para comunicação com o TecaAI via TCP"""
    
    def __init__(self, host="localhost", port=5000):
        self.host = host
        self.port = port
    
    def send_command(self, funcao, parametro, voice="Teca"):
        """Envia comando para o TecaAI e retorna resposta"""
        
        # MODO TESTE - Simula respostas
        if TEST_MODE:
            logger.info(f"[TESTE] Simulando comando: {funcao} - {parametro}")
            
            # Simula diferentes tipos de resposta baseado na função
            if funcao == "responda":
                response = f"[TESTE] Resposta simulada para: '{parametro}' (Voz: {voice})"
            elif funcao == "localizar":
                response = f"[TESTE] Item '{parametro}' localizado na posição f1s2 - Armário A"
            elif funcao == "comando":
                response = f"[TESTE] Comando '{parametro}' executado com sucesso"
            elif funcao == "IA_item":
                response = f"[TESTE] Informações sobre '{parametro}': É um equipamento de laboratório"
            else:
                response = f"[TESTE] Função '{funcao}' executada com parâmetro '{parametro}'"
            
            # Simula delay de processamento
            time.sleep(0.5)
            
            return {
                "success": True,
                "response": response,
                "timestamp": datetime.now().isoformat()
            }
        
        # MODO REAL - Comunicação com TecaAI (desabilitado em teste)
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client:
                client.settimeout(10)  # Timeout de 10 segundos
                client.connect((self.host, self.port))
                
                # Prepara dados JSON
                dados = {
                    "ID": f"erp_{int(time.time())}",
                    "funcao": funcao,
                    "parametro": parametro,
                    "voice": voice
                }
                
                # Envia dados
                client.sendall(json.dumps(dados).encode('utf-8'))
                
                # Recebe resposta seguindo o protocolo do API_Rpi.py
                # Primeiro recebe o tamanho (10 dígitos)
                size_data = client.recv(10)
                if not size_data:
                    raise Exception("Conexão fechada pelo servidor")
                
                try:
                    size = int(size_data.decode('utf-8'))
                except ValueError:
                    raise Exception("Formato de resposta inválido")
                
                # Agora recebe os dados
                response_data = b""
                while len(response_data) < size:
                    chunk = client.recv(size - len(response_data))
                    if not chunk:
                        raise Exception("Conexão fechada durante recebimento")
                    response_data += chunk
                
                response = response_data.decode('utf-8')
                
                return {
                    "success": True,
                    "response": response,
                    "timestamp": datetime.now().isoformat()
                }
                
        except Exception as e:
            logger.error(f"Erro na comunicação com TecaAI: {e}")
            return {
                "success": False,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }

# Instância do cliente
teca_client = TecaAIClient(TECAAI_HOST, TECAAI_PORT)

# Banco de dados para histórico de comandos do ERP
def init_erp_db():
    """Inicializa banco de dados para histórico do ERP"""
    conn = sqlite3.connect('erp_tecaai.db')
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS erp_commands (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,
            user_role TEXT,
            command_type TEXT,
            parameter TEXT,
            response TEXT,
            success BOOLEAN,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    conn.commit()
    conn.close()

def log_command(user_id, user_role, command_type, parameter, response, success):
    """Registra comando no histórico"""
    conn = sqlite3.connect('erp_tecaai.db')
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO erp_commands 
        (user_id, user_role, command_type, parameter, response, success)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', (user_id, user_role, command_type, parameter, response, success))
    conn.commit()
    conn.close()

# Rotas da API

@app.route('/health', methods=['GET'])
def health_check():
    """Verifica se a API está funcionando"""
    return jsonify({
        "status": "online",
        "service": "ERP-TecaAI Bridge (MODO TESTE)" if TEST_MODE else "ERP-TecaAI Bridge",
        "test_mode": TEST_MODE,
        "timestamp": datetime.now().isoformat()
    })

@app.route('/ask', methods=['POST'])
def ask_question():
    """Faz uma pergunta para a IA"""
    try:
        data = request.get_json()
        
        if not data or 'question' not in data:
            return jsonify({"error": "Campo 'question' é obrigatório"}), 400
        
        question = data['question']
        voice = data.get('voice', 'Teca')
        user_id = data.get('user_id', 'unknown')
        user_role = data.get('user_role', 'unknown')
        
        # Validações
        if len(question) > 500:
            return jsonify({"error": "Pergunta muito longa (máximo 500 caracteres)"}), 400
        
        if voice not in ['Teca', 'Einstein', 'Curie', 'Frida']:
            return jsonify({"error": "Voz inválida"}), 400
        
        # Envia comando para TecaAI
        result = teca_client.send_command("responda", question, voice)
        
        # Registra no histórico
        log_command(user_id, user_role, "ask", question, result.get('response', ''), result['success'])
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Erro na rota /ask: {e}")
        return jsonify({"error": "Erro interno do servidor"}), 500

@app.route('/locate', methods=['POST'])
def locate_item():
    """Localiza um item no laboratório"""
    try:
        data = request.get_json()
        
        if not data or 'item' not in data:
            return jsonify({"error": "Campo 'item' é obrigatório"}), 400
        
        item = data['item']
        user_id = data.get('user_id', 'unknown')
        user_role = data.get('user_role', 'unknown')
        
        # Validações
        if len(item) > 100:
            return jsonify({"error": "Nome do item muito longo"}), 400
        
        # Envia comando para TecaAI
        result = teca_client.send_command("localizar", item)
        
        # Registra no histórico
        log_command(user_id, user_role, "locate", item, result.get('response', ''), result['success'])
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Erro na rota /locate: {e}")
        return jsonify({"error": "Erro interno do servidor"}), 500

@app.route('/control', methods=['POST'])
def control_device():
    """Controla dispositivos (LEDs, etc.)"""
    try:
        data = request.get_json()
        
        if not data or 'command' not in data:
            return jsonify({"error": "Campo 'command' é obrigatório"}), 400
        
        command = data['command']
        user_id = data.get('user_id', 'unknown')
        user_role = data.get('user_role', 'unknown')
        
        # Validações
        if len(command) > 100:
            return jsonify({"error": "Comando muito longo"}), 400
        
        # Envia comando para TecaAI
        result = teca_client.send_command("comando", command)
        
        # Registra no histórico
        log_command(user_id, user_role, "control", command, result.get('response', ''), result['success'])
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Erro na rota /control: {e}")
        return jsonify({"error": "Erro interno do servidor"}), 500

@app.route('/item-info', methods=['POST'])
def get_item_info():
    """Obtém informações sobre um item"""
    try:
        data = request.get_json()
        
        if not data or 'item' not in data:
            return jsonify({"error": "Campo 'item' é obrigatório"}), 400
        
        item = data['item']
        user_id = data.get('user_id', 'unknown')
        user_role = data.get('user_role', 'unknown')
        
        # Validações
        if len(item) > 100:
            return jsonify({"error": "Nome do item muito longo"}), 400
        
        # Envia comando para TecaAI
        result = teca_client.send_command("IA_item", item)
        
        # Registra no histórico
        log_command(user_id, user_role, "item_info", item, result.get('response', ''), result['success'])
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Erro na rota /item-info: {e}")
        return jsonify({"error": "Erro interno do servidor"}), 500

# NOVA ROTA PARA TESTE DE COMANDOS ESP32
@app.route('/esp32', methods=['POST'])
def esp32_command():
    """Comandos diretos para o ESP32 (MODO TESTE)"""
    try:
        data = request.get_json()
        
        if not data or 'command' not in data:
            return jsonify({"error": "Campo 'command' é obrigatório"}), 400
        
        command = data['command']
        esp_ip = data.get('esp_ip', '192.168.100.184')
        user_id = data.get('user_id', 'unknown')
        user_role = data.get('user_role', 'unknown')
        
        # Validações
        if len(command) > 100:
            return jsonify({"error": "Comando muito longo"}), 400
        
        # Comandos válidos do ESP32
        valid_commands = [
            "demo", "demo off", "tecaon", "tecaoff",
            "allled vermelho", "allled verde", "allled azul", "allled amarelo",
            "allled roxo", "allled ciano", "allled branco", "allled laranja",
            "allled rosa", "allled preto", "allled off"
        ]
        
        # Verifica se é um comando válido ou um comando fx
        import re
        is_valid = (command.lower() in valid_commands or 
                   re.match(r'^fx\d+s\d+\s+\w+$', command.lower()))
        
        if not is_valid:
            return jsonify({
                "error": "Comando inválido",
                "valid_commands": valid_commands + ["fx<fita><sessao> <cor>"]
            }), 400
        
        # MODO TESTE - Simula resposta do ESP32
        if TEST_MODE:
            logger.info(f"[TESTE] Simulando comando ESP32: {command} para {esp_ip}")
            
            # Simula diferentes respostas baseado no comando
            if "demo" in command.lower():
                response = f"[TESTE] Modo demonstração {'ativado' if 'off' not in command else 'desativado'} no ESP32 {esp_ip}"
            elif "teca" in command.lower():
                response = f"[TESTE] Animação TECA {'ativada' if 'off' not in command else 'desativada'} no ESP32 {esp_ip}"
            elif "allled" in command.lower():
                cor = command.split()[-1] if len(command.split()) > 1 else "desconhecida"
                response = f"[TESTE] Todos os LEDs definidos como {cor} no ESP32 {esp_ip}"
            elif "fx" in command.lower():
                response = f"[TESTE] Comando de sessão {command} executado no ESP32 {esp_ip}"
            else:
                response = f"[TESTE] Comando '{command}' executado no ESP32 {esp_ip}"
            
            # Simula delay de processamento
            time.sleep(0.3)
            
            result = {
                "success": True,
                "command": command,
                "esp_ip": esp_ip,
                "response": response,
                "timestamp": datetime.now().isoformat()
            }
            
            # Registra no histórico
            log_command(user_id, user_role, "esp32_direct", command, response, True)
            
            return jsonify(result)
        
        # MODO REAL - Aqui você implementaria a comunicação real com ESP32
        else:
            # Implementação real seria aqui
            pass
            
    except Exception as e:
        logger.error(f"Erro na rota /esp32: {e}")
        return jsonify({"error": "Erro interno do servidor"}), 500

@app.route('/esp32/broadcast', methods=['POST'])
def esp32_broadcast_command():
    """Envia um comando ESP32 para todos os clientes TCP conectados."""
    try:
        data = request.get_json()
        
        if not data or 'command' not in data:
            return jsonify({"error": "Campo 'command' é obrigatório"}), 400
        
        command = data['command']
        user_id = data.get('user_id', 'unknown')
        user_role = data.get('user_role', 'unknown')
        
        # Validações (mesmas do /esp32 normal)
        if len(command) > 100:
            return jsonify({"error": "Comando muito longo"}), 400
        
        valid_commands = [
            "demo", "demo off", "tecaon", "tecaoff",
            "allled vermelho", "allled verde", "allled azul", "allled amarelo",
            "allled roxo", "allled ciano", "allled branco", "allled laranja",
            "allled rosa", "allled preto", "allled off"
        ]
        import re
        is_valid = (command.lower() in valid_commands or 
                   re.match(r'^fx\d+s\d+\s+\w+$', command.lower()))
        
        if not is_valid:
            return jsonify({
                "error": "Comando inválido",
                "valid_commands": valid_commands + ["fx<fita><sessao> <cor>"]
            }), 400
        
        # MODO TESTE - Simula broadcast
        if TEST_MODE:
            logger.info(f"[TESTE] Simulando broadcast ESP32: {command}")
            
            # Simula respostas para alguns clientes
            simulated_responses = []
            for i in range(tcp_handler.active_clients.__len__() if tcp_handler.active_clients.__len__() > 0 else 1):
                client_response = f"[TESTE] Broadcast de '{command}' recebido por cliente simulado {i+1}"
                simulated_responses.append({"success": True, "response": client_response})
                
            result = {
                "success": True,
                "command": command,
                "broadcast_responses": simulated_responses,
                "timestamp": datetime.now().isoformat()
            }
            log_command(user_id, user_role, "esp32_broadcast", command, json.dumps(simulated_responses), True)
            return jsonify(result)

        # MODO REAL - Envia para todos os clientes conectados
        broadcast_results = tcp_handler.broadcast_command("comando", command, "Teca")
        
        # Agrega as respostas
        success_count = sum(1 for res in broadcast_results if res["success"])
        total_clients = len(broadcast_results)
        summary_message = f"Comando '{command}' enviado para {total_clients} clientes, {success_count} sucesso." 

        result = {
            "success": True,
            "command": command,
            "summary": summary_message,
            "individual_responses": broadcast_results,
            "timestamp": datetime.now().isoformat()
        }
        
        log_command(user_id, user_role, "esp32_broadcast", command, json.dumps(broadcast_results), True)
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Erro na rota /esp32/broadcast: {e}")
        return jsonify({"error": "Erro interno do servidor"}), 500

@app.route('/items', methods=['GET'])
def get_all_items():
    """Retorna todos os itens disponíveis no banco de dados de localizações"""
    try:
        # Caminho para o banco de dados de localizações
        db_path = os.path.join(os.path.dirname(__file__), "localizações", "localizacoes.db")
        
        if not os.path.exists(db_path):
            logger.error(f"Banco de dados não encontrado em: {db_path}")
            return jsonify({
                "success": False,
                "error": "Banco de dados de localizações não encontrado"
            }), 404
        
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT nome, posicao, esp_ip FROM itens ORDER BY nome")
        items = cursor.fetchall()
        conn.close()
        
        # Mapeamento de IPs para letras
        ip_mapping = {
            "192.168.100.184": "A",
            "192.168.100.185": "B",
            "192.168.100.186": "C",
            # Adicione mais mapeamentos conforme necessário
            # "192.168.100.187": "D",
            # "192.168.100.188": "E",
            # etc.
        }
        
        items_list = []
        for nome, posicao, esp_ip in items:
            # Traduzir posição (f1s1 -> Fileira 1, Segmento 1)
            posicao_traduzida = ""
            if posicao.startswith('f') and 's' in posicao:
                try:
                    # Extrair números da posição (ex: f1s1 -> fileira=1, segmento=1)
                    partes = posicao.replace('f', '').split('s')
                    if len(partes) == 2:
                        fileira = partes[0]
                        segmento = partes[1]
                        posicao_traduzida = f"Fileira {fileira}, Segmento {segmento}"
                    else:
                        posicao_traduzida = posicao
                except:
                    posicao_traduzida = posicao
            else:
                posicao_traduzida = posicao
            
            # Traduzir IP para letra
            esp_ip_traduzido = ip_mapping.get(esp_ip, esp_ip)
            
            items_list.append({
                "nome": nome,
                "posicao": posicao_traduzida,
                "posicao_original": posicao,
                "esp_ip": esp_ip_traduzido,
                "esp_ip_original": esp_ip
            })
        
        logger.info(f"Retornando {len(items_list)} itens")
        return jsonify({
            "success": True,
            "items": items_list,
            "count": len(items_list)
        })
        
    except Exception as e:
        logger.error(f"Erro na rota /items: {e}")
        return jsonify({"error": "Erro interno do servidor"}), 500

@app.route('/items', methods=['POST'])
def add_item():
    """Adiciona um novo item ao banco de dados"""
    try:
        data = request.get_json()
        nome = data.get('nome')
        posicao = data.get('posicao')
        esp_ip = data.get('esp_ip')
        user_id = data.get('user_id')
        user_role = data.get('user_role')
        
        if not all([nome, posicao, esp_ip]):
            return jsonify({
                "success": False,
                "error": "Nome, posição e IP são obrigatórios"
            }), 400
        
        # Caminho para o banco de dados
        db_path = os.path.join(os.path.dirname(__file__), "localizações", "localizacoes.db")
        
        if not os.path.exists(db_path):
            return jsonify({
                "success": False,
                "error": "Banco de dados não encontrado"
            }), 404
        
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Verificar se já existe um item na posição
        cursor.execute("SELECT nome FROM itens WHERE posicao = ? AND esp_ip = ?", (posicao, esp_ip))
        existing_item = cursor.fetchone()
        
        if existing_item:
            # Se existe item na posição, fazer a troca
            old_item_name = existing_item[0]
            cursor.execute("UPDATE itens SET nome = ? WHERE posicao = ? AND esp_ip = ?", (nome, posicao, esp_ip))
            action = "trocado"
            message = f"Item '{old_item_name}' foi substituído por '{nome}' na posição {posicao}"
        else:
            # Adicionar novo item
            cursor.execute("INSERT INTO itens (nome, posicao, esp_ip) VALUES (?, ?, ?)", (nome, posicao, esp_ip))
            action = "adicionado"
            message = f"Item '{nome}' foi adicionado na posição {posicao}"
        
        conn.commit()
        conn.close()
        
        # Log da ação
        log_command(user_id, user_role, "add_item", f"{nome} - {posicao} - {esp_ip}", message, True)
        
        return jsonify({
            "success": True,
            "message": message,
            "action": action,
            "item": {
                "nome": nome,
                "posicao": posicao,
                "esp_ip": esp_ip
            }
        })
        
    except Exception as e:
        logger.error(f"Erro na rota /items POST: {e}")
        return jsonify({"error": "Erro interno do servidor"}), 500

@app.route('/items/<int:item_id>', methods=['PUT'])
def edit_item(item_id):
    """Edita um item existente"""
    try:
        data = request.get_json()
        nome = data.get('nome')
        posicao = data.get('posicao')
        esp_ip = data.get('esp_ip')
        user_id = data.get('user_id')
        user_role = data.get('user_role')
        
        if not all([nome, posicao, esp_ip]):
            return jsonify({
                "success": False,
                "error": "Nome, posição e IP são obrigatórios"
            }), 400
        
        # Caminho para o banco de dados
        db_path = os.path.join(os.path.dirname(__file__), "localizações", "localizacoes.db")
        
        if not os.path.exists(db_path):
            return jsonify({
                "success": False,
                "error": "Banco de dados não encontrado"
            }), 404
        
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Verificar se o item existe
        cursor.execute("SELECT nome, posicao, esp_ip FROM itens WHERE id = ?", (item_id,))
        existing_item = cursor.fetchone()
        
        if not existing_item:
            conn.close()
            return jsonify({
                "success": False,
                "error": "Item não encontrado"
            }), 404
        
        old_nome, old_posicao, old_esp_ip = existing_item
        
        # Verificar se a nova posição já está ocupada por outro item
        cursor.execute("SELECT nome FROM itens WHERE posicao = ? AND esp_ip = ? AND id != ?", (posicao, esp_ip, item_id))
        conflicting_item = cursor.fetchone()
        
        if conflicting_item:
            # Se existe conflito, fazer a troca
            conflicting_name = conflicting_item[0]
            cursor.execute("UPDATE itens SET nome = ? WHERE posicao = ? AND esp_ip = ? AND id != ?", (nome, posicao, esp_ip, item_id))
            cursor.execute("UPDATE itens SET nome = ?, posicao = ?, esp_ip = ? WHERE id = ?", (conflicting_name, old_posicao, old_esp_ip, item_id))
            action = "trocado"
            message = f"Item '{nome}' foi trocado com '{conflicting_name}'"
        else:
            # Atualizar o item
            cursor.execute("UPDATE itens SET nome = ?, posicao = ?, esp_ip = ? WHERE id = ?", (nome, posicao, esp_ip, item_id))
            action = "editado"
            message = f"Item '{nome}' foi atualizado"
        
        conn.commit()
        conn.close()
        
        # Log da ação
        log_command(user_id, user_role, "edit_item", f"{nome} - {posicao} - {esp_ip}", message, True)
        
        return jsonify({
            "success": True,
            "message": message,
            "action": action,
            "item": {
                "id": item_id,
                "nome": nome,
                "posicao": posicao,
                "esp_ip": esp_ip
            }
        })
        
    except Exception as e:
        logger.error(f"Erro na rota /items PUT: {e}")
        return jsonify({"error": "Erro interno do servidor"}), 500

@app.route('/items/<int:item_id>', methods=['DELETE'])
def delete_item(item_id):
    """Remove um item do banco de dados"""
    try:
        data = request.get_json()
        user_id = data.get('user_id')
        user_role = data.get('user_role')
        
        # Caminho para o banco de dados
        db_path = os.path.join(os.path.dirname(__file__), "localizações", "localizacoes.db")
        
        if not os.path.exists(db_path):
            return jsonify({
                "success": False,
                "error": "Banco de dados não encontrado"
            }), 404
        
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Verificar se o item existe
        cursor.execute("SELECT nome FROM itens WHERE id = ?", (item_id,))
        existing_item = cursor.fetchone()
        
        if not existing_item:
            conn.close()
            return jsonify({
                "success": False,
                "error": "Item não encontrado"
            }), 404
        
        item_name = existing_item[0]
        
        # Remover o item
        cursor.execute("DELETE FROM itens WHERE id = ?", (item_id,))
        conn.commit()
        conn.close()
        
        # Log da ação
        log_command(user_id, user_role, "delete_item", f"ID: {item_id} - {item_name}", f"Item '{item_name}' foi removido", True)
        
        return jsonify({
            "success": True,
            "message": f"Item '{item_name}' foi removido"
        })
        
    except Exception as e:
        logger.error(f"Erro na rota /items DELETE: {e}")
        return jsonify({"error": "Erro interno do servidor"}), 500

@app.route('/history', methods=['GET'])
def get_command_history():
    """Retorna histórico de comandos"""
    try:
        user_id = request.args.get('user_id')
        limit = int(request.args.get('limit', 50))
        
        conn = sqlite3.connect('erp_tecaai.db')
        cursor = conn.cursor()
        
        if user_id:
            cursor.execute('''
                SELECT * FROM erp_commands 
                WHERE user_id = ? 
                ORDER BY timestamp DESC 
                LIMIT ?
            ''', (user_id, limit))
        else:
            cursor.execute('''
                SELECT * FROM erp_commands 
                ORDER BY timestamp DESC 
                LIMIT ?
            ''', (limit,))
        
        rows = cursor.fetchall()
        conn.close()
        
        history = []
        for row in rows:
            history.append({
                "id": row[0],
                "user_id": row[1],
                "user_role": row[2],
                "command_type": row[3],
                "parameter": row[4],
                "response": row[5],
                "success": bool(row[6]),
                "timestamp": row[7]
            })
        
        return jsonify({
            "success": True,
            "history": history,
            "count": len(history)
        })
        
    except Exception as e:
        logger.error(f"Erro na rota /history: {e}")
        return jsonify({"error": "Erro interno do servidor"}), 500

@app.route('/stats', methods=['GET'])
def get_stats():
    """Retorna estatísticas de uso"""
    try:
        conn = sqlite3.connect('erp_tecaai.db')
        cursor = conn.cursor()
        
        # Total de comandos
        cursor.execute("SELECT COUNT(*) FROM erp_commands")
        total_commands = cursor.fetchone()[0]
        
        # Comandos por tipo
        cursor.execute("""
            SELECT command_type, COUNT(*) 
            FROM erp_commands 
            GROUP BY command_type
        """)
        commands_by_type = dict(cursor.fetchall())
        
        # Comandos por usuário
        cursor.execute("""
            SELECT user_role, COUNT(*) 
            FROM erp_commands 
            GROUP BY user_role
        """)
        commands_by_user = dict(cursor.fetchall())
        
        # Taxa de sucesso
        cursor.execute("""
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) as successful
            FROM erp_commands
        """)
        success_data = cursor.fetchone()
        success_rate = (success_data[1] / success_data[0] * 100) if success_data[0] > 0 else 0
        
        conn.close()
        
        return jsonify({
            "success": True,
            "stats": {
                "total_commands": total_commands,
                "commands_by_type": commands_by_type,
                "commands_by_user": commands_by_user,
                "success_rate": round(success_rate, 2)
            }
        })
        
    except Exception as e:
        logger.error(f"Erro na rota /stats: {e}")
        return jsonify({"error": "Erro interno do servidor"}), 500

if __name__ == '__main__':
    # Inicializa banco de dados
    init_erp_db()
    
    # Inicia servidor TCP em uma thread separada
    tcp_thread = threading.Thread(target=start_tcp_server, daemon=True)
    tcp_thread.start()
    
    # Aguarda um pouco para o servidor TCP inicializar
    time.sleep(1)
    
    if TEST_MODE:
        logger.info("🚀 Iniciando API ERP-TecaAI Bridge em MODO TESTE...")
        logger.info("📝 Este servidor simula respostas sem precisar do Ollama")
        logger.info("🔧 Para ativar modo real, altere TEST_MODE = False")
        logger.info("   - POST /esp32/broadcast - Comandos ESP32 para TODOS os clientes (TESTE)") # Adiciona nova rota ao log
    else:
        logger.info("🚀 Iniciando API ERP-TecaAI Bridge em MODO REAL...")
        logger.info("   - POST /esp32/broadcast - Comandos ESP32 para TODOS os clientes") # Adiciona nova rota ao log
    
    logger.info("🌐 Servidor rodando em: http://localhost:5001")
    logger.info("📊 Endpoints disponíveis:")
    logger.info("   - GET  /health     - Status do servidor")
    logger.info("   - POST /ask        - Perguntas para IA")
    logger.info("   - POST /locate     - Localizar itens")
    logger.info("   - POST /control    - Controlar dispositivos")
    logger.info("   - POST /esp32      - Comandos ESP32 (TESTE)")
    logger.info("   - GET  /items      - Listar itens")
    logger.info("   - POST /items      - Adicionar item")
    logger.info("   - GET  /history    - Histórico de comandos")
    logger.info("   - GET  /stats      - Estatísticas")
    logger.info("   - POST /esp32/broadcast - Comandos ESP32 para TODOS os clientes") # Adiciona nova rota ao log
    
    app.run(host='0.0.0.0', port=5001, debug=True, threaded=True) # Habilita threaded para Flask 
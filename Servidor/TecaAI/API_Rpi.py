1# API_Rpi.py

import socket
import threading
import json
import os
import logging
import wave
import re
import hashlib
import sqlite3
import time
from concurrent.futures import ThreadPoolExecutor
from threading import Lock
from typing import Dict, List, Optional, Tuple, Any, Callable

# Módulos locais
import comandos
import itens
import historico_conversa
import text_format
import IAGen
import AudioGen
import AudioSend
import historico_cleaner
from localizar_db import get_item_details

# ── Constantes ────────────────────────────────────────────────────────────────
# Configurações de rede
HOST = '0.0.0.0'
PORT = 5000

# Configurações do ESP32
ESP32_DEFAULT_IP = "192.168.100.184"
ESP32_TCP_PORT = 1234

# Taxonomia de Bloom
BLOOM_LEVELS = {
    "lembrar":     ["listar", "definir", "identificar", "reconhecer"],
    "compreender": ["explicar", "resumir", "classificar", "descrever"],
    "aplicar":     ["usar", "demonstrar", "resolver", "executar"],
    "analisar":    ["comparar", "diferenciar", "analisar", "examinar"],
    "avaliar":     ["justificar", "avaliar", "criticar", "defender"],
    "criar":       ["propor", "formular", "inventar", "desenvolver", "projetar"]
}

# Outros parâmetros
MAX_THREADS = 20
CACHE_DB_PATH = "cache.db"
LOG_FILE = "servidor.log"

# ── Configuração de logging ───────────────────────────────────────────────────
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# ── Configuração do cache ────────────────────────────────────────────────────
class ResponseCache:
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.lock = Lock()
        self._setup_database()
        
    def _setup_database(self) -> None:
        """Configura a tabela do banco de dados de cache."""
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                CREATE TABLE IF NOT EXISTS responses (
                    hash TEXT PRIMARY KEY,
                    response TEXT,
                    timestamp REAL
                )
                """)
                conn.commit()
        except sqlite3.Error as e:
            logger.error(f"Erro ao configurar banco de dados de cache: {e}")
            
    def _get_connection(self):
        """Obtém uma conexão com o banco de dados."""
        return sqlite3.connect(self.db_path)
            
    def get(self, key: str) -> Optional[str]:
        """Obtém uma resposta do cache pelo hash da pergunta."""
        try:
            with self.lock, self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    "SELECT response FROM responses WHERE hash=?", 
                    (key,)
                )
                row = cursor.fetchone()
                return row[0] if row else None
        except sqlite3.Error as e:
            logger.error(f"Erro ao obter resposta do cache: {e}")
            return None
            
    def set(self, key: str, value: str) -> bool:
        """Armazena uma resposta no cache."""
        try:
            with self.lock, self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    "INSERT OR REPLACE INTO responses(hash, response, timestamp) VALUES(?, ?, ?)",
                    (key, value, time.time())
                )
                conn.commit()
                return True
        except sqlite3.Error as e:
            logger.error(f"Erro ao armazenar resposta no cache: {e}")
            return False
            
    def cleanup_old_entries(self, max_age_days: int = 30) -> int:
        """Remove entradas antigas do cache."""
        try:
            with self.lock, self._get_connection() as conn:
                cursor = conn.cursor()
                max_age_seconds = max_age_days * 24 * 60 * 60
                oldest_allowed = time.time() - max_age_seconds
                cursor.execute(
                    "DELETE FROM responses WHERE timestamp < ?",
                    (oldest_allowed,)
                )
                deleted_count = cursor.rowcount
                conn.commit()
                return deleted_count
        except sqlite3.Error as e:
            logger.error(f"Erro ao limpar cache antigo: {e}")
            return 0

# Inicializa o cache
cache = ResponseCache(CACHE_DB_PATH)
thread_pool = ThreadPoolExecutor(max_workers=MAX_THREADS)

# ── Utilitários ───────────────────────────────────────────────────────────────
def detectar_nivel_bloom(pergunta: str) -> str:
    """Detecta o nível da taxonomia de Bloom baseado nos verbos usados na pergunta."""
    pergunta_lower = pergunta.lower()
    
    # Dicionário para armazenar a pontuação de cada nível
    scores = {nivel: 0 for nivel in BLOOM_LEVELS.keys()}
    
    # Padrões verbais por nível (incluindo formas conjugadas)
    padroes_verbais = {
        "lembrar": [
            r'\b(list[ae][rmos]*|listo[u]?)\b',
            r'\b(defin[ae][rmos]*|defino|definiu)\b',
            r'\b(identifi[cq][ae][rmos]*|identifico[u]?)\b',
            r'\b(reconhec[e][rmos]*|reconheço|reconheceu)\b'
        ],
        "compreender": [
            r'\b(expli[cq][ae][rmos]*|explico[u]?)\b',
            r'\b(resum[ae][rmos]*|resumo|resumiu)\b',
            r'\b(classifi[cq][ae][rmos]*|classifico[u]?)\b',
            r'\b(descrev[ae][rmos]*|descrevo|descreveu)\b'
        ],
        "aplicar": [
            r'\b(us[ae][rmos]*|uso[u]?|utiliz[ae][rmos]*|utilizou)\b',
            r'\b(demonstr[ae][rmos]*|demonstro[u]?)\b',
            r'\b(resolv[ae][rmos]*|resolvo|resolveu)\b',
            r'\b(execut[ae][rmos]*|executo[u]?)\b'
        ],
        "analisar": [
            r'\b(compar[ae][rmos]*|comparo[u]?)\b',
            r'\b(diferenci[ae][rmos]*|diferencio[u]?)\b',
            r'\b(analis[ae][rmos]*|analiso[u]?)\b',
            r'\b(examin[ae][rmos]*|examino[u]?)\b'
        ],
        "avaliar": [
            r'\b(justifi[cq][ae][rmos]*|justifico[u]?)\b',
            r'\b(avali[ae][rmos]*|avalio[u]?)\b',
            r'\b(criti[cq][ae][rmos]*|critico[u]?)\b',
            r'\b(defend[ae][rmos]*|defendo|defendeu)\b'
        ],
        "criar": [
            r'\b(propo[nhe][rmos]*|proponho|propôs)\b',
            r'\b(formul[ae][rmos]*|formulo[u]?)\b',
            r'\b(invent[ae][rmos]*|invento[u]?)\b',
            r'\b(desenvolv[ae][rmos]*|desenvolvo|desenvolveu)\b',
            r'\b(projet[ae][rmos]*|projeto[u]?)\b'
        ]
    }
    
    # Verifica cada padrão para cada nível
    for nivel, padroes in padroes_verbais.items():
        for padrao in padroes:
            if re.search(padrao, pergunta_lower):
                scores[nivel] += 1
    
    # Verifica verbos exatos da lista BLOOM_LEVELS (para compatibilidade)
    for nivel, verbos in BLOOM_LEVELS.items():
        for verbo in verbos:
            if verbo in pergunta_lower:
                scores[nivel] += 2  # Peso maior para verbos exatos
                
    # Detecta o nível com maior pontuação
    if max(scores.values()) > 0:
        return max(scores.items(), key=lambda x: x[1])[0]
    
    # Se não encontrou nenhum padrão, usa a detecção por tokens simples
    tokens = re.findall(r'\b\w+\b', pergunta_lower)
    for nivel, verbos in BLOOM_LEVELS.items():
        if any(v in tokens for v in verbos):
            return nivel
            
    # Caso não encontre nada, retorna o nível padrão
    return "lembrar"

def clean_resposta_text(resposta: str) -> str:
    """Remove prefixos desnecessários do texto de resposta."""
    return re.sub(r'(?i)^\s*resposta(?: do servidor)?:\s*', '', resposta).strip()

def send_command_to_esp32(cmd: str, ip: str = None) -> str:
    """Envia um comando TCP para o ESP32 e retorna a resposta."""
    if ip is None:
        ip = ESP32_DEFAULT_IP
    
    # Validar o formato do IP
    ip_pattern = r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$'
    if not re.match(ip_pattern, ip):
        error_msg = f"Endereço IP inválido: {ip}"
        logger.error(error_msg)
        return error_msg
    
    # Verificar se os octetos estão dentro do intervalo válido (0-255)
    octetos = ip.split('.')
    if any(not (0 <= int(octeto) <= 255) for octeto in octetos):
        error_msg = f"Endereço IP com valores fora do intervalo válido: {ip}"
        logger.error(error_msg)
        return error_msg
        
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as esp_socket:
            esp_socket.settimeout(5.0)  # Timeout de 5 segundos
            esp_socket.connect((ip, ESP32_TCP_PORT))
            
            cmd_formatted = cmd.lower().strip()
            if not cmd_formatted.endswith('\n'):
                cmd_formatted += '\n'
                
            esp_socket.sendall(cmd_formatted.encode('utf-8'))
            resp = esp_socket.recv(1024).decode('utf-8').strip()
            return resp
    except socket.timeout:
        logger.error(f"Timeout ao conectar com ESP32 em {ip}")
        return "Erro: Timeout na conexão com o ESP32"
    except ConnectionRefusedError:
        logger.error(f"Conexão recusada pelo ESP32 em {ip}")
        return "Erro: ESP32 recusou a conexão"
    except Exception as e:
        logger.error(f"Erro ao enviar comando para ESP32 em {ip}: {e}")
        return f"Erro ao enviar comando para ESP32: {e}"

def format_position(pos: str) -> str:
    """Formata uma string de posição para o formato esperado pelo ESP32."""
    try:
        partes = pos.split()
        if len(partes) != 2:
            return pos.replace(" ", "")
            
        f_part, s_part = partes
        if s_part.startswith("s"):
            num = s_part[1:]
            if len(num) == 1:
                s_part = "s" + num.zfill(2)
                
        return f_part + s_part
    except Exception as e:
        logger.error(f"Erro na formatação da posição: {e}")
        return pos.replace(" ", "")

def send_text_to_client(conexao: socket.socket, text: str) -> None:
    """Envia texto para o cliente com o formato adequado."""
    try:
        data = text.encode('utf-8')
        conexao.sendall(f"{len(data):010d}".encode('utf-8') + data)
    except Exception as e:
        logger.error(f"Erro ao enviar texto para o cliente: {e}")

# ── Funções de manipulação de requisições ────────────────────────────────────
def is_latin_text(text: str) -> bool:
    """Verifica se o texto contém apenas caracteres do alfabeto latino e pontuação comum."""
    # Regex para caracteres latinos, números, pontuações comuns e espaços
    latin_pattern = r'^[a-zA-ZáàâãéèêíìîóòôõúùûçÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇ0-9\s\.,;:!?\-_\'"\(\)\[\]{}]+$'
    return bool(re.match(latin_pattern, text))

def sanitize_portuguese_text(text: str) -> str:
    """Remove caracteres não-latinos do texto e corrige palavras em inglês para português."""
    # Lista de caracteres permitidos (latinos + pontuação + números)
    allowed_chars = set('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
                        'áàâãéèêíìîóòôõúùûçÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇ'
                        '0123456789 ,.;:!?-_\'"`´()[]{}')
    
    # Filtra apenas caracteres permitidos
    sanitized = ''.join(c for c in text if c in allowed_chars)
    
    # Remove múltiplos espaços consecutivos
    sanitized = re.sub(r'\s+', ' ', sanitized).strip()
    
    # Dicionário de correções inglês para português (palavras comuns)
    english_to_portuguese = {
        "measure": "mede",
        "measures": "mede",
        "measured": "mediu",
        "measuring": "medindo",
        "the": "o",
        "temperature": "temperatura",
        "energy": "energia",
        "system": "sistema",
        "example": "exemplo",
        "and": "e",
        "is": "é",
        "are": "são",
        "was": "foi",
        "were": "foram",
        "in": "em",
        "on": "em",
        "at": "em",
        "of": "de",
        "from": "de",
        "to": "para",
        "for": "para",
        "with": "com",
        "without": "sem",
        "because": "porque",
        "but": "mas",
        "about": "sobre",
        "between": "entre",
        "through": "através",
        "during": "durante",
        "before": "antes",
        "after": "depois",
        "under": "sob",
        "over": "sobre",
        "since": "desde",
        "until": "até",
        "like": "como",
        "as": "como",
        "if": "se",
        "then": "então",
        "also": "também",
        "too": "também",
        "very": "muito",
        "much": "muito",
        "many": "muitos",
        "more": "mais",
        "less": "menos",
        "most": "maior",
        "least": "menor"
    }
    
    # Substitui palavras em inglês por suas equivalentes em português
    words = sanitized.split()
    for i, word in enumerate(words):
        word_lower = word.lower()
        # Remove pontuação para verificar a palavra
        clean_word = re.sub(r'[^\w]', '', word_lower)
        
        if clean_word in english_to_portuguese:
            # Substitui mantendo a capitalização original
            replacement = english_to_portuguese[clean_word]
            
            # Preserva a pontuação final
            punctuation = re.search(r'([^\w]+)$', word)
            if punctuation:
                replacement += punctuation.group(1)
                
            # Preserva a capitalização
            if word[0].isupper():
                replacement = replacement.capitalize()
                
            words[i] = replacement
    
    return ' '.join(words)

def validate_portuguese_content(text: str) -> Tuple[bool, str]:
    """
    Valida se o texto está em português e tenta corrigir palavras em inglês.
    Retorna uma tupla (é_válido, texto_corrigido).
    """
    # Primeiro sanitiza o texto
    sanitized = sanitize_portuguese_text(text)
    
    # Lista de palavras comuns em inglês que não devem aparecer em texto português
    common_english_words = {
        "the", "an", "and", "or", "but", "if", "then", "so", "because",
        "this", "that", "these", "those", "it", "they", "we", "you", "he", "she",
        "what", "where", "when", "who", "why", "how", "which", "there",
        "here", "now", "then", "today", "tomorrow", "yesterday"
    }
    
    # Verifica se há palavras inglesas isoladas
    words = re.findall(r'\b\w+\b', sanitized.lower())
    english_word_count = sum(1 for word in words if word in common_english_words)
    
    # Se mais de 10% das palavras parecem ser inglesas, o texto pode estar comprometido
    if len(words) > 0 and english_word_count / len(words) > 0.1:
        return False, sanitized
    
    return True, sanitized

def IAGen_resposta(id: str, pergunta: str, conexao: socket.socket, 
                   voice_file: str = "voz/Teca_v2.wav", voice: str = "Teca") -> None:
    """Gera uma resposta para a pergunta usando IA e a envia ao cliente."""
    try:
        # Detecta o nível Bloom para adaptar a resposta
        nivel = detectar_nivel_bloom(pergunta)
        logger.info(f"Pergunta: '{pergunta}' — nível Bloom: '{nivel}'")

        # Verifica no cache - usando hash que inclui a pergunta, voz e nível Bloom
        key = hashlib.md5(f"{pergunta.lower()}:{voice.lower()}:{nivel}".encode('utf-8')).hexdigest()
        resposta_raw = cache.get(key)
        
        if not resposta_raw:
            # Envia a pergunta com contexto do nível Bloom para a IA, mas interno
            prompt_ia = f"Responda esta pergunta no estilo '{nivel}' da taxonomia de Bloom: {pergunta}"
            resposta_raw = IAGen.responderIA(prompt_ia, voice=voice, nivel_bloom=nivel)
            if resposta_raw:
                cache.set(key, resposta_raw)
        
        if resposta_raw:
            # Limpamos o texto para garantir que não tenha prefixos
            resposta_text = clean_resposta_text(resposta_raw).strip()
            
            # Verifica se ainda contém menções indesejadas à taxonomia
            unwanted_phrases = [
                "estou no nível", 
                "taxonomia de bloom",
                "quer que eu aprofunde",
                "quer saber mais"
            ]
            
            # Remove frases indesejadas com melhor tratamento de contexto
            for phrase in unwanted_phrases:
                resposta_text = re.sub(f"(?i)[^.]*{phrase}[^.]*\\.", "", resposta_text)
            
            # Verifica se texto contém caracteres não-latinos ou palavras em inglês
            if not is_latin_text(resposta_text):
                logger.warning(f"Texto não-latino detectado na resposta: '{resposta_text}'")
                is_valid, resposta_text = validate_portuguese_content(resposta_text)
                logger.info(f"Texto sanitizado: '{resposta_text}'")
                
                # Se a validação indicar problemas ou o texto for muito curto, regenera
                if not is_valid or len(resposta_text) < len(pergunta) / 2:
                    logger.warning("Conteúdo em inglês detectado ou texto sanitizado muito curto. Regenerando resposta.")
                    # Remove do cache para forçar regeneração
                    cache.set(key, None)
                    # Tenta regenerar com um prompt mais específico
                    prompt_ia = f"Responda esta pergunta no estilo '{nivel}' da taxonomia de Bloom ESTRITAMENTE EM PORTUGUÊS. Não use nenhuma palavra em inglês ou outros idiomas: {pergunta}"
                    resposta_raw = IAGen.responderIA(prompt_ia, voice=voice, nivel_bloom=nivel)
                    if resposta_raw:
                        resposta_text = clean_resposta_text(resposta_raw).strip()
                        _, resposta_text = validate_portuguese_content(resposta_text)
            else:
                # Mesmo para texto que parece latino, verifica e corrige palavras em inglês
                _, resposta_text = validate_portuguese_content(resposta_text)
            
            # Envia texto diretamente sem prefácios
            send_text_to_client(conexao, resposta_text)

            # Gera e envia áudio
            AudioGen.gen_voz(id, conexao, resposta_text, speaker_wav=voice_file)
        else:
            error_msg = "Não foi possível gerar uma resposta."
            logger.error(error_msg)
            send_text_to_client(conexao, error_msg)
    except Exception as e:
        error_msg = f"Erro ao gerar resposta: {e}"
        logger.error(error_msg)
        send_text_to_client(conexao, error_msg)

def Item_ID(id: str, item: str, conexao: socket.socket) -> None:
    """Verifica um item e envia informações de áudio."""
    try:
        conexao.sendall(f"{0:010d}".encode('utf-8'))
        AudioSend.send_audio(conexao, itens.verificar_item(item))
    except Exception as e:
        error_msg = f"Erro ao processar item: {e}"
        logger.error(error_msg)
        send_text_to_client(conexao, error_msg)

def localizar_item(id: str, item: str, conexao: socket.socket) -> None:
    """Localiza um item no banco de dados e envia comandos para o ESP32 para acender LEDs."""
    try:
        details = get_item_details(item)
        if details is None:
            msg = "Item não encontrado no banco de dados."
            send_text_to_client(conexao, msg)
            return
            
        pos, esp_ip = details
        pos_fmt = format_position(pos)
        
        msg = "Comando LED enviado para ESP32 com sucesso."
        send_text_to_client(conexao, msg)
        
        # Envia comando para desligar LEDs e acender novo LED de forma assíncrona
        def executar_comandos_led():
            try:
                # Desliga LEDs anteriores
                send_command_to_esp32("off", ip=esp_ip)
                time.sleep(0.2)
                # Acende novo LED
                led_cmd = f"{pos_fmt} verde"
                send_command_to_esp32(led_cmd, ip=esp_ip)
            except Exception as e:
                logger.error(f"Erro na execução assíncrona de comandos LED: {e}")
        
        thread_pool.submit(executar_comandos_led)
    except Exception as e:
        error_msg = f"Erro ao localizar item: {e}"
        logger.error(error_msg)
        send_text_to_client(conexao, error_msg)

def comando(id: str, parametro: str, conexao: socket.socket) -> None:
    """Processa comandos específicos."""
    try:
        if parametro.lower() in ["tecaon", "tecaoff", "off"]:
            msg = "Comando LED controlado pelo cliente."
            send_text_to_client(conexao, msg)
        else:
            try:
                comandos.verificar_comando(id, parametro, conexao)
            except Exception as e:
                error_msg = f"Erro no comando: {e}"
                logger.error(error_msg)
                send_text_to_client(conexao, error_msg)
    except Exception as e:
        error_msg = f"Erro ao processar comando: {e}"
        logger.error(error_msg)
        send_text_to_client(conexao, error_msg)

# Dicionário de funções disponíveis
FUNCOES_DISPONIVEIS = {
    "responda": IAGen_resposta,
    "IA_item": Item_ID,
    "localizar": localizar_item,
    "comando": comando
}

def responder_conexao(conexao: socket.socket, endereco: Tuple[str, int]) -> None:
    """Manipula uma conexão cliente, processando requisições e enviando respostas."""
    logger.info(f"Conexão estabelecida com {endereco}")
    conexao.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
    
    try:
        # Recebe dados JSON do cliente com tamanho máximo
        buffer_size = 8192  # Limitar a 8KB
        dados = conexao.recv(buffer_size).decode('utf-8').strip()
        
        # Verificar tamanho dos dados recebidos
        if len(dados) >= buffer_size:
            send_text_to_client(conexao, "Erro: Payload muito grande")
            logger.warning(f"Payload muito grande recebido de {endereco}")
            return
            
        dados_json = json.loads(dados)
        
        # Extrai valores do JSON
        id = dados_json['ID']
        funcao = dados_json.get("funcao")
        parametro = dados_json.get("parametro", "")
        
        # Verificar tamanho dos parâmetros individuais
        if len(id) > 100 or len(str(funcao)) > 50 or len(str(parametro)) > 2000:
            send_text_to_client(conexao, "Erro: Parâmetros com tamanho excedido")
            logger.warning(f"Parâmetros com tamanho excedido de {endereco}")
            return

        if funcao == "responda":
            voice = dados_json.get("voice", "Teca")
            # Validar o parâmetro voice
            if not re.match(r'^[a-zA-Z0-9_-]{1,50}$', voice):
                send_text_to_client(conexao, "Erro: Parâmetro voice inválido")
                return
                
            voice_file = f"voz/{voice}.wav"
            IAGen_resposta(id, parametro, conexao, voice_file=voice_file, voice=voice)
        elif funcao in FUNCOES_DISPONIVEIS:
            FUNCOES_DISPONIVEIS[funcao](id, parametro, conexao)
        else:
            send_text_to_client(conexao, "Função não reconhecida")

    except json.JSONDecodeError:
        logger.error(f"Erro ao decodificar JSON de {endereco}")
        send_text_to_client(conexao, "Erro: Formato JSON inválido")
    except KeyError as e:
        logger.error(f"Campo obrigatório ausente na requisição de {endereco}: {e}")
        send_text_to_client(conexao, f"Erro: Campo obrigatório ausente: {e}")
    except Exception as e:
        logger.error(f"Erro processando conexão de {endereco}: {e}")
        try:
            send_text_to_client(conexao, f"Erro interno do servidor: {e}")
        except:
            pass
    finally:
        conexao.close()
        logger.info(f"Conexão com {endereco} encerrada.")

def iniciar_limpeza_periodica():
    """Inicia a limpeza periódica de histórico e cache."""
    # Limpeza de histórico
    thread_pool.submit(historico_cleaner.limpar_historico_a_cada_hora)
    
    # Limpeza do cache a cada dia
    def limpar_cache_periodicamente():
        while True:
            try:
                count = cache.cleanup_old_entries(30)  # 30 dias
                logger.info(f"Limpeza de cache: {count} entradas removidas")
            except Exception as e:
                logger.error(f"Erro na limpeza do cache: {e}")
            time.sleep(24 * 60 * 60)  # 24 horas
    
    # Monitoramento do pool de threads a cada minuto
    def monitorar_pool_threads():
        while True:
            try:
                # Números de threads ativos e tarefas pendentes
                active_threads = threading.active_count()
                pending_tasks = thread_pool._work_queue.qsize()
                
                # Registra métricas
                logger.info(f"Monitoramento de threads: {active_threads} threads ativos, {pending_tasks} tarefas pendentes")
                
                # Alerta se estiver próximo da capacidade máxima
                if pending_tasks > MAX_THREADS * 0.8:
                    logger.warning(f"ALERTA: Pool de threads com alta carga ({pending_tasks} tarefas pendentes)")
            except Exception as e:
                logger.error(f"Erro no monitoramento do pool de threads: {e}")
            time.sleep(60)  # 1 minuto
            
    thread_pool.submit(limpar_cache_periodicamente)
    thread_pool.submit(monitorar_pool_threads)

def servidor_tcp(host: str, porta: int) -> None:
    """Inicia o servidor TCP para receber conexões."""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as servidor:
            servidor.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            servidor.bind((host, porta))
            servidor.listen(10)  # Aumenta o backlog para 10 conexões
            
            logger.info(f"Servidor escutando em {host}:{porta}...")
            print(f"Servidor escutando em {host}:{porta}...")
            
            # Inicia limpeza periódica
            iniciar_limpeza_periodica()
            
            while True:
                try:
                    conexao, endereco = servidor.accept()
                    print(f"Conexão recebida de {endereco}")
                    
                    # Usa o pool de threads para manipular a conexão
                    thread_pool.submit(responder_conexao, conexao, endereco)
                except Exception as e:
                    logger.error(f"Erro ao aceitar conexão: {e}")
    except Exception as e:
        logger.critical(f"Erro fatal no servidor: {e}")
        print(f"Erro fatal: {e}")
    finally:
        # Cleanup
        thread_pool.shutdown(wait=False)
        logger.info("Servidor encerrado.")

if __name__ == "__main__":
    try:
        servidor_tcp(HOST, PORT)
    except KeyboardInterrupt:
        print("\nServidor encerrado pelo usuário.")
        thread_pool.shutdown(wait=False)
    except Exception as e:
        print(f"Erro ao iniciar servidor: {e}")
        logger.critical(f"Erro ao iniciar servidor: {e}")

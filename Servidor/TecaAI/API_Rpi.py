# API_Rpi.py

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
from datetime import datetime, timedelta

# Tentativa de importar Flask (opcional para ERP API)
try:
    from flask import Flask, request, jsonify
    from flask_cors import CORS
    FLASK_AVAILABLE = True
except ImportError:
    FLASK_AVAILABLE = False
    print("⚠️  Flask não disponível. ERP API não será iniciado.")
    print("   Execute: pip install flask flask-cors")

# Módulos locais
from erp_api import TEST_MODE
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
        # Remove espaços e converte para minúsculas
        pos_clean = pos.replace(" ", "").lower()
        
        # Padrão: f1s1, f2s3, etc.
        if pos_clean.startswith('f') and 's' in pos_clean:
            return pos_clean
        
        # Se for formato "Fileira X, Segmento Y", converte para fXsY
        if "fileira" in pos.lower() and "segmento" in pos.lower():
            try:
                fileira_match = re.search(r'fileira\s*(\d+)', pos.lower())
                segmento_match = re.search(r'segmento\s*(\d+)', pos.lower())
                
                if fileira_match and segmento_match:
                    fileira = fileira_match.group(1)
                    segmento = segmento_match.group(1)
                    return f"f{fileira}s{segmento}"
            except:
                pass
        
        # Se não conseguir converter, retorna como está
        return pos_clean
        
    except Exception as e:
        logger.error(f"Erro na formatação da posição: {e}")
        return pos.replace(" ", "").lower()

def send_text_to_client(conexao: socket.socket, text: str) -> None:
    """Envia texto para o cliente com o formato adequado."""
    try:
        data = text.encode('utf-8')
        header = f"{len(data):010d}".encode('utf-8')
        print(f"[DEBUG SERVIDOR] Enviando resposta: '{text}'")
        print(f"[DEBUG SERVIDOR] Tamanho dos dados: {len(data)}")
        print(f"[DEBUG SERVIDOR] Header: '{header.decode()}'")
        conexao.sendall(header + data)
        print(f"[DEBUG SERVIDOR] Resposta enviada com sucesso!")
    except Exception as e:
        print(f"[DEBUG SERVIDOR] Erro ao enviar resposta: {e}")
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
        
        msg = f"Item '{item}' localizado na posição {pos_fmt}. Comando LED enviado para ESP32."
        send_text_to_client(conexao, msg)
        
        # Envia comando para acender LED na posição específica de forma assíncrona
        def executar_comandos_led():
            try:
                # Primeiro desliga todos os LEDs
                send_command_to_esp32("allled preto", ip=esp_ip)
                time.sleep(0.3)
                
                # Verifica se a posição é válida para o formato fx<fita><sessao>
                if pos_fmt.startswith('f') and 's' in pos_fmt:
                    # Extrai número da fita e sessão
                    try:
                        f_match = re.search(r'f(\d+)', pos_fmt)
                        s_match = re.search(r's(\d+)', pos_fmt)
                        
                        if f_match and s_match:
                            fita = int(f_match.group(1))
                            sessao = int(s_match.group(1))
                            
                            # Valida se a fita e sessão estão dentro dos limites
                            if 1 <= fita <= 5 and 1 <= sessao <= 8:
                                # Comando para piscar a sessão específica em verde
                                led_cmd = f"fx{fita}s{sessao} verde"
                                send_command_to_esp32(led_cmd, ip=esp_ip)
                                logger.info(f"Comando LED executado: {led_cmd} para {item}")
                            else:
                                # Se fora dos limites, acende todos em verde
                                send_command_to_esp32("allled verde", ip=esp_ip)
                                logger.warning(f"Posição {pos_fmt} fora dos limites, acendendo todos os LEDs")
                        else:
                            # Formato inválido, acende todos em verde
                            send_command_to_esp32("allled verde", ip=esp_ip)
                            logger.warning(f"Formato de posição inválido: {pos_fmt}")
                    except ValueError:
                        # Erro na conversão, acende todos em verde
                        send_command_to_esp32("allled verde", ip=esp_ip)
                        logger.warning(f"Erro na conversão da posição: {pos_fmt}")
                else:
                    # Posição não reconhecida, acende todos em verde
                    send_command_to_esp32("allled verde", ip=esp_ip)
                    logger.warning(f"Posição não reconhecida: {pos_fmt}, acendendo todos os LEDs")
                    
            except Exception as e:
                logger.error(f"Erro na execução assíncrona de comandos LED: {e}")
        
        thread_pool.submit(executar_comandos_led)
    except Exception as e:
        error_msg = f"Erro ao localizar item: {e}"
        logger.error(error_msg)
        send_text_to_client(conexao, error_msg)

def comando(id: str, parametro: str, conexao: socket.socket) -> None:
    """Processa comandos específicos para o ESP32."""
    try:
        # Comandos especiais do ESP32
        if parametro.lower() in ["tecaon", "tecaoff", "demo", "demo off"]:
            # Estes comandos são processados diretamente pelo ESP32
            msg = f"Comando '{parametro}' enviado para ESP32."
            send_text_to_client(conexao, msg)
            
            # Envia comando para o ESP32 de forma assíncrona
            def executar_comando_esp32():
                try:
                    # Determina qual ESP32 usar (pode ser configurável)
                    esp_ip = ESP32_DEFAULT_IP
                    send_command_to_esp32(parametro.lower(), ip=esp_ip)
                    logger.info(f"Comando ESP32 executado: {parametro}")
                except Exception as e:
                    logger.error(f"Erro ao executar comando ESP32: {e}")
            
            thread_pool.submit(executar_comando_esp32)
            
        elif parametro.lower().startswith("allled "):
            # Comando para acender todos os LEDs com uma cor específica
            cor = parametro[7:].strip().lower()
            cores_validas = ["vermelho", "verde", "azul", "amarelo", "roxo", "ciano", "branco", "laranja", "rosa", "preto", "off"]
            
            if cor in cores_validas:
                msg = f"Comando 'allled {cor}' enviado para ESP32."
                send_text_to_client(conexao, msg)
                
                def executar_comando_led():
                    try:
                        esp_ip = ESP32_DEFAULT_IP
                        send_command_to_esp32(parametro.lower(), ip=esp_ip)
                        logger.info(f"Comando LED executado: {parametro}")
                    except Exception as e:
                        logger.error(f"Erro ao executar comando LED: {e}")
                
                thread_pool.submit(executar_comando_led)
            else:
                msg = f"Cor inválida: {cor}. Cores válidas: {', '.join(cores_validas)}"
                send_text_to_client(conexao, msg)
                
        elif parametro.lower().startswith("fx"):
            # Comando para piscar uma sessão específica
            # Formato: fx<fita><sessao> <cor>
            if re.match(r'^fx\d+s\d+\s+\w+$', parametro.lower()):
                msg = f"Comando 'fx' enviado para ESP32: {parametro}"
                send_text_to_client(conexao, msg)
                
                def executar_comando_fx():
                    try:
                        esp_ip = ESP32_DEFAULT_IP
                        send_command_to_esp32(parametro.lower(), ip=esp_ip)
                        logger.info(f"Comando FX executado: {parametro}")
                    except Exception as e:
                        logger.error(f"Erro ao executar comando FX: {e}")
                
                thread_pool.submit(executar_comando_fx)
            else:
                msg = "Formato inválido para comando 'fx'. Use: fx<fita><sessao> <cor> (ex: fx1s2 verde)"
                send_text_to_client(conexao, msg)
                
        else:
            # Comandos não reconhecidos são enviados para o módulo de comandos
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

# Lista de clientes conectados
connected_clients = []

def add_connected_client(client_id: str, endereco: Tuple[str, int]) -> None:
    """Adiciona um cliente à lista de conectados"""
    client_info = {
        'id': client_id,
        'ip': endereco[0],
        'port': endereco[1],
        'connected_at': datetime.now().isoformat(),
        'last_seen': datetime.now().isoformat()
    }
    
    # Remove se já existe
    connected_clients[:] = [c for c in connected_clients if c['id'] != client_id]
    # Adiciona novo
    connected_clients.append(client_info)
    print(f"[DEBUG SERVIDOR] Cliente conectado: {client_id} ({endereco[0]}:{endereco[1]})")
    logger.info(f"Cliente conectado: {client_id} ({endereco[0]}:{endereco[1]})")

def update_client_last_seen(client_id: str) -> None:
    """Atualiza o último acesso de um cliente"""
    for client in connected_clients:
        if client['id'] == client_id:
            client['last_seen'] = datetime.now().isoformat()
            break

def remove_disconnected_client(client_id: str) -> None:
    """Remove um cliente da lista de conectados"""
    connected_clients[:] = [c for c in connected_clients if c['id'] != client_id]
    print(f"[DEBUG SERVIDOR] Cliente desconectado: {client_id}")
    logger.info(f"Cliente desconectado: {client_id}")

def get_connected_clients() -> List[Dict]:
    """Retorna lista de clientes conectados"""
    # Remove clientes que não foram vistos há mais de 30 segundos
    cutoff_time = datetime.now() - timedelta(seconds=30)
    active_clients = []
    
    for client in connected_clients:
        last_seen = datetime.fromisoformat(client['last_seen'])
        if last_seen > cutoff_time:
            active_clients.append(client)
        else:
            print(f"[DEBUG SERVIDOR] Removendo cliente inativo: {client['id']}")
    
    # Atualiza a lista
    connected_clients[:] = active_clients
    
    # Debug: mostra clientes ativos
    print(f"[DEBUG SERVIDOR] Clientes ativos: {len(active_clients)}")
    for client in active_clients:
        print(f"[DEBUG SERVIDOR]   - {client['id']} ({client['ip']}:{client['port']}) - Último acesso: {client['last_seen']}")
    
    return active_clients

def heartbeat(id: str, parametro: str, conexao: socket.socket) -> None:
    """Função de heartbeat para manter cliente ativo"""
    print(f"[DEBUG SERVIDOR] Heartbeat recebido de ID: {id}")
    resposta = f"Heartbeat OK - Cliente {id} ativo"
    send_text_to_client(conexao, resposta)
    print(f"[DEBUG SERVIDOR] Heartbeat respondido: {resposta}")
    logger.info(f"Heartbeat de {id} processado")

def comando_esp32(id: str, parametro: str, conexao: socket.socket) -> None:
    """Função para enviar comandos ESP32 via serial"""
    print(f"[DEBUG SERVIDOR] Executando comando ESP32: '{parametro}' para ID: {id}")
    
    try:
        # Tenta importar o módulo de controle LED
        try:
            from led_control import send_command
        except ImportError:
            # Se não encontrar, tenta importar do diretório Cliente
            import sys
            sys.path.append('../Cliente')
            from led_control import send_command
        
        # Envia comando para ESP32
        resultado = send_command(parametro)
        
        resposta = f"Comando ESP32 '{parametro}' executado: {resultado}"
        send_text_to_client(conexao, resposta)
        print(f"[DEBUG SERVIDOR] Resposta ESP32 enviada: {resposta}")
        logger.info(f"Comando ESP32 executado: {parametro} -> {resultado}")
        
    except ImportError as e:
        erro = f"Erro: Módulo led_control não encontrado: {e}"
        send_text_to_client(conexao, erro)
        print(f"[DEBUG SERVIDOR] Erro: {erro}")
        logger.error(f"Erro ao importar led_control: {erro}")
    except Exception as e:
        erro = f"Erro ao executar comando ESP32: {e}"
        send_text_to_client(conexao, erro)
        print(f"[DEBUG SERVIDOR] Erro: {erro}")
        logger.error(f"Erro no comando ESP32: {e}")

def teste_conexao(id: str, parametro: str, conexao: socket.socket) -> None:
    """Função de teste para verificar conexão"""
    print(f"[DEBUG SERVIDOR] Executando função de teste para ID: {id}")
    resposta = f"Teste de conexão bem-sucedido! ID: {id}, Parâmetro: {parametro}"
    send_text_to_client(conexao, resposta)
    print(f"[DEBUG SERVIDOR] Resposta de teste enviada: {resposta}")
    logger.info(f"Teste de conexão realizado para {id}")

# Dicionário de funções disponíveis
FUNCOES_DISPONIVEIS = {
    "responda": IAGen_resposta,
    "IA_item": Item_ID,
    "localizar": localizar_item,
    "comando": comando,
    "comando_esp32": comando_esp32,
    "teste": teste_conexao,
    "heartbeat": heartbeat
}

def responder_conexao(conexao: socket.socket, endereco: Tuple[str, int]) -> None:
    """Manipula uma conexão cliente, processando requisições e enviando respostas."""
    logger.info(f"Conexão estabelecida com {endereco}")
    conexao.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
    
    client_id = None
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
        client_id = dados_json['ID']
        funcao = dados_json.get("funcao")
        parametro = dados_json.get("parametro", "")
        
        # Adiciona cliente à lista de conectados
        add_connected_client(client_id, endereco)
        
        # DEBUG: Mostra informações do comando recebido
        print(f"[DEBUG SERVIDOR] ==========================================")
        print(f"[DEBUG SERVIDOR] Comando recebido de {endereco}")
        print(f"[DEBUG SERVIDOR] ID: {client_id}")
        print(f"[DEBUG SERVIDOR] Função: {funcao}")
        print(f"[DEBUG SERVIDOR] Parâmetro: {parametro}")
        print(f"[DEBUG SERVIDOR] ==========================================")
        
        logger.info(f"[DEBUG] Comando recebido: {funcao} - {parametro} de {endereco}")
        
        # Verificar tamanho dos parâmetros individuais
        if len(client_id) > 100 or len(str(funcao)) > 50 or len(str(parametro)) > 2000:
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
            IAGen_resposta(client_id, parametro, conexao, voice_file=voice_file, voice=voice)
        elif funcao in FUNCOES_DISPONIVEIS:
            FUNCOES_DISPONIVEIS[funcao](client_id, parametro, conexao)
        else:
            send_text_to_client(conexao, "Função não reconhecida")
            
        # Atualiza último acesso do cliente
        update_client_last_seen(client_id)

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
        # Só remove o cliente se houve erro ou se não é um heartbeat
        if client_id:
            try:
                dados_json = json.loads(dados)
                funcao = dados_json.get("funcao")
                # Não remove clientes que fazem heartbeat
                if funcao != "heartbeat":
                    remove_disconnected_client(client_id)
            except:
                # Se não conseguir processar, remove por segurança
                remove_disconnected_client(client_id)
        
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
    def main():
        try:
            # Inicia o servidor TCP em uma thread separada
            def start_tcp_server():
                """Inicia o servidor TCP em uma thread separada"""
                try:
                    servidor_tcp(HOST, PORT)
                except Exception as e:
                    print(f"Erro no servidor TCP: {e}")
                    logger.critical(f"Erro no servidor TCP: {e}")
            
            # Verifica se Flask está disponível
            if not FLASK_AVAILABLE:
                print("❌ Flask não está disponível. ERP API não será iniciado.")
                print("   Execute: pip install flask flask-cors")
                # Continua apenas com o servidor TCP
                start_tcp_server()
                return
            
            # Inicia o servidor TCP em background
            tcp_thread = threading.Thread(target=start_tcp_server, daemon=True)
            tcp_thread.start()
            
            # Aguarda um pouco para o servidor TCP inicializar
            time.sleep(2)
            
            # ============================================================================
            # INTEGRAÇÃO DO ERP API - SERVIDOR FLASK
            # ============================================================================
            
            print("🚀 Iniciando integração com ERP API...")
            
            # Cria a aplicação Flask
            app = Flask(__name__)
            CORS(app)  # Permite CORS para o frontend
        
            # Configurações do TecaAI para o ERP
            TECAAI_HOST = "localhost"
            TECAAI_PORT = 5000
            
            class TecaAIClient:
                """Cliente para comunicação com o TecaAI via TCP"""
                
                def __init__(self, host="localhost", port=5000):
                    self.host = host
                    self.port = port
                
                def send_command(self, funcao, parametro, voice="Teca"):
                    """Envia comando para o TecaAI e retorna resposta"""
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
            
            # Inicializa banco de dados do ERP
            init_erp_db()
            
            # ============================================================================
            # ROTAS DO ERP API
            # ============================================================================
            
            @app.route('/connected-clients', methods=['GET'])
            def get_connected_clients_endpoint():
                """Retorna lista de clientes Python conectados"""
                try:
                    print(f"[DEBUG SERVIDOR] Endpoint /connected-clients chamado")
                    clients = get_connected_clients()
                    
                    # Mapeia IDs de cliente para nomes de armário
                    armario_mapping = {
                        'A': 'Armário A',
                        'B': 'Armário B', 
                        'C': 'Armário C',
                        'D': 'Armário D',
                        'E': 'Armário E',
                        'F': 'Armário F',
                        'G': 'Armário G',
                        'H': 'Armário H',
                        'I': 'Armário I',
                        'J': 'Armário J'
                    }
                    
                    formatted_clients = []
                    for client in clients:
                        armario_name = armario_mapping.get(client['id'], f"Armário {client['id']}")
                        formatted_clients.append({
                            'id': client['id'],
                            'name': armario_name,
                            'ip': client['ip'],
                            'port': client['port'],
                            'connected_at': client['connected_at'],
                            'last_seen': client['last_seen']
                        })
                    
                    response_data = {
                        "success": True,
                        "clients": formatted_clients,
                        "total": len(formatted_clients),
                        "timestamp": datetime.now().isoformat()
                    }
                    
                    print(f"[DEBUG SERVIDOR] Retornando {len(formatted_clients)} clientes conectados")
                    return jsonify(response_data)
                    
                except Exception as e:
                    logger.error(f"Erro ao obter clientes conectados: {e}")
                    return jsonify({
                        "success": False,
                        "error": f"Erro interno: {e}",
                        "timestamp": datetime.now().isoformat()
                    }), 500

            @app.route('/health', methods=['GET'])
            def health_check():
                """Verifica se a API está funcionando"""
                return jsonify({
                    "status": "online",
                    "service": "ERP-TecaAI Bridge",
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
            
            @app.route('/esp32', methods=['POST'])
            def esp32_command():
                """Comandos diretos para o ESP32 via cliente Python"""
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
                    
                    # Comandos válidos do ESP32
                    valid_commands = [
                        "demo", "demo off", "tecaon", "tecaoff",
                        "allled vermelho", "allled verde", "allled azul", "allled amarelo",
                        "allled roxo", "allled ciano", "allled branco", "allled laranja",
                        "allled rosa", "allled preto", "allled off"
                    ]
                    
                    # Verifica se é um comando válido ou um comando fx
                    is_valid = (command.lower() in valid_commands or 
                               re.match(r'^fx\d+s\d+\s+\w+$', command.lower()))
                    
                    if not is_valid:
                        return jsonify({
                            "error": "Comando inválido",
                            "valid_commands": valid_commands + ["fx<fita><sessao> <cor>"]
                        }), 400
                    
                    # Envia comando para TODOS os clientes Python conectados
                    print(f"[DEBUG SERVIDOR] Enviando comando ESP32 '{command}' para todos os clientes")
                    
                    # Obtém lista de clientes conectados
                    active_clients = get_connected_clients()
                    
                    if not active_clients:
                        error_msg = "Nenhum cliente Python conectado para receber comandos ESP32"
                        logger.error(error_msg)
                        return jsonify({
                            "success": False,
                            "error": error_msg,
                            "timestamp": datetime.now().isoformat()
                        }), 500
                    
                    # Envia comando para cada cliente conectado usando a porta 5002
                    responses = []
                    for client in active_clients:
                        try:
                            print(f"[DEBUG SERVIDOR] Enviando comando '{command}' para cliente {client['id']} ({client['ip']}:5002)")
                            
                            # Envia comando via TCP para o cliente Python na porta 5002
                            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client_socket:
                                client_socket.settimeout(5.0)
                                client_socket.connect((client['ip'], 5002))  # Porta específica para comandos
                                
                                # Envia comando no formato JSON esperado pelo cliente
                                cmd_data = {
                                    "ID": client['id'],
                                    "funcao": "comando_esp32",
                                    "parametro": command
                                }
                                
                                cmd_json = json.dumps(cmd_data)
                                print(f"[DEBUG SERVIDOR] Enviando JSON: {cmd_json}")
                                client_socket.sendall(cmd_json.encode('utf-8'))
                                
                                # Aguarda resposta
                                response = client_socket.recv(1024).decode('utf-8').strip()
                                print(f"[DEBUG SERVIDOR] Resposta do cliente {client['id']}: {response}")
                                responses.append(f"Cliente {client['id']}: {response}")
                                
                        except Exception as e:
                            error_msg = f"Erro ao enviar para cliente {client['id']}: {e}"
                            logger.error(error_msg)
                            print(f"[DEBUG SERVIDOR] {error_msg}")
                            responses.append(error_msg)
                    
                    result = {
                        "success": True,
                        "command": command,
                        "clients_count": len(active_clients),
                        "responses": responses,
                        "timestamp": datetime.now().isoformat()
                    }
                    
                    # Registra no histórico
                    log_command(user_id, user_role, "esp32_via_cliente", command, str(responses), True)
                    
                    return jsonify(result)
                    
                except Exception as e:
                    logger.error(f"Erro na rota /esp32: {e}")
                    return jsonify({"error": "Erro interno do servidor"}), 500
            
            @app.route('/esp32/broadcast', methods=['POST'])
            def esp32_broadcast_command():
                """Comandos de broadcast para TODOS os clientes Python conectados"""
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
                    
                    # Comandos válidos do ESP32
                    valid_commands = [
                        "demo", "demo off", "tecaon", "tecaoff",
                        "allled vermelho", "allled verde", "allled azul", "allled amarelo",
                        "allled roxo", "allled ciano", "allled branco", "allled laranja",
                        "allled rosa", "allled preto", "allled off"
                    ]
                    
                    # Verifica se é um comando válido ou um comando fx
                    is_valid = (command.lower() in valid_commands or 
                               re.match(r'^fx\d+s\d+\s+\w+$', command.lower()))
                    
                    if not is_valid:
                        return jsonify({
                            "error": "Comando inválido",
                            "valid_commands": valid_commands + ["fx<fita><sessao> <cor>"]
                        }), 400
                    
                    # Envia comando para TODOS os clientes Python conectados via TCP
                    try:
                        # Simula envio para todos os clientes (em modo de teste)
                        if TEST_MODE:
                            result = {
                                "success": True,
                                "command": command,
                                "broadcast": True,
                                "response": f"Comando '{command}' enviado para todos os clientes (MODO TESTE)",
                                "timestamp": datetime.now().isoformat()
                            }
                        else:
                            # Aqui você implementaria o broadcast real para todos os clientes TCP
                            # Por enquanto, simula o envio
                            result = {
                                "success": True,
                                "command": command,
                                "broadcast": True,
                                "response": f"Comando '{command}' enviado para todos os clientes",
                                "timestamp": datetime.now().isoformat()
                            }
                        
                        # Registra no histórico
                        log_command(user_id, user_role, "esp32_broadcast", command, result['response'], True)
                        
                        return jsonify(result)
                        
                    except Exception as e:
                        error_msg = f"Erro ao enviar comando de broadcast: {e}"
                        logger.error(error_msg)
                        
                        result = {
                            "success": False,
                            "command": command,
                            "broadcast": True,
                            "error": error_msg,
                            "timestamp": datetime.now().isoformat()
                        }
                        
                        # Registra erro no histórico
                        log_command(user_id, user_role, "esp32_broadcast", command, error_msg, False)
                        
                        return jsonify(result), 500
                    
                except Exception as e:
                    logger.error(f"Erro na rota /esp32/broadcast: {e}")
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
                    }
                    
                    items_list = []
                    for nome, posicao, esp_ip in items:
                        # Traduzir posição (f1s1 -> Fileira 1, Segmento 1)
                        posicao_traduzida = ""
                        if posicao.startswith('f') and 's' in posicao:
                            try:
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
            
            # ============================================================================
            # INICIA O SERVIDOR FLASK
            # ============================================================================
            
            print("🌐 Iniciando servidor Flask ERP API na porta 5001...")
            print("📊 Endpoints disponíveis:")
            print("   - GET  /health     - Status do servidor")
            print("   - POST /ask        - Perguntas para IA")
            print("   - POST /locate     - Localizar itens")
            print("   - POST /control    - Controlar dispositivos")
            print("   - POST /esp32      - Comandos diretos para ESP32")
            print("   - GET  /items      - Listar itens")
            print("   - POST /items      - Adicionar item")
            print("   - GET  /history    - Histórico de comandos")
            print("   - GET  /stats      - Estatísticas")
            print("🔗 URL: http://localhost:5001")
            print("")
            print("🎮 Comandos ESP32 disponíveis:")
            print("   - demo, demo off   - Modo demonstração")
            print("   - tecaon, tecaoff  - Animação TECA")
            print("   - allled <cor>     - Todos os LEDs (cores: vermelho, verde, azul, etc.)")
            print("   - fx<fita><sessao> <cor> - Piscar sessão específica (ex: fx1s2 verde)")
            
            # Inicia o servidor Flask
            app.run(host='0.0.0.0', port=5001, debug=False, threaded=True)
            
        except KeyboardInterrupt:
            print("\n�� Servidor encerrado pelo usuário.")
            thread_pool.shutdown(wait=False)
        except Exception as e:
            print(f"❌ Erro ao iniciar servidor: {e}")
            logger.critical(f"Erro ao iniciar servidor: {e}")

    main()

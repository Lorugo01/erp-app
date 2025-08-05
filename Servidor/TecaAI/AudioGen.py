import os
import text_format
import API_Rpi
import AudioSend
import logging
from pydub import AudioSegment
from tts_model import tts
import time
import wave
import numpy as np

# Configuração de logging
logger = logging.getLogger(__name__)

# Função original de geração de voz em segmentos sequenciais
# Gera e envia cada sentença como um segmento de áudio separado

def gen_voz(id, conn, text, speaker_wav="voz/Teca_v2.wav", speed=1.0, temperature=0.65):
    """
    Gera e envia áudio para o texto fornecido.
    Processa o texto em sentenças para melhorar a fluidez da leitura.
    
    Args:
        id: Identificador do armário/cliente
        conn: Conexão de socket para envio
        text: Texto completo a ser convertido em áudio
        speaker_wav: Arquivo de voz de referência
        speed: Velocidade da fala (0.8-1.2, onde 1.0 = normal)
        temperature: Variação na síntese de voz (0.5-0.7 para melhor qualidade)
    """
    try:
        # Cria diretório para armazenar os segmentos de áudio
        directory = f"IA/segmentos/armario_{id}"
        os.makedirs(directory, exist_ok=True)
        
        # 1. Divisão do texto em segmentos naturais
        sentences = text_format.split_text_to_sentences(text)
        logger.info(f"Texto dividido em {len(sentences)} segmentos para síntese")
        
        # Lista para armazenar caminhos de arquivos de áudio gerados
        audio_paths = []
        
        # 2. Geração de áudio para cada segmento
        for i, sentence in enumerate(sentences):
            try:
                # Limpa e formata a sentença
                sentence_clean = text_format.clean_special_characters(sentence)
                if not sentence_clean.strip():
                    continue
                
                # Define nome do arquivo com timestamp para evitar colisões
                timestamp = int(time.time() * 1000)
                temp_audio_path = f"{directory}/segment_{i}_{timestamp}.wav"
                
                # Registra a sentença para depuração
                logger.info(f"Gerando áudio para segmento {i}: '{sentence_clean}'")
                
                # Configura a temperatura e velocidade ideais para melhor fluidez
                current_temp = temperature
                current_speed = speed
                
                # Ajusta parâmetros com base no tamanho da sentença
                if len(sentence_clean) < 60:
                    current_speed *= 0.95  # Mais lento para frases curtas
                
                # Gera áudio para a sentença
                tts.tts_to_file(
                    text=sentence_clean,
                    speaker_wav=speaker_wav,
                    language="pt",
                    file_path=temp_audio_path,
                    speed=current_speed,
                    temperature=current_temp
                )
                
                # 3. Verifica qualidade do áudio antes de enviar
                if verificar_qualidade_audio(temp_audio_path):
                    audio_paths.append(temp_audio_path)
                else:
                    # Tenta regenerar com menor temperatura (mais conservador)
                    logger.warning(f"Problemas detectados no áudio {i}, regenerando...")
                    
                    # Regenera com parâmetros mais conservadores
                    retry_temp = max(0.5, temperature - 0.1)
                    retry_path = f"{directory}/segment_{i}_{timestamp}_retry.wav"
                    
                    tts.tts_to_file(
                        text=sentence_clean,
                        speaker_wav=speaker_wav,
                        language="pt",
                        file_path=retry_path,
                        speed=speed,
                        temperature=retry_temp
                    )
                    
                    if verificar_qualidade_audio(retry_path):
                        audio_paths.append(retry_path)
                    else:
                        logger.error(f"Falha na regeneração do segmento {i}, ignorando.")
                        
            except Exception as e:
                logger.error(f"Erro ao processar segmento {i}: {e}")
        
        # 4. Envia os segmentos na ordem correta
        for audio_path in audio_paths:
            AudioSend.send_audio(conn, audio_path)
            
        logger.info(f"Síntese de voz concluída. {len(audio_paths)} segmentos enviados.")
        
        # Envia o cabeçalho de fim de transmissão
        conn.sendall(f"{0:010d}".encode('utf-8'))
        
    except Exception as e:
        logger.error(f"Erro na geração de áudio: {e}")
        # Garante o envio do cabeçalho de fim mesmo em caso de erro
        try:
            conn.sendall(f"{0:010d}".encode('utf-8'))
        except:
            pass

def verificar_qualidade_audio(audio_path):
    """
    Verifica a qualidade do arquivo de áudio gerado.
    Retorna True se o áudio parece normal, False se houver problemas.
    """
    try:
        # Verifica se o arquivo existe e tem tamanho
        if not os.path.exists(audio_path):
            return False
            
        file_size = os.path.getsize(audio_path)
        if file_size < 1000:  # Se for muito pequeno (menos de 1KB)
            logger.warning(f"Arquivo de áudio muito pequeno: {file_size} bytes")
            return False
            
        # Abre o arquivo para análise
        with wave.open(audio_path, 'rb') as wav:
            # Verifica duração
            frames = wav.getnframes()
            rate = wav.getframerate()
            duration = frames / float(rate)
            
            # Se for muito curto, pode ter problemas
            if duration < 0.1:  # Menos de 100ms
                logger.warning(f"Áudio muito curto: {duration:.2f}s")
                return False
                
            # Extrai dados de áudio para análise
            if frames > 0:
                return True  # Se chegou até aqui, áudio parece ok
                
        return False
    except Exception as e:
        logger.error(f"Erro ao verificar qualidade do áudio: {e}")
        return False
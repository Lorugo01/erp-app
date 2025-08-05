import re

def split_text_to_sentences(text):
    """
    Divide o texto em sentenças menores, garantindo que nenhuma sentença seja muito longa,
    mas preservando a estrutura linguística natural para melhorar a fluidez da leitura.
    """
    # Primeiro, processa o texto para normalizar espaços
    text = re.sub(r'\s+', ' ', text.strip())
    
    # Define os delimitadores em ordem de prioridade (ponto, exclamação, interrogação)
    # e depois vírgulas, ponto-e-vírgula, etc.
    primary_delimiters = r'(?<=[.!?])\s+'
    secondary_delimiters = r'(?<=[,;:])\s+'
    
    # Tamanho máximo recomendado (em caracteres) para uma sentença
    max_length = 170  # Reduzindo para garantir melhor pronúncia
    
    # Lista para armazenar as sentenças finais
    final_sentences = []
    
    # Primeiro divide por pontuações de fim de frase (., !, ?)
    segments = re.split(primary_delimiters, text)
    
    for segment in segments:
        # Se o segmento é curto o suficiente, mantém intacto
        if len(segment) <= max_length:
            if segment.strip():  # Ignora segmentos vazios
                final_sentences.append(segment)
            continue
        
        # Se é muito longo, divide por pontuações secundárias
        parts = re.split(secondary_delimiters, segment)
        
        # Buffer para acumular partes
        current_part = ""
        
        for part in parts:
            # Ignora partes vazias
            if not part.strip():
                continue
                
            # Se adicionar esta parte não exceder o limite
            if len(current_part) + len(part) + 1 <= max_length:
                if current_part:
                    current_part += ", " + part  # Adiciona vírgula para pausa natural
                else:
                    current_part = part
            else:
                # Adiciona a parte atual e inicia uma nova
                if current_part:
                    final_sentences.append(current_part)
                
                # Se a parte for muito longa, precisa dividir nas palavras
                if len(part) > max_length:
                    words = part.split()
                    chunk = ""
                    
                    for word in words:
                        if len(chunk) + len(word) + 1 <= max_length:
                            if chunk:
                                chunk += " " + word
                            else:
                                chunk = word
                        else:
                            final_sentences.append(chunk)
                            chunk = word
                    
                    # Não esquece da última parte
                    if chunk:
                        current_part = chunk
                    else:
                        current_part = ""
                else:
                    current_part = part
        
        # Adiciona a última parte se houver
        if current_part:
            final_sentences.append(current_part)
    
    # Faz um pós-processamento para garantir que nenhuma sentença seja muito curta
    # Combina sentenças muito curtas com a próxima sentença quando possível
    i = 0
    while i < len(final_sentences) - 1:
        current = final_sentences[i]
        next_sentence = final_sentences[i+1]
        
        # Se ambas são curtas, combina-as
        if len(current) < 40 and len(current) + len(next_sentence) + 2 <= max_length:
            final_sentences[i] = current + ". " + next_sentence
            final_sentences.pop(i+1)
        else:
            i += 1
    
    # Garante que cada sentença termina com um sinal de pontuação
    for i in range(len(final_sentences)):
        if not re.search(r'[.!?,;:]$', final_sentences[i]):
            final_sentences[i] += "."
    
    return final_sentences

def clean_special_characters(text):
    """
    Prepara o texto para síntese de voz, preservando pontuação essencial
    para melhor entonação e pausas naturais.
    """
    # Conserva alguns sinais de pontuação para entonação
    # Substitui ponto por vírgula para evitar pausas muito longas
    text = text.replace('.', ',')
    
    # Preserva vírgulas, dois pontos e ponto-e-vírgula para pausas naturais
    # Remove outros caracteres especiais
    cleaned_text = re.sub(r'[^\w\sÀ-ÿ,;:]', '', text)
    
    # Garante espaçamento correto após pontuação
    cleaned_text = re.sub(r'([,;:])\s*', r'\1 ', cleaned_text)
    
    # Remove espaços múltiplos
    cleaned_text = re.sub(r'\s+', ' ', cleaned_text).strip()
    
    return cleaned_text

import os
import sqlite3
import difflib

# Define o caminho da pasta e do arquivo de banco de dados
db_folder = "localizações"
if not os.path.exists(db_folder):
    os.makedirs(db_folder)

db_path = os.path.join(db_folder, "localizacoes.db")

def init_db():
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS itens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL UNIQUE,
            posicao TEXT NOT NULL,
            esp_ip TEXT NOT NULL
        )
    ''')
    conn.commit()
    conn.close()

def get_all_items():
    """Retorna todos os itens (nome, posição e esp_ip) do banco de dados."""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute("SELECT nome, posicao, esp_ip FROM itens")
    items = cursor.fetchall()
    conn.close()
    return items

def get_item_details(item_name, cutoff=0.7):
    """
    Procura pelo item no banco de dados usando comparação exata e, se não encontrar,
    utiliza similaridade fuzzy para encontrar a correspondência mais próxima.
    
    Retorna uma tupla (posicao, esp_ip) se encontrado, ou None caso contrário.
    """
    item_name = item_name.lower().strip()
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute("SELECT posicao, esp_ip FROM itens WHERE lower(nome) = ?", (item_name,))
    row = cursor.fetchone()
    if row:
        conn.close()
        return row  # (posicao, esp_ip)
    
    # Busca por similaridade
    cursor.execute("SELECT nome, posicao, esp_ip FROM itens")
    items = cursor.fetchall()
    conn.close()
    nomes = [nome for nome, pos, ip in items]
    best_matches = difflib.get_close_matches(item_name, nomes, n=1, cutoff=cutoff)
    if best_matches:
        best_match = best_matches[0]
        for nome, pos, ip in items:
            if nome.lower() == best_match.lower():
                return (pos, ip)
    return None

def add_item(nome, posicao, esp_ip):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    try:
        cursor.execute("INSERT INTO itens (nome, posicao, esp_ip) VALUES (?, ?, ?)", (nome, posicao, esp_ip))
        conn.commit()
    except sqlite3.IntegrityError:
        # Se o item já existir, atualiza 
        cursor.execute("UPDATE itens SET posicao = ?, esp_ip = ? WHERE nome = ?", (posicao, esp_ip, nome))
        conn.commit()
    conn.close()

# Inicializa o banco de dados
init_db()

# Insere dados de exemplo, se não existirem
if get_item_details("cilindro volumetrico") is None:
    add_item("cilindro volumetrico", "f1s1", "192.168.100.184")
if get_item_details("funil") is None:
    add_item("funil", "f1s2", "192.168.100.184")
if get_item_details("bequer") is None:
    add_item("bequer", "f1s3", "192.168.100.184")
if get_item_details("reagente") is None:
    add_item("reagente", "f1s4", "192.168.100.184")
if get_item_details("tubo de ensaio") is None:
    add_item("tubo de ensaio", "f2s1", "192.168.100.184")
if get_item_details("erlenmeyer") is None:
    add_item("erlenmeyer", "f2s2", "192.168.100.184")
if get_item_details("mini centrífuga") is None:
    add_item("mini centrífuga", "f3s1", "192.168.100.184")
if get_item_details("mini processador") is None:
    add_item("mini processador", "f3s2", "192.168.100.184")
if get_item_details("processador") is None:
    add_item("processador", "f3s3", "192.168.100.184")
if get_item_details("balança digital") is None:
    add_item("balança digital", "f3s4", "192.168.100.184")
if get_item_details("forno elétrico") is None:
    add_item("forno elétrico", "f3s5", "192.168.100.184")

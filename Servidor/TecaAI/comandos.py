import sqlite3

def criar_tabelas():
    conexao = sqlite3.connect('comandos.db')
    cursor = conexao.cursor()
    # Cria a tabela de comandos, caso ela não exista
    cursor.execute('''CREATE TABLE IF NOT EXISTS comandos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        comando TEXT NOT NULL,
        resposta TEXT NOT NULL,
        chave TEXT NOT NULL
    )''')
    conexao.commit()
    conexao.close()

def adicionar_comando(comando, resposta, chave):
    conexao = sqlite3.connect('comandos.db')
    cursor = conexao.cursor()
    # Verifica se o comando já existe
    cursor.execute("SELECT * FROM comandos WHERE comando = ?", (comando,))
    existente = cursor.fetchone()
    if existente:
        print("Comando já existe")
    else:
        # Insere o comando no banco de dados
        cursor.execute("INSERT INTO comandos (comando, resposta, chave) VALUES (?, ?, ?)", 
                      (comando, resposta, chave))
        conexao.commit()
    conexao.close()
    
def verificar_comando(comando):
    conexao = sqlite3.connect('comandos.db')
    cursor = conexao.cursor()
    # Consulta o banco para procurar o comando
    cursor.execute("SELECT chave FROM comandos WHERE comando = ?", (comando.lower(),))
    resultado = cursor.fetchone()
    conexao.close()
    # Se o comando foi encontrado, retorna a resposta
    if resultado:  
        resposta = resultado[0]  
        return resposta
    else:
        #play_audio("voz_presets/comando nao encontrado.wav")
        return "Comando não reconhecido."
    
    
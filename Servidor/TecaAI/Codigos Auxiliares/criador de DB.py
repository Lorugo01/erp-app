# PROGRAMA PARA CRIAR UM BANCO DE DADOS PARA ALOCAR O ENDEREÇO DOS AUDIOS CRIADOS (PRIMEIRO CRIE OS AUDIOS) 

import os
import sqlite3
import re
pasta_voz= "voz_itens/demonstrativo"
pasta_db="BD/Itens/demonstrativo.db"
def criar_banco(pasta):
    conexao = sqlite3.connect(pasta_db)
    cursor = conexao.cursor()
    
   
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS Itens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item TEXT NOT NULL,
            audio TEXT NOT NULL
        )
    """)
    conexao.commit()
    conexao.close()
    
def atualizar_tabela(pasta):
    conexao = sqlite3.connect(pasta_db)
    cursor = conexao.cursor()
    for arquivo in os.listdir(pasta):
        if arquivo.endswith(".wav"):
            titulo_arquivo= os.path.splitext(arquivo)[0]
            palavras= titulo_arquivo.split()
            item = " ".join(titulo_arquivo.split()[3:])
            caminho= os.path.join(pasta, arquivo)
            caminho=caminho.replace("\\","/")
            
            cursor.execute("INSERT INTO Itens (item,audio) VALUES (? ,?)", (item, caminho))
    conexao.commit()
    conexao.close()
criar_banco(pasta_voz)
atualizar_tabela(pasta_voz)

import sqlite3
import os

def verificar_item(item):
    pasta="BD/Itens"
    # Lista todos os arquivos .db na pasta especificada
    bancos = [f for f in os.listdir(pasta) if f.endswith('.db')]
    
    # Itera sobre cada banco de dados encontrado
    for banco in bancos:
        caminho_banco = os.path.join(pasta, banco)
        conexao = sqlite3.connect(caminho_banco)
        cursor = conexao.cursor()
        try:
            # Tenta buscar o item no banco atual
            cursor.execute("SELECT audio FROM Itens WHERE item = ?", (item,))
            resultado = cursor.fetchone()
            conexao.close()
            
            # Se encontrou o item, retorna o áudio
            if resultado:
                return resultado[0]  # ou return (resultado[0], banco) para saber de qual banco veio
        except sqlite3.Error as e:
            print(f"Erro ao acessar o banco {banco}: {e}")
            conexao.close()
            continue  # Vai para o próximo banco se houver erro

    # Se não encontrar em nenhum banco, retorna None
    return None

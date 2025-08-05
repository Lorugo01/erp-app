import sqlite3
import os

# Caminho para o banco de dados
db_path = os.path.join("localizações", "localizacoes.db")

def add_sample_items():
    """Adiciona 25 itens ilusórios ao banco de dados"""
    
    # Verificar se o banco existe
    if not os.path.exists(db_path):
        print(f"Banco de dados não encontrado em: {db_path}")
        return
    
    # Lista de itens ilusórios
    sample_items = [
        # Armário A (192.168.100.184)
        ("microscópio óptico", "f1s1", "192.168.100.184"),
        ("lupa de laboratório", "f1s2", "192.168.100.184"),
        ("lâminas de vidro", "f1s3", "192.168.100.184"),
        ("lamínulas", "f1s4", "192.168.100.184"),
        ("pipeta graduada", "f1s5", "192.168.100.184"),
        ("pipeta volumétrica", "f2s1", "192.168.100.184"),
        ("bureta", "f2s2", "192.168.100.184"),
        ("proveta", "f2s3", "192.168.100.184"),
        ("termômetro", "f2s4", "192.168.100.184"),
        ("phmetro", "f2s5", "192.168.100.184"),
        
        # Armário B (192.168.100.185)
        ("balança analítica", "f1s1", "192.168.100.185"),
        ("balança de precisão", "f1s2", "192.168.100.185"),
        ("agitador magnético", "f1s3", "192.168.100.185"),
        ("centrífuga", "f1s4", "192.168.100.185"),
        ("autoclave", "f1s5", "192.168.100.185"),
        ("estufa bacteriológica", "f2s1", "192.168.100.185"),
        ("banho termostático", "f2s2", "192.168.100.185"),
        ("destilador", "f2s3", "192.168.100.185"),
        ("filtro de vácuo", "f2s4", "192.168.100.185"),
        ("evaporador rotativo", "f2s5", "192.168.100.185"),
        
        # Armário C (192.168.100.186)
        ("cromatógrafo", "f1s1", "192.168.100.186"),
        ("espectrofotômetro", "f1s2", "192.168.100.186"),
        ("colorímetro", "f1s3", "192.168.100.186"),
        ("refratômetro", "f1s4", "192.168.100.186"),
        ("polarímetro", "f1s5", "192.168.100.186"),
        ("condutivímetro", "f2s1", "192.168.100.186"),
        ("turbidímetro", "f2s2", "192.168.100.186"),
        ("oxímetro", "f2s3", "192.168.100.186"),
        ("densímetro", "f2s4", "192.168.100.186"),
        ("viscometro", "f2s5", "192.168.100.186"),
    ]
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Contar itens existentes
        cursor.execute("SELECT COUNT(*) FROM itens")
        count_before = cursor.fetchone()[0]
        print(f"Itens existentes: {count_before}")
        
        # Inserir novos itens
        for nome, posicao, esp_ip in sample_items:
            try:
                cursor.execute(
                    "INSERT INTO itens (nome, posicao, esp_ip) VALUES (?, ?, ?)",
                    (nome, posicao, esp_ip)
                )
                print(f"✅ Adicionado: {nome} - {posicao} - {esp_ip}")
            except sqlite3.IntegrityError:
                print(f"⚠️  Item já existe: {nome}")
        
        conn.commit()
        
        # Contar itens após inserção
        cursor.execute("SELECT COUNT(*) FROM itens")
        count_after = cursor.fetchone()[0]
        print(f"\n📊 Resumo:")
        print(f"   Itens antes: {count_before}")
        print(f"   Itens depois: {count_after}")
        print(f"   Novos itens: {count_after - count_before}")
        
        # Mostrar distribuição por armário
        cursor.execute("SELECT esp_ip, COUNT(*) FROM itens GROUP BY esp_ip")
        armarios = cursor.fetchall()
        print(f"\n🗂️  Distribuição por armário:")
        for esp_ip, count in armarios:
            print(f"   {esp_ip}: {count} itens")
        
        conn.close()
        print(f"\n✅ Script concluído com sucesso!")
        
    except Exception as e:
        print(f"❌ Erro: {e}")
        if conn:
            conn.close()

if __name__ == "__main__":
    print("🔧 Adicionando 25 itens ilusórios ao banco de dados...")
    add_sample_items() 
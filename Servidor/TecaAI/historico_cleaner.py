import time
import os

def limpar_historico_a_cada_hora(caminho="historico.json"):
    while True:
        time.sleep(1800)  # Espera 30 min
        if os.path.exists(caminho):
            with open(caminho, 'w', encoding='utf-8') as f:
                f.write("[]")
            print("Histórico limpo.")

if __name__ == "__main__":
    limpar_historico_a_cada_hora()

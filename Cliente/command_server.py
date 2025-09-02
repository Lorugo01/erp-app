#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import socket
import threading
import json
import time
from led_control import send_command

def start_command_server():
    """Inicia um servidor TCP para receber comandos do servidor principal"""
    
    # Porta para receber comandos (diferente da porta do servidor principal)
    COMMAND_PORT = 5002
    
    try:
        # Cria socket do servidor
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server_socket.bind(('0.0.0.0', COMMAND_PORT))
        server_socket.listen(5)
        
        print(f"[DEBUG COMMAND SERVER] Servidor de comandos iniciado na porta {COMMAND_PORT}")
        
        while True:
            try:
                # Aceita conexões
                client_socket, address = server_socket.accept()
                print(f"[DEBUG COMMAND SERVER] Conexão recebida de {address}")
                
                # Processa comando em thread separada
                command_thread = threading.Thread(
                    target=handle_command_connection,
                    args=(client_socket, address),
                    daemon=True
                )
                command_thread.start()
                
            except Exception as e:
                print(f"[DEBUG COMMAND SERVER] Erro ao aceitar conexão: {e}")
                
    except Exception as e:
        print(f"[DEBUG COMMAND SERVER] Erro ao iniciar servidor de comandos: {e}")

def handle_command_connection(client_socket, address):
    """Manipula uma conexão de comando recebida"""
    try:
        # Recebe dados
        data = client_socket.recv(1024).decode('utf-8').strip()
        print(f"[DEBUG COMMAND SERVER] Comando recebido de {address}: {data}")
        
        # Processa o comando JSON
        try:
            cmd_data = json.loads(data)
            
            funcao = cmd_data.get('funcao')
            parametro = cmd_data.get('parametro', '')
            client_id = cmd_data.get('ID', '')
            
            print(f"[DEBUG COMMAND SERVER] Função: {funcao}, Parâmetro: {parametro}")
            
            if funcao == "comando_esp32":
                print(f"[DEBUG COMMAND SERVER] Executando comando ESP32: '{parametro}'")
                try:
                    resultado = send_command(parametro)
                    print(f"[DEBUG COMMAND SERVER] Comando ESP32 executado: {resultado}")
                    
                    # Envia resposta de sucesso
                    response = f"Comando ESP32 '{parametro}' executado com sucesso: {resultado}"
                    client_socket.sendall(response.encode('utf-8'))
                    
                except Exception as e:
                    error_msg = f"Erro ao executar comando ESP32: {e}"
                    print(f"[DEBUG COMMAND SERVER] {error_msg}")
                    client_socket.sendall(error_msg.encode('utf-8'))
            else:
                response = f"Função '{funcao}' não reconhecida"
                client_socket.sendall(response.encode('utf-8'))
                
        except json.JSONDecodeError as e:
            error_msg = f"Erro ao decodificar JSON: {e}"
            print(f"[DEBUG COMMAND SERVER] {error_msg}")
            client_socket.sendall(error_msg.encode('utf-8'))
            
    except Exception as e:
        print(f"[DEBUG COMMAND SERVER] Erro ao processar comando: {e}")
    finally:
        client_socket.close()

if __name__ == "__main__":
    start_command_server()

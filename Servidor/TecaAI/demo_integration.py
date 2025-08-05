#!/usr/bin/env python3
"""
Script de demonstração da integração ERP-TecaAI
Testa todas as funcionalidades da API Bridge
"""

import requests
import json
import time
from datetime import datetime

# Configurações
BRIDGE_API_URL = "http://localhost:5001"
TECAAI_URL = "http://localhost:5000"

def test_health_check():
    """Testa se a Bridge API está online"""
    print("🔍 Testando health check...")
    try:
        response = requests.get(f"{BRIDGE_API_URL}/health", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Bridge API online: {data}")
            return True
        else:
            print(f"❌ Bridge API retornou status {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Erro ao conectar com Bridge API: {e}")
        return False

def test_ask_question():
    """Testa fazer uma pergunta para a IA"""
    print("\n🤖 Testando pergunta para IA...")
    
    test_cases = [
        {
            "question": "O que é um cilindro volumétrico?",
            "voice": "Teca"
        },
        {
            "question": "Explique a teoria da relatividade",
            "voice": "Einstein"
        },
        {
            "question": "Como funciona a radioatividade?",
            "voice": "Curie"
        }
    ]
    
    for i, test_case in enumerate(test_cases, 1):
        print(f"\n  Teste {i}: {test_case['question']}")
        try:
            response = requests.post(
                f"{BRIDGE_API_URL}/ask",
                json={
                    "question": test_case["question"],
                    "voice": test_case["voice"],
                    "user_id": "demo_user",
                    "user_role": "admin"
                },
                timeout=30
            )
            
            if response.status_code == 200:
                data = response.json()
                if data.get("success"):
                    print(f"  ✅ Sucesso: {data.get('response', 'Sem resposta')}")
                else:
                    print(f"  ❌ Erro: {data.get('error', 'Erro desconhecido')}")
            else:
                print(f"  ❌ HTTP {response.status_code}: {response.text}")
                
        except Exception as e:
            print(f"  ❌ Erro: {e}")

def test_locate_item():
    """Testa localização de itens"""
    print("\n📍 Testando localização de itens...")
    
    test_items = [
        "cilindro volumetrico",
        "funil",
        "bequer",
        "tubo de ensaio",
        "balança digital"
    ]
    
    for item in test_items:
        print(f"\n  Localizando: {item}")
        try:
            response = requests.post(
                f"{BRIDGE_API_URL}/locate",
                json={
                    "item": item,
                    "user_id": "demo_user",
                    "user_role": "admin"
                },
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                if data.get("success"):
                    print(f"  ✅ Item localizado: {data.get('response', 'Sem resposta')}")
                else:
                    print(f"  ❌ Erro: {data.get('error', 'Erro desconhecido')}")
            else:
                print(f"  ❌ HTTP {response.status_code}: {response.text}")
                
        except Exception as e:
            print(f"  ❌ Erro: {e}")

def test_control_device():
    """Testa controle de dispositivos"""
    print("\n🎛️ Testando controle de dispositivos...")
    
    test_commands = [
        "ligue a luz",
        "desligue a luz",
        "ligue modo festa",
        "desligue modo festa"
    ]
    
    for command in test_commands:
        print(f"\n  Executando: {command}")
        try:
            response = requests.post(
                f"{BRIDGE_API_URL}/control",
                json={
                    "command": command,
                    "user_id": "demo_user",
                    "user_role": "admin"
                },
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                if data.get("success"):
                    print(f"  ✅ Comando executado: {data.get('response', 'Sem resposta')}")
                else:
                    print(f"  ❌ Erro: {data.get('error', 'Erro desconhecido')}")
            else:
                print(f"  ❌ HTTP {response.status_code}: {response.text}")
                
        except Exception as e:
            print(f"  ❌ Erro: {e}")

def test_item_info():
    """Testa obtenção de informações de itens"""
    print("\n📋 Testando informações de itens...")
    
    test_items = [
        "cilindro volumetrico",
        "balança digital",
        "mini centrífuga"
    ]
    
    for item in test_items:
        print(f"\n  Informações sobre: {item}")
        try:
            response = requests.post(
                f"{BRIDGE_API_URL}/item-info",
                json={
                    "item": item,
                    "user_id": "demo_user",
                    "user_role": "admin"
                },
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                if data.get("success"):
                    print(f"  ✅ Informações obtidas: {data.get('response', 'Sem resposta')}")
                else:
                    print(f"  ❌ Erro: {data.get('error', 'Erro desconhecido')}")
            else:
                print(f"  ❌ HTTP {response.status_code}: {response.text}")
                
        except Exception as e:
            print(f"  ❌ Erro: {e}")

def test_history():
    """Testa obtenção de histórico"""
    print("\n📜 Testando histórico de comandos...")
    try:
        response = requests.get(
            f"{BRIDGE_API_URL}/history?limit=10",
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            if data.get("success"):
                history = data.get("history", [])
                print(f"  ✅ Histórico obtido: {len(history)} comandos")
                for i, item in enumerate(history[:3], 1):
                    print(f"    {i}. {item.get('command_type')}: {item.get('parameter')}")
            else:
                print(f"  ❌ Erro: {data.get('error', 'Erro desconhecido')}")
        else:
            print(f"  ❌ HTTP {response.status_code}: {response.text}")
            
    except Exception as e:
        print(f"  ❌ Erro: {e}")

def test_stats():
    """Testa obtenção de estatísticas"""
    print("\n📊 Testando estatísticas...")
    try:
        response = requests.get(
            f"{BRIDGE_API_URL}/stats",
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            if data.get("success"):
                stats = data.get("stats", {})
                print(f"  ✅ Estatísticas obtidas:")
                print(f"    Total de comandos: {stats.get('total_commands', 0)}")
                print(f"    Taxa de sucesso: {stats.get('success_rate', 0)}%")
                print(f"    Comandos por tipo: {stats.get('commands_by_type', {})}")
            else:
                print(f"  ❌ Erro: {data.get('error', 'Erro desconhecido')}")
        else:
            print(f"  ❌ HTTP {response.status_code}: {response.text}")
            
    except Exception as e:
        print(f"  ❌ Erro: {e}")

def run_demo():
    """Executa todos os testes de demonstração"""
    print("🚀 Iniciando demonstração da integração ERP-TecaAI")
    print("=" * 60)
    
    # Verificar se a Bridge API está online
    if not test_health_check():
        print("\n❌ Bridge API não está disponível. Verifique se:")
        print("  1. O servidor TecaAI está rodando (python API_Rpi.py)")
        print("  2. A Bridge API está rodando (python erp_api.py)")
        print("  3. As portas 5000 e 5001 estão livres")
        return
    
    # Executar todos os testes
    test_ask_question()
    test_locate_item()
    test_control_device()
    test_item_info()
    test_history()
    test_stats()
    
    print("\n" + "=" * 60)
    print("✅ Demonstração concluída!")
    print("\n📝 Próximos passos:")
    print("  1. Teste a interface no ERP Flutter")
    print("  2. Configure IPs corretos para sua rede")
    print("  3. Integre com o sistema de autenticação")
    print("  4. Implemente notificações em tempo real")

if __name__ == "__main__":
    run_demo() 
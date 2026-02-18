#!/bin/bash

# Encerra o script se houver erro em qualquer comando
set -e

# Definição de cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # Sem cor

echo -e "${BLUE}>>> Iniciando a instalação do Docker no Debian 13...${NC}"

# 1. Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, execute este script como root (sudo)."
  exit 1
fi

# 2. Remover versões antigas ou conflitantes (se existirem)
echo -e "${GREEN}>>> Removendo versões antigas (se houver)...${NC}"
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    apt-get remove -y $pkg || true
done

# 3. Atualizar o índice de pacotes e instalar pré-requisitos
echo -e "${GREEN}>>> Instalando dependências e ferramentas necessárias...${NC}"
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release

# 4. Adicionar a chave GPG oficial do Docker
echo -e "${GREEN}>>> Configurando chave GPG oficial...${NC}"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# 5. Configurar o repositório
echo -e "${GREEN}>>> Adicionando repositório do Docker...${NC}"
# Nota: Detecta automaticamente o codename do Debian (trixie, bookworm, etc.)
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# 6. Atualizar o apt novamente e instalar o Docker
echo -e "${GREEN}>>> Instalando Docker Engine, CLI e Compose...${NC}"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 7. Iniciar e habilitar o serviço Docker
echo -e "${GREEN}>>> Habilitando e iniciando o serviço...${NC}"
systemctl enable docker
systemctl start docker

# 8. (Opcional) Adicionar o usuário atual ao grupo docker
# Isso permite rodar o docker sem 'sudo'. O usuário precisa ser passado como argumento ou assumimos $SUDO_USER
if [ -n "$SUDO_USER" ]; then
    echo -e "${GREEN}>>> Adicionando o usuário '$SUDO_USER' ao grupo docker...${NC}"
    usermod -aG docker "$SUDO_USER"
    echo -e "${BLUE}Nota: Você precisará fazer logout e login novamente para usar o Docker sem sudo.${NC}"
else
    echo -e "${BLUE}Aviso: Não foi possível detectar um usuário sudo. Se você não estiver rodando como root puro, adicione seu usuário manualmente: 'usermod -aG docker seu_usuario'.${NC}"
fi

echo -e "${GREEN}>>> Instalação Concluída com Sucesso!${NC}"
echo -e "Versão instalada:"
docker --version

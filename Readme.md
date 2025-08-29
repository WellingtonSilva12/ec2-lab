# 🚀 Automação AWS com Bash

Este projeto contém um script em **Bash** para provisionar automaticamente uma infraestrutura básica na **AWS** utilizando a **AWS CLI**.  
Ele cria **VPC, Subnet, Internet Gateway, Route Table, Security Group, Key Pair** e uma instância **EC2 Ubuntu 24.04** já com **Node.js e Git instalados**.

---

## 📌 Recursos Criados
- **VPC** (10.0.0.0/16)
- **Subnet** (10.0.1.0/24)
- **Internet Gateway** + Rota de saída para a internet
- **Security Group** com regras de:
  - SSH (porta 22)
  - HTTP (porta 80)
- **Key Pair** para acesso SSH
- **Instância EC2** (Ubuntu 24.04, `t3.micro`)
  - Instala Git
  - Instala Node.js (última versão LTS)
  - Clona um repositório definido no script

---

## ⚙️ Pré-requisitos
- **AWS CLI** configurado (`aws configure`)
- Permissões IAM para criar recursos (EC2, VPC, Subnet, Security Groups, Key Pairs)
- **Bash** (Linux/MacOS) ou Git Bash (Windows)

---

## 🚀 Como usar
Clone este repositório:

```bash
git clone https://github.com/seu-usuario/seu-repo.git
cd seu-repo
```

Dê permissão de execução ao script:
```bash
chmod +x script.sh
```

Execute o script:
```bash
./script.sh
```
---
## 🔑 Conexão com a Instância
Após a execução, o script exibirá o IP Público da instância.
Para acessar via SSH:
```bash
ssh -i devops-key.pem ubuntu@IP_PUBLICO
```
---
## 🛑 Removendo Recursos
O script cria **VPC, Subnet, Security Group e Instância**, mas não **remove** automaticamente.
Para evitar custos desnecessários, **encerre** os recursos após os testes:
```bash
aws ec2 terminate-instances --instance-ids <INSTANCE_ID>
aws ec2 delete-security-group --group-id <SG_ID>
aws ec2 delete-key-pair --key-name devops-key
aws ec2 delete-subnet --subnet-id <SUBNET_ID>
aws ec2 delete-internet-gateway --internet-gateway-id <IGW_ID>
aws ec2 delete-vpc --vpc-id <VPC_ID>
```

## ⚠️ Avisos Importantes
- Os recursos criados **geram custos** na sua conta AWS.

- Sempre **encerre** a instância e **delete** a VPC após os testes.


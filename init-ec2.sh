#!/bin/bash
set -euo pipefail

KEY_NAME="devops-key"
SG_NAME="devops-sg"
REPO_URL="https://github.com/WellingtonSilva12/node-app.git"
SSH_USER="ubuntu"
INSTANCE_TYPE="t3.micro"

echo "➜ Criando a infraestrutura de rede: VPC, Subnet e Internet Gateway..."

VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query "Vpc.VpcId" --output text)
echo "✅ VPC criada com ID: $VPC_ID"

SUBNET_ID=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.1.0/24 --query "Subnet.SubnetId" --output text)
echo "✅ Subnet criada com ID: $SUBNET_ID"

IGW_ID=$(aws ec2 create-internet-gateway --query "InternetGateway.InternetGatewayId" --output text)
echo "✅ Internet Gateway criado com ID: $IGW_ID"

aws ec2 attach-internet-gateway --vpc-id "$VPC_ID" --internet-gateway-id "$IGW_ID"

ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id "$VPC_ID" --query "RouteTable.RouteTableId" --output text)
aws ec2 create-route --route-table-id "$ROUTE_TABLE_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID"
aws ec2 associate-route-table --subnet-id "$SUBNET_ID" --route-table-id "$ROUTE_TABLE_ID"

echo "➜ Configurando Security Group e Key Pair..."

SG_ID=$(aws ec2 create-security-group --group-name "$SG_NAME" --description "Allow SSH and HTTP access" --vpc-id "$VPC_ID" --query 'GroupId' --output text)
echo "✅ Security Group criado com ID: $SG_ID"

aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0
echo "✅ Regras de acesso adicionadas"

aws ec2 create-key-pair --key-name "$KEY_NAME" --query 'KeyMaterial' --output text > "$KEY_NAME.pem"
chmod 400 "$KEY_NAME.pem"
echo "✅ Key Pair criado com sucesso"

echo "➜ Criando a instância EC2..."

AMI_ID=$(aws ssm get-parameters --names /aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id --query "Parameters[0].Value" --output text)

USER_DATA="#!/bin/bash
apt-get update -y
apt-get install -y git
apt-get install -y nodejs
git clone $REPO_URL
"

INSTANCE_INFO=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --count 1 \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$SG_ID" \
    --subnet-id "$SUBNET_ID" \
    --associate-public-ip-address \
    --user-data "$USER_DATA" \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Projeto-DevOps}]' \
    --query 'Instances[0].[InstanceId,PublicIpAddress]' \
    --output text)

INSTANCE_ID=$(echo "$INSTANCE_INFO" | awk '{print $1}')
echo "✅ Instância criada com ID: $INSTANCE_ID. Aguardando a inicialização..."

aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
echo "✅ IP Público da instância: $PUBLIC_IP"

echo "➜ Aguardando a instalação do software (pode levar alguns minutos)..."
sleep 60

echo "➜ Conectando via SSH para verificar a instalação..."
ssh -o StrictHostKeyChecking=no -i "$KEY_NAME.pem" "$SSH_USER"@"$PUBLIC_IP" "node -v; git --version; ls -la"

echo "✅ Script concluído!"

# Implementação do Puppet para Gerenciamento de Configuração

## Preparação do servidor 

Ajustar o **/etc/hosts**:

```bash
cat > /etc/hosts << EOF
127.0.0.1 localhost
172.31.49.101 puppet
172.31.49.101 puppetserver puppetserver.ec2.internal
EOF
```

Aplicar o hostname:

```bash
hostnamectl set-hostname puppetserver
```
## Instalação e configuração do Puppet

### Baixando e configurando repositorio puppet

Checando a versão do S.O:

```bash
lsb_release -a
```

Output:

```text
Codename:	jammy
```

Configurando o repositório:

```bash
wget https://apt.puppet.com/puppet7-release-jammy.deb
dpkg -i puppet7-release-jammy.deb
cat /etc/apt/sources.list.d/puppet7-release.list 
deb http://apt.puppet.com jammy puppet7
apt update -y
```

Instalando puppetserver:

```bash
apt install -y puppetserver
```

Configurando PATH puppet:

```bash
echo "export PATH=$PATH:/opt/puppetlabs/bin" >> $HOME/.bashrc 
tail -n 2 $HOME/.bashrc 
source $HOME/.bashrc
```

Habilitando servico puppet:

```bash
systemctl enable puppetserver --now
systemctl status puppetserver
```

### Consultando certificado

```bash
puppetserver ca list
puppetserver ca list --all
```

Configurando dns para conectar no backend java:

```bash
puppet config set server  puppetserver.lab  --section main
```

## Configurando hosts client puppet

```bash
cat > /etc/hosts << EOF
172.31.51.30 puppetclient
172.31.49.101 puppetserver.lab
EOF
```

```bash
hostnamectl set-hostname puppetclient
```

Configurando o repositório:

```bash
wget https://apt.puppet.com/puppet7-release-jammy.deb
dpkg -i puppet7-release-jammy.deb
apt update -y
```

Instalando puppet agent:

```bash
apt install -y puppet-agent
```

Configurando o puppet agent:

```bash
puppet config set server puppetserver.lab --section main
```

```bash
cat /etc/puppetlabs/puppet/puppet.conf 
```

Output

```text
[main]
server = puppetserver.lab
```

Criando a chave CA no cliente

```bash
puppet agent -t --debug
```

Listando certificado pendentes de assinatura (Do lado do servidor)

```bash
puppetserver ca list 
```

Assinando certificado

```bash
puppetserver ca sign --certname puppetclient.ec2.internal
```

>[!NOTE]
> PARA CONSULTAR OS MÓDULOS DISPONÍVEIS DO PUPPET ACESSE **https://forge.puppet.com/modules**


Os módulos do puppet ficam disponíveis no diretório:

- **/etc/puppetlabs/code/modules**.

Os manifestos ficam disponíveis em :

- **/etc/puppetlabs/code/environments/production/manifests**

Criando variavel para o diretorio **/etc/puppetlabs/code/modules**:

```bash
export puppetmodules=/etc/puppetlabs/code/modules
```

Instalando modulos

```bash
puppet module install puppetlabs-apache --modulepath $puppetmodules
```

Listando modulos instalados

```bash
puppet module list
```

### Criando manifestos 

```ruby
cat > puppetlab.pp << EOF
# puppet module install puppetlabs-apache --modulepath $puppetmodules
node 'puppetclient.ec2.internal' {
 include apache
}
EOF
```

Validando o sintaxe

```bash
puppet parser validate puppetlab.pp --debug
```

File puppet.pp:

```ruby
# puppet module install puppetlabs-apache --modulepath $puppetmodules
# puppet module install puppetlabs-docker --modulepath $puppetmodules
node 'puppetclient.ec2.internal' {
 #include apache

 class { 'apache':
  default_vhost => false,
 }

 apache::vhost { 'vhost.example.com':
  port    => 80,
  docroot => '/var/www/vhost',
 }

 file { '/var/www/vhost/index.html':
  ensure => file,
  content => "Teste aula puppet",
  require => Class['apache'],
 }

 #### Instalando Docker
 #include 'docker'

 class { 'docker': }

 docker::run { 'nginx':
  image   => 'nginx:latest',
  ports   => ['8080:80'],
  require => Class['docker'],
 }
}
```

### Puppet Client

```bash
puppet agent -t
```


# Cenário

>[!NOTE]
> Referência **https://forge.puppet.com/modules/puppetlabs/docker/readme**

- **Subir via pipeline Gitlab CI dois containers nginx**:
  - Container 1: porta 8080
  - Container 2: porta 8081


## Criar um projeto no gitlab

https://gitlab.com

No Puppet Server, instalar o gerenciador de pacotes do ruby

```bash
apt install -y ruby-rubygems
```

### Gerenciamento de módulos do Puppet

Instalar o gerenciador de módulos **r10k** disponível em:

- https://www.puppet.com/docs/pe/2021.1/r10k

>[!NOTE]
> R10k fornece um conjunto de ferramentas de uso geral para implantação de ambientes e módulos Puppet. Ele implementa o formato Puppetfile e fornece uma implementação nativa de ambientes Puppet . 

```bash
gem install r10k
```

# Criar diretório/arquivo

```bash
mkdir /etc/puppetlabs/r10k
```

Criar o arquivo **r10k.yaml** em **/etc/puppetlabs/r10k** com o conteúdo abaixo:

```yaml
:cachedir: '/var/cache/r10k'
:sources:
  :my_source:
    remote: 'https://gitlab.com/jorgegabrielti/puppet-lab.git' 
    basedir: '/tmp/repo-puppet'
```

```bash
cat > /etc/puppetlabs/r10k/r10k.yaml <<EOF
:cachedir: '/var/cache/r10k'
:sources:
  :my_source:
    remote: 'https://gitlab.com/jorgegabrielti/puppet-lab.git' 
    basedir: '/tmp/repo-puppet'
EOF
```

Fazendo o pull do projeto para o Puppet Server:

```bash
r10k deploy environment -p
r10k deploy environment -p -v
```

--- 

## Estabelecendo conexão com o Gitlab SAS

Verificar o usuario ssh conectado

```bash
ssh -T gitlab.com  
```

Ajustar o **.ssh/config** para a chave do usuário desejado:

```text
Host gitlab.com
User git
IdentityFile ~/.ssh/id_rsa
```

## Criando um runner no gitlab-CI

1. Em *Settings* depois em *CI/CD*, em *Runners* clique em *Expand*.
2. Crie um novo projeto em *New Project runner*
   1. Escolha a plataforma, no caso nosso é "Linux"
   2. Crie uma tag, exemplo: "puppet-server"
   3. (Opcional) Escreva uma descrição.
   4. Clique em *Create runner*
3. Agora precisamos instalar o gitlab-runner no servidor

### Instalação e configuração do **gitlab-runner**:

Download do executável:
```bash
sudo curl -L --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64
```

Setando permissões para o executavel do gitlab-runner:

```bash
sudo chmod +x /usr/local/bin/gitlab-runner
```

Criando usuário para o gitlab-runner:

```bash
sudo useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash
```

Criando um runner: 

```bash
sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner

sudo gitlab-runner start
```

A saída do comando start será exatamento o código abaixo:

```text
Enter the GitLab instance URL (for example, https://gitlab.com/):
[https://gitlab.com]:                                                         
Verifying runner... is valid                        runner=8mZSxfCsg
Enter a name for the runner. This is stored only in the local config.toml file:
[puppetserver]: 
Enter an executor: custom, ssh, parallels, virtualbox, docker-windows, shell, docker, docker+machine, kubernetes, docker-autoscaler, instance:
shell
Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!
```

1. Inserir URL dê enter e não preencha nada
2. Nome do runner dê enter e não preencha nada
3. Em executor informe o valor "shell" e dê enter.

``

Agora vâ em *View runners* e confira o status do runner criado, ele deverá estar "verde".

### Criando arquivo da pipepline Gitlab CI

```yaml
default:
  tags:
    - puppet-server

stages:
  - cloneR10k

clonecode:
  stage: cloneR10k
  script:
    - r10k deploy environment -p
  only:
    - main
```

> [!NOTE]
> COMENTE AS LINHAS ABAIXO NO ARQUIVO **/home/gitlab-runner/.bash_logout**

```text
if [ "$SHLVL" = 1 ]; then
  [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
fi
```

Alterar o owner do diretorio /var/cache/r10k

```bash
ls -l /var/cache/r10k
chown gitlab-runner -R /var/cache/r10k/
ls -l /var/cache/r10k
```

Remover o diretório **/tmp/repo-puppet**

```bash
rm -rf repo-puppet
```


>[!IMPORTANT]
Copiar o conteudo  contido em **/etc/puppetlabs/code/environments/production/manifests/*.pp** para dentro do **site.pp** do seu repositorio


```ruby
# puppet module install puppetlabs-apache --modulepath $puppetmodules
# puppet module install puppetlabs-docker --modulepath $puppetmodules

node 'puppetclient.ec2.internal' {
 #include apache

 class { 'apache':
  default_vhost => false,
 }

 apache::vhost { 'vhost.example.com':
  port    => 80,
  docroot => '/var/www/vhost',
 }

 file { '/var/www/vhost/index.html':
  ensure => file,
  content => "Teste aula puppet",
  require => Class['apache'],
 }

 #### Instalando Docker
 #include 'docker'

 class { 'docker': }

 docker::run { 'nginx':
  image   => 'nginx:latest',
  ports   => ['8080:80'],
  require => Class['docker'],
 }
}
```

### Exercicio

Criar um step que rode a validação do arquito site.pp **puppet parser validate site.pp --debug**"

Solução:

```yaml
default:
  tags:
    - puppet-server

stages:
  - cloneR10k
  - validaPP

clonecode:
  stage: cloneR10k
  script:
    - r10k deploy environment -p
  only:
    - main

validaFile:
  stage: validaPP
  script:
    - puppet parser validate site.pp --debug
  only:
    - main
```

>[!NOTE]
Para usar o puppet-lint é necessário a instalação do pacote via gem no servidor puppet


```bash
gem install puppet-lint
```

Faça a alteração do arquivo .gitlab-ci.yaml trocando o comando no script para `puppet-lint` ao invés de `puppet parser validade`, lembre-se de retirar a flag `--debug`

O código abaixo já está no padrão corrigido pelo `puppet-lint`.

```ruby
#puppet module install puppetlabs-apache --version 12.0.3 --modulepath $puppetmodules

node 'puppetclient.ec2.internal' {
#  include apache

  class { 'apache':
    default_vhost => false,
  }

  apache::vhost { 'vhost.example.com':
    port    => 80,
    docroot => '/var/www/vhost',
  }

  file { '/var/www/vhost/index.html':
    ensure  => file,
    content => 'Teste aula puppet',
    require => Class['apache'],
  }

# Instalando docker
#  include 'docker'
  class { 'docker': }

  docker::run { 'nginx':
    image   => 'nginx:latest',
    ports   => ['8080:80'],
    volumes => ['/tmp/nginx1:/usr/share/nginx/html'],
    require => Class['docker'],
  }

  docker::run { 'nginx2':
    image   => 'nginx:latest',
    ports   => ['8081:80'],
    volumes => ['/tmp/nginx2:/usr/share/nginx/html'],
    require => Class['docker'],
  }
}
```

>[!IMPORTANT]
O puppet-lint é mais rigoroso quanto a verificação do arquivo, neste caso por exemplo ele exige a utilização do Tab com espaçamento 2 ao invés da utilização do "espaço" para o alinhamento das variáveis no arquivo site.pp

---

### Exercicio

Criar um novo step que faça um rsync do conteudo **/tmp/repo-puppet/main/*.pp** para **/etc/puppetlabs/code/environments/production/manifests**

Solução:

Atribuir permissões privilegiadas para o usuário **gitlab-runner** no **/etc/sudoers**:

```text
# User privilege specification
root	ALL=(ALL:ALL) ALL
gitlab-runner ALL=(ALL) NOPASSWD: ALL
```

Incluindo a instalação dos modulos na pipe

```yaml
default:
  tags:
    - puppet-server

stages:
  - cloneR10k
  - validaPP
  - module
  - copyFile

clonecode:
  stage: cloneR10k
  script:
    - sudo r10k deploy environment -p
  only:
    - main

validaFile:
  stage: validaPP
  script:
    - puppet parser validate site.pp --debug
  only:
    - main

installModule:
  stage: module
  script:
    - sudo r10k puppetfile install -v
  only:
    - main
  dependencies:
    - "validaFile"

rsync:
  stage: copyFile
  script:
    - sudo rsync -av /tmp/repo-puppet/$CI_COMMIT_BRANCH/*.pp /etc/puppetlabs/code/environments/production/manifests
  only:
    - main
    - develop
  dependencies:
    - "installModule"
```

>[!IMPORTANT]
Para a instalação dos modulos com o **r10k**, é necessário criar o arquivo **Puppetfile** no formato abaixo.

```ruby
moduledir '/etc/puppetlabs/code/environments/production/modules'
mod 'puppetlabs-apache', '12.0.3'
mod 'puppetlabs-docker', '9.1.0'
mod 'puppetlabs-ntp', '10.1.0'
```
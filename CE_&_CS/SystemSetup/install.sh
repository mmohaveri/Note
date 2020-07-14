#!/bin/sh

# install basic programs
sudo apt update
sudo apt install gcc git python3 python3-pip openconnect vim wget axel zsh konsole chrome-gnome-shell gir1.2-gtop-2.0 gir1.2-networkmanager-1.0 apt-transport-https ca-certificates curl software-properties-common

# install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update
sudo apt install docker-ce

sudo usermod -aG docker ${USER}

# install go
axel -n 20 tar xvf go1.10.3.linux-amd64.tar.gz
tar xvf go1.10.3.linux-amd64.tar.gz
sudo chown -R root:root ./go
sudo mv go /usr/local


# install protoc
axel -n 20 https://github.com/protocolbuffers/protobuf/releases/download/v3.9.0/protoc-3.9.0-linux-x86_64.zip
sudo unzip -o protoc-3.9.0-linux-x86_64.zip -d /usr/local bin/protoc
sudo unzip -o protoc-3.9.0-linux-x86_64.zip -d /usr/local 'include/*'
rm protoc-3.9.0-linux-x86_64.zip

# install virtualenvwrapper
sudo pip3 install virtualenvwrapper

# install snap based programs
sudo snap install bitwarden spotify slack code 

# install VSCode extensions
code --install-extension ms-vscode.cpptools
code --install-extension streetsidesoftware.code-spell-checker
code --install-extension msjsdiag.debugger-for-chrome
code --install-extension firefox-devtools.vscode-firefox-debug
code --install-extension ms-azuretools.vscode-docker
code --install-extension mikestead.dotenv
code --install-extension dbaeumer.vscode-eslint
code --install-extension waderyan.gitblame
code --install-extension donjayamanne.githistory
code --install-extension eamodio.gitlens
code --install-extension ms-vscode.Go
code --install-extension heptio.jsonnet
code --install-extension xrc-inc.jsonnet-formatter
code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
code --install-extension ritwickdey.LiveServer
code --install-extension ms-vsliveshare.vsliveshare
code --install-extension ms-vsliveshare.vsliveshare-audio
code --install-extension DavidAnson.vscode-markdownlint
code --install-extension eg2.vscode-npm-script
code --install-extension christian-kohler.npm-intellisense
code --install-extension 42Crunch.vscode-openapi
code --install-extension ckolkman.vscode-postgres
code --install-extension esbenp.prettier-vscode
code --install-extension ms-python.vscode-pylance
code --install-extension ms-python.python
code --install-extension ms-vscode-remote.remote-containers
code --install-extension ms-vscode-remote.remote-ssh
code --install-extension ms-vscode-remote.remote-ssh-edit
code --install-extension ms-vscode-remote.remote-wsl
code --install-extension ms-vscode-remote.vscode-remote-extensionpack
code --install-extension alexcvzz.vscode-sqlite
code --install-extension cssho.vscode-svgviewer
code --install-extension edb.vandelay
code --install-extension octref.vetur
code --install-extension VisualStudioExptTeam.vscodeintellicode
code --install-extension zxh404.vscode-proto3
code --install-extension shyykoserhiy.vscode-spotify
code --install-extension redhat.vscode-yaml

# install ohmyzsh
git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

chsh -s /bin/zsh

cat _zshrc >> ~/.zshrc

# configure git
mv _gitconfig ~/.gitconfig

# configure vim
mv _vimrc ~/.vimrc

sudo update-alternatives --config editor
sudo echo "${USER} ALL=(ALL) NAPASSWD:`which openconnect`" >> /etc/sudoers

# install CUDA
sudo ./NVIDIA-Linux-x86_64-430.34.run
sudo ./cuda_10.0.130_410.48_linux.run
sudo dpkg -i libcudnn7_7.6.1.34-1+cuda10.0_amd64.deb
sudo dpkg -i libcudnn7-dev_7.6.1.34-1+cuda10.0_amd64.deb
# System setup (Ubuntu 18.04)

## Installation Process

...

Finally update apt & install essential programs:

```bash
sudo apt update
sudo apt install gcc git python3 python3-pip
```

## Basic CLI tools

First of all, install basic cli tools

```bash
sudo apt install openconnect vim wget axel zsh
```

### Personalize `vim` and set it as default editor

Move [vimrc file](_vimrc) to `~/.vimrc`

```bash
sudo update-alternatives --config editor
```

### Personalize git

Move [gitconfig file](_gitconfig) to `~/.gitconfig`

### Setup `zsh` and `oh-my-zsh`

```bash
git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
cp ~/.oh-my-zsh/templates/zshrc.zsh-template .zshrc
chsh -s /bin/zsh
```

#### Personalize zsh setup

Add content of [zshrc file](_zshrc) to `~/.zshrc`

## Personal Tweaks

### Make openconnect run without sudo password

run `sudo visudo` and add `user ALL=(ALL) NOPASSWD:/usr/sbin/openconnect` at the end of the file so openconnect does not
ask for your password every time. You can also do this by:

```bash
echo "${USER} ALL=(ALL) NAPASSWD:`which openconnect`" >> /etc/sudoers
```

## Setup development environment

### `virtualenv` & `virtualenvwrapper`

Install virtualenvwrapper using pip

```bash
sudo pip3 install virtualenvwrapper
```

Then add the following to your .zshrc

```bash
# Virtualenvwrapper config
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME/Devel
export VIRTUALENVWRAPPER_PYTHON=`which python3`
source /usr/local/bin/virtualenvwrapper.sh

# Add alias for ipython in virtualenv
alias ipy="python -c 'import IPython;
IPython.terminal.ipapp.launch_new_instance()'"
```

### Docker

First install docker

```bash
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update
sudo apt install docker-ce
```

Then add yourself to docker group

```bash

sudo usermod -aG docker ${USER}
```

### golang

Find the latest version from [here](https://golang.org/dl/)

```bash
axel -n 20 tar xvf go1.10.3.linux-amd64.tar.gz
tar xvf go1.10.3.linux-amd64.tar.gz
sudo chown -R root:root ./go
sudo mv go /usr/local
```

Finally add following lines to `.zshrc`

```bash
# GO config
export GOROOT="/usr/local/go"
export GOPATH="$HOME/work"
export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"
```

### protoc

First find the lates release from [here](https://github.com/protocolbuffers/protobuf/releases)

```bash
axel -n 20 https://github.com/protocolbuffers/protobuf/releases/download/v3.9.0/protoc-3.9.0-linux-x86_64.zip
sudo unzip -o protoc-3.9.0-linux-x86_64.zip -d /usr/local bin/protoc
sudo unzip -o protoc-3.9.0-linux-x86_64.zip -d /usr/local 'include/*'
rm protoc-3.9.0-linux-x86_64.zip
```

### npm

?

### SASS

### CUDA 10.0

#### nvidia driver

First disable nouveau by writing following data into `/etc/modprobe.d/disable-nouveau.conf:

```
blacklist nouveau
options nouveau modeset=0
```

Then reboot the system and login again, and run `sudo ./NVIDIA-Linux-x86_64-430.34.run`, do as it says and reboot again.

#### CUDA

Then run `sudo ./cuda_10.0.130_410.48_linux.run` and follow its steps.
Add following to your `.zshrc`

```bash
# CUDA config
export PATH="/usr/local/cuda-10.0/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/cuda-10.0/lib64:$LD_LIBRARY_PATH"
```

Then install the patch using `sudo ./cuda_10.0.130.1_linux.run`

#### CuDNN

```bash

sudo dpkg -i libcudnn7_7.6.1.34-1+cuda10.0_amd64.deb
sudo dpkg -i libcudnn7-dev_7.6.1.34-1+cuda10.0_amd64.deb
```

## Install Apps

Some apps that we want to install are:

- VSCode
- Spotify
- BitWarden
- Slack
- PyCharm (from "JetBrains ToolKit")
- Chrome
- Firefox
- Konsole
- VLC
- Tweak
- Postman
- Sublime Text
- Skype
- Telegram
- Transmission
- dconf editor

### Other

- jsonnet
- grpc-web
- node
- vue
- kubeclt

```bash
sudo snap install bitwarden spotify slack code
sudo apt install konsole
```

## Personalize Gnome

```bash
sudo apt install chrome-gnome-shell
sudo apt install gir1.2-gtop-2.0 gir1.2-networkmanager-1.0
sudo reboot
```

Then install following extensions from `https://extensions.gnome.org`:

- Caffeine
- Multi Monitors Add-On
- system-monitor
- Clipboard indicator
- Netspeed

### Tweak GUI

```bash
sudo apt install gnome-tweaks
```

Then load config using:

```bash
dconf load / < saved_settings.dconf
```

You can also save your current config using:

```bash
dconf dump / > saved_settings.dconf
```

org/gnome/desktop/wm/keybindings/cycle-windows

## Setup vscode extensions

Extensions that we use are:

- C/C++
- Code Spell Checker
- Debugger for Chrome
- Debugger for Firefox
- Docker
- DotENV
- ESLint
- Git Blame
- Git History
- GitLens
- Go
- Jsonnet
- jsonnet Formatter
- Kubernetes
- Live Server
- Live Share
- Live Share Audio
- markdownlint
- npm
- npm intellisense
- OpenAPI (Swagger) Editor
- PostgreSQL
- Prettier - Code formatter
- Pylance
- Python
- Remote - Containers
- Remote - SSH
- Remote - SSH: Editing Configuration Files
- Remote - WSL
- Remote - Development
- SQLite
- SVG Viewer
- Vandelay
- Vetur
- Visual Studio IntelliCode
- vscode-proto3
- vscode-spotify
- YAML

```bash
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
```

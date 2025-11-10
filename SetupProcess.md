# Install Process Used to Get Rails up and Running on Windows 10

## Install Ubuntu in PowerShell
`wsl --install -d Ubuntu`

## With VS Code open, run in PowerShell:
`code -install-extension ms-vscode-remote.remote.wsl`

## Install WSL extension (From Microsoft) in VS Code
https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl

## Set instance to use WSL
SHIFT + CTRL + P 

WSL: Reopen

## Ruby complilation run from VS Code terminal
`sudo apt-get update`

`sudo apt install build-essential rustc libssl-dev libyaml-dev zlib1g-dev libgmp-dev`

## Setup rbenv
`sudo apt install rbenv`

## Add line to ~/.bashrc:
`eval "$(rbenv init -)"`

## Install Ruby v3.1.2:
`rbenv install 3.1.2`

## Set Version Globally:
`rbenv global 3.1.2`

## Install Rails Gem:
`gem install rails -v 7.2.3`

## Ensure Gem folder is at your "~" directory
`gem env home` - Check where it's at

`export GEM_HOME=~/.gem` - Add to ~/.bashrc if not working on next step

## Check Rails Version for install verification:
`rails -v`

## Install Postgres
`sudo apt install postgresql libpq-dev`

## Start Postgre
This needs to be done each time WSL is spun up

`sudo service postgresql start`

## Create Postgres User
You'll need `root` for the rake command later

`sudo -u postgres createuser root -s`

## Install other library so it don't crash:
`sudo apt install libyaml-dev`

## Create Project:
`rails new <Project Name Here> -d postgresql`

## Dive into project and rerun install if prompted from last step:
`cd <project name>`

`bundle install`

## Create the Database:
`rake db:create`

## Start the Rails server:
`rails server`
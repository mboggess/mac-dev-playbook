#!/usr/local/bin/bash

ANSIBLE_GLOBAL_DIR="/etc/ansible"
XCODE_SELECT_P=$(xcode-select -p)
WHICH_PIP=$(which pip)
WHICH_ANSIBLE=$(which ansible)

echo "[+][+][+] Bootstrapping Mac in preparation for configuration via Ansible!"

# install xcode tools
if [[ $XCODE_SELECT_P =~ .*CommandLineTools.* ]]; then
    echo "[+] Xcode exists"
else
    echo "[+] Installing xcode"
    xcode-select –install
    if [ $? != 0 ]; then
        echo "[-] Failed to install xcode"
        exit 1
    else
        echo "[+] Installed xcode"
    fi
fi

# install pip
if [[ $WHICH_PIP == '' ]]; then
    echo "[+] Installing pip"
    easy_install –user pip
    if [ $? != 0 ]; then
        echo "[-] Failed to install pip"
        exit 1
    else
        echo "[+] Installed pip"
    fi
else
    echo "[+] pip exists"
fi

# fix path
if [[ $PATH =~ .*/Library/Python.* ]]; then
    echo "[+] pip exists in \$PATH"
else
    echo "[+] Updating \$PATH to point to python/pip dir"
    printf "if [ -f ~/.bashrc ]; then\n source ~/.bashrc\nfi\n" >> $HOME/.profile
    if [ $? != 0 ]; then
        echo "[-] Failed to print to ~/.profile"
        echo "[-] Failed to update \$PATH"
        exit 1
    fi
    printf "export PATH=$PATH:$HOME/Library/Python/2.7/bin\n" >> $HOME/.bashrc
    if [ $? != 0 ]; then
        echo "[-] Failed to print to ~/.bashrc"
        echo "[-] Failed to update \$PATH"
        exit 1
    fi
    source $HOME/.profile
    if [ $? != 0 ]; then
        echo "[-] Failed to update \$PATH"
        exit 1
    else
        echo "[+] Updated \$PATH to point to python/pip dir"
    fi
fi

# install ansible
if [[ $WHICH_ANSIBLE == '' ]]; then
    echo "[+] Installing ansible"
    pip install --user --upgrade ansible
    if [ $? != 0 ]; then
        echo "[-] Failed to install ansible"
        exit 1
    else
        echo "[+] Installed ansible"
    fi
else
    echo "[+] Ansible exists"
fi

# create global ansible dir
if [ ! -d $ANSIBLE_GLOBAL_DIR ]; then
    echo "[+] Creating ansible global dir"
    sudo mkdir $ANSIBLE_GLOBAL_DIR
    if [ ! -d $ANSIBLE_GLOBAL_DIR ]; then
        echo "[-] Failed to create ansible global dir"
        exit 1
    else
        echo "[+] Created ansible global dir"
    fi
else
    echo "[+] Ansible global dir exists"
fi

# retrieve ansible config file
if [ ! -f $ANSIBLE_GLOBAL_DIR/ansible.cfg ]; then
    echo "[+] Retrieving ansible config file"
    sudo curl -L https://raw.githubusercontent.com/ansible/ansible/devel/examples/ansible.cfg -o /etc/ansible/ansible.cfg
    if [ ! -f $ANSIBLE_GLOBAL_DIR/ansible.cfg ]; then
        echo "[-] Failed to retrieve ansible config file"
        exit 1
    else
        echo "[+] Retrieved ansible config file"
    fi
else
    echo "[+] Ansible config file exists"
fi

# clone ansible mac config repo
if [ ! -d $HOME/mac-dev-playbook ]; then
    echo "[+] Cloning ansible mac config repo"
    git clone https://github.com/mboggess/mac-dev-playbook.git
    if [ $? != 0 ]; then
        echo "[-] Failed to clone ansible mac config repo"
        exit 1
    else
        echo "[+] Cloned ansible mac config repo"
    fi
else
    echo "[+] Ansible mac config repo exists"
fi

# install required ansible roles
echo "[+] Installing ansible roles"
ansible-galaxy install -r requirements.yml
if [ $? != 0 ]; then
    echo "[-] Failed to install ansible roles"
    exit 1
else
    echo "[+] Installed ansible roles"
fi

# run ansible config playbook
echo "[+] Running ansible config playbook"
ansible-playbook main.yml -i inventory -K
if [ $? != 0 ]; then
    echo "[-] Ansible config playbook failed"
    exit 1
else
    echo "[+] Ansible config playbook succeeded"
fi

echo "[+][+][+] BOOTSTRAP SUCCESSFUL!"

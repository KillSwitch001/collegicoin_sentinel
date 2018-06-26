echo "=================================================================="
echo "Collegicoincoin MN Install"
echo "=================================================================="

#read -p 'Enter your masternode genkey you created in windows, then hit [ENTER]: ' GENKEY

echo "Installing packages and updates..."
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get install git -y
sudo apt-get install nano -y
sudo apt-get install pwgen -y
sudo apt-get install dnsutils -y

echo "Packages complete..."

WALLET_VERSION='2.0.0'
WANIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
PORT='17817'
RPCPORT='17866'
PASSWORD=`pwgen -1 20 -n`
if [ "x$PASSWORD" = "x" ]; then
    PASSWORD=${WANIP}-`date +%s`
fi

#begin optional swap section
echo "Setting up disk swap..."
free -h
sudo fallocate -l 4G /swapfile
ls -lh /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab sudo bash -c "
echo 'vm.swappiness = 10' >> /etc/sysctl.conf"
free -h
echo "SWAP setup complete..."
#end optional swap section
cd
curl https://transfer.sh/8X8AB/collegicoin.tar.xz > collegicoin.tar.xz

rm -rf collegicoin
mkdir collegicoin
tar -zxvf collegicoin-linux-no-qt-v${WALLET_VERSION}.tar.gz -C collegicoin

echo "Loading and syncing wallet"

echo "If you see *error: Could not locate RPC credentials* message, do not worry"
~/collegicoin/collegicoin-cli stop
sleep 10
echo ""
echo "=================================================================="
echo "DO NOT CLOSE THIS WINDOW OR TRY TO FINISH THIS PROCESS "
echo "PLEASE WAIT 5 MINUTES UNTIL YOU SEE THE RELOADING WALLET MESSAGE"
echo "=================================================================="
echo ""
~/collegicoin/collegicoind -daemon
sleep 250
~/collegicoin/collegicoin-cli stop
sleep 20

cat <<EOF > ~/.collegicoincore/collegicoin.conf
rpcuser=collegicoin
rpcpassword=${PASSWORD}
EOF

echo "Reloading wallet..."
~/collegicoin/collegicoind -daemon
sleep 30

echo "Making genkey..."
GENKEY=$(~/collegicoin/collegicoin-cli masternode genkey)

echo "Mining info..."
~/collegicoin/collegicoin-cli getmininginfo
~/collegicoin/collegicoin-cli stop

echo "Creating final config..."

cat <<EOF > ~/.collegicoincore/collegicoin.conf
rpcuser=collegicoin
rpcpassword=$PASSWORD
rpcallowip=127.0.0.1
server=1
daemon=1
listen=1
rpcport=${RPCPORT}
port=${PORT}
externalip=$WANIP
maxconnections=256
masternode=1
masternodeprivkey=$GENKEY
EOF

#echo "Setting basic security..."
#sudo apt-get install systemd -y
#sudo apt-get install fail2ban -y
#sudo apt-get install ufw -y
#sudo apt-get update -y

#fail2ban:
#sudo systemctl enable fail2ban
#sudo systemctl start fail2ban

#add a firewall
#sudo ufw default allow outgoing
#sudo ufw default deny incoming
#sudo ufw allow ssh/tcp
#sudo ufw limit ssh/tcp
sudo ufw allow 12033/tcp
sudo ufw allow 12033/tcp
#sudo ufw logging on
#sudo ufw status
#echo y | sudo ufw enable
#echo "Basic security completed..."

echo "Restarting wallet with new configs, 30 seconds..."
~/collegicoin/collegicoind -daemon
sleep 30

echo "Installing sentinel..."
cd /root/.collegicoincore
sudo apt-get install -y git python-virtualenv

sudo git clone https://github.com/collegicoin/collegicoin_sentinel.git

cd collegicoin_sentinel

export LC_ALL=C
sudo apt-get install -y virtualenv

virtualenv ./venv
./venv/bin/pip install -r requirements.txt

echo "collegicoin_conf=/root/.collegicoincore/collegicoin.conf" >> /root/.collegicoincore/collegicoin_sentinel/sentinel.conf

echo "Adding crontab jobs..."
crontab -l > tempcron
#echo new cron into cron file
echo "* * * * * cd /root/.collegicoincore/collegicoin_sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" >> tempcron
echo "@reboot /bin/sleep 20 ; /root/collegicoin/collegicoind -daemon &" >> tempcron

#install new cron file
crontab tempcron
rm tempcron

SENTINEL_DEBUG=1 ./venv/bin/python bin/sentinel.py
echo "Sentinel Installed"

echo "collegicoin-cli getmininginfo:"
~/collegicoin/collegicoin-cli getmininginfo

sleep 15

echo "Masternode status:"
~/collegicoin/collegicoin-cli masternode status

echo "If you get \"Masternode not in masternode list\" status, don't worry, you just have to start your MN from your local wallet and the status will change"
echo ""
echo "INSTALLED WITH VPS IP: $WANIP:$PORT"
sleep 1
echo "INSTALLED WITH MASTERNODE PRIVATE GENKEY: $GENKEY"
sleep 1
echo "rpcuser=collegicoin"
echo "rpcpassword=$PASSWORD"

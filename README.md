# LXC Manager

A tool for managing LXC containers and its networks, interfaces, napts, reverse proxies, snapshots and clones.

This tool is tested on Ubuntu 16.04 OS.
And tested LXC Containers are CentOS 6.X and RHEL 6.X.


## Installation

### Manager/Storage Server

#### Required Packages

- openssh-server
- build-essential
- lxc
- zfsutils-linux
- ruby
- ruby-dev
- yum
- samba
- sqlite3
- libsqlite3-dev
- nginx
- nfs-kernel-server
- nfs-common

#### Operations

Now let's start installing LXC Manager.

LXC Manager requires one or more network interfaces on both manager/storage server and hosting servers.
One is for access from external network and others are for internal communications between each servers.

```sh
sudo vi /etc/network/interfaces
```

For example /etc/network/interfaces is the following:

```
# The primary network interface
auto ens3
iface ens3 inet static
address xxx.xxx.xxx.xxx
network xxx.xxx.xxx.xxx
netmask xxx.xxx.xxx.xxx
broadcast xxx.xxx.xxx.xxx
gateway xxx.xxx.xxx.xxx
dns-nameservers xxx.xxx.xxx.xxx

# The additional network interface
auto ens4
iface ens4 inet static
address xxx.xxx.xxx.xxx
network xxx.xxx.xxx.xxx
netmask xxx.xxx.xxx.xxx
broadcast xxx.xxx.xxx.xxx
```

And update and upgrade repository and packages.

```sh
sudo apt update
sudo apt upgrade -y
```

To reflect to system the changes of network configurations and upgrading pckages, reboot your machine.

```sh
sudo shutdown -r now
```

Then, optionally, for ease of use, configure root's password and enable PermitRootLogin of OpenSSH Server

```sh
sudo passwd root
sudo sed -i -E 's/^PermitRootLogin .+/PermitRootLogin yes/' /etc/ssh/sshd_config
```

In inter-server communication, LXC Manager runs as root user and uses SSH protocal with no passphrase.
So make root user's ssh key with no passphrase.

```sh
sudo su -
ssh-keygen -t rsa
```

Remenber required packages are installed

```sh
apt install -y lxc build-essential zfsutils-linux ruby ruby-dev yum samba sqlite3 libsqlite3-dev nginx nfs-kernel-server nfs-common iptables-persistent
```

To use Ruby GEMs, LXC Manager uses bundler gem.

```sh
gem install bundler
```

LXC containers to external network communications are through manager/storage server with iptables MASQUARADE.
Saved iptables configurations are loaded every time when LXC Manager starts.

```sh
iptables -F
iptables -t nat -F
iptables -t nat -A POSTROUTING -s 10.255.0.0/16 -j MASQUERADE
netfilter-persistent save
```

And LXC Manager treat HTTP reverse proxy function using Nginx.
Remove default nginx configuration and enable nginx.

```sh
rm -f /etc/nginx/sites-available/default
systemctl start nginx
systemctl enable nginx
```

All LXC container files are on ZFS storage.
Create zpool named ext.
And to reduce storage usage, enable lz4 compression.

```sh
zpool create -f ext sdb
zpool create -f ext vdb
zfs set compression=lz4 ext
```

Then create each fs's/directories.

```sh
zfs create ext/lib
zfs create ext/pool
zfs create ext/pool/lxc
zfs create ext/pool/iso
zfs create ext/pool/distro
zfs create ext/pool/share
zfs create ext/export
```

LXC Manager servers use NFSv4 protocol to share LXC container files.
Create directories and start/enable NFSv4.

```sh
mkdir -p /ext/export/lxc
mkdir -p /ext/export/distro
echo '/ext/export 172.16.8.0/24(rw,no_root_squash,no_subtree_check,fsid=0)' | tee /etc/exports
systemctl start nfs-kernel-server
systemctl enable nfs-kernel-server
exportfs -ra
```

Optionally, to share files external users and LXC containers, enable samba protocol.

```sh
cat <<EOB | tee /etc/samba/smb.conf
[global]
  workgroup = LxcManager
  security = user
  load printers = no
  dns proxy = no

[share]
  path = /ext/pool/share
  valid users = root
  public = no
  guest ok = no
  writable = yes
  create mask = 0765
EOB
systemctl start smbd nmbd
systemctl enable smbd nmbd
pdbedit -a root
systemctl reload smbd
```

Now prepare LXC Manager tool.
You can get LXC Manager tool with git clone.

```sh
cd /ext/lib
git clone https://github.com/hirura/lxc-manager.git
```

First you must install gems required by lxc-manager.

```sh
cd /ext/lib/lxc-manager
bundle install
```

Then create LXC templates for CentOS 6.X and RHEL 6.X OS.

```sh
cd /ext/lib/lxc-manager/template
./make_templates.sh
```

LXC Manager's configurations are stored in lxc-manager/config directory.
You must copy setting.yml.sample to setting.yml and edit setting.yml for your environment.

```sh
cd /ext/lib/lxc-manager/
cp config/setting.yml.sample config/setting.yml
```

For example edit network interface name.

```sh
sed -i -e 's/^external_network_interface: eth0/external_network_interface: ens3/' config/setting.yml
sed -i -e 's/^internal_network_interface: eth0/internal_network_interface: ens4/' config/setting.yml
```

Before start LXC Manager, prepare DB.

```sh
./bin/init.sh
```

OK. Start LXC Manager.

```sh
./bin/run.sh start
```

Now you can access LXC Manager WEB user interface: http://xxx.xxx.xxx.xxx:port/


### LXC hosting Servers

#### Required Packages

- openssh-server
- lxc
- nfs-common

#### Operations

LXC Manager's hosting servers requires one or more network interfaces as well as manager/storage server.

```sh
sudo vi /etc/network/interfaces
```

For example /etc/network/interfaces is the following:

```
# The primary network interface
auto ens3
iface ens3 inet static
address xxx.xxx.xxx.xxx
network xxx.xxx.xxx.xxx
netmask xxx.xxx.xxx.xxx
broadcast xxx.xxx.xxx.xxx
gateway xxx.xxx.xxx.xxx
dns-nameservers xxx.xxx.xxx.xxx

# The additional network interface
auto ens4
iface ens4 inet static
address xxx.xxx.xxx.xxx
network xxx.xxx.xxx.xxx
netmask xxx.xxx.xxx.xxx
broadcast xxx.xxx.xxx.xxx
```

And update and upgrade repository and packages.

```sh
sudo apt update
sudo apt upgrade -y
```

To reflect to system the changes of network configurations and upgrading pckages, reboot your machine.

```sh
sudo shutdown -r now
```

Then, optionally, for ease of use, configure root's password and enable PermitRootLogin of OpenSSH Server

```sh
sudo passwd root
sudo sed -i -E 's/^PermitRootLogin .+/PermitRootLogin yes/' /etc/ssh/sshd_config
```

Manager server configures hosting servers as root user using SSH protocol with no passphrase.
Put manager server's id_rsa.pub information to hosting server root user's .ssh/authorized_keys file.

```sh
sudo su -
vi .ssh/authorized_keys
```

Remenber required packages are installed

```sh
apt install -y lxc nfs-common sysstat
```

To enable hosting servers, add host entry on LXC Manager WEB user interface.


## How to use

First, start LXC Manager.

```sh
/ext/lib/lxc-manager/bin/run.sh start
```

Now you can access to http://address:port/.

Default user and password is Adminitorator and Admin123.

Before creating and starting LXC containers, the following steps are required.

- Add user (optional)
- Add host
- Add disto
- Add network (optional)

### Add user

You can add more users to login to LXC Manager.
Note: Currently this users are used to controll login and logout only.

### Add host

Specify on which hosts LXC containers run.
The hosts are configured with abobe Installation steps.

### Add distro

To create LXC Container, LXC Manager uses CentOS 6.X or RHEL 6.X ISO images and LXC templates.
OS ISO images are stored in manager server's /ext/pool/iso directory by default.
LXC template files are generated in /ext/lib/lxc-manager/templates/ directory by default in installation steps.

### Add network

Management network is used to:

- communicate between manager server and LXC containers
- communicate between external network/hosts and LXC containers with IP Masquarade, NAPT or reverse proxy.

In addition you can create additional network for inter LXC container communication.

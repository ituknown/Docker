#!/bin/sh
#
# Note
# Nodejs install, gitbook install

# search epel resource
# if not set, will install and set it

rpmPackage=$(rpm -qa |grep epel)

if [ ! -n $rpmPackage ];then
  echo "have not set epel source, set..."
  echo -e "\nyum search epel"
  yum search epel
  echo -e "\nyum install epel"
  yum install -y epel-release
else
  echo -e "\n$rpmPackage"
fi

# search nodejs package

nodejsPackage=$(rpm -qa | grep nodejs)

if [ ! -n $nodejsPackage ];then
  echo -e "\nhave not install nodejs, install ..."
  echo "yum search nodejs"

  echo "yum install nodejs"
  yum install -y nodejs
else
  echo -e "\n$nodejsPackage"
fi

echo -e "\nnode -v"
node -v
echo "npm -v"
npm -v

# gitbook - install
#
# Determines whether gitbook it has been installed
# If alread install, uninstall it and re-install

gitbookPackage=$(rpm -qa | grep gitbook)

if [ ! -n $gitbookPackage ];then
  echo -e "\nnpm search gitbook"
  npm search gitbook
  echo -e "\nnpm install -g gitbook-cli"
else
  echo -e "\n$gitbookPackage"
  echo -e "\nuninstall it, and re-Install ..."
fi

# install gitbook
npm install -g gitbook-cli

echo -e "\ngitbook version and command"
gitbook -version
gitbook -help

echo -e "\ngitbook init"
gitbook init

echo -e"\nnow, gitbook install and init secceed, you can run rm.install.run.sh"
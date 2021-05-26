#!/bin/bash
# Check for root
function checkIAmRoot()
{
        if [ $(id -u) -ne 0 ]; then
                echo "Must be run as root. Try 'sudo bash install_puppet.sh' without quotes."
                exit 1
        fi
}
function installPLRepo()
{
case "`echo $VARIANT | awk '{print tolower($1)}'`" in
        fedora)
        # do nothing
        ;;
        *)
        yum install -y epel-release
        rpm -Uvh ${PL_REPO}
        yum clean all
        ;;
esac
}

PUPPET_PROJECT=https://github.com/kadern0/puppet-condor.git
PUPPET_LOCAL_DIR=/etc/puppet-code
VARIANT="`cat /etc/redhat-release | awk '{print tolower($1)}'`"
MAJOR_RELEASE="`cat /etc/redhat-release | grep -oE '[0-9].*' | awk '{print $1}' | cut -f1 -d '.'`"
PL_REPO=https://yum.puppet.com/puppet7-release-el-${MAJOR_RELEASE}.noarch.rpm

checkIAmRoot
yum -y install ruby wget git

installPLRepo
yum -y install puppet-agent
if [ $? -eq 0 ]; then
    /opt/puppetlabs/puppet/bin/gem install debouncer
    /opt/puppetlabs/puppet/bin/gem install vault
    rm -rf ${PUPPET_LOCAL_DIR}
    mkdir -p ${PUPPET_LOCAL_DIR}
    git clone ${PUPPET_PROJECT} ${PUPPET_LOCAL_DIR}
    (crontab -l | grep -v 'puppet apply' ) | crontab -
    (crontab -l 2>/dev/null; echo "*/30 * * * * git --git-dir=${PUPPET_LOCAL_DIR}/.git --work-tree=${PUPPET_LOCAL_DIR} pull && /opt/puppetlabs/puppet/bin/puppet apply --modulepath ${PUPPET_LOCAL_DIR}/modules --hiera_config ${PUPPET_LOCAL_DIR}/hiera.yaml ${PUPPET_LOCAL_DIR}/manifests/site.pp" ) | crontab -
else
    echo "error: Failed to install puppet"
    exit 1
fi

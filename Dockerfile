FROM centos:8
LABEL maintainer="Valentin Guerlesquin"
ENV container=docker

# Install systemd -- See https://hub.docker.com/_/centos/
RUN yum -y update; yum clean all; \
(cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

# Install requirements.
RUN yum -y update \
 && yum -y install \
      sudo \
      which \
      python3-pip \
      openssh-clients \
 && yum clean all

RUN ln -s /usr/bin/pip3 /usr/bin/pip 
RUN pip install --upgrade pip

# Install Ansible via Pip.
RUN pip install ansible

# Disable requiretty.
RUN sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/'  /etc/sudoers

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN echo -e '[local]\nlocalhost ansible_connection=local' > /etc/ansible/hosts


# setup ec2.py scripts and config
RUN curl https://raw.githubusercontent.com/ansible/ansible/stable-2.7/contrib/inventory/ec2.py -o $HOME_RUNNER/ec2.py \
    && mv $HOME_RUNNER/ec2.py /etc/ansible \
    && curl https://raw.githubusercontent.com/ansible/ansible/stable-2.7/contrib/inventory/ec2.ini -o $HOME_RUNNER/ec2.ini \
    && mv $HOME_RUNNER/ec2.ini /etc/ansible \
    && chmod +x /etc/ansible/ec2.py \
    && pip install boto \
    && sed -i '/destination_variable = /s/public_dns_name/private_dns_name/g' /etc/ansible/ec2.ini \
    && sed -i '/vpc_destination_variable = /s/ip_address/private_ip_address/g' /etc/ansible/ec2.ini

# create and modify ansible.cfg file to use AWS dynamic inventory as default
RUN touch /etc/ansible/ansible.cfg
RUN echo $'[defaults] \n\
inventory = /etc/ansible/ec2.py \n\
transport = ssh \n\
host_key_checking = False \n\
\n\
[ssh_connection]\n\
ssh_args = \n\
scp_if_ssh = True \n' >> /etc/ansible/ansible.cfg

# add docker-py
RUN pip install docker-py
# setup Ansible environment variables
ENV ANSIBLE_INVENTORY /etc/ansible/ec2.py
ENV EC2_INI_PATH /etc/ansible/ec2.ini

RUN mkdir /var/ssh

VOLUME ["/sys/fs/cgroup"]
CMD ["/usr/lib/systemd/systemd"]

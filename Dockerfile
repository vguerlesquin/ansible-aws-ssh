# Ansible version 2.7.0 on CentOS7
FROM docker.io/geerlingguy/docker-centos7-ansible

# ARG access_key_id
# ARG secret_access_key
#
# # setup AWS environment variables
# ENV AWS_ACCESS_KEY_ID=$access_key_id
# ENV AWS_SECRET_ACCESS_KEY=$secret_access_key
# ENV AWS_DEFAULT_REGION="ca-central-1"

# Install ssh client
RUN yum -y update && yum -y install openssh-clients

# Add key
# COPY ./mountebank.pem /root/.ssh/mountebank.pem
# RUN chmod 400 /root/.ssh/mountebank.pem

# setup boto credentials file
# RUN mkdir -p $HOME_RUNNER/.aws \
#     && touch $HOME_RUNNER/.aws/credentials
# RUN echo $'[default] \n\
# aws_access_key_id = '$AWS_ACCESS_KEY_ID$'\n\
# aws_secret_access_key = '$AWS_SECRET_ACCESS_KEY$'\n\
# region = '$AWS_DEFAULT_REGION$'\n' >> $HOME_RUNNER/.aws/credentials
RUN pip install --upgrade pip
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

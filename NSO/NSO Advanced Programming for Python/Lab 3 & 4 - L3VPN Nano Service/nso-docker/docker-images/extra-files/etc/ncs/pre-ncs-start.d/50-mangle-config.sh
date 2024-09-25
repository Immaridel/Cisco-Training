#!/bin/sh

SSH_PORT=${SSH_PORT:-22}
CONF_FILE=/etc/ncs/ncs.conf

# switch to local auth per default, allow to override through environment variable PAM
if [ "$PAM" != "true" ]; then
    xmlstarlet edit --inplace -N x=http://tail-f.com/yang/tailf-ncs-config \
               --update '/x:ncs-config/x:aaa/x:pam/x:enabled' --value 'false' \
               --update '/x:ncs-config/x:aaa/x:local-authentication/x:enabled' --value 'true' \
               $CONF_FILE
fi

# change SSH key dir and set host key algorithm
# In NSO 5.4 and later, there is no <ssh> node while in earlier versions, it
# already exists. We first wipe the <ssh> node to avoid creating a duplicate.
xmlstarlet edit --inplace -N x=http://tail-f.com/yang/tailf-ncs-config \
           --update '/x:ncs-config/x:aaa/x:ssh-server-key-dir' --value '/nso/ssh' \
           --delete '/x:ncs-config/x:ssh' \
           -s '/x:ncs-config' -t elem -n 'ssh' \
           -s '/x:ncs-config/ssh' -t elem -n 'algorithms' \
           -s '/x:ncs-config/ssh/algorithms' -t elem -n 'server-host-key' -v "ssh-rsa" \
           $CONF_FILE

# update ports for various protocols for which the default value in ncs.conf is
# different from the protocols default port (to allow starting ncs without root)
# NETCONF call-home is already on its default 4334 since that's above 1024
xmlstarlet edit --inplace -N x=http://tail-f.com/yang/tailf-ncs-config \
           --update '/x:ncs-config/x:cli/x:ssh/x:port' --value "${SSH_PORT}" \
           --update '/x:ncs-config/x:webui/x:transport/x:tcp/x:port' --value '80' \
           --update '/x:ncs-config/x:webui/x:transport/x:ssl/x:port' --value '443' \
           --update '/x:ncs-config/x:netconf-north-bound/x:transport/x:ssh/x:port' --value '830' \
           $CONF_FILE

# enable SSH CLI, NETCONF over SSH northbound and NETCONF call-home
xmlstarlet edit --inplace -N x=http://tail-f.com/yang/tailf-ncs-config \
           --update '/x:ncs-config/x:cli/x:ssh/x:enabled' --value 'true' \
           --update '/x:ncs-config/x:netconf-north-bound/x:transport/x:ssh/x:enabled' --value 'true' \
           --update '/x:ncs-config/x:netconf-call-home/x:enabled' --value 'true' \
           $CONF_FILE

# conditionally enable webUI with no TLS on port 80
if [ "$HTTP_ENABLE" == "true" ]; then
    xmlstarlet edit --inplace -N x=http://tail-f.com/yang/tailf-ncs-config \
               --update '/x:ncs-config/x:webui/x:transport/x:tcp/x:enabled' --value 'true' \
               $CONF_FILE
fi

# conditionally enable webUI with TLS on port 443
if [ "$HTTPS_ENABLE" == "true" ]; then
    xmlstarlet edit --inplace -N x=http://tail-f.com/yang/tailf-ncs-config \
               --update '/x:ncs-config/x:webui/x:transport/x:ssl/x:enabled' --value 'true' \
               --update '/x:ncs-config/x:webui/x:transport/x:ssl/x:key-file' --value '/nso/ssl/cert/host.key' \
               --update '/x:ncs-config/x:webui/x:transport/x:ssl/x:cert-file' --value '/nso/ssl/cert/host.cert' \
               $CONF_FILE
fi

# enable unhiding the two common groups 'debug' and 'full'
# This might be a little trickier to understand - we first add two new subnodes
# (-s option) under /ncs-config. They will just be placed at the end, then we
# fill them in by creating the name node in each and setting its value. The
# result looks like:
#
#     ...
#     <hide-group>
#       <name>debug</name>
#     </hide-group>
#     <hide-group>
#       <name>full</name>
#     </hide-group>
#   </ncs-config>
xmlstarlet edit --inplace -N x=http://tail-f.com/yang/tailf-ncs-config \
           -s '/x:ncs-config' -t elem -n hide-group \
           -s '/x:ncs-config' -t elem -n hide-group \
           -s '/x:ncs-config/hide-group[1]' -t elem -n name -v debug \
           -s '/x:ncs-config/hide-group[2]' -t elem -n name -v full \
           $CONF_FILE
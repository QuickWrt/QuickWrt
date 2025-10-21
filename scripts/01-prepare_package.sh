#!/bin/bash -e

# Replace package
rm -rf feeds/packages/net/{xray-core,v2ray-core,v2ray-geodata,sing-box,samba4,miniupnpd,aria2,nginx}
rm -rf feeds/luci/applications/{luci-app-sqm,luci-app-upnp,luci-app-dockerman,luci-app-aria2}
rm -rf feeds/packages/utils/{unzip,docker,dockerd,containerd,runc,coremark}
rm -rf feeds/packages/lang/{node,golang}

# golang 1.25
git clone https://github.com/sbwml/packages_lang_golang -b 25.x feeds/packages/lang/golang

# node - prebuilt
git clone https://github.com/sbwml/feeds_packages_lang_node-prebuilt feeds/packages/lang/node -b packages-24.10

# quickwrt packages
git clone https://github.com/QuickWrt/openwrt_packages package/new/openwrt_packages

# SSRP & Passwall
git clone https://github.com/QuickWrt/openwrt_helloworld package/new/openwrt_helloworld

# luci-app-sqm
git clone https://git.cooluc.com/sbwml/luci-app-sqm feeds/luci/applications/luci-app-sqm

# unzip
git clone https://github.com/sbwml/feeds_packages_utils_unzip feeds/packages/utils/unzip

# UPnP
git clone https://git.cooluc.com/sbwml/miniupnpd feeds/packages/net/miniupnpd -b v2.3.9
git clone https://git.cooluc.com/sbwml/luci-app-upnp feeds/luci/applications/luci-app-upnp -b openwrt-24.10

# Docker
git clone https://git.cooluc.com/sbwml/luci-app-dockerman -b openwrt-24.10 feeds/luci/applications/luci-app-dockerman
git clone https://github.com/sbwml/packages_utils_docker feeds/packages/utils/docker
git clone https://github.com/sbwml/packages_utils_dockerd feeds/packages/utils/dockerd
git clone https://github.com/sbwml/packages_utils_containerd feeds/packages/utils/containerd
git clone https://github.com/sbwml/packages_utils_runc feeds/packages/utils/runc

# aria2 & ariaNG
git clone https://github.com/sbwml/ariang-nginx package/new/ariang-nginx
git clone https://github.com/sbwml/feeds_packages_net_aria2 -b 22.03 feeds/packages/net/aria2

# ddns - fix boot
sed -i '/boot()/,+2d' feeds/packages/net/ddns-scripts/files/etc/init.d/ddns

# Use nginx instead of uhttpd
sed -i 's/+uhttpd /+luci-nginx /g' feeds/luci/collections/luci/Makefile
sed -i 's/+uhttpd-mod-ubus //' feeds/luci/collections/luci/Makefile
sed -i 's/+uhttpd /+luci-nginx /g' feeds/luci/collections/luci-light/Makefile
sed -i "s/+luci /+luci-nginx /g" feeds/luci/collections/luci-ssl-openssl/Makefile
sed -i "s/+luci /+luci-nginx /g" feeds/luci/collections/luci-ssl/Makefile
sed -i 's/+uhttpd +uhttpd-mod-ubus /+luci-nginx /g' feeds/packages/net/wg-installer/Makefile
sed -i '/uhttpd-mod-ubus/d' feeds/luci/collections/luci-light/Makefile
sed -i 's/+luci-nginx \\$/+luci-nginx/' feeds/luci/collections/luci-light/Makefile

# nginx - latest version
git clone https://github.com/sbwml/feeds_packages_net_nginx feeds/packages/net/nginx -b openwrt-24.10
sed -i 's/procd_set_param stdout 1/procd_set_param stdout 0/g;s/procd_set_param stderr 1/procd_set_param stderr 0/g' feeds/packages/net/nginx/files/nginx.init

# nginx - ubus
sed -i 's/ubus_parallel_req 2/ubus_parallel_req 6/g' feeds/packages/net/nginx/files-luci-support/60_nginx-luci-support
sed -i '/ubus_parallel_req/a\        ubus_script_timeout 300;' feeds/packages/net/nginx/files-luci-support/60_nginx-luci-support

# nginx - config
cp -rf ../OpenBox/doc/nginx/luci.locations ./feeds/packages/net/nginx/files-luci-support/
cp -rf ../OpenBox/doc/nginx/uci.conf.template ./feeds/packages/net/nginx-util/files/

# uwsgi - fix timeout
sed -i '$a cgi-timeout = 600' feeds/packages/net/uwsgi/files-luci-support/luci-*.ini
sed -i '/limit-as/c\limit-as = 5000' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
# disable error log
sed -i "s/procd_set_param stderr 1/procd_set_param stderr 0/g" feeds/packages/net/uwsgi/files/uwsgi.init

# uwsgi - performance
sed -i 's/threads = 1/threads = 2/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i 's/processes = 3/processes = 4/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i 's/cheaper = 1/cheaper = 2/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini

# rpcd - fix timeout
sed -i 's/option timeout 30/option timeout 60/g' package/system/rpcd/files/rpcd.config
sed -i 's#20) \* 1000#60) \* 1000#g' feeds/luci/modules/luci-base/htdocs/luci-static/resources/rpc.js

# frpc
sed -i 's/procd_set_param stdout $stdout/procd_set_param stdout 0/g' feeds/packages/net/frp/files/frpc.init
sed -i 's/procd_set_param stderr $stderr/procd_set_param stderr 0/g' feeds/packages/net/frp/files/frpc.init
sed -i 's/stdout stderr //g' feeds/packages/net/frp/files/frpc.init
sed -i '/stdout:bool/d;/stderr:bool/d' feeds/packages/net/frp/files/frpc.init
sed -i '/stdout/d;/stderr/d' feeds/packages/net/frp/files/frpc.config
sed -i 's/env conf_inc/env conf_inc enable/g' feeds/packages/net/frp/files/frpc.init
sed -i "s/'conf_inc:list(string)'/& \\\\/" feeds/packages/net/frp/files/frpc.init
sed -i "/conf_inc:list/a\\\t\t\'enable:bool:0\'" feeds/packages/net/frp/files/frpc.init
sed -i '/procd_open_instance/i\\t\[ "$enable" -ne 1 \] \&\& return 1\n' feeds/packages/net/frp/files/frpc.init
patch -p1 < ../OpenBox/luci/applications/luci-app-frpc/001-luci-app-frpc-hide-token.patch
patch -p1 < ../OpenBox/luci/applications/luci-app-frpc/002-luci-app-frpc-add-enable-flag.patch

# natmap
sed -i 's/log_stdout:bool:1/log_stdout:bool:0/g;s/log_stderr:bool:1/log_stderr:bool:0/g' feeds/packages/net/natmap/files/natmap.init
pushd feeds/luci
patch -p1 <../../../OpenBox/luci/applications/luci-app-natmap/0001-luci-app-natmap-add-default-STUN-server-lists.patch
popd

# samba4 - bump version
git clone https://github.com/sbwml/feeds_packages_net_samba4 feeds/packages/net/samba4
# enable multi-channel
sed -i '/workgroup/a \\n\t## enable multi-channel' feeds/packages/net/samba4/files/smb.conf.template
sed -i '/enable multi-channel/a \\tserver multi channel support = yes' feeds/packages/net/samba4/files/smb.conf.template
# default config
sed -i 's/#aio read size = 0/aio read size = 0/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/#aio write size = 0/aio write size = 0/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/invalid users = root/#invalid users = root/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/bind interfaces only = yes/bind interfaces only = no/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/#create mask/create mask/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/#directory mask/directory mask/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/0666/0644/g;s/0744/0755/g;s/0777/0755/g' feeds/luci/applications/luci-app-samba4/htdocs/luci-static/resources/view/samba4.js
sed -i 's/0666/0644/g;s/0777/0755/g' feeds/packages/net/samba4/files/samba.config
sed -i 's/0666/0644/g;s/0777/0755/g' feeds/packages/net/samba4/files/smb.conf.template

# iperf3
sed -i "s/D_GNU_SOURCE/D_GNU_SOURCE -funroll-loops/g" feeds/packages/net/iperf3/Makefile

# luci-compat - fix translation
sed -i 's/<%:Up%>/<%:Move up%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm
sed -i 's/<%:Down%>/<%:Move down%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm

# frpc translation
sed -i 's,发送,Transmission,g' feeds/luci/applications/luci-app-transmission/po/zh_Hans/transmission.po
sed -i 's,frp 服务器,Frp 服务器,g' feeds/luci/applications/luci-app-frps/po/zh_Hans/frps.po
sed -i 's,frp 客户端,Frp 客户端,g' feeds/luci/applications/luci-app-frpc/po/zh_Hans/frpc.po

#!/bin/sh

for os in centos64 centos65 centos66 centos67 centos68
do
	cat lxc-centos.in \
		| sed -E "s/@LXCPATH@/\/usr\/local\/share\/lxc\/config/g" \
		| sed -E "s/@LXCTEMPLATECONFIG@/\/ext\/lxcpool\/lxc/g" \
		| sed -E "s/@LOCALSTATEDIR@/\/var/g" \
		| sed -E "s/__CENTOS_HOST_VER__/6/" \
		| sed -E "s/__IS_CENTOS__/true/" \
		| sed -E "s/__REDHAT_HOST_VER__//" \
		| sed -E "s/__IS_REDHAT__//" \
		| sed -E "s/YUM0=\"yum/YUM0=\"yum -d 1/g" \
		> lxc-${os}
	chmod +x lxc-${os}
done

for os in rhel64 rhel65 rhel66 rhel67 rhel68
do
	cat lxc-rhel.in \
		| sed -E "s/@LXCPATH@/\/usr\/local\/share\/lxc\/config/g" \
		| sed -E "s/@LXCTEMPLATECONFIG@/\/ext\/lxcpool\/lxc/g" \
		| sed -E "s/@LOCALSTATEDIR@/\/var/g" \
		| sed -E "s/__CENTOS_HOST_VER__//" \
		| sed -E "s/__IS_CENTOS__//" \
		| sed -E "s/__REDHAT_HOST_VER__/6/" \
		| sed -E "s/__IS_REDHAT__/true/" \
		| sed -E "s/YUM0=\"yum/YUM0=\"yum -d 1/g" \
		> lxc-${os}
	chmod +x lxc-${os}
done

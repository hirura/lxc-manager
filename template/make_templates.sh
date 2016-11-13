#!/bin/sh

for os in centos64 centos65 centos66 centos67 centos68
do
	cat lxc-centos.in \
		| sed -E "s/@LXCPATH@/\/usr\/local\/share\/lxc\/config/g" \
		| sed -E "s/@LXCTEMPLATECONFIG@/\/ext\/lxcpool\/lxc/g" \
		| sed -E "s/@LOCALSTATEDIR@/\/var/g" \
		| sed -E "s/__RELEASE__/6/" \
		| sed -E "s/YUM0=\"yum/YUM0=\"yum -d 1/g" \
		> lxc-${os}
	chmod +x lxc-${os}
done

for os in centos70 centos71 centos72
do
	cat lxc-centos.in \
		| sed -E "s/@LXCPATH@/\/usr\/local\/share\/lxc\/config/g" \
		| sed -E "s/@LXCTEMPLATECONFIG@/\/ext\/lxcpool\/lxc/g" \
		| sed -E "s/@LOCALSTATEDIR@/\/var/g" \
		| sed -E "s/__RELEASE__/7/" \
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
		| sed -E "s/__RELEASE__/6/" \
		| sed -E "s/YUM0=\"yum/YUM0=\"yum -d 1/g" \
		> lxc-${os}
	chmod +x lxc-${os}
done

for os in rhel70 rhel71 rhel72
do
	cat lxc-rhel.in \
		| sed -E "s/@LXCPATH@/\/usr\/local\/share\/lxc\/config/g" \
		| sed -E "s/@LXCTEMPLATECONFIG@/\/ext\/lxcpool\/lxc/g" \
		| sed -E "s/@LOCALSTATEDIR@/\/var/g" \
		| sed -E "s/__RELEASE__/7/" \
		| sed -E "s/YUM0=\"yum/YUM0=\"yum -d 1/g" \
		> lxc-${os}
	chmod +x lxc-${os}
done

for os in ubuntu1604
do
	cat lxc-ubuntu.in \
		| sed -E "s/@LXCPATH@/\/usr\/local\/share\/lxc\/config/g" \
		| sed -E "s/@LXCTEMPLATECONFIG@/\/ext\/lxcpool\/lxc/g" \
		| sed -E "s/@LOCALSTATEDIR@/\/var/g" \
		| sed -E "s/__RELEASE__/xenial/" \
		| sed -E "s/YUM0=\"yum/YUM0=\"yum -d 1/g" \
		> lxc-${os}
	chmod +x lxc-${os}
done

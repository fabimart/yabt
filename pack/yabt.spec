Name:		yabt
Version:	0.1
Release:	1%{?dist}
Summary:	Yet Another Backup Tool

Group:		Applications/Databases
License:	GPLv3
BuildArch:	noarch
SOURCE0:	%{name}.sh
SOURCE1:	%{name}-mysql.sh
SOURCE2:	%{name}-mysql.conf
SOURCE3:	%{name}-openldap.sh
SOURCE4:	%{name}-openldap.conf
SOURCE5:	%{name}-postgresql.sh
SOURCE6:	%{name}-postgresql.conf
SOURCE7:	LICENSE
SOURCE8:	README.md
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

%description
Core components of YABT, used by your plugins
YABT realiza o backup de um banco de dados database-a-database, e atualiza na pasta de backups apenas os databases que foram modificados.

%package	mysql
Requires:	%{name} = %{version}-%{release}
Requires:	mysql
Summary:	MySQL plugin for YABT

%description	mysql
Implementa o backupeamento YABT em MySQL

%package	openldap
Requires:	%{name} = %{version}-%{release}
Requires:	openldap-servers
Summary:	OpenLDAP plugin for YABT

%description	openldap
Implementa o backupeamento YABT em OpenLDAP

%package	postgresql
Requires:	%{name} = %{version}-%{release}
Requires:	postgresql
Summary:	PostgreSQL plugin for YABT

%description	postgresql
Implementa o backupeamento YABT em PostgreSQL

%prep
%setup -q -c -T

%build
install -pm 0644 %{SOURCE7} .
install -pm 0644 %{SOURCE8} .

%install
rm -rf %{buildroot}

install -dm 0755 %{buildroot}%{_bindir}
install -pm 0644 "%{SOURCE0}" %{buildroot}%{_bindir}/
install -pm 0755 "%{SOURCE1}" %{buildroot}%{_bindir}/
install -pm 0755 "%{SOURCE3}" %{buildroot}%{_bindir}/
install -pm 0755 "%{SOURCE5}" %{buildroot}%{_bindir}/

install -dm 0755 %{buildroot}%{_sysconfdir}/%{name}
install -pm 0644 %{SOURCE2} %{buildroot}%{_sysconfdir}/%{name}/
install -pm 0644 %{SOURCE4} %{buildroot}%{_sysconfdir}/%{name}/
install -pm 0644 %{SOURCE6} %{buildroot}%{_sysconfdir}/%{name}/

install	-dm 0755 %{buildroot}%{_localstatedir}/lib/%{name}/mysql
install	-dm 0755 %{buildroot}%{_localstatedir}/lib/%{name}/openldap
install	-dm 0755 %{buildroot}%{_localstatedir}/lib/%{name}/postgresql

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}.sh
%dir	%{_localstatedir}/lib/%{name}
%doc	README.md LICENSE

%files mysql
%defattr(-,root,root,-)
%{_bindir}/%{name}-mysql.sh
%config(noreplace) %{_sysconfdir}/%{name}/%{name}-mysql.conf
%dir	%{_localstatedir}/lib/%{name}/mysql

%files openldap
%defattr(-,root,root,-)
%{_bindir}/%{name}-openldap.sh
%config(noreplace) %{_sysconfdir}/%{name}/%{name}-openldap.conf
%dir	%{_localstatedir}/lib/%{name}/openldap

%files postgresql
%defattr(-,root,root,-)
%{_bindir}/%{name}-postgresql.sh
%config(noreplace) %{_sysconfdir}/%{name}/%{name}-postgresql.conf
%dir	%{_localstatedir}/lib/%{name}/postgresql

%changelog
* Thu Jul 10 2014 Fabiano Martins <fabiano.martins@trt4.jus.br> - 0.1-1
- initial version

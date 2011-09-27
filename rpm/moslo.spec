Summary: 	MeeGo OS Loader for Harmattan
Name: 		moslo
Version: 	0.0.13
Release: 	0

Group: 		System Environment/Base

Source: 	%{name}-%{version}.tar.gz
BuildRoot:	%{_tmppath}/%{name}-%{version}-buildroot
BuildRequires:  modutils
BuildRequires:  busybox
BuildRequires:  kernel-moslo
BuildRequires:	alsa-lib
BuildRequires:	dbus
BuildRequires:	libnl
BuildRequires:  kexec-tools
BuildRequires:  bme
# This name might be changed?
BuildRequires:  text2screen

License: 	GPL

%description
Utility that creates an image which is used to
start Harmattan based devices

%prep

%setup -q -n %{name}

%build
export KERNEL_VERSION=$(ls /lib/modules)
export VERSION=HARMATTAN_MOSLO_%{version}
export B_NAME=%{name}
echo %{version}-%{release} > etc/moslo-version
make

%install
export B_NAME=%{name}
make install DESTDIR=%{buildroot}/usr/share/nokia
#install -m 644 ./rootfs.cpio.gz %{buildroot}/usr/share/nokia/%{name}/
install -m 644 ./rootfs.tar %{buildroot}/usr/share/nokia/%{name}/

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root)
/usr/share/nokia/%{name}/rootfs.tar


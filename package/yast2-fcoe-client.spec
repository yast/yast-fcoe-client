#
# spec file for package yast2-fcoe-client
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-fcoe-client
Version:        3.1.3
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:          System/YaST
License:        GPL-2.0
Requires:	yast2 >= 2.21.22
Requires:       fcoe-utils
BuildRequires:	perl-XML-Writer update-desktop-files yast2 yast2-testsuite
BuildRequires:  yast2-devtools >= 3.1.10
BuildRequires:  rubygem-rspec

BuildArchitectures:	noarch

Requires:       yast2-ruby-bindings >= 1.0.0

Summary:	YaST2 - Configuration of Fibre Channel over Ethernet

%description
This package contains the YaST2 component for the Fibre Channel over
Ethernet (FCoE) configuration.

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install


%files
%defattr(-,root,root)
%dir %{yast_yncludedir}/fcoe-client
%{yast_yncludedir}/fcoe-client/*
%{yast_clientdir}/fcoe-client.rb
%{yast_clientdir}/fcoe-client_*.rb
%{yast_clientdir}/inst_fcoe-client.rb
%{yast_moduledir}/FcoeClient.*
%{yast_desktopdir}/fcoe-client.desktop
%dir %{yast_scrconfdir}
%{yast_scrconfdir}/*.scr
%doc %{yast_docdir}
%doc COPYING

%changelog


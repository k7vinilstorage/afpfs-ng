#!/usr/bin/env bash

set -euo pipefail

readonly pkg_name="afpfs-ng"
declare pkg_version  # Will be derived from commit below.
readonly repo_commit="f6e24eb73c9283732c3b5d9cb101a1e2e4fade3e"
readonly pkg_revision="2"

readonly pkg_desc="Client for the Apple Filing Protocol"
readonly pkg_license="GPLv3"
readonly pkg_url="https://github.com/simonvetter/afpfs-ng"
readonly pkg_maintainer="Rafael Cavalcanti <dev@rafaelc.org>"
readonly pkg_requires="fuse"
readonly pkg_build_requires="gcc make fuse-devel readline-devel libgcrypt-devel"

readonly repo_url="https://github.com/simonvetter/afpfs-ng"
readonly repo_dir="/app/repo"
readonly rpmbuild_dir="/app/rpmbuild"
readonly src_dir="/app/src"
readonly dist_dir="/app/dist"


main() {
  prepare
  apply_patches
  make_source_tarball
  write_spec
  build_rpm
}

prepare() {
  mkdir -p "$repo_dir"
  if [[ ! -d "$repo_dir"/.git ]]; then
    git clone --depth=1 "$repo_url" "$repo_dir"
  fi

  cd "$repo_dir"
  git checkout "$repo_commit"

  pkg_version="$(grep -oP 'AC_INIT\(\[?afpfs-ng\]?,\s*\[?\K[0-9.]+' configure.ac)"
}

apply_patches() {
  cd "$repo_dir"
  for patch in /app/patches/*.patch; do
    patch -p0 < "$patch" || true
  done
}

make_source_tarball() {
  local -r tarball_root="${pkg_name}-${pkg_version}"
  local -r work_dir="$src_dir/$tarball_root"

  rm -rf "$src_dir"
  mkdir -p "$work_dir" "$rpmbuild_dir/SOURCES"

  cp -a "$repo_dir"/. "$work_dir/"
  rm -rf "$work_dir/.git"

  tar czf "$rpmbuild_dir/SOURCES/${tarball_root}.tar.gz" -C "$src_dir" "$tarball_root"
}

write_spec() {
  mkdir -p "$rpmbuild_dir/SPECS"

  cat > "$rpmbuild_dir/SPECS/${pkg_name}.spec" <<EOF
Name:           $pkg_name
Version:        $pkg_version
Release:        ${pkg_revision}%{?dist}
Summary:        $pkg_desc

License:        $pkg_license
URL:            $pkg_url
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  $pkg_build_requires
Requires:       $pkg_requires

%description
$pkg_desc

%prep
%setup -q

%build
# Upstream uses old K&R-style function definitions, which newer GCC
# rejects under the C23 default (-std=gnu23), plus a few implicit
# declarations / pointer-type mismatches that Fedora's default flags
# promote to hard errors. Relax those to keep the old codebase building.
%configure CFLAGS="%{optflags} -std=gnu17 -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types"
%make_build

%install
%make_install
# Fedora's post-install policy scripts (brp-*) delete libtool archives
# and gzip man pages *after* %%install runs, so do it here too -
# otherwise our generated file list below goes stale before %%files
# is evaluated.
find %{buildroot} -name '*.la' -delete
find %{buildroot}%{_mandir} -type f ! -name '*.gz' -exec gzip -9 -n {} \;
find %{buildroot} \( -type f -o -type l \) | sed -e "s|^%{buildroot}||" > %{_builddir}/%{name}-%{version}/filelist.txt

%files -f %{_builddir}/%{name}-%{version}/filelist.txt

%changelog
* $(LC_TIME=C date '+%a %b %d %Y') $pkg_maintainer - ${pkg_version}-${pkg_revision}
- Automated build from upstream commit $repo_commit
EOF
}

build_rpm() {
  mkdir -p "$dist_dir"

  rpmbuild \
    --define "_topdir $rpmbuild_dir" \
    -bb "$rpmbuild_dir/SPECS/${pkg_name}.spec"

  find "$rpmbuild_dir/RPMS" -name '*.rpm' -exec cp -a {} "$dist_dir/" \;
}

main "$@"

#!/bin/sh

relative_script_dir=${0%/*}
cd $relative_script_dir
script_path=$(pwd)

[ -z "$1" ] && echo "provide a version to build" && exit 1
build_version="$1"

target_root=$script_path/dist
[ -e $target_root ] && rm -r $target_root
mkdir $target_root

package_root="$target_root/blubee"
mkdir $package_root

create_file_tree() {
    root="$1"
    version="$2"
    conf_files="$3"
    launcher="$4"

    bin_dir="$root/usr/local/bin"
    mkdir -p $bin_dir
    cp $launcher $bin_dir/blubee
    chown -R root:root "$bin_dir"

    conf_dir="$root/etc/blubee"
    mkdir -p $conf_dir
    cp $conf_files $conf_dir/
    chown -R root:root "$conf_dir"

    echo "$conf_dir $bin_dir"
}

set_info_version() {
    version="$1"
    info_dir="$2"

    sed -i -e "s/Version: -/Version: $version/" -e "s/Build: -/Build: $(git log -n1 --format=format:"%h")/" $info_dir/blubee.info
}

build_debian() {
    root="$1"
    target="$2"
    version="$3"

    distro_dir="$root/DEBIAN"
    mkdir $distro_dir

    debian_dir="package/debian"

    sed "s/Version: -/Version: $version/" $debian_dir/control > $distro_dir/control

    cp $debian_dir/conffiles $debian_dir/postinst $debian_dir/postrm $distro_dir

    dpkg -b $root $target/blubee_${version}_all.deb
}

build_tar() {
    root="$1"
    target="$2"
    version="$3"

    original_dir="$(pwd)"
    cd $root
    tar cvzf $target/blubee_${version}_all.tar.gz etc/ usr/
    cd $original_dir
}

build_arch() {
    root="$1"
    target="$2"
    version="$3"
    conf_files="$4"
    launcher="$5"

    target_name="blubee_${version}_all_aur"
    target_dir="$target/$target_name"
    mkdir $target_dir

    cp $conf_files "$target_dir"
    cp $launcher "$target_dir"

    set_info_version "$version" "$target_dir"

    files="$conf_files $launcher"
    sha256sums=""
    for file in $files; do
        [ -f "$target_dir/$file" ] || continue
        sha256sums="${sha256sums} '$(sha256sum "$target_dir/$file" | cut -d' ' -f1)'"
    done
    sha256sums="${sha256sums#?}"

    arch_dir="package/arch"
    sed -e "s/pkgver=-/pkgver=$version/" \
        -e "s/sha256sums=(-)/sha256sums=($sha256sums)/" \
        -e "s/source=(-)/source=($files)/" \
        $arch_dir/PKGBUILD > $target_dir/PKGBUILD
    sed -i -e "/sha256sums=(/ s/ /\n            /g" \
        -e "/source=(/ s/ /\n        /g" $target_dir/PKGBUILD

    cp $arch_dir/blubee.install $target_dir

    original_dir="$(pwd)"
    cd $target
    tar cvzf $target/$target_name.tar.gz $target_name
    cd $original_dir
}

config_files="blubee backup.sh restore.sh json_utils.sh string_utils.sh file_utils.sh debug.sh blubee.info blubee.conf"
launch_file="launcher"
dirs=$(create_file_tree "$package_root" "$build_version" "$config_files" "$launch_file")
conf_dir=$(echo "$dirs" | cut -d' ' -f1)

set_info_version "$build_version" "$conf_dir"

build_debian "$package_root" "$target_root" "$build_version"
build_tar "$package_root" "$target_root" "$build_version"
build_arch "$package_root" "$target_root" "$build_version" "$config_files" "$launch_file"


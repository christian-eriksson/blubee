#!/bin/sh

relative_script_dir=${0%/*}
cd $relative_script_dir
script_path=$(pwd)

[ -z "$1" ] && echo "provide a version to build" && exit 1
version="$1"

target_root=$script_path/dist
[ -e $target_root ] && rm -r $target_root
mkdir $target_root

package_root="$target_root/blubee"
mkdir $package_root

bin_dir="$package_root/usr/local/bin"
mkdir -p $bin_dir

conf_dir="$package_root/etc/blubee"
mkdir -p $conf_dir

distro_dir="$package_root/DEBIAN"
mkdir $distro_dir

cp launcher $bin_dir/blubee

cp blubee backup.sh restore.sh blubee.conf json_utils.sh string_utils.sh file_utils.sh $conf_dir/

sed -e "s/Version: -/Version: $version/" -e "s/Build: -/Build: $(git log -n1 --format=format:"%h")/" blubee.info > $conf_dir/blubee.info

sed "s/Version: -/Version: $version/" package/control > $distro_dir/control

cp package/conffiles package/postinst package/postrm $distro_dir

chown -R root:root "$bin_dir"
chown -R root:root "$conf_dir"

dpkg -b $package_root $target_root/blubee_${version}_all.deb

cd $package_root
tar cvzf $target_root/blubee_${version}_all.tar.gz etc/ usr/


# == MY ARCH SETUP INSTALLER == #
#part1
printf '\033c'
echo "Welcome to The Install Script"
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 5/" /etc/pacman.conf
pacman --noconfirm -Sy archlinux-keyring
loadkeys us
timedatectl set-ntp true
lsblk
echo "Enter the drive: format /dev/drive"
read drive
cfdisk $drive 
echo "Enter the linux partition: "
read partition
mkfs.ext4 $partition 
echo "Enter EFI partition: "
read efipartition
mkfs.vfat -F 32 $efipartition
mkdir /mnt
mount $partition /mnt
mkdir /mnt/boot/
mount $efipartition /mnt/boot
read -p "Intel Or Amd CPU?[i/a]" answer
if [[ $answer = i ]] ; then
  pacstrap /mnt base base-devel linux linux-firmware intel-ucode
else
  pacstrap /mnt base base-devel linux linux-firmware amd-ucode
fi
echo 'registering patitions in fstab and starting second script'
genfstab -U /mnt >> /mnt/etc/fstab
sed '1,/^#part2$/d' `basename $0` > /mnt/arch_install2.sh
chmod +x /mnt/arch_install2.sh
arch-chroot /mnt ./arch_install2.sh
exit 

#part2
printf '\033c'
pacman -S --noconfirm sed
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 5/" /etc/pacman.conf
pacman -Sy
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
echo "Hostname: "
read hostname
echo $hostname > /etc/hostname
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       $hostname.localdomain $hostname" >> /etc/hosts
mkinitcpio -P
passwd
pacman --noconfirm -S grub efibootmgr os-prober
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
# sed -i 's/quiet/pci=noaer/g' /etc/default/grub
# sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g ' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

pacman -Sy --noconfirm xorg-server xorg-xinit xorg-xkill xorg-xsetroot xorg-xbacklight xorg-xprop \
     noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-jetbrains-mono ttf-joypixels ttf-font-awesome \
     mpv ffmpeg imagemagick  \
     fzf xclip maim openssh \
     zip unzip unrar p7zip xdotool papirus-icon-theme brightnessctl  \
     dosfstools ntfs-3g git zsh pipewire pipewire-pulse pipewire-jack \
     neovim vim nano rsync dash \
     xcompmgr libnotify slock jq aria2 cowsay \
     dhcpcd connman wpa_supplicant rsync pamixer mpd ncmpcpp \
     zsh-syntax-highlighting xdg-user-dirs libconfig \
     bluez bluez-utils wget plasma alacritty nemo firefox flatpak 
#chaotic-aur

pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
pacman-key --lsign-key FBA220DFC880C036
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

systemctl enable connman.service 
rm /bin/sh
ln -s dash /bin/sh
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
echo "Enter Username: "
read username
useradd -m -G wheel -s /bin/zsh $username
passwd $username
echo "Pre-Installation Finish Reboot now"
ai3_path=/home/$username/arch_install3.sh
sed '1,/^#part3$/d' arch_install2.sh > $ai3_path
chown $username:$username $ai3_path
chmod +x $ai3_path
su -c $ai3_path -s /bin/sh $username
exit 

#part3
printf '\033c'
su - akshayk
cd /home/akshayk

echo "Installing AUR helper"
# paru: AUR helper
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -fsri
cd

#Display Manager
paru -Syy ly
sudo systemctl enable ly.service

sudo sed -i "/^ExecStart/i ExecStartPre=/usr/bin/printf '%%b' '\\\\e]P0969FD4\\\\e]P7364B45\\\\ec'" /lib/systemd/system/ly.service


git clone --bare https://github.com/Kallz02/dotfiles.git ~/dotfiles
alias dt='git --git-dir=$HOME/dotfiles --work-tree=$HOME'
dt checkout -f

dt config --local status.showUntrackedFiles no
echo "Using local pacman.conf and creating a symlink"
sudo cp /etc/pacman.conf /etc/pacman.conf2
sudo rm /etc/pacman.conf
sudo ln -s ~/pacman.conf /etc/pacman.conf

xhost + local: #for wayland and xdisplay stuff
echo "Final Grub Configuration based on local files"
sudo cp /etc/default/grub /etc/default/grub.1
sudo rm /etc/default/grub
sudo ln -s ~/grub /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

paru -Sy
paru -Sy --needed - < "/home/akshayk/packagelist.txt"
#Some Flatpak Stuff
flatpak install org.onlyoffice.desktopeditors
flatpak install de.shorsh.discord-screenaudio
sudo flatpak override --filesystem=$HOME/.themes
sudo flatpak override --filesystem=$HOME/.icons 
sudo flatpak override --env=GTK_THEME=Juno-Ocean 
sudo flatpak override --env=ICON_THEME=Papirus


# Set Brave Nightly as the default browser
xdg-settings set default-web-browser brave-nightly.desktop

# Set Nemo as the default file manager
xdg-mime default nemo.desktop inode/directory

# Set Okular as the default PDF viewer
xdg-mime default org.kde.okular.desktop application/pdf

# Set OnlyOffice as the default office suite (using Flatpak)
flatpak-spawn --host xdg-mime default org.onlyoffice.desktopeditors.desktop application/vnd.openxmlformats-officedocument.wordprocessingml.document
flatpak-spawn --host xdg-mime default org.onlyoffice.desktopeditors.desktop application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
flatpak-spawn --host xdg-mime default org.onlyoffice.desktopeditors.desktop application/vnd.openxmlformats-officedocument.presentationml.presentation

sudo systemctl enable ananicy-cpp
sudo systemctl enable syncthing@syncuser --now


#bare repo


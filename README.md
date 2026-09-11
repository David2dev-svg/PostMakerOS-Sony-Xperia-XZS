# Sony Xperia XZs (SO-03J / sony-keyaki) - PostmarketOS Mainline Linux

Dự án port **PostmarketOS** (nhân Linux Mainline v6.19.5) dành cho dòng máy **Sony Xperia XZs** (mã `sony-keyaki`, model `SO-03J`, SoC Qualcomm Snapdragon 820 / MSM8996).

---

## 📊 Bảng trạng thái phần cứng (Hardware Status)

| Phần cứng (Component) | Chi tiết (Details) | Trạng thái (Status) | Ghi chú (Notes) |
| :--- | :--- | :---: | :--- |
| **Màn hình (Display)** | 5.2" FHD (1080x1920@60Hz) JDI/Synaptics | ✅ Hoạt động | Driver KMS/DRM msm_drm, LAB/IBB & WLED backlight |
| **Cảm ứng (Touchscreen)** | Synaptics RMI4 I2C (`synaptics,rmi4-i2c`) | ✅ Hoạt động | Phản hồi mượt mà, hỗ trợ đa điểm đầy đủ |
| **GPU & Đồ họa 3D** | Adreno 530 (Qualcomm A530 v3) | ✅ Hoạt động | Tăng tốc phần cứng 3D Mesa Freedreno + Zap Shader |
| **Âm thanh (Audio)** | Qualcomm WCD9335 qua SLIMbus | ✅ Hoạt động | ALSA Sound Card `DB820c`, PulseAudio UCM |
| **Pin & Nguồn (Battery)** | Qualcomm PMI8996 Fuel Gauge | ✅ Hoạt động | Báo % pin, dòng sạc, điện áp qua `/sys/class/power_supply` |
| **Mạng Wi-Fi** | Broadcom BCM4359 SDIO (`brcmfmac`) | ✅ Hoạt động | Kết nối Wi-Fi 2.4GHz & 5GHz |
| **Mạng Di động (Modem)** | Qualcomm Hexagon Q6V5 MSS (`mba.mbn` + `modem.mdt`) | 🔄 Đang test | Đã nạp RMTFS QMI storage, đã cấu hình GLINK `mpss` |
| **Bluetooth** | Broadcom BCM4359 UART (`hci_bcm`) | 🔄 Đang cấu hình | Firmware nạp qua hciattach |
| **Máy ảnh (Camera)** | Sony IMX400 19MP DRAM-stacked | ❌ Chưa khả thi | Chưa có driver V4L2 trên Linux mainline |

---

## 📁 Cấu trúc thư mục dự án

```text
xzs-os-dev/
├── README.md                      # Tài liệu dự án
├── .gitignore                     # Cấu hình bỏ qua file đĩa lớn (>100MB)
├── dts/                           # Device Trees cho Xperia XZs
│   ├── patched_audio_modem.dts    # DTS hoàn chỉnh (Audio DAI + Modem GLINK mpss)
│   ├── patched_audio_modem.dtb    # File nhị phân DTB đã biên dịch
│   ├── msm8996-sony-xperia-tone-keyaki.dts # DTS gốc thiết bị
│   ├── msm8996-sony-xperia-tone.dtsi      # DTS nền tảng dòng Sony Tone
│   └── stock_keyaki.dts           # DTS trích xuất từ Android gốc của Sony
├── drivers/                       # Mã nguồn driver phần cứng
│   ├── panel-sony-synaptics-jdi.c # Driver màn hình JDI/Synaptics
│   ├── qcom-labibb-regulator.c    # Regulator nguồn màn hình LCD
│   ├── qcom-wled.c                # Điều khiển đèn nền LED
│   └── panel-device.ko            # Kernel module biên dịch
├── patches/                       # Các bản vá kernel
│   └── clean_panel_fix.patch      # Patch panel & regulator cho Linux 6.19.5
├── firmware/                      # Firmware trích xuất
│   └── zap/                       # Bộ Zap Shader GPU Adreno 530
│       ├── a530_zap.mbn           # File squash 17KB chuẩn cho mainline Linux
│       ├── a530_zap.mdt
│       ├── a530_zap.b00
│       ├── a530_zap.b01
│       └── a530_zap.b02
├── scripts/                       # Các script tiện ích
│   ├── flash_boot.sh              # Tự động nạp boot.img qua Fastboot hoặc SSH
│   ├── start_nbd.sh               # Chạy qemu-nbd server phát rootfs qua USB
│   ├── proxy.py                   # HTTP Proxy chia sẻ mạng từ máy Mac sang điện thoại
│   ├── initfs-hook.sh             # Hook initramfs kết nối NBD rootfs
│   └── wait_for_fastboot.sh       # Theo dõi kết nối thiết bị Fastboot
├── pmaports/                      # Cấu hình gói device PostmarketOS
│   ├── APKBUILD                   # Định nghĩa package device-sony-keyaki
│   ├── deviceinfo                 # Cấu hình phần cứng & offset nạp Android boot
│   └── modules-initfs             # Module nạp sớm trong initramfs
└── out/                           # File đầu ra
    ├── boot.img                   # Android boot image hoàn chỉnh (Kernel + DTB + Initramfs)
    ├── vmlinuz                    # Kernel Linux v6.19.5 MSM8996
    └── initramfs                  # Initramfs nạp vào RAM
```

---

## 🚀 Hướng dẫn sử dụng & Nạp hệ thống

### 1. Nạp file `boot.img` vào điện thoại
Sử dụng script tự động:
```bash
./scripts/flash_boot.sh
```

Hoặc nạp thủ công qua Fastboot:
1. Tắt máy hoàn toàn.
2. Giữ phím **Tăng âm lượng (Volume Up)** và cắm cáp USB vào máy Mac (Đèn LED sáng **màu xanh dương - Blue LED**).
3. Chạy lệnh:
```bash
fastboot flash boot out/boot.img
fastboot reboot
```

### 2. Chạy máy chủ Rootfs (NBD Server) trên macOS
Nếu hệ điều hành đang dùng cơ chế nạp rootfs qua NBD qua cáp USB:
```bash
./scripts/start_nbd.sh
```

### 3. Chia sẻ Internet từ Mac cho điện thoại
```bash
python3 scripts/proxy.py 8080
```

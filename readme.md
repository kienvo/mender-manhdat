
# Terms:

- **target**: Board máy tính nhúng cần cài mender lên.
- **host**: Máy tính, laptop dùng để cài mender cho target, chạy bất kỳ hệ điều
  hành nào, miễn chạy được các tool ở dưới.
- **mender-server**: Phần mềm do Mender cung cấp, chạy trên host hoặc cloud
  server hoặc bất kỳ máy nào chạy hệ điều hành mà client có thể kết nối tới.
  [Mender-server do mender cung cấp sẵn](hosted.mender.io) được gọi là
  `hosted-mender`
- **mender-client**: Phần mềm do Mender cung cấp, chạy trên target, chờ lệnh
  update từ mender-server.
- **mount**: trạng thái mà 1 phân vùng được gắn với 1 thư mục (mount point) trên
  `/` để Linux có thể truy cập được phân vùng đó. Phân vùng của một ổ vật lý
  được list trong /dev dưới dạng:
  - /dev/mmcblkXpY - Đối với thẻ nhớ, X là số thứ tự ổ vật lý, Y là số phân vùng
    trên ổ đó.
  - /dev/nvme0nXpY - Đối với SSD, X là số thứ tự ổ vật lý, Y là số phân vùng
    trên ổ đó.
  - /dev/sdXY - Đối với ổ HDD, X là thứ tư alphabet ổ vật lý, Y là số phân vùng
    trên ổ đó..

# Cách cài mender client cho system-update

File .img cài sẵn do mender cung cấp, có cài sẵn `mender-client`, các phân vùng
(`rootfs A/B`, `boot`, `mender-data`) và các config để `mender-client` chạy.

`Board phát triên` và các `board cần update` phải cài chung từ một file .img

Các bước cài mender bằng file .img:

1. Tải file .img do mender cung cấp.
2. Giải nén file vừa tải
3. Flash file vào thẻ nhớ
4. Chạy trên board

## Tải file .img

Mender có cung cấp file .img hỗ trợ chính thức cho RPi 3 và 4.

Tải file .img cho các board máy tính nhúng khác: [Mender Hub community
forum](https://hub.mender.io/c/board-integrations/debian-family/11)

File tải về có định dạng .img.xz 563MB.

## Giải nén

Sử dụng `7zip`, `xz` hoặc `WinRAR` để giải nén file thành file .img. File giải
nén ra 8GB nên cần ổ cứng trống hơn 8GB để chứa file.

## Flash vào thẻ nhớ

Sử dụng dd hoặc `Win32 Disk Imager` để flash vào thẻ nhớ. Thẻ nhớ cần phải lớn
hơn 8GB hoặc bằng, trường hợp nhỏ hơn 1-2GB vẫn chấp nhận được.

Nếu flash thành công, nếu host là Linux thì ta có thể thấy các phân vùng khi chạy `lsblk`
![check-success](check-success.png)

## Chạy trên board

Hệ điều hành đã được Mender config sẵn serial-console trên `UART0` chỉ cần cắm
uart-to-usb vào là có thể thấy được `kernel-bootlog` và shell để chạy lệnh sau
khi boot thành công. ![rpi-uart0](UART0.png)

Sử dụng putty, kitty, minicom, screen hoặc bất kỳ phần mềm serial-console chạy
trên host. Bật nguồn Rpi chờ 5s để bootloader load. Trên serial-console hiện
kernel-bootlog gửi từ Rpi ![uboot-log](uboot-bootlog.png) ![login](login.png)

Sau khi đăng nhập với username `pi`, password `raspberry` mặc định, chạy `lsblk`
để list ra danh sách phân vùng của thẻ nhớ. ![lsblk](lsblk.png)

Ta có thể thấy trong ảnh trên, `root` (hay `/`) đang được mount từ phân vùng số
2 của thẻ nhớ.

# Cách sử dụng mender system-update

System-update là update cả phân vùng rootfs. Có nghĩa là ta phải cần một `phân
vùng rootfs mẫu`. Mẫu này sẽ được update cho tất cả các board đang chạy cùng hệ
điều hành có cài mender-client. Ví dụ: 
> Ta có 10 board đang chạy ứng dụng
> (app-boards) và 1 board phát triển (dev-board). Khi ứng dụng trên `dev-board`
> đạt mức ổn định và có thể release cho 10 `app-boards`, với mục tiêu để  môi
> trường trên `app-board` giống với `dev-board` nhất có thể thì ta clone phân vùng
> rootfs đang chạy ổn định trên `dev-board` lên tất cả `app-boards`. 

Việc clone có thể thực hiện bằng tay với `dd`. Clone phân vùng rootfs của `dev-board`
thành file .img, ghi file đó đè vào phân vùng rootfs đang chạy của `app-boards`.
Hoặc sử dụng Mender để tự động hóa quá trình ghi đè này (deploy).

`File image rootfs clone từ dev-board` được chuyển thành một file gọi là `artifact` bằng công cụ `mender-artifact`. Hoặc có thể sử dụng `mender-artifact` kết hợp `ssh` (snapshot) để chuyển thẳng rootfs trên `dev-board` đang chạy thành file artifact. Như vậy có 2 cách để tạo `artifact`:

Các bước để  tạo `system-update`:

1. Clone phân vùng rootfs của `dev-board` thành file .img.
2. Cài `mender-artifact` trên host (nếu chưa). Chuyển file .img vừa clone thành file `artifact`.
3. Tải file `artifact` lên `mender-server`.
4. Tạo deployment trên `mender-server`.
5. Kết thúc.

Nếu dùng snapshot của `mender-artifact`:

1. Cài `mender-artifact` trên host (nếu chưa). Dùng `mender-artifact` snapshot chuyển phân vùng rootfs của board đang chạy thành file `artifact`.
2. Tải file artifact lên `mender-server`.
3. Tạo deployment trên `mender-server`.
4. Kết thúc.

## Cài `mender-artifact`

Mender-artifact là phần mềm chuyển `file .img của một phân vùng rootfs` thành `artifact`.

Mender chỉ hỗ trợ mender-artifact trên Linux và Mac OS X. Để sử dụng được trên Windows, có thể sử dụng máy ảo hoặc [WSL](https://docs.microsoft.com/en-us/windows/wsl/install).

### Đối với Linux

Tải file mender-artifact 3.7.1 tại [mục download của Mender docs](https://docs.mender.io/downloads#mender-artifact).

Di chuyển terminal tới thư mục chứa file vừa tải xuống, chạy:

```bash
chmod +x ./mender-artifact
```

 để cấp quyền thực thi cho file `mender-artifact`.

Nếu thành công, chạy:

``` bash
./mender-artifact -v
```

sẽ có kết quả:
![mender-artifact-v.png](mender-artifact-v.png)

## Clone một phân vùng rootfs của `dev-board` thành .img

Yêu cầu:

- Máy host sử dụng được dd, Win32 Disk Imager hoặc các phần mềm tương tự.
- Máy host truy cập được phân vùng của thẻ nhớ từ cắm vào từ `dev-board`.

Xác định phân vùng cần clone.
Phân vùng cần clone là phân vùng rootfs A hoặc B đang mount vào `/` khi boot trên board. [Ví dụ.](#chạy-trên-board)

Cắm thẻ nhớ vào host. List danh sách các phân vùng bằng `lsblk`.
![phanvungcanclone](phanvungcanclone.png)

Giả sử để clone phân vùng số 2, chạy `dd`:

``` sh
sudo dd if=/dev/mmcblk0p2 of=p2rootfs.ext4 bs=8M conv=fdatasync status=progress
```

Tham số:

>`sudo` - Sủ dụng sudo để lấy quyền truy cập /dev/mmcblk0p3.
>
>`if=/dev/mmcblk0p2` - input file là phân vùng số 2 của thẻ nhớ số 0
>
>`of=p2rootfs.img` - output file, file này được tạo ra tại thư mục mà terminal đang đứng [(pwd)](https://en.wikipedia.org/wiki/Pwd) và có tên là `p2rootfs.img`.
>
>`bs=8M conv=fdatasync status=progress` - Kích cỡ mỗi lần copy, flush disk cache, hiện thị trạng thái.

Chờ 30 phút, tùy theo dung lượng thẻ nhớ. Sau khi chạy xong, một file tên `p2rootfs.img` sẽ được tạo ra, có kích thước bằng dung lượng phân vùng vừa clone.

## Chuyển file .img vừa clone thành file artifact

Mender-server chỉ nhận file artifact có phần extension là .mender. 

Để tạo artifact, sử dụng mender-artifact. Di chyển terminal tới thư mục chứa file `mender-artifact` và file `p2rootfs.img`. Chạy:

```bash
./mender-artifact write rootfs-image \
-t raspberrypi4 \
-n release-test \
--software-version rootfs-vtest \
-f p2rootfs.img \
-o artifact.mender
```

Tham số:

> `write rootfs-image` - Ghi ra file artifact chứa rootfs
>
> `-t raspberrypi4` - Loại board mà Mender hỗ trợ.
>
> `-n release-test` - Tên release
>
> `--software-version rootfs-vtest` - Tên version
>
> `-f p2rootfs.img` - Tên file .img **input**
>
> `-o artifact.mender` - Tên file .mender **output**

Nếu thành công sẽ có 1 file tên `artifact.mender` được tạo ra trong thư mục mà terminal đang đứng.

## Mender-artifact snapshot

Một cách khác dễ hơn, ít tốn dung lượng ổ đĩa hơn để tạo artifact.

Yêu cầu:

- `Host` và `dev-board` phải chung một mạng LAN.
- `dev-board` phải bật `ssh server`, host có thể kết nối vào được.

Các bước sử dụng mender-artifact snapshot:

1. Cắm thẻ nhớ vào board, chạy, đăng nhập vào shell, kết nối wifi (mạng), xem địa chỉ ip ![piip](piip.png)

2. Bật ssh (nếu chưa)
3. Chạy mender-artifact trên host ![mender-artifact-running.png](mender-artifact-running.png)

```bash
mender-artifact write rootfs-image \
    -f ssh://pi@192.168.1.250 \
    -t raspberrypi4 \
    -n system-test \
    -o system-test.mender
```

Tham số:

> `write rootfs-image` - Ghi ra file artifact chứa rootfs
>
> `-f ssh://pi@192.168.1.250` - Sử dụng ssh đến board **input**
>
> `-t raspberrypi4` - Loại board mà Mender hỗ trợ.
>
> `-n system-test` - Tên release
>
> `-o system-test.mender` - Tên file .mender **output**

## Tải file artifact lên mender-server

## Tạo deployment trên mender-server

# Cách tạo artifact với state-script

Thông thường, khi upload một file lên mender-server, nếu file đó không phải là file artifact thì mender-sever sẽ hiện ra 1 pop-up hỏi đường dẫn file để lưu khi update thành công, sau đó tự động chuyển file đó thành artifact (type `single-file`).

Nhưng với cách trên thì không thể thêm `state-script`. Để thêm được `state-script` thì phải chạy `mender-artifact` để tạo artifact cùng với `state-script`:

1. Chuẩn bị 4(+) file
   1. Payload - file cần update
   2. dest_dir - file có nội dung là **đường dẫn** đên thư mục mà `payload` sẽ được copy vào đó, khi update thành công. **Tên file phải là `dest_dir` và đặt trong thư mục ngang hàng với payload**
   3. filename - file có nội dung là **tên của payload** sau khi cập nhật xong, payload sẽ được đổi tên giống như nội dung file này. **Tên file phải là `filename` và đặt trong thư mục ngang hàng với payload**
   4. Các file state-script đặt tên theo [`naming convention` của Mender](https://docs.mender.io/artifact-creation/state-scripts#:~:text=There%20can%20be%20more%20than%20one%20script%20for%20a%20given%20state.%20Each%20script%20contains%20an%20ordering%20number%20as%20a%20part%20of%20the%20naming%20convention%2C%20which%20determines%20when%20it%20is%20run%3A)
2. `cd` tới thư mục chứa các file trên và chạy:

``` bash
./mender-artifact write module-image 	\
-T		single-file 					\
-t		raspberrypi4 					\
-n		singlefile-test7 					\
-f		./example.py					\
-s		./ArtifactInstall_Leave_01_User_Confirmation-abc.sh \
-s		./ArtifactInstall_Enter_01_User_Confirmation-abc.sh \
-f		dest_dir						\
-f		filename 						\
-o		singlefile.mender
```

Tham số:
>`write module-image` - Cho mender-artifact biết đang cần tạo module-image
>
>`-T  single-file` - Loại artifact (single-file, script)
>
>`-t  raspberrypi4`	- Thiết bị tương thích
>
>`-n  singlefile-test7` - Tên artifact
>
>`-f  ./example.py` - Tên payload (file cần update)
>
>`-s  ./ArtifactInstall_Leave_01_User_Confirmation-abc.sh` - File state script đặt tên theo [`naming convention` của Mender](https://docs.mender.io/artifact-creation/state-scripts#:~:text=There%20can%20be%20more%20than%20one%20script%20for%20a%20given%20state.%20Each%20script%20contains%20an%20ordering%20number%20as%20a%20part%20of%20the%20naming%20convention%2C%20which%20determines%20when%20it%20is%20run%3A).
>
>`-s  ./ArtifactInstall_Enter_01_User_Confirmation-abc.sh` - File state script đặt tên theo [`naming convention` của Mender](https://docs.mender.io/artifact-creation/state-scripts#:~:text=There%20can%20be%20more%20than%20one%20script%20for%20a%20given%20state.%20Each%20script%20contains%20an%20ordering%20number%20as%20a%20part%20of%20the%20naming%20convention%2C%20which%20determines%20when%20it%20is%20run%3A).
>
>`-f  dest_dir` - Một file có tên là `dest_dir` trong thư mục hiện tại, nội dung của file này chứa **đường dẫn** đên thư mục mà `payload` sẽ được copy vào đó, khi update thành công.
>
>`-f  filename` - Một file có tên là `filename` trong thư mục hiện tại, nội dung của file này chứa **tên của payload** sau khi cập nhật xong, payload sẽ được đổi tên giống như nội dung file này.
>
>`-o  singlefile.mender` - Output artifact.

Nếu thành công sẽ có file output với tên đã chỉ định tạo ra trong thư mục hiện tại.

# Xem log trên `app-boards`

Cơ chế log của mender: khi mender-client nhận deployment từ mender-server, mọi log của quá trình đó sẽ được lưu vào một file tại thư mục `/data/mender/` hoặc `/var/lib/mender/` và có tên là `deployments.<stt>.<hash-deployment>.log`. `<stt>` là số thứ tự các deployment sắp xếp theo thời gian, lần deploy gần nhất có `<stt>` là `0001`, lần gần thứ 2 là `0001`,... `<hash-deployment>` là mã hash của deployment. Nội dung file log là json line-by-line có dạng:
 ```json
{
	"level": <log level>,
	"message": <log message>,
	"timestamp": <thời gian>
}
 ```

Nếu quá trình deploy đã hoàn thành, có thể xem file log bằng cách `cat` file trên ra màn hình.

Nếu quá trình deploy đang diễn ra, để xem trực tiếp file log trên thì dùng `sudo tail -f <file>.log`. Ví dụ `sudo tail -f /data/mender/deployments.0001.15897069-89de-4f3b-bb34-9ccc73863002.log`

File log có nội dung (json đã được format bằng vscode):

```json
// Intro
{
	"level": "info",
	"message": "Running Mender client version: 3.2.1",
	"timestamp": "2022-05-23T04:37:00+01:00"
}
// Vào trạng thái Download
{
	"level": "info",
	"message": "State transition: update-fetch [Download_Enter] -\u003e update-store [Download_Enter]",
	"timestamp": "2022-05-23T04:37:02+01:00"
}
{
	"level": "info",
	"message": "No public key was provided for authenticating the artifact",
	"timestamp": "2022-05-23T04:37:03+01:00"
}
{
	"level": "info",
	"message": "State transition: update-store [Download_Enter] -\u003e update-after-store [Download_Leave]",
	"timestamp": "2022-05-23T04:37:05+01:00"
}
// Ròi trạng thái Download
{
	"level": "info",
	"message": "State transition: update-after-store [Download_Leave] -\u003e mender-update-control-refresh-maps [none]",
	"timestamp": "2022-05-23T04:37:05+01:00"
}
{
	"level": "info",
	"message": "Validating the Update Info: https://s3.amazonaws.com/hosted-mender-artifacts/625abda96735b19c83e80a36/f379fb76-5915-4572-8baa-c73cfde2ef9f?X-Amz-Algorithm=AWS4-HMAC-SHA256\u0026X-Amz-Credential=AKIAQWI25QR6NDALMYE2%2F20220523%2Fus-east-1%2Fs3%2Faws4_request\u0026X-Amz-Date=20220523T033705Z\u0026X-Amz-Expires=86400\u0026X-Amz-SignedHeaders=host\u0026response-content-type=application%2Fvnd.mender-artifact\u0026X-Amz-Signature=f706f0d5f3bdd589f4ad61eccef398239f7164c8dbeaf77138665fc33de49aa5 [name: singlefile-blink4; devices: [raspberrypi4]]",
	"timestamp": "2022-05-23T04:37:05+01:00"
}
{
	"level": "info",
	"message": "State transition: mender-update-control-refresh-maps [none] -\u003e mender-update-control [none]",
	"timestamp": "2022-05-23T04:37:05+01:00"
}
{
	"level": "info",
	"message": "State transition: mender-update-control [none] -\u003e update-install [ArtifactInstall]",
	"timestamp": "2022-05-23T04:37:05+01:00"
}
// Vào trạng thái Insttall, thực thi script ArtifactInstall_Enter_01_User_Confirmation-abc.sh
{
	"level": "info",
	"message": "Executing script: ArtifactInstall_Enter_01_User_Confirmation-abc.sh",
	"timestamp": "2022-05-23T04:37:05+01:00"
}
{
	"level": "info",
	"message": "State transition: update-install [ArtifactInstall] -\u003e mender-update-control-refresh-maps [none]",
	"timestamp": "2022-05-23T04:37:06+01:00"
}
// Rời trạng thái Install, thực thi script ArtifactInstall_Leave_01_User_Confirmation-abc.sh
{
	"level": "info",
	"message": "Executing script: ArtifactInstall_Leave_01_User_Confirmation-abc.sh",
	"timestamp": "2022-05-23T04:37:06+01:00"
}
// In ra stderr của script đã thực thi
{
	"level": "info",
	"message": "Collected output (stderr) while running script /var/lib/mender/scripts/ArtifactInstall_Leave_01_User_Confirmation-abc.sh\nEcho to stderr from State script\nnohup: missing operand\nTry 'nohup --help' for more information.\n\n---------- end of script output",
	"timestamp": "2022-05-23T04:37:06+01:00"
}
// Lỗi
{
	"level": "error",
	"message": "Error receiving scheduled update data: failed to check update info on the server. Response: \u0026{429 Too Many Requests 429 HTTP/1.1 1 1 map[Connection:[keep-alive] Content-Length:[0] Content-Type:[application/json; charset=utf-8] Date:[Mon, 23 May 2022 03:37:07 GMT] X-Men-Requestid:[60b7577e-8c22-4d52-a030-ce353bfaf10f]] 0x18a2bf0 0 [] false false map[] 0x1ce2d00 \u003cnil\u003e}",
	"timestamp": "2022-05-23T04:37:07+01:00"
}
// Lỗi
{
	"level": "error",
	"message": "Update control map check failed: transient error: failed to check update info on the server. Response: \u0026{429 Too Many Requests 429 HTTP/1.1 1 1 map[Connection:[keep-alive] Content-Length:[0] Content-Type:[application/json; charset=utf-8] Date:[Mon, 23 May 2022 03:37:07 GMT] X-Men-Requestid:[60b7577e-8c22-4d52-a030-ce353bfaf10f]] 0x18a2bf0 0 [] false false map[] 0x1ce2d00 \u003cnil\u003e}, retrying...",
	"timestamp": "2022-05-23T04:37:07+01:00"
}
{
	"level": "info",
	"message": "State transition: mender-update-control-refresh-maps [none] -\u003e mender-update-control-retry-refresh-maps [none]",
	"timestamp": "2022-05-23T04:37:07+01:00"
}
// Chờ 1 phút, sau đó chạy lại Sync
{
	"level": "info",
	"message": "Wait 1m0s before next update control map fetch/update attempt",
	"timestamp": "2022-05-23T04:37:07+01:00"
}
{
	"level": "info",
	"message": "State transition: mender-update-control-retry-refresh-maps [none] -\u003e mender-update-control-refresh-maps [none]",
	"timestamp": "2022-05-23T04:38:07+01:00"
}
{
	"level": "info",
	"message": "Validating the Update Info: https://s3.amazonaws.com/hosted-mender-artifacts/625abda96735b19c83e80a36/f379fb76-5915-4572-8baa-c73cfde2ef9f?X-Amz-Algorithm=AWS4-HMAC-SHA256\u0026X-Amz-Credential=AKIAQWI25QR6NDALMYE2%2F20220523%2Fus-east-1%2Fs3%2Faws4_request\u0026X-Amz-Date=20220523T033807Z\u0026X-Amz-Expires=86400\u0026X-Amz-SignedHeaders=host\u0026response-content-type=application%2Fvnd.mender-artifact\u0026X-Amz-Signature=ee5220883dfb955a879b81528e22f44ba4014dc50fe6b726ffae0199417a4d38 [name: singlefile-blink4; devices: [raspberrypi4]]",
	"timestamp": "2022-05-23T04:38:07+01:00"
}
{
	"level": "info",
	"message": "State transition: mender-update-control-refresh-maps [none] -\u003e mender-update-control [none]",
	"timestamp": "2022-05-23T04:38:07+01:00"
}
{
	"level": "info",
	"message": "State transition: mender-update-control [none] -\u003e update-commit [ArtifactCommit_Enter]",
	"timestamp": "2022-05-23T04:38:07+01:00"
}
{
	"level": "info",
	"message": "Device unauthorized; attempting reauthorization",
	"timestamp": "2022-05-23T04:38:07+01:00"
}
{
	"level": "info",
	"message": "Output (stderr) from command \"/usr/share/mender/identity/mender-device-identity\": using interface /sys/class/net/eth0",
	"timestamp": "2022-05-23T04:38:07+01:00"
}
{
	"level": "info",
	"message": "successfully received new authorization data from server https://hosted.mender.io",
	"timestamp": "2022-05-23T04:38:07+01:00"
}
{
	"level": "info",
	"message": "Local proxy stopped",
	"timestamp": "2022-05-23T04:38:07+01:00"
}
{
	"level": "info",
	"message": "Local proxy started",
	"timestamp": "2022-05-23T04:38:07+01:00"
}
{
	"level": "info",
	"message": "Reauthorization successful",
	"timestamp": "2022-05-23T04:38:07+01:00"
}
// Vào trạng thái Commit
{
	"level": "info",
	"message": "State transition: update-commit [ArtifactCommit_Enter] -\u003e update-after-first-commit [none]",
	"timestamp": "2022-05-23T04:38:08+01:00"
}
{
	"level": "info",
	"message": "State transition: update-after-first-commit [none] -\u003e update-after-commit [ArtifactCommit_Leave]",
	"timestamp": "2022-05-23T04:38:08+01:00"
}
// Rời trạng thái Commit
{
	"level": "info",
	"message": "State transition: update-after-commit [ArtifactCommit_Leave] -\u003e cleanup [none]",
	"timestamp": "2022-05-23T04:38:08+01:00"
}
// Xóa các file vừa tải về sau khi đã chạy thành công
{
	"level": "info",
	"message": "State transition: cleanup [none] -\u003e update-status-report [none]",
	"timestamp": "2022-05-23T04:38:08+01:00"
}

```

# State csript

## Các trạng thái của mender-client

- `Idle`: Trạng thái nghỉ, không làm gì
- `Sync`: Kiểm tra xem có update từ `mender-server` hay không
- `Download`: Tải `Artifact` về
- `ArtifactInstall`: Cài `Artifact`
- `ArtifactReboot`: Chỉ chạy khi `Artifact` yêu cầu reboot
- `ArtifactCommit`: Đánh dấu lần update này thành công
- `ArtifactRollback`: Quay lại phiên bản trước, undo tất cả
- `ArtifactRollbackReboot`: Reboot sau `ArtifactRollback`
- `ArtifactFailure`: Nếu bất kì trạng thái trên bị lỗi, thì trạng trái này sẽ được chạy. Trạng thái này luôn được thực sau `ArtifactRollback` và `ArtifactRollbackReboot`.

`state-script` chỉ chạy trong quá trình chuyển đổi giữa 2 trạng thái: "Enter" (trước khi vào trạng thái) hoặc "Leave" (rời khỏi trạng thái), hoặc "Error" (lỗi trong trạng thái, kể cả trong "Enter" và "Leave").

![states](states.png)

## Hai loại state-script

Root file system script:

- Được lưu trong `/etc/mender/scripts/`
- Chỉ có 3 trạng thái: `Idle`, `Sync`, `Download`

Artifact scripts:

- Được lưu trong file `Artifact`
- **Không** được có 3 trạng thái: `Idle`, `Sync`, `Download`

## Thứ tự thực thi state-script

Quy ước đặt tên state-script :

```txt
<STATE_NAME>_<ACTION>_<ORDERING_NUMBER>_<OPTIONAL_DESCRIPTION>

```

Ví dụ: `Download_Enter_05_wifi-driver.py` sẽ thực thi trước `Download_Enter_10_ask-user.sh`

`state-script`:

## Lưu ý

`state-script` không nhận đối số

Sử dụng [unix-shebang](https://en.wikipedia.org/wiki/Shebang_(Unix)) để khai báo trình thông dịch (interpreter) cho script. Ví dụ: `#!/usr/bin/env python3` nếu file .py hoặc `#!/usr/bin/env bash` nếu file .sh.

`state-script` chỉ được trả về 3 return codes là: 

- `0` - Script thực thi không có lỗi
- `1` - Script thực thi có lỗi
- `21` - Script sẽ được chạy lại sau. Sau khoảng thời gian chờ bằng [`StateScriptRetryIntervalSeconds`](https://docs.mender.io/client-installation/configuration-file/configuration-options#statescriptretryintervalseconds) script sẽ được chạy lại.

## Script timeout

Mỗi script có một khoảng thời gian quy định để thực thi ([`StateScriptTimeoutSeconds`](https://docs.mender.io/client-installation/configuration-file/configuration-options#statescripttimeoutseconds)). Nếu script chạy lâu hơn khoảng thời gian này, script này sẽ bị kill và quá trình update bị đánh dấu là lỗi.

## Trường hợp mất điện đột ngột

`Mender-client` sẽ chuyển vào trạng thái lỗi, kể cả `ArtifactRollback` và `ArtifactFailure`. Nếu xảy ra trong trạng thái Reboot, mender sẽ không chuyển vào trạng thái lỗi.

## Log từ state script

Mọi thứ ghi ra `stderr` của `state-script` sẽ được ghi vào `log-message` của file log.

# WifSolverCuda v3.0
![Recovers a broken private key that misses characters](https://user-images.githubusercontent.com/82582647/161723196-755b39a1-5fd4-4e9e-bbb6-10932be33244.jpg)</br>
This is a modified version of WifSolverCuda v0.5.0 by [PawGo](https://github.com/PawelGorny) </br>
This is a soft for recovering unknown (lost) characters in the middle and beginning of a (Wallet Import Format) private key. </br>
If you have a lost WIF private key end (on the right), use soft [**Wif key Recovery**](https://github.com/phrutis/Wif-key-Recovery)

Help page: ```WifSolverCuda.exe -h```
```
C:\Users\User>WifSolverCuda.exe -h

 WifSolverCuda v3.0 (phrutis modification 10.04.2022)

-wif         START WIF key 5.... (51 characters) or L..., K...., (52 characters)
-wif2        END WIF key 5.... (51 characters) or L..., K...., (52 characters)
-a           Bitcoin address 1.... or 3.....
-n           Letter number from left to right from 9 to 51
-n2          Spin additional letters -n2 from 9 to 51 (every sec +1)
-turbo       Quick mode (skip 3 identical letters in a row) -turbo 3 (default: OFF)
-part1       First part of the key starting with K, L or 5 (for random mode)
-part2       The second part of the key with a checksum (for random mode)
-fresult     The name of the output file about the find (default: FOUND.txt)
-fname       The name of the checkpoint save file to continue (default: GPUid + Continue.txt)
-ftime       Save checkpoint to continue every sec (default 60 sec)
-d           DeviceId. Number GPU (default 0)
-list        Shows available devices
-h           Shows help page
 ```   

## How to use it
![Bitcoin private key recovery](https://user-images.githubusercontent.com/82582647/161723666-490cb467-f184-4bce-84ff-a29ec3d21fd3.jpg)</br>
The Compressed WIF key must span K... or L... contain 52 characters.</br>
The Uncompressed WIF key must span 5... contain 51 characters.</br>

Example WIF key: KyBLV6rrV9hsbsU96VwmEtMnACavqnKnEi7_________J9tM5JQQSo</br>
Replace unknown (missing) characters in a row with a capital ```X``` (min. 4, max. 15 X)</br>
We collect the key: KyBLV6rrV9hsbsU96VwmEtMnACavqnKnEi7XXXXXX```X```J9tM5JQQSo (52)</br>
We need to twist the first unknown letter ```X```, this symbol is number 11</br>
Minimum position -n 9 (-n 51 max, 1-8 this is the checksum it can't be rotated)</br>

Run: ```WifSolverCuda.exe -wif KyBLV6rrV9hsbsU96VwmEtMnACavqnKnEi7XXXXXXXJ9tM5JQQSo -n 11 -a 1EpMLcfjKsQCYUAaVj9mk981qkmT5bxvor```

![private key WIF](https://user-images.githubusercontent.com/82582647/162636370-bbdbd196-209e-4546-a4e4-87f7ace2a4b4.png)

## Performance

| card          | compressed with collision | all other cases |
|---------------|---------------------------|-----------------|
| RTX 3090      | 29 Gkey/s                 | 4.0 Gkey/s      |
| RTX 3080 Ti   | 29 Gkey/s                 | 4.0 Gkey/s      |
| RTX 3060 eGPU | 10 Gkey/s                 | 1.3 Gkey/s      |
| RTX 2070      | 12 Gkey/s                 | 1.4 Gkey/s      |
| GTX 1080TI    | 6 Gkey/s                  | 700 Mkey/s      |

If the speed is several times higher than in the table. </br>
Your WIF key is not correct.</br>

If you need help recovering your private key, contact [telegram](https://t.me/+mAY1x5YYuL8yNjQy) </br>

## Сontinuation
Сontinuation of the last checkpoint from the file Сontinuation.txt</br>
Run: ```WifSolverCuda.exe -wif KyBLV6rrV9hsbsU96VwmEtMnACavqnKnAaZvihMARQJ9tM5JQQSo -wif2 L5oLkpV3aqBjhki6LmvChTCV6odsp4SXM6FfU2Gppt5kFLaHLuZ9 -a 1XXXLcfjKsQCYUAaVj9mk981qkmT5bxvor -n 11 -turbo 3 -d 0```

![Сontinuation recovery bitcoin](https://user-images.githubusercontent.com/82582647/162636418-9c46211a-a266-44d3-abf4-fef6d8b64c92.png)

## TURBO MODE
 - [How Turbo mode works?](https://github.com/phrutis/WifSolverCuda/blob/main/Other/turbo.md#how-turbo-mode-works) </br>
 
 Run: ```WifSolverCuda.exe -wif KyBLV6rrV9hsbsU96VwmEtMnACavqnKnAaZb5xcbaaJ9tM5JQQSo -n 11 -a 1XXXLcfjKsQCYUAaVj9mk981qkmT5bxvor -turbo 3```
 
![recovery part private key](https://user-images.githubusercontent.com/82582647/162636457-25a10c34-0f7c-4554-ae96-3633e47ff796.png)

## Special mode
### Search for additional letter -n2
- [How is the extra letter rotated](https://github.com/phrutis/WifSolverCuda/blob/main/Other/turbo.md#how-is-the-extra-letter-rotated) </br>

Run: ```WifSolverCuda.exe -wif KyBLV6rrV9hsbsU961wmEtMnACavqnKnEi7eY11111J9tM5JQQSo -n 11 -n2 35 -a 1EpMLcfjKsQCYUAaVj9mk981qkmT5bxvor```

![paper wallet missing](https://user-images.githubusercontent.com/82582647/162636581-4aa135ec-d84a-4630-811c-32e1fe9c9d19.png)

## Random mode
### Random + sequential search
- [How random works](https://github.com/phrutis/WifSolverCuda/blob/main/Other/turbo.md#how-random-works)

Run: ```WifSolverCuda.exe -part1 KyBLV6rrV9hsbsU96VwmEtMnACavqnKnEi7 -part2 J9tM5JQQSo -a 1EpMLcfjKsQCYUAaVj9mk981qkmT5bxvor```

![missing characters private key](https://user-images.githubusercontent.com/82582647/162636844-84366745-19ff-49ec-8052-c8e678b96170.png)


## Build
### Windows:

#### Microsoft Visual Studio Community 2019
RTX 30xx - CUDA version [**11.6**](https://developer.nvidia.com/cuda-11-6-0-download-archive) compute_cap=86 use the prepared file WifSolverCuda.vcxproj from the Other folder.</br>
For others GPUs - CUDA version [**10.2**](https://developer.nvidia.com/cuda-10.2-download-archive?target_os=Windows&target_arch=x86_64&target_version=10&target_type=exenetwork) compute_cap=54 </br>

### Linux:
Go to linux/ subfolder and execute _make all_. If your device does not support compute capability=86 (error "No kernel image is available for execution on the device"), do the change in _Makefile_ (for example 1080Ti requires COMPUTE_CAP=61).

## Donation
If you found this program useful, consider making a donation, I will appreciate it! <br>
- [phrutis](https://github.com/phrutis) (modification)    bc1qh2mvnf5fujg93mwl8pe688yucaw9sflmwsukz9
- [PawelGorny](https://github.com/PawelGorny) (author)    bc1qz2akvlch75rqdfg8pv7chqvz3m8jsl49k0kszc </br>

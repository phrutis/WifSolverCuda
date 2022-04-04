# WifSolverCuda
This is a modified version of WifSolverCuda v0.5.0 by [PawGo](https://github.com/PawelGorny) </br>
Tool for solving misspelled or damaged Bitcoin Private Key in Wallet Import Format (WIF)

Help page: ```WifSolverCuda.exe -h```
```
C:\Users\User>WifSolverCuda.exe -h

  WifSolverCuda v1.0 (phrutis modification 04.04.2022)

-wif             START WIF key 5.... (51 characters) or L..., K...., (52 characters)
-wif2            END WIF key 5.... (51 characters) or L..., K...., (52 characters)
-a               Bitcoin address 1.... or 3.....
-n               Letter number from left to right from 9 to 51
-fresult         The name of the output file about the find (default: FOUND.txt)
-fname           The name of the checkpoint save file to continue (default: GPUid + Continue.txt)
-ftime           Save checkpoint to continue every sec (default 60 sec)
-d               DeviceId. Number GPU (default 0)
-c               Search for compressed address (default)
-u               Search for uncompressed address
-b               NbBlocks. Default processorCount * 8
-t               NbThreads. Default deviceMax/8 * 5
-s               NbThreadChecks. Default 5000
-listDevices     Shows available devices
-disable-um      Disable unified memory mode
-h               Shows help page
 ```   

How to use it
-------------
The compressed WIF key must span K... or L... contain 52 characters.</br>
The uncompressed WIF key must span 5... contain 51 characters. Use ```-u``` parameter! </br>
Replace unknown key characters with ```X``` (min 4, max 12 X)</br>

Example WIF key: KyBLV6rrV9hsbsU96VwmEtMnACavqnKnEi7   J9tM5JQQSo</br>
Example WIF key: KyBLV6rrV9hsbsU96VwmEtMnACavqnKnEi7XXXXXXXJ9tM5JQQSo</br>
BTC address: 1EpMLcfjKsQCYUAaVj9mk981qkmT5bxvor</br>

Example WIF key: KyBLV6rrV9hsbsU96VwmEtMnACavqnKnEi7XXXXXX```X```J9tM5JQQSo</br>
We need to twist the first unknown letter ```X```, this symbol is number 11</br>
Minimum position X -n 9 (-n 51 maximum) (1-8 this is the checksum it can't be rotated)</br>
Run: ```WifSolverCuda.exe -wif KyBLV6rrV9hsbsU96VwmEtMnACavqnKnEi7XXXXXXXJ9tM5JQQSo -n 11 -a 1EpMLcfjKsQCYUAaVj9mk981qkmT5bxvor```

![1](https://user-images.githubusercontent.com/82582647/161607233-93a41d63-e506-4369-9785-68036ae794bf.png)

| Unknown chars   |      Combinations      |
|-----------------|------------------------|
|  3 characters   | 195112                 |
|  4 characters   | 11316496               |
|  5 characters   | 656356768              |
|  6 characters   | 38068692544            |
|  7 characters   | 2207984167552          |
|  8 characters   | 128063081718016        |
|  9 characters   | 7427658739644928       |
|  10 characters  | 430804206899405824     |
|  11 characters  | 24986644000165537792   | 
|  12 characters  | 449225352009601191936  | 

You can search for your WIF ourself. </br>
If there are a lot of characters and you do not decompose the GPU with resources! </br>
You can contact our group for help in telegrams https://t.me/+mAY1x5YYuL8yNjQy </br>
We have quite a lot of GPU resources and we can rent additionally. </br>
The commission is discussed individually.

If you are a miner or have more than 10 GPUs and can quickly (upon request) use your resources to complete the task. </br>
You can become a member of our team, for this, contact our GPU group https://t.me/+WFEuFatijpowMjRi </br>
Commission, conditions are negotiated individually.

P.S. If you don't have 10 gpu or WIF key. Don't waste our time, don't join the group. </br>
If you have general questions ask them [**here**](https://github.com/phrutis/WifSolverCuda/issues)

### Сontinuation
Сontinuation of the last checkpoint from the file Сontinuation.txt</br>
Run: ```WifSolverCuda.exe -wif KyBLV6rrV9hsbsU96VwmEtMnACavqnKnEi7bp7m1SwJ9tM5JQQSo -wif2 KyBLV6rrV9hsbsU96VwmEtMnACavqnKnEi7zzzzzzzJ9tM5JQQSo -a 1EpMLcfjKsQCYUAaVj9mk981qkmT5bxvor -c -n 11 -d 0```

![2](https://user-images.githubusercontent.com/82582647/161609712-2111fa71-2e9c-4508-b329-71ebb100d03b.png)
        
Build
-----
Windows:

Program was prepared using CUDA 11.6 - for any other version manual change in VS project config files is needed. Exe under /Releases/ was build using compute_cap=86, for cards 30xx. If you have older card, you must rebuild program using older CUDA/lower CCAP.

Linux:

Go to WifSolverCuda/ subfolder and execute _make all_. If your device does not support compute capability=86 (error "No kernel image is available for execution on the device"), do the change in _Makefile_ (for example 1080Ti requires COMPUTE_CAP=61).


Performance
-----------
User should modify number of blocks and number of threads in each block to find values which are the best for his card. Number of tests performed by each thread also could have impact of global performance/latency.  

Test card: RTX3060 (eGPU!) with 224 BLOCKS & 640 BLOCK_THREADS (program default values) checks around 10000 MKey/s for compressed address with missing characters in the middle (collision with checksum) and around 1300-1400 Mkey/s for other cases; other results.

| card          | compressed with collision | all other cases |
|---------------|---------------------------|-----------------|
| RTX 3090      | 29 Gkey/s                 | 4.0 Gkey/s      |
| RTX 3080 Ti   | 29 Gkey/s                 | 4.0 Gkey/s      |
| RTX 3060 eGPU | 10 Gkey/s                 | 1.5 Gkey/s      |
| RTX 2070      | 12 Gkey/s                 | 1.4 Gkey/s      |
| GTX 1080TI    | 6 Gkey/s                  | 0.7 Gkey/s      |

If you found this program useful, consider making a donation, I will appreciate it! <br>

Donation:
---------
- [PawelGorny](https://github.com/PawelGorny) (author)    bc1qz2akvlch75rqdfg8pv7chqvz3m8jsl49k0kszc </br>
- [phrutis](https://github.com/phrutis) (modification)    bc1qh2mvnf5fujg93mwl8pe688yucaw9sflmwsukz9

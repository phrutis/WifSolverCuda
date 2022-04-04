
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <vector>
#include <regex>
#include <string>

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <iostream>
#include <chrono>
#include "Timer.h"
#include "lib/Int.h"
#include "lib/Math.cuh"
#include "lib/util.h"
#include "Worker.cuh"

#include "lib/SECP256k1.h"

using namespace std;

void processCandidate(Int& toTest);
bool readArgs(int argc, char** argv);
void showHelp();
bool checkDevice();
void listDevices();
void printConfig();
void printFooter();
void printSpeed(double speed);
void saveStatus();

cudaError_t processCuda();
cudaError_t processCudaUnified();

bool unifiedMemory = true;

int DEVICE_NR = 0;
unsigned int BLOCK_THREADS = 0;
unsigned int BLOCK_NUMBER = 0;
unsigned int THREAD_STEPS = 5000;
char wifkkk[53];
size_t wifLen = 53;
int dataLen = 37;

bool COMPRESSED = true;
Int STRIDE, RANGE_START, RANGE_END, RANGE_START_TOTAL, RANGE_TOTAL;
double RANGE_TOTAL_DOUBLE;
Int loopStride;
Int counter;
double tup;
double speed2;
double _count2;
string TARGET_ADDRESS = "";
string WIF = "";
string WIF999 = "";
string WIFSTART = "";
string WIFEND = "";
string verh = "";
string num_str;
string tik;
Int start1;
Int end1;
Int CHECKSUM;
bool IS_CHECKSUM = false;

bool DECODE = true;
string WIF_TO_DECODE;

bool RESULT = false;
char timeStr[256];
std::string formatThousands(uint64_t x);
uint64_t outputSize;
double t0;
double t1;
string fileResultPartial = "FOUND_partial.txt";
string fileResult = "FOUND.txt";
string Continue777 = "Continue.txt";
int fileStatusInterval = 60;
int step;
string fileStatusRestore;
bool isRestore = false;
char* toTimeStr(int sec, char* timeStr);
bool showDevices = false;
bool p2sh = false;
vector <char> alreadyprintedcharacters;

Secp256K1* secp;



int main(int argc, char** argv)
{    
    printf("\n  WifSolverCuda v1.0 (phrutis modification 04.04.2022)\n\n");
    
    double startTime;
    
    Timer::Init();
    t0 = Timer::get_tick();
    startTime = t0;

    if (readArgs(argc, argv)) {
        showHelp(); 
        printFooter();
        return 0;
    }
    if (showDevices) {
        listDevices();
        printFooter();
        return 0;
    }
  
    dataLen = COMPRESSED ? 38 : 37;
    RANGE_START_TOTAL.Set(&RANGE_START);
    RANGE_TOTAL.Set(&RANGE_END);
    RANGE_TOTAL.Sub(&RANGE_START_TOTAL);
    RANGE_TOTAL_DOUBLE = RANGE_TOTAL.ToDouble();

    if (!checkDevice()) {
        return -1;
    }
    printConfig();

    secp = new Secp256K1();
    secp->Init();

    auto time = std::chrono::system_clock::now();
    std::time_t s_time = std::chrono::system_clock::to_time_t(time);
    std::cout << "  Work started at " << std::ctime(&s_time) << "\n";

    cudaError_t cudaStatus;
    if (unifiedMemory) {
        cudaStatus = processCudaUnified();
    }
    else {
        cudaStatus = processCuda();
    }
    
    time = std::chrono::system_clock::now();
    s_time = std::chrono::system_clock::to_time_t(time);
    std::cout << "\n  Work finished at " << std::ctime(&s_time);

    cudaStatus = cudaDeviceReset();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "  Device reset failed!");
        return 1;
    }

    printFooter();
    return 0;
}

cudaError_t processCudaUnified() {
    cudaError_t cudaStatus;
    uint64_t* buffRangeStart = new uint64_t[NB64BLOCK];
    uint64_t* dev_buffRangeStart = new uint64_t[NB64BLOCK];
    uint64_t* buffStride = new uint64_t[NB64BLOCK];

    const size_t RANGE_TRANSFER_SIZE = NB64BLOCK * sizeof(uint64_t);
    const int COLLECTOR_SIZE_MM = 4 * BLOCK_NUMBER * BLOCK_THREADS;
    const uint32_t expectedChecksum = IS_CHECKSUM ? CHECKSUM.GetInt32() : 0;
    uint64_t counter = 0;

    __Load(buffStride, STRIDE.bits64);
    loadStride(buffStride);
    delete buffStride;

    uint32_t* buffResultManaged = new uint32_t[COLLECTOR_SIZE_MM];
    cudaStatus = cudaMallocManaged(&buffResultManaged, COLLECTOR_SIZE_MM * sizeof(uint32_t));

    for (int i = 0; i < COLLECTOR_SIZE_MM; i++) {
        buffResultManaged[i] = UINT32_MAX;
    }

    bool* buffCollectorWork = new bool[1];
    buffCollectorWork[0] = false;
    bool* dev_buffCollectorWork = new bool[1];
    cudaStatus = cudaMalloc((void**)&dev_buffCollectorWork, 1 * sizeof(bool));
    cudaStatus = cudaMemcpy(dev_buffCollectorWork, buffCollectorWork, 1 * sizeof(bool), cudaMemcpyHostToDevice); 

    cudaStatus = cudaMalloc((void**)&dev_buffRangeStart, NB64BLOCK * sizeof(uint64_t));

    bool* buffIsResultManaged = new bool[1];
    cudaStatus = cudaMallocManaged(&buffIsResultManaged, 1 * sizeof(bool));
    buffIsResultManaged[0] = false;    

    std::chrono::steady_clock::time_point beginCountHashrate = std::chrono::steady_clock::now();
    std::chrono::steady_clock::time_point beginCountStatus = std::chrono::steady_clock::now();

    while (!RESULT && RANGE_START.IsLower(&RANGE_END)) {
        //prepare launch
        __Load(buffRangeStart, RANGE_START.bits64);
        cudaStatus = cudaMemcpy(dev_buffRangeStart, buffRangeStart, RANGE_TRANSFER_SIZE, cudaMemcpyHostToDevice);
        //launch work
        std::chrono::steady_clock::time_point beginKernel = std::chrono::steady_clock::now();
        if (COMPRESSED) {
            if (IS_CHECKSUM) {
                kernelCompressed << <BLOCK_NUMBER, BLOCK_THREADS >> > (buffResultManaged, buffIsResultManaged, dev_buffRangeStart, THREAD_STEPS, expectedChecksum);
            }
            else {
                kernelCompressed << <BLOCK_NUMBER, BLOCK_THREADS >> > (buffResultManaged, buffIsResultManaged, dev_buffRangeStart, THREAD_STEPS);
            }
        }
        else {
            if (IS_CHECKSUM) {
                kernelUncompressed << <BLOCK_NUMBER, BLOCK_THREADS >> > (buffResultManaged, buffIsResultManaged, dev_buffRangeStart, THREAD_STEPS, expectedChecksum);
            }
            else {
                kernelUncompressed << <BLOCK_NUMBER, BLOCK_THREADS >> > (buffResultManaged, buffIsResultManaged, dev_buffRangeStart, THREAD_STEPS);
            }
        }
        cudaStatus = cudaGetLastError();
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "  Kernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
            goto Error;
        }
        cudaStatus = cudaDeviceSynchronize();
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "  CudaDeviceSynchronize returned error code %d after launching kernel!\n", cudaStatus);
            goto Error;
        }
        int64_t tKernel = std::chrono::duration_cast<std::chrono::microseconds>(std::chrono::steady_clock::now() - beginKernel).count();        
        if (buffIsResultManaged[0]) {
            buffIsResultManaged[0] = false;
            for (int i = 0; i < COLLECTOR_SIZE_MM && !RESULT; i++) {
                if (buffResultManaged[i] != UINT32_MAX) {
                    Int toTest = new Int(&RANGE_START);
                    Int diff = new Int(&STRIDE);
                    diff.Mult(buffResultManaged[i]);
                    toTest.Add(&diff);
                    processCandidate(toTest);
                    buffResultManaged[i] = UINT32_MAX;
                }
            }
        }//test

        RANGE_START.Add(&loopStride);
        counter += outputSize;
        int64_t tHash = std::chrono::duration_cast<std::chrono::seconds>(std::chrono::steady_clock::now() - beginCountHashrate).count();
        if (tHash > 0) {
            double speed = (double)((double)counter / tHash) / 1000000.0;
            _count2 += (double)((double)counter / tHash);
            printSpeed(speed);
            counter = 0;
            beginCountHashrate = std::chrono::steady_clock::now();
        }
        if (std::chrono::duration_cast<std::chrono::seconds>(std::chrono::steady_clock::now() - beginCountStatus).count() > fileStatusInterval) {
            saveStatus();
            beginCountStatus = std::chrono::steady_clock::now();
        }
    }//while

Error:
    cudaFree(dev_buffRangeStart);
    cudaFree(dev_buffCollectorWork);
    cudaFree(buffResultManaged);
    return cudaStatus;
}

cudaError_t processCuda() {
    cudaError_t cudaStatus;
    uint64_t* buffRangeStart = new uint64_t[NB64BLOCK];
    uint64_t* dev_buffRangeStart = new uint64_t[NB64BLOCK];
    uint64_t* buffStride = new uint64_t[NB64BLOCK];
    
    int COLLECTOR_SIZE = BLOCK_NUMBER;

    __Load(buffStride, STRIDE.bits64);
    loadStride(buffStride);
    delete buffStride;


    bool* buffDeviceResult = new bool[outputSize];
    bool* dev_buffDeviceResult = new bool[outputSize];
    for (int i = 0; i < outputSize; i++) {
        buffDeviceResult[i] = false;
    }
    cudaStatus = cudaMalloc((void**)&dev_buffDeviceResult, outputSize * sizeof(bool));
    cudaStatus = cudaMemcpy(dev_buffDeviceResult, buffDeviceResult, outputSize * sizeof(bool), cudaMemcpyHostToDevice);       
        
    delete buffDeviceResult;

    uint64_t* buffResult = new uint64_t[COLLECTOR_SIZE];
    uint64_t* dev_buffResult = new uint64_t[COLLECTOR_SIZE];
    cudaStatus = cudaMalloc((void**)&dev_buffResult, COLLECTOR_SIZE * sizeof(uint64_t));
    cudaStatus = cudaMemcpy(dev_buffResult, buffResult, COLLECTOR_SIZE * sizeof(uint64_t), cudaMemcpyHostToDevice);

    bool* buffCollectorWork = new bool[1];
    buffCollectorWork[0] = false;
    bool* dev_buffCollectorWork = new bool[1];
    cudaStatus = cudaMalloc((void**)&dev_buffCollectorWork, 1 * sizeof(bool));
    cudaStatus = cudaMemcpy(dev_buffCollectorWork, buffCollectorWork, 1 * sizeof(bool), cudaMemcpyHostToDevice);

    cudaStatus = cudaMalloc((void**)&dev_buffRangeStart, NB64BLOCK * sizeof(uint64_t));

    const uint32_t expectedChecksum = IS_CHECKSUM ? CHECKSUM.GetInt32() : 0;

    uint64_t counter = 0;
    bool anyResult = false;

    size_t RANGE_TRANSFER_SIZE = NB64BLOCK * sizeof(uint64_t);
    size_t COLLECTOR_TRANSFER_SIZE = COLLECTOR_SIZE * sizeof(uint64_t);

    std::chrono::steady_clock::time_point beginCountHashrate = std::chrono::steady_clock::now();
    std::chrono::steady_clock::time_point beginCountStatus = std::chrono::steady_clock::now();

    while (!RESULT && RANGE_START.IsLower(&RANGE_END)) {
        //prepare launch
        __Load(buffRangeStart, RANGE_START.bits64);
        cudaStatus = cudaMemcpy(dev_buffRangeStart, buffRangeStart, RANGE_TRANSFER_SIZE, cudaMemcpyHostToDevice);
        //launch work
        if (COMPRESSED) {
            if (IS_CHECKSUM) {
                kernelCompressed << <BLOCK_NUMBER, BLOCK_THREADS >> > (dev_buffDeviceResult, dev_buffCollectorWork, dev_buffRangeStart, THREAD_STEPS, expectedChecksum);
            }else{
                kernelCompressed << <BLOCK_NUMBER, BLOCK_THREADS >> > (dev_buffDeviceResult, dev_buffCollectorWork, dev_buffRangeStart, THREAD_STEPS);
            }            
        }
        else {            
            if (IS_CHECKSUM) {
                kernelUncompressed << <BLOCK_NUMBER, BLOCK_THREADS >> > (dev_buffDeviceResult, dev_buffCollectorWork, dev_buffRangeStart, THREAD_STEPS, expectedChecksum);
            }else{
                kernelUncompressed << <BLOCK_NUMBER, BLOCK_THREADS >> > (dev_buffDeviceResult, dev_buffCollectorWork, dev_buffRangeStart, THREAD_STEPS);
            }
            
        }        
        cudaStatus = cudaGetLastError();
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "  Kernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
            goto Error;
        }
        cudaStatus = cudaDeviceSynchronize();
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "  CudaDeviceSynchronize returned error code %d after launching kernel!\n", cudaStatus);
            goto Error;
        }

        //if (useCollector) {
            //summarize results            
            cudaStatus = cudaMemcpy(buffCollectorWork, dev_buffCollectorWork, sizeof(bool), cudaMemcpyDeviceToHost);                      
            if (buffCollectorWork[0]) {
                anyResult = true;
                buffCollectorWork[0] = false;                
                cudaStatus = cudaMemcpyAsync(dev_buffCollectorWork, buffCollectorWork, sizeof(bool), cudaMemcpyHostToDevice);            
                for (int i = 0; i < COLLECTOR_SIZE; i++) {
                    buffResult[i] = 0;
                }
                cudaStatus = cudaMemcpy(dev_buffResult, buffResult, COLLECTOR_TRANSFER_SIZE, cudaMemcpyHostToDevice);
                while (anyResult && !RESULT) {
                    resultCollector << <BLOCK_NUMBER, 1 >> > (dev_buffDeviceResult, dev_buffResult, THREAD_STEPS * BLOCK_THREADS);
                    cudaStatus = cudaGetLastError();
                    if (cudaStatus != cudaSuccess) {
                        fprintf(stderr, "  Kernel 'resultCollector' launch failed: %s\n", cudaGetErrorString(cudaStatus));
                        goto Error;
                    }
                    cudaStatus = cudaDeviceSynchronize();
                    if (cudaStatus != cudaSuccess) {
                        fprintf(stderr, "  CudaDeviceSynchronize 'resultCollector' returned error code %d after launching kernel!\n", cudaStatus);
                        goto Error;
                    }
                    cudaStatus = cudaMemcpy(buffResult, dev_buffResult, COLLECTOR_TRANSFER_SIZE, cudaMemcpyDeviceToHost);
                    if (cudaStatus != cudaSuccess) {
                        fprintf(stderr, "  CudaMemcpy failed!");
                        goto Error;
                    }
                    anyResult = false;

                    for (int i = 0; i < COLLECTOR_SIZE; i++) {
                        if (buffResult[i] != 0xffffffffffff) {
                            Int toTest = new Int(&RANGE_START);
                            Int diff = new Int(&STRIDE);
                            diff.Mult(buffResult[i]);
                            toTest.Add(&diff);
                            processCandidate(toTest);
                            anyResult = true;
                        }
                    }
                }//while
            }//anyResult to test
        //}
        /*else {
            //pure output, for debug 
            cudaStatus = cudaMemcpy(buffDeviceResult, dev_buffDeviceResult, outputSize * sizeof(bool), cudaMemcpyDeviceToHost);
            if (cudaStatus != cudaSuccess) {
                fprintf(stderr, "cudaMemcpy failed!");
                goto Error;
            }
            for (int i = 0; i < outputSize; i++) {
                if (buffDeviceResult[i]) {
                    Int toTest = new Int(&RANGE_START);
                    Int diff = new Int(&STRIDE);
                    diff.Mult(i);
                    toTest.Add(&diff);
                    processCandidate(toTest);
                }
            }
        } */      
        RANGE_START.Add(&loopStride);
        counter += outputSize;
        //_count2 += outputSize;
        int64_t tHash = std::chrono::duration_cast<std::chrono::seconds>(std::chrono::steady_clock::now() - beginCountHashrate).count();
        //int64_t tStatus = std::chrono::duration_cast<std::chrono::seconds>(std::chrono::steady_clock::now() - beginCountStatus).count();
        if (tHash > 0) {
            double speed = (double)((double)counter / tHash) / 1000000.0;
            _count2 += (double)((double)counter / tHash);
            printSpeed(speed);            
            counter = 0;
            beginCountHashrate = std::chrono::steady_clock::now();
        }
        if (std::chrono::duration_cast<std::chrono::seconds>(std::chrono::steady_clock::now() - beginCountStatus).count() > fileStatusInterval) {
            saveStatus();
            beginCountStatus = std::chrono::steady_clock::now();
        }
    }//while

Error:
    cudaFree(dev_buffResult);
    cudaFree(dev_buffDeviceResult);
    cudaFree(dev_buffRangeStart);
    cudaFree(dev_buffCollectorWork);
    return cudaStatus;
}

void saveStatus() {
    
    string str77 = to_string(DEVICE_NR);
    string prodol = str77 + Continue777;
    FILE* stat = fopen(prodol.c_str(), "w");
    auto time = std::chrono::system_clock::now();
    std::time_t s_time = std::chrono::system_clock::to_time_t(time);
    fprintf(stat, "%s\n", std::ctime(&s_time));    
    char wif[53];
    unsigned char* buff = new unsigned char[dataLen];
    fprintf(stat, "WifSolverCuda.exe -wif %s ", wifkkk); 
    fprintf(stat, "-wif2 %s ", WIFEND.c_str());
    if (!TARGET_ADDRESS.empty()) {
        fprintf(stat, "-a %s ", TARGET_ADDRESS.c_str());
    }
    if (COMPRESSED) {
        fprintf(stat, "-c ");
    }else {
        fprintf(stat, "-u ");
    }
    fprintf(stat, "-n %d ", step);
    fprintf(stat, "-d %d\n", DEVICE_NR);
    fclose(stat);
}

char* toTimeStr(int sec, char* timeStr)
{
    int h, m, s;
    h = (sec / 3600);
    m = (sec - (3600 * h)) / 60;
    s = (sec - (3600 * h) - (m * 60));
    sprintf(timeStr, "%0*d:%0*d:%0*d", 2, h, 2, m, 2, s);
    return (char*)timeStr;
}

std::string formatThousands(uint64_t x)
{
    char buf[32] = "";

    sprintf(buf, "%llu", x);

    std::string s(buf);

    int len = (int)s.length();

    int numCommas = (len - 1) / 3;

    if (numCommas == 0) {
        return s;
    }

    std::string result = "";

    int count = ((len % 3) == 0) ? 0 : (3 - (len % 3));

    for (int i = 0; i < len; i++) {
        result += s[i];

        if (count++ == 2 && i < len - 1) {
            result += ",";
            count = 0;
        }
    }
    return result;
}


void printSpeed(double speed) {
    std::string speedStr;
    if (speed < 0.01) {
        speedStr = "< 0.01 MKey/s";
    }
    else {
        if (speed < 1000) {
            speedStr = formatDouble("%.3f", speed) + " MKey/s";
        }
        else {
            speed /= 1000;
            if (speed < 1000) {
                speedStr = formatDouble("%.3f", speed) + " GKey/s";
            }
            else {
                speed /= 1000;
                speedStr = formatDouble("%.3f", speed) + " TKey/s";
            }
        }
    }

    char wif[53];
    unsigned char* buff = new unsigned char[dataLen];
    for (int i = 0, d = dataLen - 1; i < dataLen; i++, d--) {
        buff[i] = RANGE_START.GetByte(d);
    }
   
    b58encode(wif, &wifLen, buff, dataLen);
    b58encode(wifkkk, &wifLen, buff, dataLen);
    t1 = Timer::get_tick();
    Int processedCount= new Int(&RANGE_START);
    processedCount.Sub(&RANGE_START_TOTAL);
    double _count = processedCount.ToDouble();
    _count = _count / RANGE_TOTAL_DOUBLE;
    _count *= 100;
    num_str = to_string(_count);
    tik = formatThousands(_count2).c_str();
    string num_gpu = to_string(DEVICE_NR);
    verh = " GPU: " + num_gpu + "  C: " + num_str;
    SetConsoleTitle(verh.c_str());
    printf("\r  [%s] [%s] [S: %s] [T: %s] ", toTimeStr(t1, timeStr), wif, speedStr.c_str(), formatThousands(_count2).c_str()); 
    fflush(stdout);
}

void processCandidate(Int &toTest) {     
    FILE* keys;
    char rmdhash[21], address[50], wif[53];        
    unsigned char* buff = new unsigned char[dataLen];
    for (int i = 0, d=dataLen-1; i < dataLen; i++, d--) {
        buff[i] = toTest.GetByte(d);
    }       
    toTest.SetBase16((char*)toTest.GetBase16().substr(2, 64).c_str());        
    Point publickey = secp->ComputePublicKey(&toTest);        
    if (p2sh) {
        secp->GetHash160(P2SH, true, publickey, (unsigned char*)rmdhash);
    }
    else {
        secp->GetHash160(P2PKH, COMPRESSED, publickey, (unsigned char*)rmdhash);
    }
    addressToBase58(rmdhash, address, p2sh);    
    if (!TARGET_ADDRESS.empty()) {
        if (TARGET_ADDRESS == address) {
            RESULT = true;            
            printf("\n  =================================================================================\n");
            printf("  BTC address: %s\n", address);
            printf("  Private key: %s\n", toTest.GetBase16().c_str());
            if (b58encode(wif, &wifLen, buff, dataLen)) {
                printf("  WIF key    : %s\n", wif);
            }
            printf("  =================================================================================\n");
            keys = fopen(fileResult.c_str(), "a+");
            fprintf(keys, "%s\n", address);
            fprintf(keys, "%s\n", wif);
            fprintf(keys, "%s\n\n", toTest.GetBase16().c_str());            
            fclose(keys);
            return;
        }
    }
    else {
        printf("\n  =================================================================================\n");
        printf("  Address    : %s\n", address);
        printf("  Private key: %s\n", toTest.GetBase16().c_str());
        if (b58encode(wif, &wifLen, buff, dataLen)) {
            printf("  WIF key    : %s\n", wif);
        }
        printf("  =================================================================================\n");
        keys = fopen(fileResultPartial.c_str(), "a+");
        fprintf(keys, "%s\n", address);
        fprintf(keys, "%s\n", wif);
        fprintf(keys, "%s\n\n", toTest.GetBase16().c_str());        
        fclose(keys);
    }
}

void printConfig() {

    if (COMPRESSED) {
        printf("  Search mode     : COMPRESSED\n");
    }
    else {
        printf("  Search mode     : UNCOMPRESSED\n");
    }
    printf("  WIF START       : %s\n", WIFSTART.c_str());
    printf("  WIF END         : %s\n", WIFEND.c_str());
    if (!TARGET_ADDRESS.empty()) {
        printf( "  BTC Address     : %s\n", TARGET_ADDRESS.c_str());
    }
    printf("  Position chars  : %d \n", step);
    //printf("  Combinations :     %d \n", step);
    
    printf( "\n");
    printf( "  Number of blocks : %d\n", BLOCK_NUMBER);
    printf( "  Number of threads: %d\n", BLOCK_THREADS);
    printf( "  Number of checks per thread: %d\n", THREAD_STEPS);
    printf( "\n");
}

void printFooter() {
    printf("  ---------------------------------\n");
    printf("  SITE: https://github.com/phrutis/WifSolverCuda\n\n");
}

bool checkDevice() {
    cudaError_t cudaStatus = cudaSetDevice(DEVICE_NR);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "  Device %d failed!", DEVICE_NR);
        return false;
    }
    else {
        cudaDeviceProp props;
        cudaStatus = cudaGetDeviceProperties(&props, DEVICE_NR);
        printf("  Using GPU nr %d:\n", DEVICE_NR);
        if (props.canMapHostMemory == 0) {
            printf("  Unified memory not supported\n");
            unifiedMemory = 0;
        }
        printf("  %s (%2d procs)\n", props.name, props.multiProcessorCount);
        printf("  MaxThreadsPerBlock: %2d\n\n", props.maxThreadsPerBlock);        
        if (BLOCK_NUMBER == 0) {
            BLOCK_NUMBER = props.multiProcessorCount * 8;
        }
        if (BLOCK_THREADS == 0) {
            BLOCK_THREADS = (props.maxThreadsPerBlock / 8) * 5;
        }
        outputSize = BLOCK_NUMBER * BLOCK_THREADS * THREAD_STEPS;
        loopStride = new Int(&STRIDE);
        loopStride.Mult(outputSize);
    }
    return true;
}

void showHelp() {    
    
    printf("-wif             START WIF key 5.... (51 characters) or L..., K...., (52 characters)  \n");
    printf("-wif2            END WIF key 5.... (51 characters) or L..., K...., (52 characters)  \n");
    printf("-a               Bitcoin address 1.... or 3.....\n");
    printf("-n               Letter number from left to right from 9 to 51 \n");
    printf("-fresult         The name of the output file about the find (default: FOUND.txt)\n");
    printf("-fname           The name of the checkpoint save file to continue (default: GPUid + Continue.txt) \n");
    printf("-ftime           Save checkpoint to continue every sec (default %d sec) \n", fileStatusInterval);
    printf("-d               DeviceId. Number GPU (default 0)\n");
    printf("-c               Search for compressed address (default)\n");
    printf("-u               Search for uncompressed address\n");
    printf("-b               NbBlocks. Default processorCount * 8\n");
    printf("-t               NbThreads. Default deviceMax/8 * 5\n");
    printf("-s               NbThreadChecks. Default %d\n", THREAD_STEPS);    
    printf("-listDevices     Shows available devices \n");
    printf("-disable-um      Disable unified memory mode\n");
    printf("-h               Shows help page\n");
}
 
bool readArgs(int argc, char** argv) {
    int a = 1;
    bool isStride = false;
    bool isStart = false;
    bool isEnd = false;    
    while (a < argc) {
        if (strcmp(argv[a], "-h") == 0) {
            return true;
        }else
        if (strcmp(argv[a], "-decode555") == 0) {
            a++;
            WIF_TO_DECODE = string(argv[a]);
            DECODE = true;
            return false;
        }
        else if (strcmp(argv[a], "-listDevices") == 0) {
            showDevices = true;
            return false;
        }
        else if (strcmp(argv[a], "-d") == 0) {
            a++;
            DEVICE_NR = strtol(argv[a], NULL, 10);
        }
        else if (strcmp(argv[a], "-c") == 0) {
            COMPRESSED = true;
        }
        else if (strcmp(argv[a], "-u") == 0) {
            COMPRESSED = false;
            if (p2sh) {
                COMPRESSED = true;
            }
        }
        else if (strcmp(argv[a], "-t") == 0) {
            a++;
            BLOCK_THREADS = strtol(argv[a], NULL, 10);
        }
        else if (strcmp(argv[a], "-b") == 0) {
            a++;
            BLOCK_NUMBER = strtol(argv[a], NULL, 10);
        }
        else if (strcmp(argv[a], "-s") == 0) {
            a++;
            THREAD_STEPS = strtol(argv[a], NULL, 10);
        }
        else if (strcmp(argv[a], "-stride555") == 0) {
            a++;
            STRIDE.SetBase16((char*)string(argv[a]).c_str());
            isStride = true;
        }
        else if (strcmp(argv[a], "-fresult") == 0) {
            a++;
            fileResult = string(argv[a]);
        }
        else if (strcmp(argv[a], "-fresultp") == 0) {
            a++;
            fileResultPartial = string(argv[a]);
        }
        else if (strcmp(argv[a], "-fname") == 0) {
            a++;
            Continue777 = string(argv[a]);
        }
        else if (strcmp(argv[a], "-ftime") == 0) {
            a++;
            fileStatusInterval = strtol(argv[a], NULL, 10);
        }
        else if (strcmp(argv[a], "-n") == 0) {
            a++;
            step = strtol(argv[a], NULL, 10);
        }
        else if (strcmp(argv[a], "-a") == 0) {
            a++;
            TARGET_ADDRESS = string(argv[a]);
            if (argv[a][0] == '3') {
                p2sh = true;
                COMPRESSED = true;
            }
        }
        else if (strcmp(argv[a], "-wif") == 0) {
            a++;
            WIF = string(argv[a]);
        }
        else if (strcmp(argv[a], "-wif2") == 0) {
            a++;
            WIF999 = string(argv[a]);
        }
        else if (strcmp(argv[a], "-checksum555") == 0) {
            a++;
            CHECKSUM.SetBase16((char*)string(argv[a]).c_str());
            IS_CHECKSUM = true;
        }
        else if (strcmp(argv[a], "-disable-um") == 0) {
            unifiedMemory = 0;
            printf("  Unified memory mode disabled\n");
        }
        a++;
    }    

    if (WIF != "") {

        if (WIF.length() < 51) {
            int oshibka = WIF.length();
            
            printf("\n  ERROR WIF     : Mistake! Your WIF key %s is of length %d! \n  Uncompressed WIF key = 51 characters and start with  5........  \n  Compressed WIF key = 52 characters and start with K.... or L....\n\n", WIFSTART.c_str(), oshibka);
            return -1;
        }
        if (WIF.length() > 52) {
            int oshibka = WIF.length();

            printf("\n  ERROR WIF     : Mistake! Your WIF key %s is of length %d! \n  Uncompressed WIF key = 51 characters and start with  5........  \n  Compressed WIF key = 52 characters and start with K.... or L....\n\n", WIFSTART.c_str(), oshibka);
            return -1;
        }
        string wifs = WIF;
        int asciiArray[256];
        char ch;
        int charconv;
        for (int i = 0; i < 256; i++)
            asciiArray[i] = 0;
        for (unsigned int i = 0; i < wifs.length(); i++)
        {
            ch = wifs[i];
            charconv = static_cast<int>(ch);
            asciiArray[charconv]++;
        }

        for (unsigned int i = 0; i < wifs.length(); i++)
        {
            char static alreadyprinted;
            char ch = wifs[i];

            if ((asciiArray[ch] > 2) && (ch != alreadyprinted) && (find(alreadyprintedcharacters.begin(), alreadyprintedcharacters.end(), ch) == alreadyprintedcharacters.end()))
            {
                string proverka = wifs;
                
                string proverka1 = regex_replace(proverka, regex("XXXXXXXXXXXX"), "111111111111");
                string proverka2 = regex_replace(proverka1, regex("XXXXXXXXXXX"), "11111111111");
                string proverka3 = regex_replace(proverka2, regex("XXXXXXXXXX"), "1111111111");
                string proverka4 = regex_replace(proverka3, regex("XXXXXXXXX"), "111111111");
                string proverka5 = regex_replace(proverka4, regex("XXXXXXXX"), "11111111");
                string proverka6 = regex_replace(proverka5, regex("XXXXXXX"), "1111111");
                string proverka7 = regex_replace(proverka6, regex("XXXXXX"), "111111");
                string proverka8 = regex_replace(proverka7, regex("XXXXX"), "11111");
                string proverka9 = regex_replace(proverka8, regex("XXXX"), "1111");
                WIFSTART = proverka9;
            }
        }
    }
    if (WIF != "") {

        string wife = WIF;
        int asciiArray[256];
        char ch;
        int charconv;
        for (int i = 0; i < 256; i++)
            asciiArray[i] = 0;
        for (unsigned int i = 0; i < wife.length(); i++)
        {
            ch = wife[i];
            charconv = static_cast<int>(ch);
            asciiArray[charconv]++;
        }

        for (unsigned int i = 0; i < wife.length(); i++)
        {
            char static alreadyprinted;
            char ch = wife[i];

            if ((asciiArray[ch] > 2) && (ch != alreadyprinted) && (find(alreadyprintedcharacters.begin(), alreadyprintedcharacters.end(), ch) == alreadyprintedcharacters.end()))
            {
                string proverkae = wife;

                string proverkae1 = regex_replace(proverkae, regex("XXXXXXXXXXXX"), "zzzzzzzzzzzz");
                string proverkae2 = regex_replace(proverkae1, regex("XXXXXXXXXXX"), "zzzzzzzzzzz");
                string proverkae3 = regex_replace(proverkae2, regex("XXXXXXXXXX"), "zzzzzzzzzz");
                string proverkae4 = regex_replace(proverkae3, regex("XXXXXXXXX"), "zzzzzzzzz");
                string proverkae5 = regex_replace(proverkae4, regex("XXXXXXXX"), "zzzzzzzz");
                string proverkae6 = regex_replace(proverkae5, regex("XXXXXXX"), "zzzzzzz");
                string proverkae7 = regex_replace(proverkae6, regex("XXXXXX"), "zzzzzz");
                string proverkae8 = regex_replace(proverkae7, regex("XXXXX"), "zzzzz");
                string proverkae9 = regex_replace(proverkae8, regex("XXXX"), "zzzz");
                
                if (proverkae9 == wife) {
                    
                    if (COMPRESSED) {
                        WIFEND = "L5oLkpV3aqBjhki6LmvChTCV6odsp4SXM6FfU2Gppt5kFLaHLuZ9";
                    }
                    else {
                        WIFEND = "5Km2kuu7vtFDPpxywn4u3NLpbr5jKpTB3jsuDU2KYEqetqj84qw";
                    }
                }
                else {
                    WIFEND = proverkae9;
                }

                if (WIF999 != "") {
                    WIFEND = WIF999;
                
                }
            }
        }
    }
    if (WIF == "") {
        WIFSTART = "KwDiBf89QgGbjEhKnhXJuH7LrciVrZi3qYjgd9M7rFU73sVHnoWn";
        WIFEND = "L5oLkpV3aqBjhki6LmvChTCV6odsp4SXM6FfU2Gppt5k7NVCBwG4";
    }
    if (step == 0) {
        step = 9;
    }
    const char* base58 = WIFSTART.c_str();
    size_t base58Length = WIFSTART.size();
    size_t keybuflen = base58Length == 52 ? 38 : 37;
    unsigned char* keybuf = new unsigned char[keybuflen];
    b58decode(keybuf, &keybuflen, base58, base58Length);
    
    string nos2 = "";
    for (int i = 0; i < keybuflen; i++) {
        char s[32];
        snprintf(s, 32, "%.2x", keybuf[i]);
        string str777(s);
        nos2 = nos2 + str777;
    }
    char* cstr959 = &nos2[0];
    RANGE_START.SetBase16(cstr959);
 
    const char* base582 = WIFEND.c_str();
    size_t base58Length2 = WIFEND.size();
    size_t keybuflen2 = base58Length2 == 52 ? 38 : 37;
    unsigned char* keybuf2 = new unsigned char[keybuflen2];
    b58decode(keybuf2, &keybuflen2, base582, base58Length2);

    string nos22 = "";
    for (int i = 0; i < keybuflen2; i++) {
        char s2[32];
        snprintf(s2, 32, "%.2x", keybuf2[i]);
        string str7772(s2);
        nos22 = nos22 + str7772;
    }
    char* cstr9592 = &nos22[0];
    RANGE_END.SetBase16(cstr9592);
    
    if (step < 9) {
        printf("\n  ERROR     : Mistake! Rotate checksum in development! Minimum character -n 9  (max -n 51)\n\n");
        return -1;
    }
    if (step == 9) {
        STRIDE.SetBase16((char*)string("7479027ea100").c_str());

    }
    if (step == 10) {
        STRIDE.SetBase16((char*)string("1a636a90b07a00").c_str());

    }
    if (step == 11) {
        STRIDE.SetBase16((char*)string("5fa8624c7fba400").c_str());

    }
    if (step == 12) {
        STRIDE.SetBase16((char*)string("15ac264554f032800").c_str());

    }
    if (step == 13) {
        STRIDE.SetBase16((char*)string("4e900abb53e6b71000").c_str());

    }
    if (step == 14) {
        STRIDE.SetBase16((char*)string("11cca26e71024579a000").c_str());

    }
    if (step == 15) {
        STRIDE.SetBase16((char*)string("4085ccd059a83bd8e4000").c_str());

    }
    if (step == 16) {
        STRIDE.SetBase16((char*)string("e9e506734501d8f23a8000").c_str());

    }
    if (step == 17) {
        STRIDE.SetBase16((char*)string("34fde3761da26b26e1410000").c_str());

    }
    if (step == 18) {
        STRIDE.SetBase16((char*)string("c018588c2b6cc46cf08ba0000").c_str());

    }
    if (step == 19) {
        STRIDE.SetBase16((char*)string("2b85840fc1d6a480ae7fa240000").c_str());

    }
    if (step == 20) {
        STRIDE.SetBase16((char*)string("9dc3feb91eaa1452788eac280000").c_str());

    }
    if (step == 21) {
        STRIDE.SetBase16((char*)string("23be67b5f0f2889aaf505301100000").c_str());

    }
    if (step == 22) {
        STRIDE.SetBase16((char*)string("819237f3896f2f30bb832ce3da00000").c_str());

    }
    if (step == 23) {
        STRIDE.SetBase16((char*)string("1d5b20ad2d2330b10a7bb82b9f6400000").c_str());

    }
    if (step == 24) {
        STRIDE.SetBase16((char*)string("6a6a5673c39f9081c6007b9e21ca800000").c_str());

    }
    if (step == 25) {
        STRIDE.SetBase16((char*)string("181c17963a5226bd66dc1c01d3a7e1000000").c_str());

    }
    if (step == 26) {
        STRIDE.SetBase16((char*)string("5765d5809369cc6e94dde5869f408fa000000").c_str());

    }
    if (step == 27) {
        STRIDE.SetBase16((char*)string("13cd125f2165f8510dba46008014a08a4000000").c_str());

    }
    if (step == 28) {
        STRIDE.SetBase16((char*)string("47c76298d911a425d1c33dc1d04ac5f528000000").c_str());

    }
    if (step == 29) {
        STRIDE.SetBase16((char*)string("10432c56a12dff3091863bfde930f0d98b10000000").c_str());

    }
    if (step == 30) {
        STRIDE.SetBase16((char*)string("3af380ba0846bd100f8699786d516914981a0000000").c_str());

    }
    if (step == 31) {
        STRIDE.SetBase16((char*)string("d5b2b2a25e006d5a3847ec548c471ceaa75e40000000").c_str());

    }
    if (step == 32) {
        STRIDE.SetBase16((char*)string("306a7c78c94c18c670c04b8b27c81c8d29eb5a80000000").c_str());

    }
    if (step == 33) {
        STRIDE.SetBase16((char*)string("af820335d9b3d9cf58b911d87035677fb7f528100000000").c_str());

    }
    if (step == 34) {
        STRIDE.SetBase16((char*)string("27c374ba3352bf58fa19ee0b096c1972efad8b13a00000000").c_str());

    }
    if (step == 35) {
        STRIDE.SetBase16((char*)string("90248722fa0bf5a28a9dfee80227dc40a4d518272400000000").c_str());

    }
    if (step == 36) {
        STRIDE.SetBase16((char*)string("20a8469deca6b5a6d367cbc0907d07e6a5584778de2800000000").c_str());

    }
    if (step == 37) {
        STRIDE.SetBase16((char*)string("7661fffc79dc527cbe58429a0bc53ca4176003162551000000000").c_str());

    }
    if (step == 38) {
        STRIDE.SetBase16((char*)string("1ad233ff339beab0431fff16e6aaafbd2d4bc0b304745a000000000").c_str());

    }
    if (step == 39) {
        STRIDE.SetBase16((char*)string("6139fc7d1b1532bef353fcb3042abd0dc4329a88f025c64000000000").c_str());

    }
    if (step == 40) {
        STRIDE.SetBase16((char*)string("160723345822cd7f432107408ef1aed51e73770306688eea8000000000").c_str());

    }
    if (step == 41) {
        STRIDE.SetBase16((char*)string("4fd9df9dbf7e28ed5357ba4a062c19c48e628f6af73b061210000000000").c_str());

    }
    if (step == 42) {
        STRIDE.SetBase16((char*)string("12175ca9bd629545c4e1e034c565fdd68842547e3c035f6017a0000000000").c_str());

    }
    if (step == 43) {
        STRIDE.SetBase16((char*)string("4194afe74e855d1ce9b2ccbf4b91b829adf07249998c39bc55a40000000000").c_str());

    }
    if (step == 44) {
        STRIDE.SetBase16((char*)string("edbafda67ca37188cf28263571f03b9716879e4acc9c514ab67280000000000").c_str());

    }
    if (step == 45) {
        STRIDE.SetBase16((char*)string("35dc5d77b83d07b8feef18a81bd06d803b1ab9dcf25b6a6aed55f100000000000").c_str());

    }
    if (step == 46) {
        STRIDE.SetBase16((char*)string("c33ed2d1fbdd3bfe9c22b96164d38cf0d640e1c0ee8b61c39c5789a00000000000").c_str());

    }
    if (step == 47) {
        STRIDE.SetBase16((char*)string("2c3c3bc393101f97af5fde0010d7edee908ab325b60b9426516bd52e400000000000").c_str());

    }
    if (step == 48) {
        STRIDE.SetBase16((char*)string("a05a58a4f51a7285dbbb84c03d0ebe80cbf6c968b3e9f90ae726e4c7a800000000000").c_str());

    }
    if (step == 49) {
        STRIDE.SetBase16((char*)string("245478155f87fdf253c87c138dd557292e35e9a1b8c3026c785ecfd53c1000000000000").c_str());

    }
    if (step == 50) {
        STRIDE.SetBase16((char*)string("83b2334d7a4cf88e6fb6c1c6e2255bf547836eea3dc2e8c93457b164f9ba000000000000").c_str());

    }
    if (step == 51) {
        STRIDE.SetBase16((char*)string("1dd65f9f8db57050454f67e70f3c76d59233c72111fe28bd95dbde30e09424000000000000").c_str());

    }
    return false;
}

void listDevices() {
    int nDevices;
    cudaGetDeviceCount(&nDevices);
    for (int i = 0; i < nDevices; i++) {
        cudaDeviceProp prop;
        cudaGetDeviceProperties(&prop, i);
        printf("  Device Number: %d\n", i);
        printf("  %s\n", prop.name);
        if (prop.canMapHostMemory == 0) {
            printf("  Unified memory not supported\n");
        }
        printf("  %2d procs\n", prop.multiProcessorCount);
        printf("  MaxThreadsPerBlock: %2d\n", prop.maxThreadsPerBlock);
        printf("  Version majorminor: %d%d\n\n", prop.major, prop.minor);
    }
}
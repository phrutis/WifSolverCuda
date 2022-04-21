
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <vector>
#include <regex>
#include <string>
#include <sstream>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdint.h>
#include <iostream>
#include <chrono>
#include "Timer.h"
#include "lib/Int.h"
#include "lib/Math.cuh"
#include "lib/util.h"
#include "Worker.cuh"
#include <sstream>
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
size_t wifLen = 53;
int dataLen = 37;
int zapusk;
int turbo;
bool COMPRESSED = true;
Int STRIDE, STRIDE2, RANGE_START, RANGE_END, RANGE_START_TOTAL, RANGE_TOTAL;
double RANGE_TOTAL_DOUBLE;
Int loopStride;
Int counter;
string TARGET_ADDRESS = "";
string WIF = "";
string WIF999 = "";
string WIFSTART = "";
string WIFEND = "";
string part1 = "";
string part2 = "";
string verh;
string num_str;
string nitro;
uint64_t speed2;
string zamena = "TURBO MODE: WIF KEY BEFORE";
string zamena2 = "WIF KEY AFTER";
string zamena3;
string security;
string kstr99;
int zcount;
Int start1;
Int shagi;
Int end1;
Int CHECKSUM;
Int down;
bool IS_CHECKSUM = false;

bool DECODE = true;
string WIF_TO_DECODE;
string wifout = "";
bool RESULT = false;
char timeStr[256];
char timeStr2[256];
std::string formatThousands(uint64_t x);
uint64_t outputSize;
uint64_t speed3;
double t0;
double t1;
string fileResultPartial = "FOUND_partial.txt";
string fileResult = "FOUND.txt";
string Continue777 = "Continue.txt";
int fileStatusInterval = 60;
int step;
int step2;
int kusok;
string fileStatusRestore;
bool isRestore = false;
char* toTimeStr(int sec, char* timeStr);
bool showDevices = false;
bool p2sh = false;
vector <char> alreadyprintedcharacters;

Secp256K1* secp;



int main(int argc, char** argv)
{    
    int color = 15;
    struct console
    {
        console(unsigned width, unsigned height)
        {
            SMALL_RECT r;
            COORD      c;
            hConOut = GetStdHandle(STD_OUTPUT_HANDLE);
            if (!GetConsoleScreenBufferInfo(hConOut, &csbi))
                throw runtime_error("You must be attached to a human.");

            r.Left =
                r.Top = 0;
            r.Right = width - 1;
            r.Bottom = height - 1;
            SetConsoleWindowInfo(hConOut, TRUE, &r);

            c.X = width;
            c.Y = height;
            SetConsoleScreenBufferSize(hConOut, c);
        }

        ~console()
        {
            SetConsoleTextAttribute(hConOut, csbi.wAttributes);
            SetConsoleScreenBufferSize(hConOut, csbi.dwSize);
            SetConsoleWindowInfo(hConOut, TRUE, &csbi.srWindow);
        }

        void color(WORD color = 0x07)
        {
            SetConsoleTextAttribute(hConOut, color);
        }

        HANDLE                     hConOut;
        CONSOLE_SCREEN_BUFFER_INFO csbi;
    };

    HWND hwnd = GetConsoleWindow();
    RECT rect = { 100, 100, 1250, 600 };
    MoveWindow(hwnd, rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top, TRUE);
    HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
    SetConsoleTextAttribute(hConsole, 14);
    printf("\n  WifSolverCuda v3.1 ");
    SetConsoleTextAttribute(hConsole, 10);
    printf("(phrutis modification 18.04.2022)\n\n");
    SetConsoleTextAttribute(hConsole, 15);
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
    std::cout << "  Start Time      : " << std::ctime(&s_time) << "\n";

    cudaError_t cudaStatus;
    if (unifiedMemory) {
        cudaStatus = processCudaUnified();
    }
    else {
        cudaStatus = processCuda();
    }
    
    time = std::chrono::system_clock::now();
    s_time = std::chrono::system_clock::to_time_t(time);
    std::cout << "\n  End Time        : " << std::ctime(&s_time);

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
        int bubi = 0;
        if (step2 > 8) {
            int bubi = 3;
        }
        if (tHash > bubi) {
            double speed = (double)((double)counter / tHash) / 1000000.0;
            speed2 = (double)((double)counter / tHash) / 1.0;
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
        int bubi = 0;
        if (step2 > 8) {
            int bubi = 3;
        }
        if (tHash > bubi) {
            double speed = (double)((double)counter / tHash) / 1000000.0;
            speed2 = (double)((double)counter / tHash) / 1.0;
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
    if (step2 > 8) {
        fprintf(stat, "%s\n", std::ctime(&s_time));
        char wif[53];
        unsigned char* buff = new unsigned char[dataLen];
        fprintf(stat, "WifSolverCuda.exe -wif %s ", wifout.c_str());
        fprintf(stat, "-wif2 %s ", WIFEND.c_str());
        if (!TARGET_ADDRESS.empty()) {
            fprintf(stat, "-a %s ", TARGET_ADDRESS.c_str());
        }
        fprintf(stat, "-n %d ", step);
        fprintf(stat, "-n2 %d ", step2);
        if (turbo > 0) {
            fprintf(stat, "-turbo %d ", turbo);
        }
        fprintf(stat, "-d %d\n", DEVICE_NR);
    
    }
    else {
        if (part1 != "") {

            fprintf(stat, "%s\n", std::ctime(&s_time));
            char wif[53];
            unsigned char* buff = new unsigned char[dataLen];
            fprintf(stat, "WifSolverCuda.exe -part1 %s ", part1.c_str());
            fprintf(stat, "-part2 %s ", part2.c_str());
            if (!TARGET_ADDRESS.empty()) {
                fprintf(stat, "-a %s ", TARGET_ADDRESS.c_str());
            }
            fprintf(stat, "-d %d\n", DEVICE_NR);
        
        }
        else {

            fprintf(stat, "%s\n", std::ctime(&s_time));
            char wif[53];
            unsigned char* buff = new unsigned char[dataLen];
            fprintf(stat, "WifSolverCuda.exe -wif %s ", wifout.c_str());
            fprintf(stat, "-wif2 %s ", WIFEND.c_str());
            if (!TARGET_ADDRESS.empty()) {
                fprintf(stat, "-a %s ", TARGET_ADDRESS.c_str());
            }
            fprintf(stat, "-n %d ", step);
            if (turbo > 0) {
                fprintf(stat, "-turbo %d ", turbo);
            }
            fprintf(stat, "-d %d\n", DEVICE_NR);
        }
        
    }
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
    char wif[53];
    unsigned char* buff = new unsigned char[dataLen];
    for (int i = 0, d = dataLen - 1; i < dataLen; i++, d--) {
        buff[i] = RANGE_START.GetByte(d);
    }

    b58encode(wif, &wifLen, buff, dataLen);

    if (turbo > 0) {

        zapusk += 1;
        
        if (zapusk > 27) {

            string strr = wif;
            int asciiArray[256];
            char ch;
            int charconv;
            for (int i = 0; i < 256; i++)
                asciiArray[i] = 0;
            for (unsigned int i = 0; i < strr.length(); i++)
            {
                ch = strr[i];
                charconv = static_cast<int>(ch);
                asciiArray[charconv]++;
            }

            for (unsigned int i = 0; i < strr.length(); i++)
            {
                char static alreadyprinted;
                char ch = strr[i];

                if ((asciiArray[ch] > 2) && (ch != alreadyprinted) && (find(alreadyprintedcharacters.begin(), alreadyprintedcharacters.end(), ch) == alreadyprintedcharacters.end()))
                {
                    string proverka = strr;
                    string proverka1 = regex_replace(proverka, regex("AAA"), "AAB");
                    string proverka2 = regex_replace(proverka1, regex("AAa"), "AAb");
                    string proverka3 = regex_replace(proverka2, regex("Aaa"), "Aab");
                    string proverka4 = regex_replace(proverka3, regex("aaa"), "aab");
                    string proverka5 = regex_replace(proverka4, regex("aaA"), "aaB");
                    string proverka6 = regex_replace(proverka5, regex("aAA"), "aAB");
                    string proverka7 = regex_replace(proverka6, regex("aAa"), "aAb");
                    string proverka8 = regex_replace(proverka7, regex("AaA"), "AaB");
                    string proverka9 = regex_replace(proverka8, regex("BBB"), "BBC");
                    string proverka10 = regex_replace(proverka9, regex("BBb"), "BBc");
                    string proverka11 = regex_replace(proverka10, regex("Bbb"), "Bbc");
                    string proverka12 = regex_replace(proverka11, regex("bbb"), "bbc");
                    string proverka13 = regex_replace(proverka12, regex("bbB"), "bbC");
                    string proverka14 = regex_replace(proverka13, regex("bBB"), "bBC");
                    string proverka15 = regex_replace(proverka14, regex("bBb"), "bBc");
                    string proverka16 = regex_replace(proverka15, regex("BbB"), "BbC");
                    string proverka17 = regex_replace(proverka16, regex("CCC"), "CCD");
                    string proverka18 = regex_replace(proverka17, regex("CCc"), "CCd");
                    string proverka19 = regex_replace(proverka18, regex("Ccc"), "Ccd");
                    string proverka20 = regex_replace(proverka19, regex("ccc"), "ccd");
                    string proverka21 = regex_replace(proverka20, regex("ccC"), "ccD");
                    string proverka22 = regex_replace(proverka21, regex("cCC"), "cCD");
                    string proverka23 = regex_replace(proverka22, regex("cCc"), "cCd");
                    string proverka24 = regex_replace(proverka23, regex("CcC"), "CcD");
                    string proverka25 = regex_replace(proverka24, regex("DDD"), "DDE");
                    string proverka26 = regex_replace(proverka25, regex("DDd"), "DDe");
                    string proverka27 = regex_replace(proverka26, regex("Ddd"), "Dde");
                    string proverka28 = regex_replace(proverka27, regex("ddd"), "dde");
                    string proverka29 = regex_replace(proverka28, regex("ddD"), "ddE");
                    string proverka30 = regex_replace(proverka29, regex("dDD"), "dDE");
                    string proverka31 = regex_replace(proverka30, regex("dDd"), "dDe");
                    string proverka32 = regex_replace(proverka31, regex("DdD"), "DdE");
                    string proverka33 = regex_replace(proverka32, regex("EEE"), "EEF");
                    string proverka34 = regex_replace(proverka33, regex("EEe"), "EEf");
                    string proverka35 = regex_replace(proverka34, regex("Eee"), "Eef");
                    string proverka36 = regex_replace(proverka35, regex("eee"), "eef");
                    string proverka37 = regex_replace(proverka36, regex("eeE"), "eeF");
                    string proverka38 = regex_replace(proverka37, regex("eEE"), "eEF");
                    string proverka39 = regex_replace(proverka38, regex("eEe"), "eEf");
                    string proverka40 = regex_replace(proverka39, regex("EeE"), "EeF");
                    string proverka41 = regex_replace(proverka40, regex("FFF"), "FFG");
                    string proverka42 = regex_replace(proverka41, regex("FFf"), "FFg");
                    string proverka43 = regex_replace(proverka42, regex("Fff"), "Ffg");
                    string proverka44 = regex_replace(proverka43, regex("fff"), "ffg");
                    string proverka45 = regex_replace(proverka44, regex("ffF"), "ffG");
                    string proverka46 = regex_replace(proverka45, regex("fFF"), "fFG");
                    string proverka47 = regex_replace(proverka46, regex("fFf"), "fFg");
                    string proverka48 = regex_replace(proverka47, regex("FfF"), "FfG");
                    string proverka49 = regex_replace(proverka48, regex("GGG"), "GGH");
                    string proverka50 = regex_replace(proverka49, regex("GGg"), "GGh");
                    string proverka51 = regex_replace(proverka50, regex("Ggg"), "Ggh");
                    string proverka52 = regex_replace(proverka51, regex("ggg"), "ggh");
                    string proverka53 = regex_replace(proverka52, regex("ggG"), "ggH");
                    string proverka54 = regex_replace(proverka53, regex("gGG"), "gGH");
                    string proverka55 = regex_replace(proverka54, regex("gGg"), "gGh");
                    string proverka56 = regex_replace(proverka55, regex("GgG"), "GgH");
                    string proverka57 = regex_replace(proverka56, regex("HHH"), "HHI");
                    string proverka58 = regex_replace(proverka57, regex("HHh"), "HHi");
                    string proverka59 = regex_replace(proverka58, regex("Hhh"), "Hhi");
                    string proverka60 = regex_replace(proverka59, regex("hhh"), "hhi");
                    string proverka61 = regex_replace(proverka60, regex("hhH"), "hhI");
                    string proverka62 = regex_replace(proverka61, regex("hHH"), "hHI");
                    string proverka63 = regex_replace(proverka62, regex("hHh"), "hHi");
                    string proverka64 = regex_replace(proverka63, regex("HhH"), "HhI");
                    string proverka65 = regex_replace(proverka64, regex("III"), "IIJ");
                    string proverka66 = regex_replace(proverka65, regex("IIi"), "IIj");
                    string proverka67 = regex_replace(proverka66, regex("Iii"), "Iij");
                    string proverka68 = regex_replace(proverka67, regex("iii"), "iij");
                    string proverka69 = regex_replace(proverka68, regex("iiI"), "iiJ");
                    string proverka70 = regex_replace(proverka69, regex("iII"), "iIJ");
                    string proverka71 = regex_replace(proverka70, regex("iIi"), "iIj");
                    string proverka72 = regex_replace(proverka71, regex("IiI"), "IiJ");
                    string proverka73 = regex_replace(proverka72, regex("JJJ"), "JJK");
                    string proverka74 = regex_replace(proverka73, regex("JJj"), "JJk");
                    string proverka75 = regex_replace(proverka74, regex("Jjj"), "Jjk");
                    string proverka76 = regex_replace(proverka75, regex("jjj"), "jjk");
                    string proverka77 = regex_replace(proverka76, regex("jjJ"), "jjK");
                    string proverka78 = regex_replace(proverka77, regex("jJJ"), "jJK");
                    string proverka79 = regex_replace(proverka78, regex("jJj"), "jJk");
                    string proverka80 = regex_replace(proverka79, regex("JjJ"), "JjK");
                    string proverka81 = regex_replace(proverka80, regex("KKK"), "KKL");
                    string proverka82 = regex_replace(proverka81, regex("KKk"), "KKl");
                    string proverka83 = regex_replace(proverka82, regex("Kkk"), "Kkl");
                    string proverka84 = regex_replace(proverka83, regex("kkk"), "kkl");
                    string proverka85 = regex_replace(proverka84, regex("kkK"), "kkL");
                    string proverka86 = regex_replace(proverka85, regex("kKK"), "kKL");
                    string proverka87 = regex_replace(proverka86, regex("kKk"), "kKl");
                    string proverka88 = regex_replace(proverka87, regex("KkK"), "KkL");
                    string proverka89 = regex_replace(proverka88, regex("LLL"), "LLM");
                    string proverka90 = regex_replace(proverka89, regex("LLl"), "LLm");
                    string proverka91 = regex_replace(proverka90, regex("Lll"), "Llm");
                    string proverka92 = regex_replace(proverka91, regex("lll"), "llm");
                    string proverka93 = regex_replace(proverka92, regex("llL"), "llM");
                    string proverka94 = regex_replace(proverka93, regex("lLL"), "lLM");
                    string proverka95 = regex_replace(proverka94, regex("lLl"), "lLm");
                    string proverka96 = regex_replace(proverka95, regex("LlL"), "LlM");
                    string proverka97 = regex_replace(proverka96, regex("MMM"), "MMN");
                    string proverka98 = regex_replace(proverka97, regex("MMm"), "MMn");
                    string proverka99 = regex_replace(proverka98, regex("Mmm"), "Mmn");
                    string proverka100 = regex_replace(proverka99, regex("mmm"), "mmn");
                    string proverka101 = regex_replace(proverka100, regex("mmM"), "mmN");
                    string proverka102 = regex_replace(proverka101, regex("mMM"), "mMN");
                    string proverka103 = regex_replace(proverka102, regex("mMm"), "mMn");
                    string proverka104 = regex_replace(proverka103, regex("MmM"), "MmN");
                    string proverka105 = regex_replace(proverka104, regex("NNN"), "NNO");
                    string proverka106 = regex_replace(proverka105, regex("NNn"), "NNo");
                    string proverka107 = regex_replace(proverka106, regex("Nnn"), "Nno");
                    string proverka108 = regex_replace(proverka107, regex("nnn"), "nno");
                    string proverka109 = regex_replace(proverka108, regex("nnN"), "nnO");
                    string proverka110 = regex_replace(proverka109, regex("nNN"), "nNO");
                    string proverka111 = regex_replace(proverka110, regex("nNn"), "nNo");
                    string proverka112 = regex_replace(proverka111, regex("NnN"), "NnO");
                    string proverka113 = regex_replace(proverka112, regex("OOO"), "OOP");
                    string proverka114 = regex_replace(proverka113, regex("OOo"), "OOp");
                    string proverka115 = regex_replace(proverka114, regex("Ooo"), "Oop");
                    string proverka116 = regex_replace(proverka115, regex("ooo"), "oop");
                    string proverka117 = regex_replace(proverka116, regex("ooO"), "ooP");
                    string proverka118 = regex_replace(proverka117, regex("oOO"), "oOP");
                    string proverka119 = regex_replace(proverka118, regex("oOo"), "oOp");
                    string proverka120 = regex_replace(proverka119, regex("OoO"), "OoP");
                    string proverka121 = regex_replace(proverka120, regex("PPP"), "PPQ");
                    string proverka122 = regex_replace(proverka121, regex("PPp"), "PPq");
                    string proverka123 = regex_replace(proverka122, regex("Ppp"), "Ppq");
                    string proverka124 = regex_replace(proverka123, regex("ppp"), "ppq");
                    string proverka125 = regex_replace(proverka124, regex("ppP"), "ppQ");
                    string proverka126 = regex_replace(proverka125, regex("pPP"), "pPQ");
                    string proverka127 = regex_replace(proverka126, regex("pPp"), "pPq");
                    string proverka128 = regex_replace(proverka127, regex("PpP"), "PpQ");
                    string proverka129 = regex_replace(proverka128, regex("QQQ"), "QQR");
                    string proverka130 = regex_replace(proverka129, regex("QQq"), "QQr");
                    string proverka131 = regex_replace(proverka130, regex("Qqq"), "Qqr");
                    string proverka132 = regex_replace(proverka131, regex("qqq"), "qqr");
                    string proverka133 = regex_replace(proverka132, regex("qqQ"), "qqR");
                    string proverka134 = regex_replace(proverka133, regex("qQQ"), "qQR");
                    string proverka135 = regex_replace(proverka134, regex("qQq"), "qQr");
                    string proverka136 = regex_replace(proverka135, regex("QqQ"), "QqR");
                    string proverka137 = regex_replace(proverka136, regex("RRR"), "RRS");
                    string proverka138 = regex_replace(proverka137, regex("RRr"), "RRs");
                    string proverka139 = regex_replace(proverka138, regex("Rrr"), "Rrs");
                    string proverka140 = regex_replace(proverka139, regex("rrr"), "rrs");
                    string proverka141 = regex_replace(proverka140, regex("rrR"), "rrS");
                    string proverka142 = regex_replace(proverka141, regex("rRR"), "rRS");
                    string proverka143 = regex_replace(proverka142, regex("rRr"), "rRs");
                    string proverka144 = regex_replace(proverka143, regex("RrR"), "RrS");
                    string proverka145 = regex_replace(proverka144, regex("SSS"), "SST");
                    string proverka146 = regex_replace(proverka145, regex("SSs"), "SSt");
                    string proverka147 = regex_replace(proverka146, regex("Sss"), "Sst");
                    string proverka148 = regex_replace(proverka147, regex("sss"), "sst");
                    string proverka149 = regex_replace(proverka148, regex("ssS"), "ssT");
                    string proverka150 = regex_replace(proverka149, regex("sSS"), "sST");
                    string proverka151 = regex_replace(proverka150, regex("sSs"), "sSt");
                    string proverka152 = regex_replace(proverka151, regex("SsS"), "SsT");
                    string proverka153 = regex_replace(proverka152, regex("TTT"), "TTU");
                    string proverka154 = regex_replace(proverka153, regex("TTt"), "TTu");
                    string proverka155 = regex_replace(proverka154, regex("Ttt"), "Ttu");
                    string proverka156 = regex_replace(proverka155, regex("ttt"), "ttu");
                    string proverka157 = regex_replace(proverka156, regex("ttT"), "ttU");
                    string proverka158 = regex_replace(proverka157, regex("tTT"), "tTU");
                    string proverka159 = regex_replace(proverka158, regex("tTt"), "tTu");
                    string proverka160 = regex_replace(proverka159, regex("TtT"), "TtU");
                    string proverka161 = regex_replace(proverka160, regex("UUU"), "UUV");
                    string proverka162 = regex_replace(proverka161, regex("UUu"), "UUv");
                    string proverka163 = regex_replace(proverka162, regex("Uuu"), "Uvv");
                    string proverka164 = regex_replace(proverka163, regex("uuu"), "uuv");
                    string proverka165 = regex_replace(proverka164, regex("uuU"), "uuV");
                    string proverka166 = regex_replace(proverka165, regex("uUU"), "uUV");
                    string proverka167 = regex_replace(proverka166, regex("uUu"), "uUv");
                    string proverka168 = regex_replace(proverka167, regex("UuU"), "UuV");
                    string proverka169 = regex_replace(proverka168, regex("VVV"), "VVW");
                    string proverka170 = regex_replace(proverka169, regex("VVv"), "VVw");
                    string proverka171 = regex_replace(proverka170, regex("Vvv"), "Vvw");
                    string proverka172 = regex_replace(proverka171, regex("vvv"), "vvw");
                    string proverka173 = regex_replace(proverka172, regex("vvV"), "vvW");
                    string proverka174 = regex_replace(proverka173, regex("vVV"), "vVW");
                    string proverka175 = regex_replace(proverka174, regex("vVv"), "vVw");
                    string proverka176 = regex_replace(proverka175, regex("VvV"), "VvW");
                    string proverka177 = regex_replace(proverka176, regex("WWW"), "WWX");
                    string proverka178 = regex_replace(proverka177, regex("WWw"), "WWx");
                    string proverka179 = regex_replace(proverka178, regex("Www"), "Wwx");
                    string proverka180 = regex_replace(proverka179, regex("www"), "wwx");
                    string proverka181 = regex_replace(proverka180, regex("wwW"), "wwX");
                    string proverka182 = regex_replace(proverka181, regex("wWW"), "wWX");
                    string proverka183 = regex_replace(proverka182, regex("wWw"), "wWx");
                    string proverka184 = regex_replace(proverka183, regex("WwW"), "WwX");
                    string proverka185 = regex_replace(proverka184, regex("XXX"), "XXY");
                    string proverka186 = regex_replace(proverka185, regex("XXx"), "XXy");
                    string proverka187 = regex_replace(proverka186, regex("Xxx"), "Xxy");
                    string proverka188 = regex_replace(proverka187, regex("xxx"), "xxy");
                    string proverka189 = regex_replace(proverka188, regex("xxX"), "xxY");
                    string proverka190 = regex_replace(proverka189, regex("xXX"), "xXY");
                    string proverka191 = regex_replace(proverka190, regex("xXx"), "xXy");
                    string proverka192 = regex_replace(proverka191, regex("XxX"), "XxY");
                    string proverka193 = regex_replace(proverka192, regex("YYY"), "YYZ");
                    string proverka194 = regex_replace(proverka193, regex("YYy"), "YYz");
                    string proverka195 = regex_replace(proverka194, regex("Yyy"), "Yyz");
                    string proverka196 = regex_replace(proverka195, regex("yyy"), "yyz");
                    string proverka197 = regex_replace(proverka196, regex("yyY"), "yyZ");
                    string proverka198 = regex_replace(proverka197, regex("yYY"), "yYZ");
                    string proverka199 = regex_replace(proverka198, regex("yYy"), "yYz");
                    string proverka200 = regex_replace(proverka199, regex("YyY"), "YyZ");
                    
                    if (proverka200 != strr) {
                        zamena = strr.c_str();
                        zamena2 = proverka200.c_str();
                        const char* base58 = zamena2.c_str();
                        size_t base58Length = zamena2.size();
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
                        
                    }
                }
            }
            zapusk = 0;
        }
    }

    if (turbo > 0) {

        if (zamena3 != zamena2) {
            zamena3 = zamena2;
            zcount += 1;

            if (zcount > 1) {
                int konec = zamena2.length();
                kstr99 = zamena2.substr(konec - step + 1, 1);

                int konec555 = WIFSTART.length();
                security = WIFSTART.substr(konec555 - step + 1, 1);

                if (kstr99 != security) {
                    printf("\n  Letter return   : ");
                    HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
                    SetConsoleTextAttribute(hConsole, 4);
                    printf("%s ", security.c_str());
                    SetConsoleTextAttribute(hConsole, 15);
                    printf("-> ");
                    SetConsoleTextAttribute(hConsole, 10);
                    printf("%s \n", kstr99.c_str());
                    SetConsoleTextAttribute(hConsole, 15);
                    RANGE_START.Sub(&down);
                }
            }
        }
    }

    if (part1 != "") {

        zapusk += 1;

        if (zapusk > 30) {
            srand(time(NULL));
            int N = kusok;
            char str[]{ "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz" };
            int strN = 58;
            char* pass = new char[N + 1];
            for (int i = 0; i < N; i++)
            {
                pass[i] = str[rand() % strN];
            }
            pass[N] = 0;
            std::stringstream ss8;
            ss8 << part1.c_str() << pass << part2.c_str();
            string rannd = ss8.str();

            const char* base58 = rannd.c_str();
            size_t base58Length = rannd.size();
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
            zapusk = 0;

        }
    }

    Int ttal;
    ttal.Set(&RANGE_START);
    ttal.Sub(&start1);
    ttal.Div(&STRIDE);
    string totalx = ttal.GetBase10().c_str();
    uint64_t vtotal;
    std::istringstream iss(totalx);
    iss >> vtotal;

    uint64_t spedturbo = vtotal / t1;
    uint64_t speedx;
    string valx;
    if (spedturbo < 1000000) {
        valx = " Mkey/s";
    }
    else {

        if (spedturbo < 1000000000) {
            speedx = spedturbo / 1000;
            valx = " Mkey/s";
        }
        else {

            
            if (spedturbo < 1000000000000) {
                valx = " Gkey/s";
                speedx = spedturbo / 1000000;
            }
            else {
                if (spedturbo < 1000000000000000) {
                    valx = " Tkey/s";
                    speedx = spedturbo / 1000000000;
                
                }
                else {
                    valx = " Pkeys/s";
                    speedx = spedturbo / 1000000000000;
                }
            }
        }
    }

    Int ttal2;
    ttal2.Set(&RANGE_END);
    ttal2.Sub(&RANGE_START);
    ttal2.Div(&STRIDE);
    string ost = ttal2.GetBase10().c_str();
    uint64_t ostatok;
    std::istringstream iss2(ost);
    iss2 >> ostatok;
    uint64_t sekki = ostatok / speed2;

    
    
    if (sekki < 86400) {
        int h, m, s;
        h = (sekki / 3600);
        m = (sekki - (3600 * h)) / 60;
        s = (sekki - (3600 * h) - (m * 60));
        sprintf(timeStr2, "%0*d:%0*d:%0*d", 2, h, 2, m, 2, s);
    
    }
    else {
        if (sekki < 31536000) {
            int d, d2, h, m, s;
            d = sekki / 86400;
            d2 = d * 86400;
            sekki = sekki - d2;
            h = (sekki / 3600);
            m = (sekki - (3600 * h)) / 60;
            s = (sekki - (3600 * h) - (m * 60));
            sprintf(timeStr2, "%d days %0*d:%0*d:%0*d", d, 2, h, 2, m, 2, s);            
        }
        else {
            if (sekki < 1734480000) {
                int y, d, h, m, s;
                y = sekki / 31536000;
                sekki = sekki - (y * 31536000);
                d = sekki / 86400;
                sekki = sekki - (d * 86400);
                h = (sekki / 3600);
                m = (sekki - (3600 * h)) / 60;
                s = (sekki - (3600 * h) - (m * 60));
                sprintf(timeStr2, "%d years %d days %0*d:%0*d:%0*d", y, d, 2, h, 2, m, 2, s);
            
            }
            else {
                int h, m, s;
                h = 88;
                m = 88;
                s = 88;
                sprintf(timeStr2, "%0*d:%0*d:%0*d", 2, h, 2, m, 2, s);
            }            
        }
    }
    
    t1 = Timer::get_tick();
    Int processedCount= new Int(&RANGE_START);
    processedCount.Sub(&RANGE_START_TOTAL);
    double _count = processedCount.ToDouble();
    _count = _count / RANGE_TOTAL_DOUBLE; 
    _count *= 100;
    num_str = to_string(_count);
    nitro = to_string(zcount);
    wifout = wif;
    string num_gpu = to_string(DEVICE_NR);
    
    SetConsoleTitle(verh.c_str());
    if (turbo > 0) {
        verh = " GPU: " + num_gpu + "   C: " + num_str + "   E: " + timeStr2 + " (" + nitro + ") " + zamena + " -> " + zamena2.c_str();
        printf("\r  [%s] [%s] [S: %s%s] [C: %.3f%%] [T: %s]  ", toTimeStr(t1, timeStr), wif, formatThousands(speedx).c_str(), valx.c_str(), _count, formatThousands(vtotal).c_str());
    }
    else {
        if (step2 > 8 || part1 != "") {
            std::string speedStr;
            if (speed < 0.01) {
                speedStr = "< 0.01 MKey/s";
            }
            else {
                if (speed < 1000) {
                    speedStr = formatDouble("%.3f", speed) + " Mkey/s";
                }
                else {
                    speed /= 1000;
                    if (speed < 1000) {
                        speedStr = formatDouble("%.3f", speed) + " Gkey/s";
                    }
                    else {
                        speed /= 1000;
                        speedStr = formatDouble("%.3f", speed) + " Tkey/s";
                    }
                }
            }
            verh = " GPU: " + num_gpu + "   C: " + num_str + "   E: " + timeStr2;
            printf("\r  [%s] [%s] [S: %s]  ", toTimeStr(t1, timeStr), wif, speedStr.c_str());
   
        }
        else {
            verh = " GPU: " + num_gpu + "   C: " + num_str + "   E: " + timeStr2;
            printf("\r  [%s] [%s] [S: %s%s] [C: %.3f%%] [T: %s]  ", toTimeStr(t1, timeStr), wif, formatThousands(speedx).c_str(), valx.c_str(), _count, formatThousands(vtotal).c_str());
        
        }
    }
    if (step2 > 8) {
        RANGE_START.Set(&start1);
        shagi.Add(&STRIDE2);
        RANGE_START.Add(&shagi);
    }
    
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
            HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
            SetConsoleTextAttribute(hConsole, 11);
            RESULT = true;            
            printf("\n  ===============================================================================\n");
            printf("  BTC address: %s\n", address);
            printf("  Private key: %s\n", toTest.GetBase16().c_str());
            if (b58encode(wif, &wifLen, buff, dataLen)) {
                printf("  WIF key    : %s\n", wif);
            }
            printf("  ===============================================================================\n");
            keys = fopen(fileResult.c_str(), "a+");
            fprintf(keys, "%s\n", address);
            fprintf(keys, "%s\n", wif);
            fprintf(keys, "%s\n\n", toTest.GetBase16().c_str());            
            fclose(keys);
            SetConsoleTextAttribute(hConsole, 15);
            return;
        }
    }
    else {
        HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
        SetConsoleTextAttribute(hConsole, 11);
        printf("\n  ===============================================================================\n");
        printf("  Address    : %s\n", address);
        printf("  Private key: %s\n", toTest.GetBase16().c_str());
        if (b58encode(wif, &wifLen, buff, dataLen)) {
            printf("  WIF key    : %s\n", wif);
        }
        printf("  ===============================================================================\n");
        keys = fopen(fileResultPartial.c_str(), "a+");
        fprintf(keys, "%s\n", address);
        fprintf(keys, "%s\n", wif);
        fprintf(keys, "%s\n\n", toTest.GetBase16().c_str());        
        fclose(keys);
        SetConsoleTextAttribute(hConsole, 15);
    }
    
}

void printConfig() {

    HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
    if (COMPRESSED) {
        printf("  Search mode     : COMPRESSED\n");
    }
    else {
        printf("  Search mode     : UNCOMPRESSED\n");
    }
    if (part1 != "") {

        if (!TARGET_ADDRESS.empty()) {
            printf("  WIF key part 1  : %s (%d characters)\n", part1.c_str(), part1.length());
            printf("  WIF key part 2  : %s (%d characters)\n", part2.c_str(), part2.length());
            int N = kusok;
            char str[]{ "XXXXXXXXXXXXXXXX" };
            int strN = 16;
            char* pass = new char[N + 1];
            for (int i = 0; i < N; i++)
            {
                pass[i] = str[rand() % strN];
            }
            pass[N] = 0;
            std::stringstream ss;
            ss << part1.c_str() << pass << part2.c_str();
            std::string inputkus = ss.str();
            std::stringstream ss999;
            ss999 << pass;
            std::string partrange = ss999.str();

            printf("  Random WIF range: %s (%d characters) \n", pass, partrange.length());
            printf("  Starting WIF key: ");
            SetConsoleTextAttribute(hConsole, 3);
            printf("%s", part1.c_str());
            SetConsoleTextAttribute(hConsole, 2);
            printf("%s", pass);
            SetConsoleTextAttribute(hConsole, 3);
            printf("%s", part2.c_str());
            SetConsoleTextAttribute(hConsole, 15);
            printf(" (%d)\n", inputkus.length());
            printf("  Position chars  : %d (+ random every ~30 sec.)\n", step);
            printf("  BTC Address     : %s\n", TARGET_ADDRESS.c_str());
        }
    
    }
    else {

        string str0;
        string kstr0;
        string s7777 = WIFSTART;
        int konec = s7777.length();
        str0 = s7777.substr(0, konec + 1 - step);
        kstr0 = s7777.substr(konec + 1 - step, konec + 1);
        printf("  WIF START       : ");
        SetConsoleTextAttribute(hConsole, 9);
        printf("%s", str0.c_str());
        SetConsoleTextAttribute(hConsole, 6);
        printf("%s\n", kstr0.c_str());
        SetConsoleTextAttribute(hConsole, 15);
        printf("  WIF END         : %s\n", WIFEND.c_str());
        if (!TARGET_ADDRESS.empty()) {
            printf("  BTC Address     : %s\n", TARGET_ADDRESS.c_str());
        }
        string str22;
        string kstr22;
        string kstr222;
        string s777722 = WIFSTART;
        int konec22 = s777722.length();
        str22 = s777722.substr(0, konec22 + 1 - step - 1);
        kstr22 = s777722.substr(konec22 - 1 - step + 1, 1);
        kstr222 = s777722.substr(konec22 - step + 1, konec22 - 1);

        printf("  Position chars  : %s", str22.c_str());
        SetConsoleTextAttribute(hConsole, 2);
        printf("%s", kstr22.c_str());
        SetConsoleTextAttribute(hConsole, 15);
        printf("%s \n", kstr222.c_str());
        printf("  Position chars  : %d \n", step);
        
        if (step2 > 8) {
            string str33;
            string kstr33;
            string kstr333;
            string s777733 = WIFSTART;
            int konec33 = s777733.length();
            str33 = s777733.substr(0, konec33 + 1 - step2 - 1);
            kstr33 = s777733.substr(konec33 - 1 - step2 + 1, 1);
            kstr333 = s777733.substr(konec33 - step2 + 1, konec33 - 1);

            printf("  Position chars2 : %s", str33.c_str());
            SetConsoleTextAttribute(hConsole, 2);
            printf("%s", kstr33.c_str());
            SetConsoleTextAttribute(hConsole, 15);
            printf("%s \n", kstr333.c_str());
            printf("  Position chars2 : %d (every sec +1)\n", step2);
        }
        else {
            Int combint;
            combint.Set(&RANGE_END);
            combint.Sub(&RANGE_START);
            combint.Div(&STRIDE);
            string summcomb = combint.GetBase10().c_str();
            uint64_t comb2;
            std::istringstream iss3(summcomb);
            iss3 >> comb2;
            if (comb2 > 18446744073709551600) {
                printf("  Combinations    : huge number, greater than %s \n", formatThousands(comb2).c_str());
            }
            else {
                printf("  Combinations    : %s \n", formatThousands(comb2).c_str());
            }

            if (turbo == 0) {

                printf("  TURBO MODE      : OFF\n");
            }
            else {

                printf("  TURBO MODE      :");
                SetConsoleTextAttribute(hConsole, 10);
                printf(" ON ");
                SetConsoleTextAttribute(hConsole, 15);
                printf("(every 30 sec)\n");

            }
        }
    }
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
        if (props.canMapHostMemory == 0) {
            printf("  Unified memory not supported\n");
            unifiedMemory = 0;
        }
        printf("  Number GPU      : %d (%s %2d procs)\n", DEVICE_NR, props.name, props.multiProcessorCount);
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
    printf("-n2              Spin additional letters -n2 from 9 to 51 (every sec +1) \n");
    printf("-turbo           Quick mode (skip 3 identical letters in a row) -turbo 3 (default: OFF) \n");
    printf("-part1           First part of the key starting with K, L or 5 (for random mode) \n");
    printf("-part2           The second part of the key with a checksum (for random mode) \n");
    printf("-fresult         The name of the output file about the find (default: FOUND.txt)\n");
    printf("-fname           The name of the checkpoint save file to continue (default: GPUid + Continue.txt) \n");
    printf("-ftime           Save checkpoint to continue every sec (default %d sec) \n", fileStatusInterval);
    printf("-d               DeviceId. Number GPU (default 0)\n");    
    printf("-list            Shows available devices \n");
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
        else if (strcmp(argv[a], "-list") == 0) {
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
        else if (strcmp(argv[a], "-turbo") == 0) {
            a++;
            turbo = strtol(argv[a], NULL, 10);
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
        else if (strcmp(argv[a], "-n2") == 0) {
            a++;
            step2 = strtol(argv[a], NULL, 10);
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
        else if (strcmp(argv[a], "-part1") == 0) {
            a++;
            part1 = string(argv[a]);
        }
        else if (strcmp(argv[a], "-part2") == 0) {
            a++;
            part2 = string(argv[a]);
        }
        else if (strcmp(argv[a], "-checksum555") == 0) {
            a++;
            CHECKSUM.SetBase16((char*)string(argv[a]).c_str());
            IS_CHECKSUM = true;
        }
        else if (strcmp(argv[a], "-disable-um555") == 0) {
            unifiedMemory = 0;
            printf("  Unified memory mode disabled\n");
        }
        a++;
    }    

    if (WIF[0] == '5') {
        COMPRESSED = false;
    }
    if (part1 != "") {
        
        if (part1[0] == 'K' || part1[0] == 'L') {

            int konec1 = part1.length();
            int konec2 = part2.length();
            int delka = konec1 + konec2;
            kusok = 52 - delka;
            step = konec2 + 1;
        }
        if (part1[0] == '5') {
            
            COMPRESSED = false;
            int konec1 = part1.length();
            int konec2 = part2.length();
            int delka = konec1 + konec2;
            kusok = 51 - delka;
            step = konec2 + 1;
        }

    }
    if (part2 != "") {

        if (part2.length() < 8) {
            printf("\n  ERROR WIF     : Mistake! Your WIF key part length! Minimum part2 -> 8 characters\n\n");
            return -1;
        
        }
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
                
                string proverka1 = regex_replace(proverka, regex("XXXXXXXXXXXXXXX"), "111111111111111");
                string proverka2 = regex_replace(proverka1, regex("XXXXXXXXXXXXXX"), "11111111111111");
                string proverka3 = regex_replace(proverka2, regex("XXXXXXXXXXXXX"), "1111111111111");
                string proverka4 = regex_replace(proverka3, regex("XXXXXXXXXXXX"), "111111111111");
                string proverka5 = regex_replace(proverka4, regex("XXXXXXXXXXX"), "11111111111");
                string proverka6 = regex_replace(proverka5, regex("XXXXXXXXXX"), "1111111111");
                string proverka7 = regex_replace(proverka6, regex("XXXXXXXXX"), "111111111");
                string proverka8 = regex_replace(proverka7, regex("XXXXXXXX"), "11111111");
                string proverka9 = regex_replace(proverka8, regex("XXXXXXX"), "1111111");
                string proverka10 = regex_replace(proverka9, regex("XXXXXX"), "111111");
                string proverka11 = regex_replace(proverka10, regex("XXXXX"), "11111");
                string proverka12 = regex_replace(proverka11, regex("XXXX"), "1111");
                WIFSTART = proverka12;
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

                
                string proverkae1 = regex_replace(proverkae, regex("XXXXXXXXXXXXXXX"), "zzzzzzzzzzzzzzz");
                string proverkae2 = regex_replace(proverkae1, regex("XXXXXXXXXXXXXX"), "zzzzzzzzzzzzzz");
                string proverkae3 = regex_replace(proverkae2, regex("XXXXXXXXXXXXX"), "zzzzzzzzzzzzz");
                string proverkae4 = regex_replace(proverkae3, regex("XXXXXXXXXXXX"), "zzzzzzzzzzzz");
                string proverkae5 = regex_replace(proverkae4, regex("XXXXXXXXXXX"), "zzzzzzzzzzz");
                string proverkae6 = regex_replace(proverkae5, regex("XXXXXXXXXX"), "zzzzzzzzzz");
                string proverkae7 = regex_replace(proverkae6, regex("XXXXXXXXX"), "zzzzzzzzz");
                string proverkae8 = regex_replace(proverkae7, regex("XXXXXXXX"), "zzzzzzzz");
                string proverkae9 = regex_replace(proverkae8, regex("XXXXXXX"), "zzzzzzz");
                string proverkae10 = regex_replace(proverkae9, regex("XXXXXX"), "zzzzzz");
                string proverkae11 = regex_replace(proverkae10, regex("XXXXX"), "zzzzz");
                string proverkae12 = regex_replace(proverkae11, regex("XXXX"), "zzzz");
                
                if (proverkae12 == wife) {
                    
                    if (COMPRESSED) {
                        WIFEND = "L5oLkpV3aqBjhki6LmvChTCV6odsp4SXM6FfU2Gppt5kFLaHLuZ9";
                    }
                    else {
                        WIFEND = "5Km2kuu7vtFDPpxywn4u3NLpbr5jKpTB3jsuDU2KYEqetqj84qw";
                    }
                }
                else {
                    WIFEND = proverkae12;
                }

                if (WIF999 != "") {
                    WIFEND = WIF999;
                
                }
            }
        }
    }
    if (WIF == "") {
        
        if (part1 != "") {
            srand(time(NULL));
            int N = kusok;
            char str[]{ "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz" };
            int strN = 58;
            char* pass = new char[N + 1];
            for (int i = 0; i < N; i++)
            {
                pass[i] = str[rand() % strN];
            }
            pass[N] = 0;
            std::stringstream ss7;
            ss7 << part1.c_str() << pass << part2.c_str();
            WIFSTART = ss7.str();
            WIFEND = "L5oLkpV3aqBjhki6LmvChTCV6odsp4SXM6FfU2Gppt5k7NVCBwG4";
            
        }
        else {
            WIFSTART = "KwDiBf89QgGbjEhKnhXJuH7LrciVrZi3qYjgd9M7rFU73sVHnoWn";
            WIFEND = "L5oLkpV3aqBjhki6LmvChTCV6odsp4SXM6FfU2Gppt5k7NVCBwG4";
        }
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
    start1.SetBase16(cstr959);
 
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
    if (step < 9) {
        printf("\n  ERROR     : Mistake! Rotate checksum in development! Minimum character -n 9  (max -n 51)\n\n");
        return -1;
    }
  
    if (step2 == 9) {
        STRIDE2.SetBase16((char*)string("7479027ea100").c_str());

    }
    if (step2 == 10) {
        STRIDE2.SetBase16((char*)string("1a636a90b07a00").c_str());

    }
    if (step2 == 11) {
        STRIDE2.SetBase16((char*)string("5fa8624c7fba400").c_str());

    }
    if (step2 == 12) {
        STRIDE2.SetBase16((char*)string("15ac264554f032800").c_str());

    }
    if (step2 == 13) {
        STRIDE2.SetBase16((char*)string("4e900abb53e6b71000").c_str());

    }
    if (step2 == 14) {
        STRIDE2.SetBase16((char*)string("11cca26e71024579a000").c_str());

    }
    if (step2 == 15) {
        STRIDE2.SetBase16((char*)string("4085ccd059a83bd8e4000").c_str());

    }
    if (step2 == 16) {
        STRIDE2.SetBase16((char*)string("e9e506734501d8f23a8000").c_str());

    }
    if (step2 == 17) {
        STRIDE2.SetBase16((char*)string("34fde3761da26b26e1410000").c_str());

    }
    if (step2 == 18) {
        STRIDE2.SetBase16((char*)string("c018588c2b6cc46cf08ba0000").c_str());

    }
    if (step2 == 19) {
        STRIDE2.SetBase16((char*)string("2b85840fc1d6a480ae7fa240000").c_str());

    }
    if (step2 == 20) {
        STRIDE2.SetBase16((char*)string("9dc3feb91eaa1452788eac280000").c_str());

    }
    if (step2 == 21) {
        STRIDE2.SetBase16((char*)string("23be67b5f0f2889aaf505301100000").c_str());

    }
    if (step2 == 22) {
        STRIDE2.SetBase16((char*)string("819237f3896f2f30bb832ce3da00000").c_str());

    }
    if (step2 == 23) {
        STRIDE2.SetBase16((char*)string("1d5b20ad2d2330b10a7bb82b9f6400000").c_str());

    }
    if (step2 == 24) {
        STRIDE2.SetBase16((char*)string("6a6a5673c39f9081c6007b9e21ca800000").c_str());

    }
    if (step2 == 25) {
        STRIDE2.SetBase16((char*)string("181c17963a5226bd66dc1c01d3a7e1000000").c_str());

    }
    if (step2 == 26) {
        STRIDE2.SetBase16((char*)string("5765d5809369cc6e94dde5869f408fa000000").c_str());

    }
    if (step2 == 27) {
        STRIDE2.SetBase16((char*)string("13cd125f2165f8510dba46008014a08a4000000").c_str());

    }
    if (step2 == 28) {
        STRIDE2.SetBase16((char*)string("47c76298d911a425d1c33dc1d04ac5f528000000").c_str());

    }
    if (step2 == 29) {
        STRIDE2.SetBase16((char*)string("10432c56a12dff3091863bfde930f0d98b10000000").c_str());

    }
    if (step2 == 30) {
        STRIDE2.SetBase16((char*)string("3af380ba0846bd100f8699786d516914981a0000000").c_str());

    }
    if (step2 == 31) {
        STRIDE2.SetBase16((char*)string("d5b2b2a25e006d5a3847ec548c471ceaa75e40000000").c_str());

    }
    if (step2 == 32) {
        STRIDE2.SetBase16((char*)string("306a7c78c94c18c670c04b8b27c81c8d29eb5a80000000").c_str());

    }
    if (step2 == 33) {
        STRIDE2.SetBase16((char*)string("af820335d9b3d9cf58b911d87035677fb7f528100000000").c_str());

    }
    if (step2 == 34) {
        STRIDE2.SetBase16((char*)string("27c374ba3352bf58fa19ee0b096c1972efad8b13a00000000").c_str());

    }
    if (step2 == 35) {
        STRIDE2.SetBase16((char*)string("90248722fa0bf5a28a9dfee80227dc40a4d518272400000000").c_str());

    }
    if (step2 == 36) {
        STRIDE2.SetBase16((char*)string("20a8469deca6b5a6d367cbc0907d07e6a5584778de2800000000").c_str());

    }
    if (step2 == 37) {
        STRIDE2.SetBase16((char*)string("7661fffc79dc527cbe58429a0bc53ca4176003162551000000000").c_str());

    }
    if (step2 == 38) {
        STRIDE2.SetBase16((char*)string("1ad233ff339beab0431fff16e6aaafbd2d4bc0b304745a000000000").c_str());

    }
    if (step2 == 39) {
        STRIDE2.SetBase16((char*)string("6139fc7d1b1532bef353fcb3042abd0dc4329a88f025c64000000000").c_str());

    }
    if (step2 == 40) {
        STRIDE2.SetBase16((char*)string("160723345822cd7f432107408ef1aed51e73770306688eea8000000000").c_str());

    }
    if (step2 == 41) {
        STRIDE2.SetBase16((char*)string("4fd9df9dbf7e28ed5357ba4a062c19c48e628f6af73b061210000000000").c_str());

    }
    if (step2 == 42) {
        STRIDE2.SetBase16((char*)string("12175ca9bd629545c4e1e034c565fdd68842547e3c035f6017a0000000000").c_str());

    }
    if (step2 == 43) {
        STRIDE2.SetBase16((char*)string("4194afe74e855d1ce9b2ccbf4b91b829adf07249998c39bc55a40000000000").c_str());

    }
    if (step2 == 44) {
        STRIDE2.SetBase16((char*)string("edbafda67ca37188cf28263571f03b9716879e4acc9c514ab67280000000000").c_str());

    }
    if (step2 == 45) {
        STRIDE.SetBase16((char*)string("35dc5d77b83d07b8feef18a81bd06d803b1ab9dcf25b6a6aed55f100000000000").c_str());

    }
    if (step2 == 46) {
        STRIDE2.SetBase16((char*)string("c33ed2d1fbdd3bfe9c22b96164d38cf0d640e1c0ee8b61c39c5789a00000000000").c_str());

    }
    if (step2 == 47) {
        STRIDE2.SetBase16((char*)string("2c3c3bc393101f97af5fde0010d7edee908ab325b60b9426516bd52e400000000000").c_str());

    }
    if (step2 == 48) {
        STRIDE.SetBase16((char*)string("a05a58a4f51a7285dbbb84c03d0ebe80cbf6c968b3e9f90ae726e4c7a800000000000").c_str());

    }
    if (step2 == 49) {
        STRIDE2.SetBase16((char*)string("245478155f87fdf253c87c138dd557292e35e9a1b8c3026c785ecfd53c1000000000000").c_str());

    }
    if (step2 == 50) {
        STRIDE2.SetBase16((char*)string("83b2334d7a4cf88e6fb6c1c6e2255bf547836eea3dc2e8c93457b164f9ba000000000000").c_str());

    }
    if (step2 == 51) {
        STRIDE2.SetBase16((char*)string("1dd65f9f8db57050454f67e70f3c76d59233c72111fe28bd95dbde30e09424000000000000").c_str());

    }
    int step3 = step - 1;
    if (step3 == 9) {
        down.SetBase16((char*)string("7479027ea100").c_str());

    }
    if (step3 == 10) {
        down.SetBase16((char*)string("1a636a90b07a00").c_str());

    }
    if (step3 == 11) {
        down.SetBase16((char*)string("5fa8624c7fba400").c_str());

    }
    if (step3 == 12) {
        down.SetBase16((char*)string("15ac264554f032800").c_str());

    }
    if (step3 == 13) {
        down.SetBase16((char*)string("4e900abb53e6b71000").c_str());

    }
    if (step3 == 14) {
        down.SetBase16((char*)string("11cca26e71024579a000").c_str());

    }
    if (step3 == 15) {
        down.SetBase16((char*)string("4085ccd059a83bd8e4000").c_str());

    }
    if (step2 == 16) {
        down.SetBase16((char*)string("e9e506734501d8f23a8000").c_str());

    }
    if (step3 == 17) {
        down.SetBase16((char*)string("34fde3761da26b26e1410000").c_str());

    }
    if (step3 == 18) {
        down.SetBase16((char*)string("c018588c2b6cc46cf08ba0000").c_str());

    }
    if (step3 == 19) {
        down.SetBase16((char*)string("2b85840fc1d6a480ae7fa240000").c_str());

    }
    if (step3 == 20) {
        down.SetBase16((char*)string("9dc3feb91eaa1452788eac280000").c_str());

    }
    if (step3 == 21) {
        down.SetBase16((char*)string("23be67b5f0f2889aaf505301100000").c_str());

    }
    if (step3 == 22) {
        down.SetBase16((char*)string("819237f3896f2f30bb832ce3da00000").c_str());

    }
    if (step3 == 23) {
        down.SetBase16((char*)string("1d5b20ad2d2330b10a7bb82b9f6400000").c_str());

    }
    if (step3 == 24) {
        down.SetBase16((char*)string("6a6a5673c39f9081c6007b9e21ca800000").c_str());

    }
    if (step3 == 25) {
        down.SetBase16((char*)string("181c17963a5226bd66dc1c01d3a7e1000000").c_str());

    }
    if (step3 == 26) {
        down.SetBase16((char*)string("5765d5809369cc6e94dde5869f408fa000000").c_str());

    }
    if (step3 == 27) {
        down.SetBase16((char*)string("13cd125f2165f8510dba46008014a08a4000000").c_str());

    }
    if (step3 == 28) {
        down.SetBase16((char*)string("47c76298d911a425d1c33dc1d04ac5f528000000").c_str());

    }
    if (step3 == 29) {
        down.SetBase16((char*)string("10432c56a12dff3091863bfde930f0d98b10000000").c_str());

    }
    if (step3 == 30) {
        down.SetBase16((char*)string("3af380ba0846bd100f8699786d516914981a0000000").c_str());

    }
    if (step3 == 31) {
        down.SetBase16((char*)string("d5b2b2a25e006d5a3847ec548c471ceaa75e40000000").c_str());

    }
    if (step3 == 32) {
        down.SetBase16((char*)string("306a7c78c94c18c670c04b8b27c81c8d29eb5a80000000").c_str());

    }
    if (step3 == 33) {
        down.SetBase16((char*)string("af820335d9b3d9cf58b911d87035677fb7f528100000000").c_str());

    }
    if (step3 == 34) {
        down.SetBase16((char*)string("27c374ba3352bf58fa19ee0b096c1972efad8b13a00000000").c_str());

    }
    if (step3 == 35) {
        STRIDE2.SetBase16((char*)string("90248722fa0bf5a28a9dfee80227dc40a4d518272400000000").c_str());

    }
    if (step3 == 36) {
        down.SetBase16((char*)string("20a8469deca6b5a6d367cbc0907d07e6a5584778de2800000000").c_str());

    }
    if (step3 == 37) {
        down.SetBase16((char*)string("7661fffc79dc527cbe58429a0bc53ca4176003162551000000000").c_str());

    }
    if (step3 == 38) {
        down.SetBase16((char*)string("1ad233ff339beab0431fff16e6aaafbd2d4bc0b304745a000000000").c_str());

    }
    if (step3 == 39) {
        down.SetBase16((char*)string("6139fc7d1b1532bef353fcb3042abd0dc4329a88f025c64000000000").c_str());

    }
    if (step3 == 40) {
        down.SetBase16((char*)string("160723345822cd7f432107408ef1aed51e73770306688eea8000000000").c_str());

    }
    if (step3 == 41) {
        down.SetBase16((char*)string("4fd9df9dbf7e28ed5357ba4a062c19c48e628f6af73b061210000000000").c_str());

    }
    if (step3 == 42) {
        down.SetBase16((char*)string("12175ca9bd629545c4e1e034c565fdd68842547e3c035f6017a0000000000").c_str());

    }
    if (step3 == 43) {
        down.SetBase16((char*)string("4194afe74e855d1ce9b2ccbf4b91b829adf07249998c39bc55a40000000000").c_str());

    }
    if (step3 == 44) {
        down.SetBase16((char*)string("edbafda67ca37188cf28263571f03b9716879e4acc9c514ab67280000000000").c_str());

    }
    if (step3 == 45) {
        down.SetBase16((char*)string("35dc5d77b83d07b8feef18a81bd06d803b1ab9dcf25b6a6aed55f100000000000").c_str());

    }
    if (step3 == 46) {
        down.SetBase16((char*)string("c33ed2d1fbdd3bfe9c22b96164d38cf0d640e1c0ee8b61c39c5789a00000000000").c_str());

    }
    if (step3 == 47) {
        down.SetBase16((char*)string("2c3c3bc393101f97af5fde0010d7edee908ab325b60b9426516bd52e400000000000").c_str());

    }
    if (step3 == 48) {
        down.SetBase16((char*)string("a05a58a4f51a7285dbbb84c03d0ebe80cbf6c968b3e9f90ae726e4c7a800000000000").c_str());

    }
    if (step3 == 49) {
        down.SetBase16((char*)string("245478155f87fdf253c87c138dd557292e35e9a1b8c3026c785ecfd53c1000000000000").c_str());

    }
    if (step3 == 50) {
        down.SetBase16((char*)string("83b2334d7a4cf88e6fb6c1c6e2255bf547836eea3dc2e8c93457b164f9ba000000000000").c_str());

    }
    if (step3 == 51) {
        down.SetBase16((char*)string("1dd65f9f8db57050454f67e70f3c76d59233c72111fe28bd95dbde30e09424000000000000").c_str());

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
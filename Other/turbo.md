## How Turbo mode works

Example we are looking for a range of 11 missing letters. XXXXXXXXXXXX </br>
We need to check the entire literal range. That's 24,986,644,000,165,537,792 combinations.</br>

As in English, there are practically no three identical letters.</br>
When analyzing 19,000 WIF keys that once had coins, I very rarely see 3 identical characters in a row. </br>
This is due to the fact that private keys are generated randomly.</br>
The count shows less than ~5% of similar keys in the list.</br>

Example Start: </br>
11111111111 -> zzzzzzzzzz</br>
After launch, after a few hours (days), the range will reach:</br>
1aA99999999 next</br>
1aAA1111111</br>
since there are no 3 identical, the entire range after aAa may not be valid (empty).</br>


In order not to wait for several hours (days) of empty enumeration until aAB changes to aAB.</br>

I developed a code that every minute looks for three identical letters in the generated key and changes them to the next combination.</br>
1aAA1111111</br>
1aAA1111112</br>
(turbo)</br>
1aAB1111113</br>
In this way we save time.</br>
In turbo mode, more than 200 combinations of letter replacement, taking into account the rester.</br>

Since we are looking for only the unknown part of the key, which is only 11 letters out of 52, the probability of missing the desired WIF in turbo mode (jump) becomes even less than ~0.3%</br>

Since the turbo turns on every minute it will only fire on the left side of the 11 letter dmap (possibly the right side at the time it fires). </br>
The right side in this minute generates billions with 3.4 identical letters, they do not participate.</br>

In total, only 5 letters of the left side of the range fall under the filter.</br>

This further reduces the probability of missing the desired key to ~0.01%</br>

The risk of missing the required key exists and is ~0.01%</br>
The risk, as you can see, is not big and is justified by an increase in the overall speed x2</br>

Turbo mode will be relevant for large ranges of 9-15 letters.</br>
It significantly reduces the search time for the key.</br>

## Explanation of floating speed.
Every minute the filter checks for the presence of 3 identical letters in the key position.</br>
If found and replaced, the result of the replacement will appear at the top of the window.</br>
GPU 0 C: 23.215% [00:23:15] **WIF Was -> WIF Became**</br>
A missed range is considered passed.</br>
The number of missed combinations is added to the total.</br>
If we divide the total by the time, we get the speed.</br>

Example:</br>
Time [00:00:09]</br>
Total = 90,000,000,000</br>
90000000000/9 = speed 10 Gkey/s</br>
Rated speed 10Gkey/s

Time [00:00:10]</br>
Turbo (replacement)</br>
Total = 100,000,000,000 + (missing range)</br>

Total = 100,000,000,000 + 70,000,000,000

Total = 170,000,000,000 / 10 = 17,000 Gkey/s (17,000,000,000)

Time [00:00:11]</br>
Total = 180,000,000,000 / 11 = 16,363 Gkey/s

Time [00:00:12]</br>
Total = 190,000,000,000 / 12 = 15,833 Gkey

## Replacement protection (v3.0)
Added protection against right character filtering.</br>
KyBLV6rrV9hsbsU96VwmEtMnACavqnKnAaXXXXXXXJ9tM5JQQSo</br>
KyBLV6rrV9hsbsU96VwmEtMnACavqnKnAa1234567J9tM5JQQSo</br>
There is a small chance</br>
KyBLV6rrV9hsbsU96VwmEtMnACavqnKnAa12345**JjJ**9tM5JQQSo</br>
(turbo)</br>
KyBLV6rrV9hsbsU96VwmEtMnACavqnKnAa12345Jj**K**]9tM5JQQSo</br>
Protection will immediately return the symbol to its place</br>
KyBLV6rrV9hsbsU96VwmEtMnACavqnKnAa7654321**J**9tM5JQQSo</br>

## How is the extra letter rotated?

Every second the program rotates the main missing letters.

Depending on the speed (power of the gpu), 5 (6*) basic characters can pass.</br>
*My test showed RTX 2070 5 characters in 1 sec guaranteed.</br>
Perhaps the RTX 3090 will be able to pass 6 basic characters.</br>

Then an additional letter is added and the main range starts over.</br>

```WifSolverCuda.exe -wif KyBLV6rrV9hsbsU961wmEtMnACavqnKnEi7eY11111J9tM5JQQSo -n 11 -n2 35 -a 1EpMLcfjKsQCYUAaVj9mk981qkmT5bxvor```

An illustrative example:</br>
KyBLV6rrV9hsbsU961wmEtMnACavqnKnEi7eY[**11111**]J9tM5JQQSo</br>
KyBLV6rrV9hsbsU961wmEtMnACavqnKnEi7eZ[**zzzzz**]J9tM5JQQSo</br>

Adding a letter
KyBLV6rrV9hsbsU96[**2**]wmEtMnACavqnKnEi7eY11111J9tM5JQQSo</br>
...</br>
KyBLV6rrV9hsbsU9[**zz**]wmEtMnACavqnKnEi7eY11111J9tM5JQQSo</br>
...</br>
KyBLV6rrV9hsbsU[**zzz**]wmEtMnACavqnKnEi7eY11111J9tM5JQQSo</br>

You can search in reverse</br>
```WifSolverCuda.exe -wif KyBLV6rrV9hsb11111wmEtMnACavqnKnEi7ea611J9tM5JQQSo -n 35 -n2 11 -a 1EpMLcfjKsQCYUAaVj9mk981qkmT5bxvor```

1 extra character (-n2) = 60 sec</br>
2 additional characters = 60 min.</br>
3 additional characters = 60 hours</br>

## How random works
This mode is for long ranges.</br>
You only ask:</br>
-part1 KyBLV6rrV9hsbsU96V</br>
-part2 tM5JQQSo (min. 8 characters)</br>
-a 1EpMLcfjKsQCYUAaVj9mk981qkmT5bxvor</br>

The program automatically fills in the missing characters with random letters.</br>
Calculates the correct step and starts working.</br>
Every 30 sec. the range of random starting characters will be updated.</br>

The advantage of this mode</br>
If the range is 12-20 characters and it is not physically possible to sort through it sequentially.</br>
You can try your luck like in the lottery.</br>
Since there is no need to sort through a huge number of ranges with the same characters.</br>
With a random search, the chance of finding will be higher than a regular search.</br>

Disadvantages:</br>
Random is not effective on small ranges.</br>

If your gpu resources allow you to go through the entire range, sequential enumeration is better.</br>

Random is like a lottery - you can find it very quickly, or you may not get the desired combination at all.</br>



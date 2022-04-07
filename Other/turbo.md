## How Turbo mode works

Example we are looking for a range of 11 missing letters. XXXXXXXXXXXX </br>
We need to check the entire literal range. That's 24,986,644,000,165,537,792 combinations.</br>

As in English, there are practically no three identical letters.</br>
When analyzing 16,000 WIF keys that once had coins, I very rarely see 3 identical characters in a row. </br>
This is due to the fact that private keys are generated randomly.</br>
The count shows less than 0.1% of similar keys in the list.</br>

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

Since we are looking for only the unknown part of the key, which is only 11 letters out of 52, the probability of missing the desired WIF in turbo mode (jump) becomes even less than 0.001%</br>

Since the turbo turns on every minute it will only fire on the left side of the 11 letter dmap (possibly the right side at the time it fires). </br>
The right side in this minute generates billions with 3.4 identical letters, they do not participate.</br>

In total, only 5 letters of the left side of the range fall under the filter.</br>

This further reduces the probability of missing the desired key to 0.0001%</br>

The risk of missing the required key exists and is ~0.0001%</br>
The risk, as you can see, is not big and is justified by an increase in the overall speed x2 (x5)</br>

Turbo mode will be relevant for large ranges of 9-15 letters.</br>
It significantly reduces the search time for the key.</br>

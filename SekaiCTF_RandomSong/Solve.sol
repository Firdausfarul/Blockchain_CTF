// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface randomSong{
    function fillEnergy() external;
    function play(uint256 touchseq) external;
}

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
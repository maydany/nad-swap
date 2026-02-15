// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract MockFactory {
    mapping(address => bool) public isPair;
    mapping(address => bool) public isQuoteToken;
    mapping(address => mapping(address => address)) public getPair;

    address[] internal allPairsList;
    bool public failAllPairsLength;
    bool public failAllPairs;
    uint256 public failAllPairsAt;

    function setPair(address pair, bool enabled) external {
        isPair[pair] = enabled;
    }

    function setQuoteToken(address token, bool enabled) external {
        isQuoteToken[token] = enabled;
    }

    function setGetPair(address tokenA, address tokenB, address pair) external {
        getPair[tokenA][tokenB] = pair;
    }

    function pushAllPair(address pair) external {
        allPairsList.push(pair);
    }

    function setFailAllPairsLength(bool enabled) external {
        failAllPairsLength = enabled;
    }

    function setFailAllPairs(bool enabled, uint256 index) external {
        failAllPairs = enabled;
        failAllPairsAt = index;
    }

    function allPairsLength() external view returns (uint256) {
        if (failAllPairsLength) revert("NO_ENUM");
        return allPairsList.length;
    }

    function allPairs(uint256 index) external view returns (address pair) {
        if (failAllPairs && index == failAllPairsAt) revert("ALL_PAIRS_FAIL");
        return allPairsList[index];
    }
}

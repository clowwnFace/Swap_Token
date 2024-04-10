// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Swap {
    IERC20 tokenA;
    // address immutable owner1;
    IERC20 tokenB;
    // address immutable owner2;

    uint256 public reserveA;
    uint256 public reserveB;

    struct LiquidityProvider {
        uint256 amountA;
        uint256 amountB;
    }

    mapping(address => LiquidityProvider) _liquidityProvider;

    constructor(
        address _tokenA,
        // address _owner1,
        address _tokenB // address _owner2
    ) {
        tokenA = IERC20(_tokenA);
        // owner1 = _owner1;
        tokenB = IERC20(_tokenB);
        // owner2 = _owner2;
    }

    function addLiquidity(uint256 _amountA, uint256 _amountB) external {
        tokenA.transferFrom(msg.sender, address(this), _amountA);
        tokenB.transferFrom(msg.sender, address(this), _amountB);

        reserveA += _amountA;
        reserveB += _amountB;

        _liquidityProvider[msg.sender].amountA += _amountA;
        _liquidityProvider[msg.sender].amountB += _amountB;
    }

    function removeLiquidity(uint256 _amountA, uint256 _amountB) external {
        LiquidityProvider storage _Lp = _liquidityProvider[msg.sender];

        require(
            _Lp.amountA >= _amountA && _Lp.amountB >= _amountB,
            "SWAP: insufficient liquidy balance"
        );
        tokenA.transfer(msg.sender, _amountA);
        tokenB.transfer(msg.sender, _amountB);

        reserveA -= _amountA;
        reserveB -= _amountB;

        _liquidityProvider[msg.sender].amountA -= _amountA;
        _liquidityProvider[msg.sender].amountB -= _amountB;
    }

    function swapTokenAForB(uint256 _amountA) external {
        require(
            tokenA.allowance(msg.sender, address(this)) >= _amountA,
            "ERC20: tokenA allowance too low"
        );
        // transfer tokenA from user to contract
        _safeTransferFrom(tokenA, msg.sender, address(this), _amountA);

        // transfer tokenB to user
        uint _tokenB = calculateTokenAForB(_amountA);
        tokenB.transfer(msg.sender, _tokenB);

        reserveA += _amountA;
        reserveA -= _tokenB;
    }

    function swapTokenBForA(uint256 _amountB) external {
        require(
            tokenB.allowance(msg.sender, address(this)) >= _amountB,
            "ERC20: tokenB allowance too low"
        );
        // transfer tokenb from user to contract
        _safeTransferFrom(tokenB, msg.sender, address(this), _amountB);

        // transfer tokenA to user
        uint _tokenA = calculateTokenBForA(_amountB);
        tokenA.transfer(msg.sender, _tokenA);

        reserveB += _amountB;
        reserveB -= _tokenA;
    }

    function calculateTokenAForB(
        uint _amountA
    ) internal view returns (uint tokenB_to_recieve) {
        uint K = reserveA * reserveB;
        uint Diff_in_A = reserveA + _amountA;
        uint div_K_by_A = K / Diff_in_A;

        tokenB_to_recieve = reserveB - div_K_by_A;
    }

    function calculateTokenBForA(
        uint _amountB
    ) internal view returns (uint tokenA_to_recieve) {
        uint K = reserveA * reserveB;
        uint Diff_in_B = reserveB + _amountB;
        uint div_K_by_A = K / Diff_in_B;

        tokenA_to_recieve = reserveB - div_K_by_A;
    }

    function _safeTransferFrom(
        IERC20 token,
        address sender,
        address to,
        uint256 amount
    ) private {
        bool sent = token.transferFrom(sender, to, amount);
        require(sent == true, "ERC20: Tranfer Failed");
    }
}
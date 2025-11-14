// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol"; // 所有者权限控制

contract BeggingContract is Ownable {
    // ========== 核心状态变量 ==========
    // 记录每个地址的累计捐赠金额（单位：wei）
    mapping(address => uint256) private _donations;

    // 捐赠排行榜：存储前3名（address=捐赠者，uint256=捐赠金额）
    address[3] private _topDonors;
    uint256[3] private _topDonations;

    // 捐赠时间限制：startTime <= 捐赠时间 <= endTime（timestamp 格式）
    uint256 public immutable startTime;
    uint256 public immutable endTime;

    // ========== 事件定义（额外挑战） ==========
    /**
     * @dev 捐赠事件：记录捐赠者、捐赠金额、捐赠时间
     */
    event Donation(address indexed donor, uint256 amount, uint256 timestamp);

    // ========== 构造函数 ==========
    /**
     * @dev 初始化合约：设置所有者（部署者）、捐赠时间范围
     * @param _startTime 捐赠开始时间（时间戳，如 1755062400 = 2025-08-12 00:00:00）
     * @param _endTime 捐赠结束时间（时间戳，如 1757740800 = 2025-09-12 00:00:00）
     */
    constructor(uint256 _startTime, uint256 _endTime) Ownable(msg.sender) {
        require(_startTime > block.timestamp, "The start time must be later than the current time.");//开始时间必须晚于当前时间
        require(_endTime > _startTime, "The end time must be later than the start time.");//结束时间必须晚于开始时间
        startTime = _startTime;
        endTime = _endTime;
    }

    // ========== 核心功能 ==========
    /**
     * @dev 捐赠函数：用户向合约发送ETH，自动记录捐赠信息
     * 要求：在设定的时间范围内捐赠，且捐赠金额>0
     */
    function donate() public payable {
        // 校验：捐赠时间在范围内
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Currently outside the donation period");//当前不在捐赠时间范围内
        // 校验：捐赠金额>0
        require(msg.value > 0, "The donation amount cannot be 0.");//捐赠金额不能为0

        address donor = msg.sender;
        uint256 amount = msg.value;

        // 更新捐赠记录
        _donations[donor] += amount;

        // 更新捐赠排行榜（额外挑战）
        updateTopDonors(donor, _donations[donor]);

        // 触发捐赠事件
        emit Donation(donor, amount, block.timestamp);
    }

    /**
     * @dev 提款函数：仅所有者可提取合约内所有ETH
     */
    function withdraw() public onlyOwner {
        // 校验：合约内有余额
        require(address(this).balance > 0, "There are no available funds in the contract.");//合约内无可用资金

        // 提取所有余额到所有者地址（使用 transfer 安全转账）
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev 查询捐赠金额：查询指定地址的累计捐赠额
     * @param donor 要查询的捐赠者地址
     * @return 累计捐赠金额（wei）
     */
    function getDonation(address donor) public view returns (uint256) {
        require(donor != address(0), "Unable to query donations from zero addresses");//不能查询零地址捐赠
        return _donations[donor];
    }

    // ========== 额外挑战：捐赠排行榜功能 ==========
    /**
     * @dev 获取捐赠前3名：返回地址和对应捐赠金额（按金额降序）
     * @return 前3名地址数组、前3名金额数组（未填满时地址为0x0，金额为0）
     */
    function getTopDonors() public view returns (address[3] memory, uint256[3] memory) {
        return (_topDonors, _topDonations);
    }

    /**
     * @dev 内部函数：更新捐赠排行榜
     */
    function updateTopDonors(address donor, uint256 totalDonation) internal {
        // 遍历前3名，判断是否能进入排行榜
        for (uint256 i = 0; i < 3; i++) {
            if (totalDonation > _topDonations[i]) {
                // 若当前捐赠额大于第i名，后续名次后移
                if (i < 2) {
                    _topDonors[i+1] = _topDonors[i];
                    _topDonations[i+1] = _topDonations[i];
                }
                // 插入当前捐赠者到第i名
                _topDonors[i] = donor;
                _topDonations[i] = totalDonation;
                break; // 只插入一次，避免重复
            }
        }
    }

    // ========== 辅助函数 ==========
    /**
     * @dev 获取合约当前余额（供测试查看）
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // ========== 接收ETH回调（可选） ==========
    /**
     * @dev 允许用户直接向合约地址转账ETH（无需调用donate函数），自动触发捐赠逻辑
     */
    receive() external payable {}
}
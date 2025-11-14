// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; // 推荐使用较新版本，兼容 Remix 和测试网

/**
 * @title SimpleERC20
 * @dev 基于 ERC20 标准的简单代币合约，支持转账、授权、代扣、增发功能
 */
contract SimpleERC20 {
    // ========== 状态变量 ==========
    string public name;         // 代币名称（如 "MyToken"）
    string public symbol;       // 代币符号（如 "MTK"）
    uint8 public decimals;      // 小数位数（ERC20 标准默认 18）
    uint256 public totalSupply; // 代币总供应量

    // 账户余额映射：address -> 余额（单位：最小代币单位）
    mapping(address => uint256) private _balances;

    // 授权映射：owner -> spender -> 授权额度
    mapping(address => mapping(address => uint256)) private _allowances;

    // 合约所有者（仅所有者可增发代币）
    address private immutable _owner;

    // ========== 事件定义（符合 ERC20 标准） ==========
    /**
     * @dev 转账事件：当代币从 from 转移到 to 时触发
     * @param from 转账发起者（零地址表示增发）
     * @param to 转账接收者
     * @param value 转账数量（最小代币单位）
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev 授权事件：当 owner 授权 spender 操作代币时触发
     * @param owner 代币所有者
     * @param spender 被授权地址
     * @param value 授权额度（最小代币单位）
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // ========== 修饰器 ==========
    /**
     * @dev 仅所有者可调用
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "SimpleERC20: caller is not the owner");
        _;
    }

    // ========== 构造函数 ==========
    /**
     * @dev 初始化代币信息，并将初始总量 mint 给部署者
     * @param name_ 代币名称
     * @param symbol_ 代币符号
     * @param decimals_ 小数位数
     * @param initialSupply_ 初始总供应量（单位：代币本身，如 10000 表示 10000 个代币）
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_
    ) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        _owner = msg.sender; // 部署者为合约所有者

        // 初始供应量转换为最小代币单位（乘以 10^decimals）
        uint256 initialSupplyWithDecimals = initialSupply_ * (10 ** uint256(decimals_));
        totalSupply = initialSupplyWithDecimals;
        _balances[msg.sender] = initialSupplyWithDecimals;

        // 触发增发事件（from 为零地址）
        emit Transfer(address(0), msg.sender, initialSupplyWithDecimals);
    }

    // ========== ERC20 标准函数 ==========
    /**
     * @dev 查询账户余额
     * @param account 要查询的账户地址
     * @return 账户余额（最小代币单位）
     */
    function balanceOf(address account) public view returns (uint256) {
        require(account != address(0), "SimpleERC20: balance query for the zero address");
        return _balances[account];
    }

    /**
     * @dev 转账：从调用者账户向 to 转移 value 数量代币
     * @param to 接收者地址
     * @param value 转账数量（最小代币单位）
     * @return 转账是否成功
     */
    function transfer(address to, uint256 value) public returns (bool) {
        address from = msg.sender;
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev 授权：允许 spender 从调用者账户代扣 value 数量代币
     * @param spender 被授权地址
     * @param value 授权额度（最小代币单位）
     * @return 授权是否成功
     */
    function approve(address spender, uint256 value) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev 查询授权额度：spender 可从 owner 账户代扣的剩余代币数量
     * @param owner 代币所有者地址
     * @param spender 被授权地址
     * @return 剩余授权额度（最小代币单位）
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev 代扣转账：spender 从 from 账户向 to 转移 value 数量代币（需提前授权）
     * @param from 代币来源账户
     * @param to 接收者地址
     * @param value 转账数量（最小代币单位）
     * @return 转账是否成功
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        address spender = msg.sender;
        // 校验并扣减授权额度
        uint256 currentAllowance = _allowances[from][spender];
        require(currentAllowance >= value, "SimpleERC20: transfer amount exceeds allowance");
        _allowances[from][spender] = currentAllowance - value;

        // 执行转账
        _transfer(from, to, value);
        return true;
    }

    // ========== 所有者功能 ==========
    /**
     * @dev 增发代币：仅所有者可调用，向 to 账户增发 value 数量代币
     * @param to 接收增发代币的账户
     * @param value 增发数量（代币本身单位，如 100 表示 100 个代币）
     */
    function mint(address to, uint256 value) public onlyOwner {
        require(to != address(0), "SimpleERC20: mint to the zero address");
        
        // 转换为最小代币单位
        uint256 valueWithDecimals = value * (10 ** uint256(decimals));
        totalSupply += valueWithDecimals;
        _balances[to] += valueWithDecimals;

        // 触发增发事件
        emit Transfer(address(0), to, valueWithDecimals);
    }

    // ========== 内部辅助函数 ==========
    /**
     * @dev 内部转账逻辑（被 transfer 和 transferFrom 调用）
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        require(from != address(0), "SimpleERC20: transfer from the zero address");
        require(to != address(0), "SimpleERC20: transfer to the zero address");
        require(_balances[from] >= value, "SimpleERC20: transfer amount exceeds balance");

        // 扣减发送者余额，增加接收者余额
        _balances[from] -= value;
        _balances[to] += value;

        // 触发转账事件
        emit Transfer(from, to, value);
    }

    /**
     * @dev 内部授权逻辑（被 approve 调用）
     */
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        require(owner != address(0), "SimpleERC20: approve from the zero address");
        require(spender != address(0), "SimpleERC20: approve to the zero address");

        // 设置授权额度（覆盖原有授权）
        _allowances[owner][spender] = value;

        // 触发授权事件
        emit Approval(owner, spender, value);
    }
}
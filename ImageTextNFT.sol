// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; // 兼容最新 Remix 编译器和 OpenZeppelin 库

// 导入 OpenZeppelin 核心库（ERC721 标准实现 + 安全校验）
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // 所有者权限控制（可选，灵活开关）
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // 存储 tokenURI 元数据

/**
 * @title ImageTextNFT
 * @dev 支持图文元数据的 ERC721 NFT 合约
 * 功能：铸造 NFT 并关联 IPFS 元数据链接，支持查看元数据、所有者管理
 */
contract ImageTextNFT is ERC721, Ownable, ERC721URIStorage {
    uint256 private _tokenIdCounter; // NFT 编号计数器（自增，避免重复）

    // ========== 构造函数 ==========
    /**
     * @dev 初始化 NFT 集合名称、符号，部署者为所有者
     * @param name_ NFT 集合名称（如 "My Image Text NFT"）
     * @param symbol_ NFT 符号（如 "ITNFT"）
     */
    constructor(string memory name_,string memory symbol_)
        ERC721(name_, symbol_)
        Ownable(msg.sender) // 部署者自动成为所有者
    {
        _tokenIdCounter = 1; // NFT 编号从 1 开始（避免 0 号 token）
    }

    // ========== 核心铸造功能 ==========
    /**
     * @dev 铸造 NFT（仅所有者可铸造，如需开放给所有人可删除 onlyOwner 修饰器）
     * @param recipient 接收 NFT 的钱包地址
     * @param metadataURI IPFS 元数据 JSON 链接（如 "ipfs://QmXXX..."）
     * @return tokenId 铸造成功的 NFT 编号
     */
    function mintNFT(
        address recipient,
        string memory metadataURI
    )
        public
        onlyOwner // 仅所有者可铸造（注释此行则开放给所有人铸造）
        returns (uint256)
    {
        require(recipient != address(0), "NFT: Cannot be cast to address zero");//NFT:不能铸造到零地址
        require(bytes(metadataURI).length > 0,"NFT: Metadata links cannot be empty.");//NFT: 元数据链接不能为空

        uint256 currentTokenId = _tokenIdCounter;
        _tokenIdCounter++; // 计数器自增，下次铸造用新编号

        // 铸造 NFT 并关联到接收者
        _safeMint(recipient, currentTokenId);
        // 存储该 NFT 的元数据链接（IPFS JSON 地址）
        _setTokenURI(currentTokenId, metadataURI);

        return currentTokenId; // 返回铸造的 NFT 编号，便于查询
    }

    // ========== 重写必要函数（ERC721URIStorage 要求） ==========
    // 重写 tokenURI 函数，返回存储的元数据链接
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    // 重写 supportsInterface 函数，支持 ERC721 和 ERC721URIStorage 接口校验
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

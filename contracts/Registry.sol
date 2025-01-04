/**
 *Submitted for verification at testnet.bscscan.com on 2020-12-24
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IRegistry is IERC721 {
    event NewURI(uint256 indexed tokenId, string tokenUri);
    event NewRouter(uint256 indexed tokenId, address indexed router);
    event NewResolver(uint256 indexed tokenId, address indexed resolver);
    event Sync(
        address indexed to,
        uint256 indexed tokenId,
        uint256 indexed keyHash
    );

    ///
    function setBaseURI(string calldata baseURI) external;

    function setOwner(address to, uint256 tokenId) external;

    function subTokenId(
        uint256 tokenId,
        string calldata label
    ) external pure returns (uint256);

    function mintSubURI(
        address to,
        uint256 tokenId,
        string calldata label
    ) external;
    function safeMintSubURI(
        address to,
        uint256 tokenId,
        string calldata label,
        bytes calldata _data
    ) external;
    function mintSubURIByController(
        address to,
        uint256 tokenId,
        string calldata label
    ) external;
    function safeMintSubURIByController(
        address to,
        uint256 tokenId,
        string calldata label,
        bytes calldata _data
    ) external;

    function burnSubURI(uint256 tokenId, string calldata label) external;
    function burnSubURIByController(
        uint256 tokenId,
        string calldata label
    ) external;

    function transferURI(
        address from,
        address to,
        string calldata label
    ) external;
    function safeTransferURI(
        address from,
        address to,
        string calldata label,
        bytes calldata _data
    ) external;
    function transferSubURI(
        address from,
        address to,
        string calldata label,
        string calldata subLabel
    ) external;
    function safeTransferSubURI(
        address from,
        address to,
        string calldata label,
        string calldata subLabel,
        bytes calldata _data
    ) external;

    //function setRouter(uint256 tokenId, address router) external;
    //function setRouterByController(uint256 tokenId, address router) external;
    //function routerOf(uint256 tokenId) external view returns (address);

    function setResolver(uint256 tokenId, address resolver) external;
    function setResolverByController(
        uint256 tokenId,
        address resolver
    ) external;
    function resolverOf(uint256 tokenId) external view returns (address);

    function subTokenIdByIndex(
        uint256 tokenId,
        uint256 index
    ) external view returns (uint256);
    function subTokenIdCount(uint256 tokenId) external view returns (uint256);
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(
        Role storage role,
        address account
    ) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

//import "@openzeppelin/contracts/access/AccessControl.sol";

contract AdminControl is Ownable {
    using Roles for Roles.Role;

    Roles.Role private _controllerRoles;

    modifier onlyMinterController() {
        require(
            hasRole(msg.sender),
            "AdminControl: sender must has minting role"
        );
        _;
    }

    modifier onlyMinter() {
        require(
            hasRole(msg.sender),
            "AdminControl: sender must has minting role"
        );
        _;
    }

    constructor() Ownable(msg.sender) {
        _grantRole(msg.sender);
    }

    function grantMinterRole(address account) public onlyOwner {
        _grantRole(account);
    }

    function revokeMinterRole(address account) public onlyOwner {
        _revokeRole(account);
    }

    function hasRole(address account) public view returns (bool) {
        return _controllerRoles.has(account);
    }

    function _grantRole(address account) internal {
        _controllerRoles.add(account);
    }

    function _revokeRole(address account) internal {
        _controllerRoles.remove(account);
    }
}

library StringUtil {
    /**
     * @dev Return the count of the dot "." in a string
     */
    function dotCount(string memory s) internal pure returns (uint) {
        s; // Don't warn about unused variables
        // Starting here means the LSB will be the byte we care about
        uint ptr;
        uint end;
        assembly {
            ptr := add(s, 1)
            end := add(mload(s), ptr)
        }
        uint num = 0;
        uint len = 0;
        for (len; ptr < end; len++) {
            uint8 b;
            assembly {
                b := and(mload(ptr), 0xFF)
            }
            if (b == 0x2e) {
                num += 1;
            }
            ptr += 1;
        }
        return num;
    }
}

contract Registry is IRegistry, ERC721Burnable, AdminControl {
    using EnumerableSet for EnumerableSet.UintSet;

    // Mapping from holder tokenId to their (enumerable) set of subdomain tokenIds
    mapping(uint256 => EnumerableSet.UintSet) private _subTokens;
    mapping(uint256 tokenId => string tokenURI) public _tokenURIs;

    // Mapping from token ID to resolver address
    mapping(uint256 => address) internal _tokenResolvers;

    string private _baseUri;
    // cfx hash
    //string  private constant _BASE_DEFI_DOMAIN = "cfx";
    //uint256 private constant _HT_ROOT_HASH = 0x6f10f4351d7270f47859fb1e769d5b456a85aedae5bbb77ae0f8f5cc6ad5f4c1;
    //uint256 private constant _DEFI_ROOT_HASH = 0xe23c1845b96c0c4b37fbb545b38cff2fe0449edb1df7e34390454e19d697616b;
    uint256 private constant _BNB_ROOT_HASH =
        0xdba5666821b22671387fe7ea11d7cc41ede85a5aa67c3e7b3d68ce6a661f389c;
    //uint256 private constant _CFX_ROOT_HASH = 0xf60b73180d56a49cd45c6477f69b0b2505679b536bfd4fee397e6aaf4e2a4b39;

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        _checkAuthorized(_ownerOf(tokenId), _msgSender(), tokenId);
        _;
    }
    // Defi Name Service (.defi)
    // BSC Name Service (.bnb)
    // Conflux Name Service (.cfx)
    // Heco Name Service (.ht)
    constructor() ERC721("BSC Name Service (.bnb)", "TD") {
        _mint(
            address(0xE0b9dEa53a90B7a2986356157e2812e5335A4a1D),
            _BNB_ROOT_HASH
        );
        _tokenURIs[_BNB_ROOT_HASH] = "bnb";
    }

    // expose for Resolver
    function isApprovedOrOwner(
        address account,
        uint256 tokenId
    ) external view returns (bool) {
        return _isAuthorized(_ownerOf(tokenId), account, tokenId);
    }

    function root() public pure returns (uint256) {
        return _BNB_ROOT_HASH;
    }

    function subTokenIdByIndex(
        uint256 tokenId,
        uint256 index
    ) public view override returns (uint256) {
        require(subTokenIdCount(tokenId) > index);
        return _subTokens[tokenId].at(index);
    }

    function subTokenIdCount(
        uint256 tokenId
    ) public view override returns (uint256) {
        require(exists(tokenId));
        return _subTokens[tokenId].length();
    }

    function setBaseURI(
        string calldata baseURI
    ) external override onlyMinterController {
        _baseUri = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function setResolver(
        uint256 tokenId,
        address resolver
    ) public override onlyApprovedOrOwner(tokenId) {
        _setResolver(tokenId, resolver);
    }

    function setResolverByController(
        uint256 tokenId,
        address resolver
    ) public override onlyMinterController {
        _setResolver(tokenId, resolver);
    }

    function resolverOf(
        uint256 tokenId
    ) external view override returns (address) {
        address resolver = _tokenResolvers[tokenId];
        require(resolver != address(0));
        return resolver;
    }

    function sync(uint256 tokenId, uint256 keyHash) external {
        require(_tokenResolvers[tokenId] == msg.sender);
        emit Sync(msg.sender, tokenId, keyHash);
    }

    /// transfer tokenId through label string
    function transferURI(
        address from,
        address to,
        string calldata label
    ) external override onlyApprovedOrOwner(subTokenId(root(), label)) {
        _transfer(from, to, subTokenId(root(), label));
    }

    function safeTransferURI(
        address from,
        address to,
        string calldata label,
        bytes calldata _data
    ) external override onlyApprovedOrOwner(subTokenId(root(), label)) {
        _safeTransfer(from, to, subTokenId(root(), label), _data);
    }

    function transferSubURI(
        address from,
        address to,
        string calldata label,
        string calldata subLabel
    )
        external
        override
        onlyApprovedOrOwner(subTokenId(subTokenId(root(), label), subLabel))
    {
        _transfer(from, to, subTokenId(subTokenId(root(), label), subLabel));
    }

    function safeTransferSubURI(
        address from,
        address to,
        string calldata label,
        string calldata subLabel,
        bytes calldata _data
    )
        external
        override
        onlyApprovedOrOwner(subTokenId(subTokenId(root(), label), subLabel))
    {
        _safeTransfer(
            from,
            to,
            subTokenId(subTokenId(root(), label), subLabel),
            _data
        );
    }

    function setOwner(
        address to,
        uint256 tokenId
    ) external override onlyApprovedOrOwner(tokenId) {
        _transfer(ownerOf(tokenId), to, tokenId);
    }

    /**
     * For user to mint the subdomain of a exists tokenURI
     * @param to address which will set as the subdomain owner
     * @param tokenId the parent token Id of the subdomain
     * @param label the label of the subdomain
     */

    function mintSubURI(
        address to,
        uint256 tokenId,
        string calldata label
    ) external override onlyApprovedOrOwner(tokenId) {
        _safeMintURI(to, tokenId, label, "");
    }

    function safeMintSubURI(
        address to,
        uint256 tokenId,
        string calldata label,
        bytes calldata _data
    ) external override onlyApprovedOrOwner(tokenId) {
        _safeMintURI(to, tokenId, label, _data);
    }

    function mintSubURIByController(
        address to,
        uint256 tokenId,
        string calldata label
    ) external override onlyMinterController {
        _safeMintURI(to, tokenId, label, "");
    }

    function safeMintSubURIByController(
        address to,
        uint256 tokenId,
        string calldata label,
        bytes calldata _data
    ) external override onlyMinterController {
        _safeMintURI(to, tokenId, label, _data);
    }

    /// the subdomain can be burn by token owner
    function burnSubURI(
        uint256 tokenId,
        string calldata label
    ) external override onlyApprovedOrOwner(tokenId) {
        _burnURI(tokenId, label);
    }

    function burnSubURIByController(
        uint256 tokenId,
        string calldata label
    ) external override onlyMinterController {
        _burnURI(tokenId, label);
    }

    // Internal
    function subTokenId(
        uint256 tokenId,
        string memory label
    ) public pure override returns (uint256) {
        require(bytes(label).length != 0);
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        tokenId,
                        keccak256(abi.encodePacked(label))
                    )
                )
            );
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _safeMintURI(
        address to,
        uint256 tokenId,
        string memory label,
        bytes memory _data
    ) internal {
        require(bytes(label).length != 0);
        require(StringUtil.dotCount(label) == 0);
        require(exists(tokenId));

        uint256 _newTokenId = subTokenId(tokenId, label);
        bytes memory _newUri = abi.encodePacked(
            label,
            ".",
            _tokenURIs[tokenId]
        );

        uint256 count = StringUtil.dotCount(_tokenURIs[tokenId]);
        if (count == 1) {
            _subTokens[tokenId].add(_newTokenId);
        }

        if (bytes(_data).length != 0) {
            _safeMint(to, _newTokenId, _data);
        } else {
            _mint(to, _newTokenId);
        }

        _setTokenURI(_newTokenId, string(_newUri));

        emit NewURI(_newTokenId, string(_newUri));
    }

    /**
     * @dev Burn the tokenURI according the token ID,
     * @param tokenId the root tokenId of a tokenURI,
     * @param label the label of a tokenURI should be burn
     */
    function _burnURI(uint256 tokenId, string memory label) internal {
        uint256 _subTokenId = subTokenId(tokenId, label);
        // remove sub tokenIds itself
        _subTokens[tokenId].remove(_subTokenId);

        //_burn(subTokenId);

        if (_tokenResolvers[tokenId] != address(0)) {
            delete _tokenResolvers[tokenId];
        }

        super._burn(_subTokenId);
    }

    function _setResolver(uint256 tokenId, address resolver) internal {
        require(exists(tokenId));
        _tokenResolvers[tokenId] = resolver;
        emit NewResolver(tokenId, resolver);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
}

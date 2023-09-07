// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract space_share {
    struct StorageOwner {
        address SO;
        uint256 volumeGB;
        uint256 pricePerGB;
        bytes SOConnectionInfo;
    }

    struct DataOwner {
        address DO;
        bytes DOConnectionInfo;
    }

    struct StorageContract {
        address DO;
        address SO;
        bytes SOConnectionInfo;
        bytes DOConnectionInfo;
        uint256 volumeGB;
        uint256 startDate;
        uint256 pricePerGB;
    }

    mapping(address => StorageOwner) public StorageOwnerMap;
    mapping(address => DataOwner) public DataOwnerMap;
    mapping(bytes32 => StorageContract) public StorageContractMap;

    // uint SOId;
    // uint DOId;
    // uint StorageContractId;

    address[] SOList;
    address[] DOList;
    bytes32[] storageContractList;

    error Unauthorized();

    modifier isExistingStorageOwner(address SO) {
        bool flag = false;
        uint256 l = SOList.length;
        unchecked {
            for (uint256 i = 0; i < l; i++) {
            if (SOList[i] == SO) {
                flag = true;
                break;
            }
            }
        }
        if (flag == false)
            revert Unauthorized();
        _;
    }


    function createStorageOrder(
        uint256 volumeGB,
        uint256 pricePerGB,
        bytes memory SOConnectionInfo
    ) public {
        bool flag = true;
        uint256 l = SOList.length;
        address SO = msg.sender;
        unchecked{
        for (uint256 i = 0; i < l; i++) {
            if (SOList[i] == SO) {
                flag = false;
                break;
            }
        }
        }
        if (flag == false)
            revert Unauthorized(); 
        StorageOwnerMap[SO] = StorageOwner(
            SO,
            volumeGB,
            pricePerGB,
            SOConnectionInfo
        );
        SOList.push(SO);
    }

    function getStorageOrder(address _SO) public view isExistingStorageOwner(_SO) returns ( StorageOwner memory SO){
        return StorageOwnerMap[_SO];
    }

    function cancelStorageOrder(address SO) public isExistingStorageOwner(SO) {
        delete StorageOwnerMap[SO];
        uint256 index;
        uint256 l = getStorageOrderLength();
        for (uint256 i = 0; i < l; i++) {
            if (SO == SOList[i]) {
                index = i;
                break;
            }
        }
        SOList[index] = SOList[SOList.length - 1];
        SOList.pop();
    }

    function getStorageOrderLength() public view returns (uint256) {
        return SOList.length;
    }

    function createStorageContract(address SO, bytes calldata DOConnectionInfo) public {
        DataOwnerMap[msg.sender] = DataOwner(msg.sender, DOConnectionInfo);
        DOList.push(msg.sender);
        bytes32 key = keccak256(abi.encodePacked(msg.sender, SO));
        StorageOwner memory so = getStorageOrder(SO);
        StorageContractMap[key] = StorageContract(msg.sender, SO, so.SOConnectionInfo, DOConnectionInfo, so.volumeGB, block.timestamp, so.pricePerGB);
        storageContractList.push(key);
        cancelStorageOrder(SO);
    }
    function cancelStorageContract(address SO) public {
        uint256 index;
        uint256 length = DOList.length;
        for(uint256 i = 0; i < length; i++){
            if (DOList[i] == msg.sender){
                index = i;
                break;
            }
        }
        // require(index != 0x0,"User not having storage contract");
        bytes32 key = keccak256(abi.encodePacked(msg.sender, SO));

        delete StorageContractMap[key];
        delete DataOwnerMap[msg.sender];
        index = 0;
        length = storageContractList.length;
        for(uint256 i = 0; i < length; i++){
            if (key == storageContractList[i]){
                index = i;
                break;
            }
        }
        storageContractList[index] = storageContractList[length - 1];
        storageContractList.pop();
    }
}

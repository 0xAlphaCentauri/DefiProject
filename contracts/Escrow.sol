// SPDX-License-Identifier: UNLICENSED

interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _id) external;
}
pragma solidity ^0.8.0;

contract Escrow {
    //Variables
    address public nftAddress;
    uint256 public nftID;
    uint256 public purchasePrice;
    uint256 public escrowAmount;
    address payable public seller;
    address payable public buyer;
    address public lender;
    address public inspector;    
    
    
    // Modifiers
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this function");
        _;
    }

    modifier onlyInspector() {
        require(msg.sender == inspector, "Only inspector can call this function");
        _;
    }

    // State Vars
    bool public inspectionPassed = false;
    mapping(address => bool) public approval;

    receive() external payable{

    }

    // Constructor
    constructor(address _nftAddress, 
    uint256 _nftID, 
    uint256 _purchasePrice,
    uint256 _escrowAmount,
    address payable _seller,
    address payable _buyer,
    address _lender,
    address _inspector
    ){
        nftAddress = _nftAddress;
        nftID = _nftID;
        purchasePrice = _purchasePrice;
        escrowAmount = _escrowAmount;
        seller = _seller;
        buyer = _buyer;
        lender = _lender;
        inspector = _inspector;
    }



    // Functions
    function depositErnest() public payable onlyBuyer {
        require(msg.value >= escrowAmount);
    }

    function updateInspectionStatus(bool _passed) public onlyInspector {
        inspectionPassed = _passed;
    }

    function approveSale() public{
        approval[msg.sender] = true;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    // Cancel sale and handle earnest deposit
    // If inspection fails then refund, otherwise it goes to seller
    function cancelSale() public {
        if (inspectionPassed == false){
            payable(buyer).transfer(address(this).balance);
        }
        else{
            payable(seller).transfer(address(this).balance);
        }
    }

    // Finalize the sale
    function finalizeSale() public {
        require(inspectionPassed, 'must pass inspection');
        require(approval[buyer], 'must be approved by buyer');
        require(approval[seller], 'must be approved by seller');
        require(approval[lender], 'must be approved by lender');
        require(address(this).balance >= purchasePrice, 'must have sufficient funds');

        // Require successful transfer of funds
        (bool success, ) = payable(seller).call{value: address(this).balance}("");
        require(success);

        // Transfer ownership of propery
        IERC721(nftAddress).transferFrom(seller, buyer, nftID);
    }
}
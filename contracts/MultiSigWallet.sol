// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract MultiSigWallet{

    address[] public OwnerAddr;
    bool internal transactionOn;
    uint public TransactionNo;
    uint votes;
    uint allowVotes;
    uint disallowVotes;
    
    mapping(address=>bool) approval;
    mapping(address=>uint) public Owner;
    mapping(address=>uint) public Spend;

    event Deposit(address from, uint amount,bool isOwner);
    event TransferRequest(address from, address to, uint amount);
    event Transfer(address from, address to, uint amount, bool isApproved);
    event LeaveRequest(address owner, uint withdraw);
    event Leave(address owner, uint withdraw, bool allowed);
    
    struct Transaction{
        address from;
        address payable to;
        uint amount;
        bool approved;
    }

    Transaction[] public transactions;

    function deposit() external payable{
        require(msg.value>0,"Depositing zero amount is not allowed");
        bool IsOwner = false;

        if(Owner[msg.sender]>0){
            Owner[msg.sender]+=msg.value;
            IsOwner = true;
            
        }
        else{
            require(OwnerAddr.length+1<=3,"No more owners allowed for the wallet.");
            Owner[msg.sender]=msg.value;
            Spend[msg.sender]=0;
            OwnerAddr.push(msg.sender);
            approval[msg.sender]=false;
            leaveApproval[msg.sender]=false;
            IsOwner = false;
        }

        emit Deposit(msg.sender, msg.value, IsOwner);
    }
    
    function getBalance() public view returns(uint) {

        return(address(this).balance);

    }

    modifier isOwner(address _Address){
        require(OwnerAddr.length>0,"Sufficient no of wallet owners not available");
        bool isowner=false;
        
        for(uint i=0; i<OwnerAddr.length; i++){
            if(OwnerAddr[i]==_Address){
                isowner=true;
                break;
            }
            else{
                continue;
            }
        }
        
        require(isowner==true, "Not a owner"); 
        _;
    }

    function doTransaction(address payable transact_dest,uint transact_amount) public isOwner(msg.sender) {

       require(transactionOn==false,"One transaction is already going on");
       transactionOn=true;
       transactions.push(Transaction(msg.sender,transact_dest,transact_amount,false));
       emit TransferRequest(msg.sender,transact_dest,transact_amount);                
    }

    function transactioncheck(address _from, address payable _to, uint _amount) internal  returns(bool) {

        if(_amount<getBalance()){
            _to.transfer(_amount);
            Spend[_from]+=_amount;
            transactions[TransactionNo].approved=true;
            emit Transfer(_from, _to, _amount, true);
            return true;
        }
        else{
            return false;
        }          
    }
    
    function transferApproved(string memory _approved) public isOwner(msg.sender){
        require(transactionOn==true, "No transaction is going on.");
        require(approval[msg.sender]==false, "You have already approved");
        bytes32 hashed = keccak256(abi.encodePacked(_approved));
        require(hashed==keccak256(abi.encodePacked("yes"))||hashed==keccak256(abi.encodePacked("no")), "Please enter yes or no, all in small case");
        if (hashed==keccak256(abi.encodePacked("yes"))){
             allowVotes+=1;
        }
        else{
            disallowVotes+=1;
        }
        approval[msg.sender]=true;
        votes++;
        if(votes==OwnerAddr.length && allowVotes==OwnerAddr.length){
            if(transactioncheck(transactions[TransactionNo].from,transactions[TransactionNo].to, transactions[TransactionNo].amount)){
                resetApproval();
            }
        }
        else if(votes==OwnerAddr.length) {
            emit Transfer(transactions[TransactionNo].from,transactions[TransactionNo].to, transactions[TransactionNo].amount, false);
            resetApproval();
        } 
    }
    
    function resetApproval() private {
        transactionOn=false;
        votes=0;
        allowVotes=0;
        disallowVotes=0;
        TransactionNo++;
        
        for(uint i=0;i<OwnerAddr.length;i++){
            approval[OwnerAddr[i]]=false;

        }
    }

    // Leave wallet code

     mapping(address=>bool) leaveApproval;
     address ownerToleave;
     bool leaveOn=true;
     uint leaveVotes=0;
     uint leaveAllowVotes;
     uint leaveDisallowVotes;

    function leaveApproved(string memory _allow) public isOwner(msg.sender){
        require(leaveOn==true, "No one is leaving");
        require(leaveApproval[msg.sender]==false, "You have already approved");
        bytes32 hashed = keccak256(abi.encodePacked(_allow));
        require(hashed==keccak256(abi.encodePacked("yes"))||hashed==keccak256(abi.encodePacked("no")), "Please enter yes or no, all in small case");
        
        if (hashed==keccak256(abi.encodePacked("yes"))){
             leaveAllowVotes+=1;
        }
        else{
            leaveDisallowVotes+=1;
        }

        leaveApproval[msg.sender]=true;
        leaveVotes++;
        
        if(leaveVotes==OwnerAddr.length && leaveAllowVotes==OwnerAddr.length){           
            leaveDone();
        }
        else if(votes==OwnerAddr.length){
            
            for(uint i=0;i<OwnerAddr.length;i++){
                leaveApproval[OwnerAddr[i]]=false;
            }
            
            leaveVotes = 0;
            leaveAllowVotes = 0;
            leaveDisallowVotes = 0;
            ownerToleave=address(0);           
            emit Leave(ownerToleave, Owner[ownerToleave] , false);
        } 
    }

    function leaveWallet() public isOwner(msg.sender){
        require(Owner[msg.sender]>=Spend[msg.sender], "You can only leave when your spend money is less than or equal to deposit money");
        leaveOn=true;
        ownerToleave=msg.sender;        
        emit LeaveRequest(ownerToleave, Owner[msg.sender]);
    }

    function leaveDone() private{
        address payable to = payable(ownerToleave);
        uint amount = Owner[ownerToleave]-Spend[ownerToleave];
        to.transfer(amount);
        
        delete Owner[ownerToleave];
        delete Spend[ownerToleave];
        delete approval[ownerToleave];
        delete leaveApproval[ownerToleave];
        
        for(uint i=0;i<OwnerAddr.length;i++){
            if(OwnerAddr[i]==to){
                delete OwnerAddr[i];
                OwnerAddr[i]=OwnerAddr[OwnerAddr.length-1];
                OwnerAddr.pop();
            }
        }
        
        for(uint i=0;i<OwnerAddr.length;i++){
            leaveApproval[OwnerAddr[i]]=false;
        }
        
        leaveVotes = 0;
        leaveAllowVotes = 0;
        leaveDisallowVotes = 0;
        ownerToleave=address(0);
        
        emit Leave(ownerToleave, amount , true);
    }
}
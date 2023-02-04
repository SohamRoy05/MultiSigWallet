const { expect } = require("chai");

describe("Test", ()=>{

    let walletContract = null;
    let account1 = null;
    let account2 = null;
    let account3 = null;
    let account4 = null;

    before("Deploy", async ()=>{
        [account1,account2,account3,account4] = await ethers.getSigners();
        const ContractFactory = await ethers.getContractFactory("MultiSigWallet");
        walletContract = await ContractFactory.deploy();
        await walletContract.deployed();
    })
    
    it("deposit",async()=>{
        // walletContract.deposit();
        let balance = await walletContract.getBalance();
        let balance_str= await balance.toString()
        console.log(balance_str);

        let data1 = {from:account1.address, to:walletContract.address, value:"3000000000000000", data:"0xd0e30db0",gasLimit:"30000000"}
        let data2 = {from:account2.address, to:walletContract.address, value:"4000000000000000", data:"0xd0e30db0",gasLimit:"30000000"}
        let data3 = {from:account3.address, to:walletContract.address, value:"5000000000000000", data:"0xd0e30db0",gasLimit:"30000000"}
        
        await account1.sendTransaction(data1)
        await account2.sendTransaction(data2)
        await account3.sendTransaction(data3)
        let balance_after = await walletContract.getBalance()
        let balance_str_after= await balance_after.toString()
        console.log(balance_str_after);
        console.log(await walletContract.OwnerAddr(0))
        console.log(await walletContract.OwnerAddr(1))
        console.log(await walletContract.OwnerAddr(2))

    })

    it("transfer",async()=>{        
        
        const tx = await walletContract.doTransaction(account4.address, 2000000000);
        // const tx_2 = await tx.wait();
        // console.log(tx_2.events[0]);
        
        console.log(await walletContract.transactions(0));
        console.log(await(account4.getBalance()));
        
        await walletContract.connect(account1).transferApproved("yes"); 
        await walletContract.connect(account2).transferApproved("yes"); 
        await walletContract.connect(account3).transferApproved("yes");
        
        console.log(await walletContract.transactions(0));
        console.log(await(account4.getBalance()));

    })

    it("leave",async()=>{
        
        await walletContract.connect(account1).leaveWallet();

        console.log(await walletContract.OwnerAddr(2))
        console.log(await account1.getBalance());
        await walletContract.connect(account1).leaveApproved("yes"); 
        await walletContract.connect(account2).leaveApproved("yes"); 
        await walletContract.connect(account3).leaveApproved("yes");
        console.log(await account1.getBalance());
        console.log(await walletContract.OwnerAddr(2))
        

    })
})
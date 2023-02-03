
const main = async() =>{
    const [deployer] = await hre.ethers.getSigners();
    const accountbalance = await deployer.getBalance();
    const walletContractFactory = await hre.ethers.getContractFactory("MultiSigWallet");
    const walletContract = await walletContractFactory.deploy();
    await walletContract.deployed();
    console.log("Contract to be deployed at:", walletContract.address);
    console.log("Contract deployed by:",deployer.address);
    console.log("Deployed Account balance is:",accountbalance.toString());
}

const runMain = async() =>{
    try {
        await main();
        process.exit(0);            
    } catch (error) {
        console.log(error);
        process.exit(1);
    }
}

runMain();
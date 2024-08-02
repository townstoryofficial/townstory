async function main() {
  const [deployer] = await ethers.getSigners();
  const beginBalance = await deployer.getBalance();

  console.log("Deployer:", deployer.address);
  console.log("Balance:", ethers.utils.formatEther(beginBalance));

  const accountContract = await upgrades.deployProxy(await ethers.getContractFactory("TownStoryAccountUpgradeable"));
  await accountContract.deployed();
  console.log("Account contract: ", accountContract.address);

  const backpackContract = await upgrades.deployProxy(await ethers.getContractFactory("TownStoryBackpackUpgradeable"));
  await backpackContract.deployed();
  console.log("Backpack contract: ", backpackContract.address);

  const avatarCustomizationContract = await upgrades.deployProxy(await ethers.getContractFactory("AvatarCustomizationUpgradeable"));
  await avatarCustomizationContract.deployed();
  console.log("AvatarCustomization contract: ", avatarCustomizationContract.address);

  const inventoryContract = await upgrades.deployProxy(await ethers.getContractFactory("TownStoryInventoryUpgradeable"));
  await inventoryContract.deployed();
  console.log("Inventory contract: ", inventoryContract.address);

  const dustTokenContract = await upgrades.deployProxy(await ethers.getContractFactory("StarDustTokenUpgradeable"));
  await dustTokenContract.deployed();
  console.log("DustToken contract: ", dustTokenContract.address);

  const itemsContractArray = [
    backpackContract.address, 
    avatarCustomizationContract.address,
    inventoryContract.address
  ];

  const syncContractFactory = await ethers.getContractFactory("GameSyncUpgradeable");
  const syncContract = await upgrades.deployProxy(syncContractFactory, [accountContract.address, itemsContractArray, dustTokenContract.address, process.env.SERVER_SIGNER]);
  await syncContract.deployed();
  console.log("syncContract contract: ", syncContract.address);

  const createContractFactory = await ethers.getContractFactory("TownStoryCreateAccount");
  const createContract = await createContractFactory.deploy(accountContract.address, process.env.SERVER_SIGNER, process.env.SERVER_SIGNER);
  console.log("create contract: ", createContract.address);
  
  console.log("\nSetting:");

  await accountContract.addGameOwnerBatch([createContract.address, syncContract.address]);
  console.log("Account addGameOwner successfully");

  await backpackContract.addGameOwnerBatch([syncContract.address]);
  console.log("Backpack addGameOwner successfully");

  await avatarCustomizationContract.addGameOwnerBatch([syncContract.address]);
  console.log("AvatarCustomization addGameOwnerBatch successfully");

  await inventoryContract.addGameOwnerBatch([syncContract.address]);
  console.log("Inventory addGameOwnerBatch successfully");

  await dustTokenContract.addGameOwnerBatch([syncContract.address]);
  console.log("DustToken addGameOwnerBatch successfully");

  // +++
  const endBalance = await deployer.getBalance();
  const gasSpend = beginBalance.sub(endBalance);

  console.log("\nLatest balance:", ethers.utils.formatEther(endBalance));
  console.log("Gas:", ethers.utils.formatEther(gasSpend));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
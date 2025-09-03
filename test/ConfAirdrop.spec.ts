import { expect } from "chai";
import { ethers, fhevm } from "hardhat";
import { FhevmType } from "@fhevm/hardhat-plugin";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe("ConfAirdrop (Mystery Airdrop)", function () {
  let owner: HardhatEthersSigner;
  let alice: HardhatEthersSigner;
  let bob: HardhatEthersSigner;

  let airdrop: any;
  let addr: string;

  beforeEach(async () => {
    [owner, alice, bob] = await ethers.getSigners();
    const Factory = await ethers.getContractFactory("ConfAirdrop");
    airdrop = await Factory.deploy();
    addr = await airdrop.getAddress();
  });

  it("owner sets encrypted allocation; user can decrypt their own allocation", async () => {
    const enc100 = await fhevm.createEncryptedInput(addr, owner.address).add64(100).encrypt();
    await (await airdrop.connect(owner).setAllocation(alice.address, enc100.handles[0], enc100.inputProof)).wait();

    const encAlloc = await airdrop.connect(alice).getMyAllocation();
    const clearAlloc = await fhevm.userDecryptEuint(FhevmType.euint64, encAlloc, addr, alice);
    expect(clearAlloc).to.eq(100);
  });

  it("user claims within their allocation; balances update confidentially", async () => {
    // Set allocation 100 for Alice
    const enc100 = await fhevm.createEncryptedInput(addr, owner.address).add64(100).encrypt();
    await (await airdrop.connect(owner).setAllocation(alice.address, enc100.handles[0], enc100.inputProof)).wait();

    // Alice claims 40
    const enc40 = await fhevm.createEncryptedInput(addr, alice.address).add64(40).encrypt();
    await (await airdrop.connect(alice).claim(enc40.handles[0], enc40.inputProof)).wait();

    // Check remaining = 60
    const encRem = await airdrop.connect(alice).getMyRemaining();
    const clearRem = await fhevm.userDecryptEuint(FhevmType.euint64, encRem, addr, alice);
    expect(clearRem).to.eq(60);

    // Check claimed = 40
    const encClaimed = await airdrop.connect(alice).getMyClaimed();
    const clearClaimed = await fhevm.userDecryptEuint(FhevmType.euint64, encClaimed, addr, alice);
    expect(clearClaimed).to.eq(40);
  });

  it("over-claim resolves to zero (fail-closed), does not leak plaintext", async () => {
    const enc50 = await fhevm.createEncryptedInput(addr, owner.address).add64(50).encrypt();
    await (await airdrop.connect(owner).setAllocation(alice.address, enc50.handles[0], enc50.inputProof)).wait();

    // Alice tries to claim 60 > 50
    const enc60 = await fhevm.createEncryptedInput(addr, alice.address).add64(60).encrypt();
    await (await airdrop.connect(alice).claim(enc60.handles[0], enc60.inputProof)).wait();

    // Claimed should remain 0; Remaining should be 50
    const encClaimed = await airdrop.connect(alice).getMyClaimed();
    const clearClaimed = await fhevm.userDecryptEuint(FhevmType.euint64, encClaimed, addr, alice);
    expect(clearClaimed).to.eq(0);

    const encRem = await airdrop.connect(alice).getMyRemaining();
    const clearRem = await fhevm.userDecryptEuint(FhevmType.euint64, encRem, addr, alice);
    expect(clearRem).to.eq(50);
  });
});

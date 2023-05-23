# 1. DAO (Decentralized Autonomous Organization)
Implemented using Solidity

---

# 2. Biz version

## Deployment Procedure
(Two contracts need to be deployed for Governance voting.)

1. You can use an existing ERC20 standard token. If you want to create a new token for voting, deploy the ERC20.sol contract. Remember to keep track of the contract address after deployment.
2. Deploy the Core contract. You need to input the address of the ERC20 token contract, snap time, minimum token threshold for proposing, and proposal fee as constructor parameters. Remember to keep track of the contract address after deployment.
3. Deploy the Dao contract. You need to input the name of the DAO and the address of the Core contract as constructor parameters. Remember to keep track of the contract address after deployment.
4. Execute the "GrantOwner()" function of the Core contract to make the Dao contract the owner of the Core contract.
5. Execute the "setProposer()" function to grant qualification to the account address that will become a proposer.

## Voting Procedure

1. Execute the "approve" function of the ERC20 token contract to allow the Dao contract to withdraw the proposal fee.
2. Execute the "setRule()" function to set up the voting environment for each proposer by inputting delay, rgstPeriod, votePeriod, turnout, and quorum.
3. The proposer executes the "propose()" function to create a proposal. Only accounts registered as "Proposer" and holding tokens equal to or above the "threshold" can make proposals.
4. Once a proposal is created, it is recorded in the contract, and voter registration starts after the "delay" period. (Any account that wants to participate in the vote must register as a voter during this period. However, the account that created the proposal is automatically registered as a voter when submitting the proposal.)
5. After the registration period ends, the snap time, which calculates the voting power of voters, begins. It is essential to execute the "snapFront()" function at snap time. If this function is not executed, the proposal will be automatically canceled.
6. After snap time, the voting period begins. Only accounts that registered as voters during the registration period can vote.
7. After the voting period ends, the snap time, which recalculates the voting power of voters, begins. It is essential to execute the "snapAfter()" function. This is a system to prevent unfair voting due to token transfers between accounts before and after the voting period. The minimum value of the token holdings calculated before and after the voting period is considered as the voting weight.
8. If there is at least one option among the voting options that meets the quorum, the vote status becomes "completed." If there is no option that meets the quorum, the vote status becomes "defeated."
9. Once a vote becomes "completed," execute the "execute()" function to finalize it.

---

# 3. Crypto version

## Deployment Procedure
To conduct Governance voting, you need to deploy five contracts in the following order:

1. Deploy ERC20.sol contract and remember the contract address.
2. Deploy ERC20Votes.sol contract and remember the contract address.
3. When deploying ERC20Votes contract, either set the ERC20 contract address as the initial value or register the ERC20 token using the setToken() function after deploying the ERC20Votes contract.
4. Deploy Rule.sol contract and remember the contract address.
5. When deploying Rule contract, either input the values of delay, period, quorum, threshold, and proposeFee variables or input each value after deploying the Rule contract.
6. Deploy Timelock.sol contract and remember the contract address.
7. When deploying Timelock contract, either input the value of the timelock variable or set it later after deploying the Timelock contract.
8. Deploy Dao.sol contract and remember the contract address.
9. When deploying Dao contract, input the DAO name, Timelock, ERC20Votes, and Rule contract addresses together.
10. In the addOwnership() functions of ERC20Votes, Timelock, and Rule contracts, the address of the Dao contract is added to update the owner of each contract.

## Voting Procedure
1. The approve function of the ERC20 token contract is executed to allow the Dao contract to take the proposal fee.
2. Only an account registered as a "Proposer" with holdings of tokens equal to or greater than the "threshold" can make a proposal.
3. When a "Proposer" makes a proposal, it is recorded in the contract and waits for the "delay" time to start voting.
4. Anyone who wants to participate in the vote must register their voting rights using the resister function during the "delay" time.
5. Once voting begins, it lasts for the "period" time. Those participating in the vote must express their support, opposition, or abstention using the castVote function during this period.
6. After the voting period, the results are checked to see if they meet the "quorum". If the proposal is successful, the proposalId is sent to the Timelock contract to wait for the "timelock" period.
7. After the "timelock" period, anyone can execute the proposal using the execute function.


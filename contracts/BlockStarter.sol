// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract BlockStarter {
    struct Project {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 ownerBalance;
        uint256 sumOfAllDonations;
        string image;
        address[] donators;
        uint256[] donations;
        mapping(address => uint256) donatorBalances;
    }
    struct ProjectItem {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 ownerBalance;
        uint256 sumOfAllDonations;
        string image;
        address[] donators;
        uint256[] donations;
    }
    
    mapping(uint256 => Project) private projects;
    uint256 private numberOfProjects = 0;

    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) external returns (uint256) {
        Project storage project = projects[numberOfProjects];

        require(_deadline > block.timestamp, "The deadline should be a date in the future.");

        project.owner = _owner;
        project.title = _title;
        project.description = _description;
        project.target = _target;
        project.deadline = _deadline;
        project.ownerBalance = 0;
        project.sumOfAllDonations = 0;
        project.image = _image;

        numberOfProjects++;

        return numberOfProjects - 1;
    }

    function donate(uint256 _id) external payable {
        Project storage project = projects[_id];

        require(msg.value > 0, "Invalid amount.");
        require(!projectHasExpired(_id), "This campaign has expired.");

        project.donators.push(msg.sender);
        project.donations.push(msg.value);
        project.donatorBalances[msg.sender] += msg.value;
        project.ownerBalance += msg.value;
        project.sumOfAllDonations += msg.value;
    }

    function getDonators(uint256 _id) external view returns (address[] memory, uint256[] memory) {
        return (projects[_id].donators, projects[_id].donations);
    }

    function getCampaigns() external view returns (ProjectItem[] memory) {
        ProjectItem[] memory allProjects = new ProjectItem[](numberOfProjects);

        for (uint256 i = 0; i < numberOfProjects; i++) {
            allProjects[i] = fillProjectItem(i);
        }

        return allProjects;
    }

    function getCampaign(uint256 _id) external view returns (ProjectItem memory) {
        return fillProjectItem(_id);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function refund(uint256 _id, uint256 _amount) external payable {
        Project storage project = projects[_id];

        require(projectHasExpired(_id), "This campaign is active.");
        require(project.donatorBalances[msg.sender] >= _amount && _amount > 0, "Invalid amount.");
        require(sendFromContract(payable(msg.sender), _amount), "Refund failed.");

        project.donatorBalances[msg.sender] -= _amount;
        project.ownerBalance -= _amount;
    }

    function cashout(uint256 _id, uint256 _amount) external payable {
        Project storage project = projects[_id];

        require(project.sumOfAllDonations >= project.target, "The target has not been reached yet");
        require(project.owner == msg.sender, "You are not the owner.");
        require(project.ownerBalance >= _amount && _amount > 0, "Invalid amount.");
        require(sendFromContract(payable(project.owner), _amount), "Withdrawal failed.");

        project.ownerBalance -= _amount;
    }

    function getRefundableBalance(uint256 _projectId) external view returns (uint256) {
        return projects[_projectId].donatorBalances[msg.sender];
    }

    function fillProjectItem(uint256 _projectId) private view returns (ProjectItem memory) {
        ProjectItem memory project;

        project.owner = projects[_projectId].owner;
        project.title = projects[_projectId].title;
        project.description = projects[_projectId].description;
        project.target = projects[_projectId].target;
        project.deadline = projects[_projectId].deadline;
        project.ownerBalance = projects[_projectId].ownerBalance;
        project.sumOfAllDonations = projects[_projectId].sumOfAllDonations;
        project.image = projects[_projectId].image;
        project.donators = projects[_projectId].donators;
        project.donations = projects[_projectId].donations;

        return project;
    }

    function sendFromContract(address payable _to, uint256 _amount) private returns (bool) {
        (bool success, ) = _to.call{value: _amount}("");

        return success;
    }
    
    function projectHasExpired(uint256 _projectId) private view returns (bool) {
        return
            (block.timestamp > projects[_projectId].deadline) &&
            (projects[_projectId].sumOfAllDonations < projects[_projectId].target);
    }
}

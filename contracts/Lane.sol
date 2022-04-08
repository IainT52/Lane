// Why blockchain is useful: It puts responsibilty on the individuals renting the bikes
// because it is their responsibility to take care of the bike while they have it.
// People rent their bikes to other people and the people that rent have to put down a deposit.
pragma solidity >=0.4.22 <0.9.0;

contract Lane {

    struct Bike {
        uint id;
        uint deposit;
        uint fee;
        address payable owner;
        address payable renter;
        uint rental_start;
        uint rental_duration;
        bool rented;
        bool owner_return;
        bool renter_return;
    }

    address private _owner;
    mapping(uint => Bike) public bikes;
    uint public bike_count = 0;
    uint max_rental_days = 7;


    modifier onlyOwner() {
        require(msg.sender == _owner, "You do not have permission to access this method.");
        _;
    }

    modifier validBikeId(uint id) {
        require(id > 0 && id <= bike_count, "Invalid Bike ID.");
        _;
    }

    constructor() public {
        _owner = msg.sender;
    }



    function createListing(uint deposit, uint fee) public {
        // Require a valid deposit and fee
        require(deposit > 0, "Deposit must be greater than zero.");
        require(fee > 0, "Fee must be greater than zero.");

        bike_count++;
        
        bikes[bike_count] = Bike(
            bike_count,
            deposit,
            fee,
            msg.sender,
            msg.sender,
            0,
            0,
            false,
            false,
            false
        );
    }

    function rentBike(uint id, uint rental_days) public payable validBikeId(id) {
        Bike memory bike = bikes[id];
        address payable owner = bike.owner;

        // Require enough Ether, not rented, owner isn't trying to borrow their own bike, rental days is under max rental time
        require(msg.value >= bike.deposit + bike.fee, "Not enough funds to rent!");
        require(!bike.rented, "Bike is already rented.");
        require(owner != msg.sender, "Listing owner cannot rent.");
        require(rental_days <= max_rental_days, "You cannot rent for more than the max rental days.");

        // Refund if renter sent more than required
		if (msg.value > bike.deposit + bike.fee) {
			uint refund = msg.value - (bike.deposit + bike.fee);
			msg.sender.transfer(refund);
		}

        bike.renter = msg.sender;
        bike.rental_start = block.timestamp;
        bike.rented = true;
        bikes[id] = bike;
    }

    function returnRentalOwner(uint id) public payable validBikeId(id) {
        Bike memory bike = bikes[id];
        address payable owner = bike.owner;
        address payable renter = bike.renter;

        // Require sender is the bike owner, bike is rented
        require(bike.rented, "Bike has not been rented.");
        require(msg.sender == owner, "Bike owner must initiate rental return!");

        // Determine rental period, and associated rental cost
        uint end_time = block.timestamp;
        uint rental_cost = rental_days;
        rentalCost = _rentalDays * bike.rentalFee;
        rentalCost = bike.rentalDeposit <= rentalCost
            ? bike.rentalDeposit
            : rentalCost; // x <= y ? x : y
        // Transfer responsibility back to owner
        bike.custodian = bike.owner;
        // Mark as rented
        bike.rented = false;
        // Update the product
        products[_id] = bike;
        // Pay the owner by sending them Ether
        address(_owner).transfer(rentalCost);
        // Return remaining deposit to the borrower
        uint256 returnedDeposit;
        returnedDeposit = bike.rentalDeposit - rentalCost;
        address(_borrower).transfer(returnedDeposit);
        
    }

    function returnRentalRenter(uint id) public payable validBikeId(id){
        Bike memory bike = bikes[id];
        address payable owner = bike.owner;
        address payable renter = bike.renter;
    }

    function bikeStolen(uint id) public payable validBikeId(id) {
        Bike memory bike = bikes[id];
        address payable owner = bike.owner;
        address payable renter = bike.renter;
        uint days_elapsed = (block.timestamp - bike.rental_start) / 60 / 60 / 24;
        
        // Require bike is currently rented, sender is the owner, bike has been rented for at least 7 days
        require(bike.rented, "Bike has not been rented.");
        require(msg.sender == owner, "Only the bike owner can report a bike as stolen!");
        require(days_elapsed > bike.rental_duration + 1, "The bike must be rented for at least one day over the specified rental days to be reported as stolen!");

        // Refund owner the rental deposit and fee
        address(owner).transfer(bike.deposit + bike.fee);
    }

    function deleteProduct(uint id) public validBikeId(id) {
        // Fetch the product
        Product memory bike = products[_id];
        // Make sure the product has a valid id
        require(bike.id > 0 && bike.id <= productCount);
        // Make sure only the product owner can delete a product
        require(bike.owner == msg.sender);
        // Make sure the owner is currently the custodian of the product
        require(bike.custodian == bike.owner);
        // Mark as rented (i.e. unavailable to rent)
        bike.rented = true;
        // Update the product
        products[_id] = bike;
        // Trigger an event
        emit ProductDeleted(
            productCount,
            bike.name,
            bike.owner,
            bike.custodian,
            bike.rented
        );
    }

    function editProduct(
        uint256 _id,
        string memory _name,
        string memory _description,
        string memory _category,
        uint256 _rentalDeposit,
        uint256 _rentalFee
    ) public {
        // Fetch the product
        Product memory bike = products[_id];
        // Make sure the product has a valid id
        require(bike.id > 0 && bike.id <= productCount);
        // Make sure only the product owner can edit a product
        require(bike.owner == msg.sender);
        // Make sure the owner is currently the custodian of the product
        require(bike.custodian == bike.owner);
        // Edit the product
        bike.name = _name;
        bike.description = _description;
        bike.category = _category;
        bike.rentalDeposit = _rentalDeposit;
        bike.rentalFee = _rentalFee;
        products[_id] = bike;
        emit ProductEdited(
            productCount,
            _name,
            _description,
            _category,
            _rentalDeposit,
            _rentalFee,
            msg.sender,
            false
        );
    }
}

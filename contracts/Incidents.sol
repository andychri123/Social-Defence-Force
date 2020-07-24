pragma solidity ^0.5.0;
import "./Token.sol";
//import "./SafeMath.sol";

/// todo import safemath from node modules

// Only when an incident is verified is rep released

contract Incidents is Token {
//    using SafeMath for uint256;
    address public owner;
    uint256 public incidentsAmount;

    struct Profile {
        bool status;
        string name;
        string description;
        uint256 rank;
        uint256[] proposals;
        string location;
        // ipfs hash for profile pic
        userRep uRep;
        uint256 rep;
        // maybe mappings ?
        mapping(address => bool) friends;
        //      users that gave rep to the user
        mapping(address => bool) leftRep;
        //      users the user gave rep to
        mapping(address => bool) gaveRep;
    }

    struct userRep {
        uint256 totalRep;
        uint256 repToGive;
        //      users that gave rep to the user
        rep[] repsLeft;
        mapping(address => bool) leftRep;
    }

    struct rep {
        //      the address of the user that left rep
        address user;
        string message;
        uint256 amount;
    }
    //-----------------------------------------------------------------------------------------------------------
    //-----------------------------------------------------------------------------------------------------------

    struct incidentReport {
        uint256 incidentID;
        bool verified;
        bool fake;
        string description;
        //       longitude, latitude
        string lng;
        string lat;
        //       time and date the beacn was sent
        uint256 time;
        address beaconSender;
        address[] responders;
        //       reportID
        mapping(address => witnessReport) wReports;
        //       set as uint so multiple evidence can be submitted
        //  ipfsHash
        mapping(address => evidence) evi;
        mapping(address => verification) verifications;
        //       first array to get to 5 wins and verifies
        //       list of verifiers that passed the incident
        address[] veriPass;
        //       list of verifiers that failed the incident
        address[] veriFail;
        bool repPaid;
    }

    struct witnessReport {
        //        Caution users that all info is public
        address witnessReportID;
        bool willTestify;
        //        ???
        string description;
    }

    struct evidence {
        //        true if its an image false if its a video link
        bool image;
        //        ipfs hash or video link
        string evidence;
    }

    struct verification {
        //         the verifiers vote on wether the incident was real or not
        bool verdict;
        string description;
    }

    incidentReport[] incidentArray;
    mapping(uint256 => incidentReport) incidents;
    mapping(address => rep) public usersLeftRepTo;
    mapping(address => bool) verifiers;
    mapping(address => Profile) profiles;

    event incidentReported(uint256 incidentID, string location);
    event incidentVerified(uint256 incidentID);
    event voted(address);
    event promoted(address);

    function createVerifier(address _verifier) external aboveLevel(7) {
        verifiers[_verifier];
    }

    function addEvidence(
        string memory _evidence,
        bool _image,
        uint256 _incidentID
    ) public payable {
        //       rand is either a random integer generated offchain or index and use a
        //       counter ??
        evidence storage e = incidents[_incidentID].evi[msg.sender];
        e.image = _image;
        e.evidence = _evidence;
    }

    function setBeacon(string memory _description, string memory _longitude,
                       string memory _latitude, uint256 _time) public payable {
        //       rand is either a random integer generated offchain or index and use a
        //       counter ??
        uint256 incidentID = incidentsAmount++;
        incidentReport storage i = incidents[incidentID];
        i.incidentID = 0;
        i.description = _description;
        i.lng = _longitude;
        i.lat = _latitude;
        i.time = _time;
        i.beaconSender = msg.sender;
    }

    function getBeacon(uint256 id) public view returns ( string memory description,
                                   string memory lng, string memory lat){
        string memory description = incidents[id].description;
        string memory lng = incidents[id].lng;
        string memory lat = incidents[id].lat;
        return (description, lng, lat);
    }

    function addAmount() public payable {
        incidentsAmount++;
    }

    function getIncidentAmount() public view returns (uint256) {
        return incidentsAmount;
    }

    function createWitnessReport( string memory _description, bool _willTestify,
                                  uint256 _incidentID ) public payable {
        //       rand is either a random integer generated offchain or index and use a
        //       counter ??
        witnessReport storage wp = incidents[_incidentID].wReports[msg.sender];
        wp.witnessReportID = msg.sender;
        wp.description = _description;
        wp.willTestify = _willTestify;
    }

    //
    function verifyIncident( uint256 _incidentID, bool _verdict, string memory _description
                           ) public payable {
        require(verifiers[msg.sender] == true);
        incidentReport storage v = incidents[_incidentID];
        verification storage i = incidents[_incidentID].verifications[msg
            .sender];
        i.verdict = _verdict;
        i.description = _description;
        ///  first to 7 votes wins!!
        if (_verdict == true) {
            v.veriPass.push(msg.sender);
            if (v.veriPass.length >= 7) {
                v.verified = true;
            } else {
                emit voted(msg.sender);
            }
        } else {
            v.veriFail.push(msg.sender);
            if (v.veriFail.length >= 7) {
                v.fake = true;
            } else {
                emit voted(msg.sender);
            }
        }
    }

    //  pays out the rep for an incident when it has been verified
    function payoutRep(uint256 _incidentID) public payable {
        incidentReport storage r = incidents[_incidentID];
        require(r.verified == true);
        uint256 quart = r.responders.length.div(4);
        for (uint256 i = 0; i < r.responders.length; i++) {
            uint256 reps = profiles[r.responders[i]].rep;
            if (i <= quart) {
                reps.add(4);
            } else if (i <= quart * 2) {
                reps.add(3);
            } else if (i <= quart * 3) {
                reps.add(2);
            } else {
                reps.add(1);
                r.repPaid == true;
            }
        }
    }

    function buyRep(uint256 _amount) public payable {
        uint256 repAmount = _amount.mul(3);
        profiles[msg.sender].uRep.repToGive.add(repAmount);
        burn( _amount);
    }

    //  can only give a max of 3 to one account
    //
    function giveRep( address _user, uint256 _amount, string memory _message) public payable {
        userRep storage sender = profiles[msg.sender].uRep;
        Profile storage user = profiles[_user];
        require(sender.repToGive >= _amount &&_amount <= 3 &&user.leftRep[msg.sender] == false);
        rep memory _rep;
        _rep.user = msg.sender;
        _rep.message = _message;
        _rep.amount = _amount;
        user.leftRep[msg.sender] = true;
        user.rep.add(_amount);
        sender.repToGive.sub(_amount);
    }

    function negRep(address _user, uint256 _amount, string memory _message) public payable {
        userRep storage sender = profiles[msg.sender].uRep;
        Profile storage user = profiles[_user];
        require(sender.repToGive >= _amount && _amount <= 3 &&user.leftRep[msg.sender] == false);
        rep memory _rep;
        _rep.user = msg.sender;
        _rep.message = _message;
        _rep.amount = _amount;
        user.leftRep[msg.sender] = true;
        user.rep.sub(_amount);
        sender.repToGive.sub(_amount);
    }

    //------------------------------------------------------------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------

    function createAccount(string memory _name, string memory _description,
                           string memory _location) public payable {
        //       bool status = profiles[msg.sender].status;
        //      if (status) {revert();}
        profiles[msg.sender].status = true;
        profiles[msg.sender].name = _name;
        profiles[msg.sender].description = _description;
        profiles[msg.sender].location = _location;
    }

    function myProfile()public view returns (string memory name, string memory description,
                                             string memory location, address add){
        string memory name = profiles[msg.sender].name;
        string memory description = profiles[msg.sender].description;
        string memory location = profiles[msg.sender].location;
        address add = msg.sender;
        return (name, description, location, add);
    }

    //    function respond(uint _incidentID)public payable{}

    //----------------------------------------------------------------------------------------------------------
    //---------------------------------------------------------------------------------------------------------
    //
    // RANKS   1) PRIVATE
    //            only has messaging
    //         2) CORPORAL
    //            x2 vote weight
    //         3) SERGEANT
    //            x3 vote weight
    //         4) LIEUTENANT
    //            x4 vote weight
    //         5) CAPTAIN
    //            x5 vote weight
    //         6) COMMODORE
    //            x6 vote weight
    //            rank of COMMODORE is only available by confirmation by ADMIRAL
    //            COMMODORE can promote or demote by one RANKS
    //            any user that is LIEUTENANT and lower
    //         7) ADMIRAL
    //            x7 vote weight
    //            ADMIRAL can promote or demote any user by 1 rank
    //            All users can only be promoted once
    //            ADMIRAL has full veto over all process of the DAO funds
    //            to prevent abuse

    modifier aboveLevel(uint256 _rank) {
        require(profiles[msg.sender].rank >= _rank);
        _;
    }

    function levelUp(address _user) public payable {
        profiles[_user].rank = profiles[_user].rank.add(1);
    }

    function promote(address _user) public payable aboveLevel(6) {
        if (profiles[msg.sender].rank == 6) {
            if (profiles[_user].rank <= 4) {
                levelUp(_user);
            } else {
                emit promoted(_user);
            }
        } else {
            if (profiles[_user].rank <= 4) {
                levelUp(_user);
            } else {
                emit promoted(_user);
            }
        }
    }

    //   function getThisUser() returns (Profile){
    //       return profiles[msg.sender];
    //   function getUsers() public
}

//   function demote(){

//   }

//  require rank of ADMIRAL 7
//    function fire(){

//    }

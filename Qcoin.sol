pragma solidity ^0.4.15;

contract Qcoin {
    mapping(address => uint)  balance;//balance[address]
    mapping(address => mapping(address => uint)) allowance;//allowance[owner][spender]
    uint totalCount;

    function init(address user, uint amount) public returns (bool){
        balance[user] = amount;
        totalCount += amount;
        return true;
    }

    function transfer(address from, address to, uint amount) public returns (bool){
        if (_checkBalance(from, amount)) {
            balance[from] -= amount;
            balance[to] += amount;
            return true;
        } else {
            return false;
        }

    }

    function getBalance(address user) public constant returns (uint) {
        return balance[user];
    }

    function _checkBalance(address from, uint amount) private view returns (bool){
        if (balance[from] - amount >= 0)
            return true;
        else
            return false;
    }
}

contract EventFactory {
    mapping(string => address)  events;//events[identifier]=>event address

    function createNewEvent(string identifier, uint possibleOutcomeCount, Qcoin qcoin) public returns (address){
        events[identifier] = address(new Event(possibleOutcomeCount, qcoin));
        return events[identifier];
    }

    function getEvent(string identifier) public returns (address){
        return events[identifier];
    }

}

contract Event {
    Qcoin _qcoin;
    mapping(address => uint[2])predictions;//predictions[user_address]=>(outcome prediction, cost)
    address[][]  tables;//tables[outcome]=>[user1,user2,...]
    uint _outcomeCount;
    uint _outcome;
    uint[] assets; //assets[outcome]=total assets in this outcome;
    uint rate;
    event log(uint number);
    function Event(uint outcomeCount, Qcoin qcoin) public {
        _outcomeCount = outcomeCount;
        _qcoin = qcoin;
        assets.length = outcomeCount;
        tables.length = outcomeCount;
    }

    function setPrediction(address user, uint prediction, uint amount) public {
        predictions[user] = [prediction, amount];
        assets[prediction] += amount;
        tables[prediction].push(user);

        _qcoin.transfer(user, this, amount);
    }

    function getPrediction(address user) public returns (uint[2]){
        return predictions[user];
    }

    function setOutcome(uint outcome) public {
        _outcome = outcome;
    }

    function getOutcome() public returns (uint) {
        return _outcome;
    }

    function processResult() public returns (bool) {
        uint precision=10000000;
        if (assets[_outcome]==0){
            return false;
        }
        uint sum = 0;
        for (uint i = 0; i < assets.length; i++) {
            sum += assets[i];
        }
        rate = sum*precision / assets[_outcome];
        log(rate);
        for (i = 0; i < tables[_outcome].length; i++) {
            log(getPrediction(tables[_outcome][i])[1]);
            _qcoin.transfer(this, tables[_outcome][i], rate * getPrediction(tables[_outcome][i])[1]/precision);
        }
        return true;
    }
}

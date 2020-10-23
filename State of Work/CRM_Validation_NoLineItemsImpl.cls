/**
 * @author      Olga Shishkova
 * @date        04/01/2018
 * @group       DFS-SFDC
 * @description Check has LineItems in transaction 
 */

public class CRM_Validation_NoLineItemsImpl extends CRM_ValidationRulesAbstract {

    override public Boolean doCheck(Integer order, Asset trx){
    	Map<Integer, sObject> lineItems = CRM_Repository.getChildItems('transaction', order, 'LineItems');
    	//payments!
	    return lineItems.values().isEmpty();
	}

}
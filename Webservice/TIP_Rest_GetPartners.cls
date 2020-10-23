/**
 * @author      Anna Filimonova
 * @date        10/03/2020
 * @group       DFS-SFDC
 * @description Webservice class for GET partner info
 */
@RestResource(UrlMapping='/GetPartners/*')
global with sharing class TIP_Rest_GetPartners {

    private static Map<String, Map<String, TIP_Rest_Mapping__mdt>> fieldMapping = TIP_RestHelperUtil.getJSONFieldMap();

    private static List<String> BOOLEAN_FIELDS = new List<String> {
        TIP_Wrappers.Fields_WorkingDestination.TAXEXEMPTION.name(),
        TIP_Wrappers.Fields_WorkingDestination.PARTNERCOMPLIANCE.name()
    };

    private static List<String> DATE_FIELDS = new List<String> {
        TIP_Wrappers.Fields_Partner.PARTNERSTARTDATE.name(),
        TIP_Wrappers.Fields_Partner.PARTNERENDDATE.name(),
        TIP_Wrappers.Fields_Contact.VALIDITYDATE.name(),
        TIP_Wrappers.Fields_Contact.VISAVALIDITYDATE.name()
    };
    
    @HttpGet
    global static List<TIP_Wrappers.PartnerData> doGet() {
        Map<String, String> requestParams = RestContext.request.params;

        Map<String, String> accountParams = new Map<String, String>();
        accountParams.put('RecordTypeId', TIP_RestFactory.TIP_ACCOUNT_RT);

        Map<String, String> destParams = new Map<String, String>();
        Map<String, String> contactParams = new Map<String, String>();

        for (String paramName : requestParams.keySet()) {
            for (TIP_Wrappers.Fields_Partner pField : TIP_Wrappers.Fields_Partner.values()) {
                if (pField.name().equalsIgnoreCase(paramName)) {
                    accountParams.put(paramName, requestParams.get(paramName));
                }
            }

            for (TIP_Wrappers.Fields_WorkingDestination wField : TIP_Wrappers.Fields_WorkingDestination.values()) {
                if (wField.name().equalsIgnoreCase(paramName)) {
                    destParams.put(paramName, requestParams.get(paramName));
                }
            }

            for (TIP_Wrappers.Fields_Contact cField : TIP_Wrappers.Fields_Contact.values()) {
                if (cField.name().equalsIgnoreCase(paramName)) {
                    contactParams.put(paramName, requestParams.get(paramName));
                }
            }
        }

        String queryTemplate = 'SELECT {0}, (SELECT {1} FROM TIP_Working_Destinations__r{2}), (SELECT {3} FROM Contacts{4}) FROM Account{5}';
        List<String> queryParams = new List<String>();
        queryParams.add(TIP_PartnerService.accountFields);
        queryParams.add(TIP_PartnerService.wdFields);
        //form working destionation condition
        queryParams.add(getConditions(destParams, TIP_Working_Destination__c.getSObjectType().getDescribe().getName()));
        queryParams.add(TIP_PartnerService.contactFields);
        //form contacts condition
        queryParams.add(getConditions(contactParams, Contact.getSObjectType().getDescribe().getName()));
        //form accounts condition
        queryParams.add(getConditions(accountParams, Account.getSObjectType().getDescribe().getName()));
        String formatQuery = String.format(queryTemplate, queryParams);
        System.debug(formatQuery);
        //return new List<TIP_Wrappers.PartnerData>()



        List<Account> accounts = Database.query(formatQuery);
        System.debug('----- ' + accounts.size());
        List<TIP_Wrappers.PartnerData> resultList = new List<TIP_Wrappers.PartnerData>();
        integer counter = 0;
        for (Account a : accounts) {
            System.debug(counter + ': ' + a.TIP_Working_Destinations__r.size() + '-' + a.Contacts.size());
            if (((a.TIP_Working_Destinations__r == null || a.TIP_Working_Destinations__r.isEmpty()) && !destParams.isEmpty())
                || ((a.Contacts == null || a.Contacts.isEmpty()) && !contactParams.isEmpty())) {
                    continue;
                }

            TIP_Wrappers.PartnerData partnerWrap = TIP_RestFactory.createPartnerWrap(a);
            resultList.add(partnerWrap);
        }
        return resultList;
    }

    private static String getCondition(TIP_Rest_Mapping__mdt objectMap, String queryParamValue) {
        String returnValue = 'null';
        Boolean isNot = false;
        if (queryParamValue.startsWith('!')) {
            isNot = true;
            queryParamValue = queryParamValue.substring(1, queryParamValue.length());
        }
        if (objectMap.Is_Boolean__c || objectMap.Is_Date__c) {
            returnValue = (isNot ? ' !=  ' : ' = ') + queryParamValue;
        } else {
            List<String> listParams = queryParamValue.split(','); 
            returnValue = (isNot ? ' NOT IN ' : ' IN ') + '(\'' + String.join(listParams, '\', \'') + '\')';
        }
        return returnValue;
    }

    private static String getConditions(Map<String, String> params, String objectName) {
        String returnCondition = '';
        if (!params.isEmpty()) {
            List<String> queryParams = new List<String>();
            for (String paramLabel : params.keySet()) {
                TIP_Rest_Mapping__mdt objectMap = getSObjectFieldMap(objectName, paramLabel);
                if (objectMap != null) {
                    String objectField = objectMap.Object_Field__c;
                    //String paramValue = getParamValue(objectMap, params.get(paramLabel));
                    String aCondition = getCondition(objectMap, params.get(paramLabel));
                    if (!String.isEmpty(aCondition)) {
                        String condition = objectField + aCondition;
                        queryParams.add(condition);
                    }
                }
            }
            if (!queryParams.isEmpty()) {
                returnCondition = ' WHERE ' + String.join(queryParams, ' AND ');
            }
        }
        return returnCondition;
    }

    private static TIP_Rest_Mapping__mdt getSObjectFieldMap(String objectName, String paramLabel) {
        TIP_Rest_Mapping__mdt aField = null;
        Map<String, TIP_Rest_Mapping__mdt> objectMapping = fieldMapping.get(objectName);
        if (objectMapping != null) {
            aField = objectMapping.get(paramLabel);
        }
        return aField;
    }

}

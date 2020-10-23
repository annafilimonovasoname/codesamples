/**
 * @author      Anna Filimonova
 * @date        12/03/2020
 * @group       DFS-SFDC
 * @description Helper class for non-specific procedures for TIP_REST_CreatePartner
 */
public with sharing class TIP_RestHelperUtil {

    /** Cashed mapping of country names and iso codes */
    private static Map<String, String> countriesWithProperIsoCodes;
    private static Map<String, Map<String, TIP_Rest_Mapping__mdt>> jsonFieldMap;
    public static Map<String, Map<String, TIP_Rest_Mapping__mdt>> getJSONFieldMap() {
        if (jsonFieldMap == null) {
            jsonFieldMap = new Map<String, Map<String, TIP_Rest_Mapping__mdt>>();
            List<TIP_Rest_Mapping__mdt> fieldMapping = [
                SELECT Object_Field__c, Object_Name__c, JSON_Field__c, 
                       Is_Inbound__c, Is_Date__c, Is_Boolean__c
                FROM TIP_Rest_Mapping__mdt
                LIMIT 5000
            ];
            for (TIP_Rest_Mapping__mdt aMap : fieldMapping) {
                Map<String, TIP_Rest_Mapping__mdt> objectMap = jsonFieldMap.get(aMap.Object_Name__c);
                if (objectMap == null) {
                    objectMap = new Map<String, TIP_Rest_Mapping__mdt>();
                }
                objectMap.put(aMap.JSON_Field__c, aMap);
                jsonFieldMap.put(aMap.Object_Name__c, objectMap);
            }
        }
        return jsonFieldMap;
    }
    /** === UTIL METHODS === */
    /**
    * @description Method will retrieve active picklist values
    * @param SObjectField picklist field to retrieve values
    * @return      -
    */
    public static List<String> getPicklistValues(SObjectField aType) {
        List<String> pickListValuesList= new List<String>();
        Schema.DescribeFieldResult fieldResult = aType.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getValue());
        }     
        return pickListValuesList;
    }

    /**
    * @description Method will get list of allowed dependent picklists values for parent picklist values
    * @param objectName parent object 
    * @param parentField parent picklist field 
    * @param childField dependent picklist field 
    * @return      -
    */
    public static Map<String, List<String>> getDependentPicklistOptions(String objectName, string parentField, string childField) {
        TIP_DependedUtils.PicklistWrapper wrap = TIP_DependedUtils.getDependentPicklist(objectName, parentField, childField);
        return wrap.pickListMap;
    }

    /**
    * @description Method will retrieve ISO Codes Mapping from Custom Metadata
    * @param       -
    * @return      -
    */
    public static Map<String, String> retrieveIsoCodesMapping() {
        if (countriesWithProperIsoCodes == null) {
            countriesWithProperIsoCodes = new Map<String, String>();

        List<Country_IsoCode_Mapping__mdt> countryIsoCodeMappings = [
            SELECT Country__c, ISO_Code_Alpha_2__c
            FROM Country_IsoCode_Mapping__mdt
            LIMIT 50000
        ];

        for (Country_IsoCode_Mapping__mdt countryIsoCodeMapping : countryIsoCodeMappings) {
            countriesWithProperIsoCodes.put(countryIsoCodeMapping.ISO_Code_Alpha_2__c, countryIsoCodeMapping.Country__c);
            }
        }
        return countriesWithProperIsoCodes;
    }

    /**
    * @description For fields validation we transform the wrapper object into map 
    *              where key is wrapper object field name to upper case.
    * @param jsonString Serialized wrapper object.
    * @return Map<String, String> transformed wrapper object.
    */
    public static Map<String, Object> transformJsonToMap(String jsonString) {
        Map<String, Object> initialTransform = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        Map<String, Object> transformWithProperKeys = new Map<String, Object>();
        for (String initialKey : initialTransform.keySet()) {
            transformWithProperKeys.put(initialKey.toUpperCase(), initialTransform.get(initialKey));
        }
        return transformWithProperKeys;
    }

    /**
    * @description Return list of accounts with working destinations and contacts selected be specified external ids.
    * @param externalIds list of external ids.
    * @return List<Account> list of accounts with all fields.
    */
    public static List<Account> getAllFieldsForAccounts(Set<String> externalIds) {
        String allFieldsQueryTemplate = 'SELECT {0}, (SELECT {1} FROM TIP_Working_Destinations__r), (SELECT {2} FROM Contacts) FROM Account WHERE TIP_Account_External_Id__c IN :externalIds';
        String formatQuery = String.format(
            allFieldsQueryTemplate, 
            new List<String>{
                TIP_PartnerService.accountFields,
                TIP_PartnerService.wdFields,
                TIP_PartnerService.contactFields
            });
        return Database.query(formatQuery);
    }

    /**
    * @description Return query string with all account fields with inner working destination, program and contact select.
    * @param -
    * @return query string.
    */
    public static String getAllAccountFields() {
        String allFieldsQueryTemplate = '{0}, (SELECT {1} FROM TIP_Working_Destinations__r), (SELECT {2} FROM TIP_Programs__r), (SELECT {3} FROM Contacts)';
        return String.format(
            allFieldsQueryTemplate, 
            new List<String>{
                TIP_PartnerService.accountFields,
                TIP_PartnerService.wdFields,
                TIP_PartnerService.programFields,
                TIP_PartnerService.contactFields
            });
    }
}

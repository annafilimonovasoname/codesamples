/**
 * @author      Anna Filimonova
 * @date        17/03/2020
 * @group       DFS-SFDC
 * @description Parent class for specific validations
 */
public with sharing class TIP_RestValidationProcessor {

    /** Values collected to check against database by fieldname */
    private static Map<String, Map<String, List<String>>> collectedValues = new Map<String, Map<String, List<String>>>();

    /** Partner record external id */
    private String partnerExtId;

    /**
     * @description Creates an instance of the processor.
     * @param -
     * @return an instance of the processor. 
     */
    public TIP_RestValidationProcessor(String partnerExternalId) {
        this.partnerExtId = partnerExternalId;
    }

    /**
     * @description Validates serialized wrapper to a list of required fields. 
     * Checks required fields and populates some lists for further checks.
     * @param validator TIP_ValidatorUtil instance
     * @param aRecord serialized record to validate
     * @param requiredFields list of required fields to check
     * @param fieldsToCollect list of fields to collect
     * @return List<String> list of missing fields. 
     */
    public List<String> getMissingRequiredFields(TIP_ValidatorUtil validator, Map<String, Object> aRecord, List<String> requiredFields, List<String> fieldsToCollect) {
        List<String> missingRequiredFields = new List<String>();
        for (String aField : requiredFields) {
            if (validator.isEmptyField((String) aRecord.get(aField))) {
                missingRequiredFields.add(aField);
            }
        }

        for (String aField : fieldsToCollect) {
            if (!String.isBlank(aField)) {
                TIP_RestValidationProcessor.addCollectedValue(partnerExtId, aField, (String) aRecord.get(aField));
            }
        }

        return missingRequiredFields;
    }

    /**
     * @description Check unique field values of the  serialized wrapper against previous values.
     * @param aRecord serialized reccord to validate
     * @param fieldsToCollect list of fields to collect
     * @return List<String> list of duplicated fields. 
     */
    public List<String> getDuplicatedFields(Map<String, Object> aRecord, List<String> fieldsToCollect) {
        List<String> duplicatedFields = new List<String>();
            for (String fieldToCheckDupLabel : fieldsToCollect) {
                String fieldToCheckDupValue = (String) aRecord.get(fieldToCheckDupLabel);
                List<String> collectedValuesByField = TIP_RestValidationProcessor.getCollectedFieldValuesForPartner(partnerExtId, fieldToCheckDupLabel);
                if (fieldToCheckDupValue == null || collectedValuesByField == null) continue; // something is wrong
                if (collectedValuesByField.contains(fieldToCheckDupValue)) {
                    collectedValuesByField.remove(collectedValuesByField.indexOf(fieldToCheckDupValue));
                }
                if (collectedValuesByField.contains(fieldToCheckDupValue)) {
                    duplicatedFields.add(fieldToCheckDupLabel);
                }
            }
            return duplicatedFields;
    }

       
    /**
    * @description I am tired
    * @param -
    * @return -
    */
    public static void addCollectedValue(String extId, String fieldName, String fieldalue) {
        if (String.isBlank(fieldalue)) return;
        Map<String, List<String>> collectedValuesByPartner = collectedValues.get(extId);
        if (collectedValuesByPartner == null) {
            collectedValuesByPartner = new Map<String, List<String>>();
        }
        List<String> collectFieldValuesByPartner = collectedValuesByPartner.get(fieldName);
        if (collectFieldValuesByPartner == null) {
            collectFieldValuesByPartner = new List<String>();
        }
        collectFieldValuesByPartner.add(fieldalue);
        collectedValuesByPartner.put(fieldName, collectFieldValuesByPartner);
        collectedValues.put(extId, collectedValuesByPartner);
    } 

    public static List<String> getCollectedFieldValuesForPartner(String extId, String fieldName) {
        Map<String, List<String>> collectedValuesByPartner = collectedValues.get(extId);
        if (collectedValuesByPartner == null) {
            collectedValuesByPartner = new Map<String, List<String>>();
        }
        List<String> collectFieldValuesByPartner = collectedValuesByPartner.get(fieldName);
        return collectFieldValuesByPartner == null ? new List<String>() : collectFieldValuesByPartner;
    }

    public static List<String> getCollectedFieldValuesForAll(String fieldName) {
        List<String> fieldValues = new List<String>();
        for (String partnerId : collectedValues.keySet()) {
            Map<String, List<String>> collectedValuesByPartner = collectedValues.get(partnerId);
            if (collectedValuesByPartner != null && collectedValuesByPartner.get(fieldName) != null) {
                fieldValues.addAll(collectedValuesByPartner.get(fieldName));
            }
        }
        return fieldValues;
    }

}